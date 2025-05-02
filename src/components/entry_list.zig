const std = @import("std");
const cl = @import("zclay");
const rl = @import("raylib");

const theme = @import("../theme.zig");

const Entry = @import("./entry.zig");
const ScrollBar = @import("./scroll_bar.zig");
const CwdInput = @import("./cwd_input.zig");

const Self = @This();

_allocator: std.mem.Allocator,
entries: std.ArrayList(*Entry),
next_entries: ?std.ArrayList(*Entry) = null,
absolute_path: ?[]const u8 = null,
cwd_input: ?CwdInput = null,

/// To set the `absolute_path` field, call `changeDir`
pub fn init(
    allocator: std.mem.Allocator,
) !Self {
    return Self{
        .entries = std.ArrayList(*Entry).init(allocator),
        ._allocator = allocator,
    };
}

pub fn deinit(self: Self) void {
    self.deinitEntries();
    if (self.absolute_path) |absolute_path| {
        self._allocator.free(absolute_path);
    }
}

pub fn changeDir(self: *Self, absolute_path: []const u8) !void {
    try self.computeNextEntries(absolute_path);

    if (self.absolute_path) |old_absolute_path| {
        self._allocator.free(old_absolute_path);
    }
    self.*.absolute_path = try self.*._allocator.dupe(u8, absolute_path);
}

fn deinitEntries(self: Self) void {
    for (self.entries.items) |entry| {
        entry.deinit();
    }
    self.entries.deinit();
}

pub fn selectEntry(self: *Self, entry_to_select: *Entry) void {
    for (self.*.entries.items) |entry| {
        entry.*.selected = false;
    }

    entry_to_select.*.selected = true;
}

pub fn computeEntries(self: *Self) void {
    if (self.next_entries) |next_entries| {
        self.deinitEntries();
        self.*.entries = next_entries;
        self.*.next_entries = null;
        self.*.cwd_input = CwdInput.init(
            self._allocator,
            self.absolute_path.?,
            self,
        );
    }
}

fn computeNextEntries(
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
        var cwd_input = &self.*.cwd_input.?;
        try cwd_input.render();

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
