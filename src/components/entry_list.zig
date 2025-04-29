const std = @import("std");
const cl = @import("zclay");

const theme = @import("../theme.zig");

const Entry = @import("./entry.zig");

const Self = @This();

_allocator: std.mem.Allocator,
entries: std.ArrayList(*Entry),
absolute_path: []const u8,

pub fn init(
    allocator: std.mem.Allocator,
) !Self {
    return Self{
        .entries = std.ArrayList(*Entry).init(allocator),
        .absolute_path = "/",
        ._allocator = allocator,
    };
}

pub fn deinit(self: Self) void {
    for (self.entries.items) |entry| {
        entry.deinit();
    }
    self.entries.deinit();
    self._allocator.free(self.absolute_path);
}

pub fn render(self: Self) !void {
    cl.UI()(.{
        .id = .ID("EntryListOuterContainer"),
        .layout = .{ .direction = .left_to_right, .sizing = .grow, .padding = .all(16), .child_gap = 16 },
        .background_color = theme.background.primary,
    })({
        cl.UI()(.{
            .id = .ID("EntryList"),
            .layout = .{
                .direction = .top_to_bottom,
                .sizing = .{ .h = .grow, .w = .grow },
                .padding = .all(16),
                .child_alignment = .{ .x = .center, .y = .top },
                .child_gap = 2,
            },
            .background_color = theme.background.secondary,
        })({
            for (self.entries.items, 0..) |entry, i| {
                try entry.render(@intCast(i));
            }
        });
    });
}

pub fn changeDir(self: *Self, absolute_path: []const u8) !void {
    self.*.absolute_path = try self.*._allocator.dupe(u8, absolute_path);

    try self.computeEntries();
}

pub fn selectEntry(self: *Self, entry_to_select: *Entry) void {
    for (self.*.entries.items) |entry| {
        entry.*.selected = false;
    }

    entry_to_select.*.selected = true;
}

fn computeEntries(
    self: *Self,
) !void {
    var dir = try std.fs.openDirAbsolute(self.*.absolute_path, .{ .iterate = true });
    defer dir.close();

    self.*.entries.clearRetainingCapacity();

    // Add "Go back" entry if we're not at the root
    if (!std.mem.eql(u8, "/", self.*.absolute_path)) {
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
        try self.*.entries.append(
            entry,
        );
    }

    var iterator = dir.iterate();
    next_entry: while (try iterator.next()) |dirEntry| {
        if (dirEntry.kind != .file and dirEntry.kind != .directory) {
            continue :next_entry;
        }
        const full_path = dir.realpathAlloc(self.*._allocator, dirEntry.name) catch |err| {
            std.log.debug(
                \\Error : Could not create full path :
                \\  Target : {s}
                \\  Kind : {}
                \\  From : {s}
                \\{}
                \\
            , .{
                dirEntry.name,
                dirEntry.kind,
                self.*.absolute_path,
                err,
            });
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
        try self.*.entries.append(
            entry,
        );
    }
}
