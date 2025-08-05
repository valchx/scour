const std = @import("std");
const builtin = @import("builtin");

const cl = @import("zclay");
const rl = @import("raylib");

const Utils = @import("../utils.zig");
const theme = @import("../theme.zig");

const EntryList = @import("./entry_list.zig");

const Self = @This();

name: []const u8,
full_path: []const u8,
kind: std.fs.Dir.Entry.Kind,
selected: bool = false,
hovered: bool = false,
last_click_time: ?i64 = null,
entryList: *EntryList,
_allocator: std.mem.Allocator,

pub fn init(
    allocator: std.mem.Allocator,
    name: []const u8,
    full_path: []const u8,
    kind: std.fs.Dir.Entry.Kind,
    entryList: *EntryList,
) !Self {
    return Self{
        ._allocator = allocator,
        .name = try allocator.dupe(u8, name),
        .full_path = try allocator.dupe(u8, full_path),
        .kind = kind,
        .entryList = entryList,
    };
}

pub fn deinit(self: *Self) void {
    self._allocator.free(self.name);
    self._allocator.free(self.full_path);
}

fn getBackgroundColor(self: Self, hovered: bool) cl.Color {
    if (self.selected) {
        return theme.entryItem.background.selected;
    }

    if (hovered) {
        return theme.entryItem.background.hovered;
    }

    return theme.entryItem.background.default;
}

const max_double_click_time_ms = 200;

fn onDoubleClick(self: *Self) !void {
    switch (self.kind) {
        .directory => {
            try self.entryList.changeDir(self.full_path);
        },
        .file => {
            self.*.selected = false;
            switch (builtin.os.tag) {
                .linux, .macos => {
                    var process = std.process.Child.init(
                        &[_][]const u8{
                            "xdg-open",
                            self.full_path,
                        },
                        self._allocator,
                    );

                    process.spawn() catch |err| {
                        std.debug.print("Failed to spawn process: {}\n", .{err});
                        return err;
                    };
                },
                else => {},
            }
        },
        else => {},
    }
}

fn onClick(self: *Self, index: usize) !void {
    defer self.*.last_click_time = std.time.milliTimestamp();

    if (self.last_click_time) |last_click_time| {
        const double_click_time = std.time.milliTimestamp() - last_click_time;
        if (double_click_time < max_double_click_time_ms) {
            try self.onDoubleClick();
            return;
        }
    }

    self.entryList.selectEntry(index);
}

pub fn render(self: *Self, index: u32) !void {
    const id = cl.ElementId.IDI("Entry-", index);
    cl.UI()(cl.ElementDeclaration{
        .id = id,
        .layout = cl.LayoutConfig{
            .sizing = .{ .w = .grow, .h = .fixed(50) },
            .padding = .{ .left = 16 },
            .child_alignment = .{ .x = .left, .y = .center },
        },
        .background_color = self.getBackgroundColor(cl.hovered()),
    })({
        if (rl.isMouseButtonPressed(.left) and cl.pointerOver(id)) {
            try self.onClick(index);
        }

        self.hovered = cl.pointerOver(id);

        cl.text(self.name, .{ .font_size = 24, .color = theme.entryItem.text.primary });
        if (self.kind == .directory) {
            cl.text("/", .{ .font_size = 24, .color = theme.entryItem.text.primary });
        }
    });
}
