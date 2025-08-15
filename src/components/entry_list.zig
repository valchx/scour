const std = @import("std");
const cl = @import("zclay");
const rl = @import("raylib");

const theme = @import("../theme.zig");

const Entry = @import("./entry.zig");
const ScrollBar = @import("./scroll_bar.zig");
const NavBar = @import("./nav_bar.zig");
const ContextMenu = @import("./context_menu.zig");

const ClickHandler = @import("./Interfaces/click_handler.zig");

const Self = @This();

const Selection = struct {
    first: usize,
    last: usize,
};

_allocator: std.mem.Allocator,
entries: std.ArrayList(*Entry),
next_entries: ?std.ArrayList(*Entry) = null,
paths_stack: std.ArrayList([]const u8),
nav_bar: ?NavBar = null,
selection: ?Selection = null,
context_menu_pos: ?cl.Vector2 = null,

pub fn init(
    allocator: std.mem.Allocator,
) Self {
    return Self{
        .entries = std.ArrayList(*Entry).init(allocator),
        ._allocator = allocator,
        .paths_stack = std.ArrayList([]const u8).init(allocator),
        .nav_bar = undefined,
    };
}

pub fn deinit(self: Self) void {
    self.deinitEntries();
    for (self.paths_stack.items) |path| {
        self._allocator.free(path);
    }
}

pub fn changeDir(self: *Self, absolute_path: []const u8) !void {
    try self.changeDirWithoutPushingToStack(absolute_path);

    try self.paths_stack.append(try self.*._allocator.dupe(u8, absolute_path));

    self.*.selection = null;
}

fn deinitEntries(self: Self) void {
    for (self.entries.items) |entry| {
        entry.deinit();
    }
    self.entries.deinit();
}

pub fn selectEntry(self: *Self, select_index: usize) void {
    self.*.context_menu_pos = null;

    if ((rl.isKeyDown(.left_shift) or rl.isKeyDown(.right_shift))) {
        if (self.selection) |*selection| {
            selection.*.last = select_index;
        }
    } else {
        self.*.selection = Selection{ .first = select_index, .last = select_index };
    }

    if (self.selection) |selection| {
        const start = if (selection.first < selection.last) selection.first else selection.last;
        const end = if (selection.first < selection.last) selection.last else selection.first;

        for (self.*.entries.items, 0..) |entry, i| {
            if (i >= start and i <= end) {
                entry.*.selected = true;
            } else {
                entry.*.selected = false;
            }
        }
    }
}

pub fn computeNextEntries(self: *Self) void {
    if (self.next_entries) |next_entries| {
        self.deinitEntries();
        self.*.entries = next_entries;
        self.*.next_entries = null;
        if (self.nav_bar) |nav_bar| {
            nav_bar.deinit();
        }
        self.*.nav_bar = NavBar.init(self._allocator, self, self.paths_stack.getLast());
    }
}

const SortOrder = enum {
    asc,
    desc,
};

fn sortNextEntries(self: *Self, sortOrder: SortOrder) !void {
    const next_entries = try self.entries.clone();

    const SortCtx = struct {
        sortOrder: std.math.Order,
    };

    const order = if (sortOrder == .asc) .lhs else .rhs;

    std.mem.sort(
        *Entry,
        next_entries.items,
        SortCtx{
            .sortOrder = order,
        },
        struct {
            fn lessThan(ctx: SortCtx, lhs: *Entry, rhs: *Entry) bool {
                return std.mem.order(u8, lhs.*.name, rhs.*.name) == ctx.sortOrder;
            }
        }.lessThan,
    );
}

