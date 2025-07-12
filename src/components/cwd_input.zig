const std = @import("std");
const cl = @import("zclay");
const rl = @import("raylib");

const Utils = @import("../utils.zig");
const theme = @import("../theme.zig");

const EntryList = @import("./entry_list.zig");
const TextInput = @import("./text_input.zig");

const Self = @This();

cwd_absolute_path: []const u8,
_allocator: std.mem.Allocator,
entry_list: *EntryList,
text_input: ?TextInput,

pub fn init(
    allocator: std.mem.Allocator,
    cwd_absolute_path: []const u8,
    entry_list: *EntryList,
) Self {
    return Self{
        ._allocator = allocator,
        .cwd_absolute_path = cwd_absolute_path,
        .entry_list = entry_list,
        .text_input = null,
    };
}

pub fn textInput(self: *Self) *TextInput {
    if (self.text_input) |*text_input| {
        return text_input;
    }

    self.text_input = TextInput.init(
        self._allocator,
        self,
        &.{
            // .on_type_callback = null,
            .on_focus_callback = null,
            .on_blur_callback = onBlur,
        },
        "cwd_input",
        self.cwd_absolute_path,
    );

    return if (self.text_input) |*text_input| text_input else unreachable;
}

pub fn deinit(self: Self) void {
    if (self.text_input) |text_input| {
        text_input.deinit();
    }
}

fn onBlur(ptr: *anyopaque, dir: []const u8) !void {
    const self: *Self = @ptrCast(@alignCast(ptr));

    self.entry_list.*.changeDir(dir) catch {};
}