fn changeDirWithoutPushingToStack(
    self: *Self,
    absolute_path: ?[]const u8,
) !void {
    if (absolute_path == null) {
        return;
    }

    var dir = try std.fs.openDirAbsolute(absolute_path.?, .{ .iterate = true });
    defer dir.close();

    self.*.next_entries = std.ArrayList(*Entry).init(self._allocator);

    // Add "Go back" entry if we're not at the root
    if (!std.mem.eql(u8, "/", absolute_path.?)) {
        const go_back_absolute_path = try dir.realpathAlloc(self._allocator, "..");
        defer self._allocator.free(go_back_absolute_path);
        const entry = try self.*._allocator.create(Entry);
        entry.* = try Entry.init(
            self._allocator,
            "..",
            go_back_absolute_path,
            .directory,
            self,
        );
        try self.*.next_entries.?.append(
            entry,
        );
    }

    var iterator = dir.iterate();
    next_entry: while (try iterator.next()) |dirEntry| {
        // TODO : Do something with sym_link ?
        if (dirEntry.kind != .file and dirEntry.kind != .directory) {
            continue :next_entry;
        }
        const full_path = dir.realpathAlloc(self.*._allocator, dirEntry.name) catch |err| {
            return err;
        };
        defer self.*._allocator.free(full_path);
        const entry = try self.*._allocator.create(Entry);
        entry.* = try Entry.init(
            self._allocator,
            dirEntry.name,
            full_path,
            dirEntry.kind,
            self,
        );
        try self.*.next_entries.?.append(
            entry,
        );
    }
}

fn copySelection(ptr: *anyopaque) !void {
    const entry_list: *Self = @ptrCast(@alignCast(ptr));
    std.debug.print("Copying {}\n", .{entry_list.*.entries.items.len});
}

fn paste(ptr: *anyopaque) !void {
    const empty: *void = @ptrCast(@alignCast(ptr));
    std.debug.print("Pasting {any}\n", .{empty});
}

pub fn render(self: *Self) !void {
    const outer_container_id = cl.ElementId.ID("EntryListOuterContainer");
    const outer_padding = 16;
    cl.UI()(cl.ElementDeclaration{
        .id = outer_container_id,
        .layout = .{
            .direction = .top_to_bottom,
            .sizing = .{
                .h = .grow,
                .w = .grow,
            },
            .padding = .all(outer_padding),
            .child_gap = 16,
        },
        .background_color = theme.background.primary,
    })({
        if (self.nav_bar) |*nav_bar| {
            try nav_bar.render();
        }

        if (rl.isMouseButtonPressed(.right)) {
            const mouse_pos = rl.getMousePosition();
            self.*.context_menu_pos = cl.Vector2{
                .x = mouse_pos.x,
                .y = mouse_pos.y,
            };
        }

        if (self.context_menu_pos) |pos| {
            // TODO : If click was over the selection, context menu should
            // include file operations on these (copy, cut, delete, rename, ...)
            const context_props = ContextMenu.Props{
                .parent_id = outer_container_id,
                .pos = pos,
                .options = &[_]ContextMenu.Option{
                    .{
                        .label = "Copy",
                        .click_handler = .{
                            .ptr = self,
                            .vtable = .{ .handleClickFn = copySelection },
                        },
                    },
                    .{
                        .label = "Paste",
                        .click_handler = .{
                            .ptr = self,
                            .vtable = .{ .handleClickFn = paste },
                        },
                    },
                },
            };
            try ContextMenu.render(context_props);
        }

        const list_container_id = cl.ElementId.ID("EntryList");
        const list_padding = 2;
        cl.UI()(cl.ElementDeclaration{
            .id = list_container_id,
            .layout = .{
                .direction = .top_to_bottom,
                .sizing = .{ .h = .grow, .w = .grow },
                .padding = .all(list_padding),
                .child_alignment = .{ .x = .center, .y = .top },
                .child_gap = 2,
            },
            .scroll = .{ .vertical = true },
            .background_color = theme.background.secondary,
        })({
            ScrollBar.init(
                list_container_id,
                0,
            ).render();
            for (self.entries.items, 0..) |entry, i| {
                try entry.render(@intCast(i));
            }
        });
    });
}
