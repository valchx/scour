// nav_bar.zig
const std = @import("std");
const cl = @import("zclay");
const rl = @import("raylib");

const theme = @import("../theme.zig");

const EntryList = @import("./entry_list.zig");
const Button = @import("./button.zig");
const CwdInput = @import("./cwd_input.zig");
const ClickHandler = @import("./Interfaces/click_handler.zig");

const Self = @This();

_allocator: std.mem.Allocator,
entry_list: *EntryList,
cwd_input: CwdInput,

pub fn init(
    allocator: std.mem.Allocator,
    entry_list: *EntryList,
    cwd_absolute_path: []const u8,
) Self {
    return .{
        ._allocator = allocator,
        .entry_list = entry_list,
        .cwd_input = CwdInput.init(
            allocator,
            cwd_absolute_path,
            entry_list,
        ),
    };
}

pub fn deinit(self: Self) void {
    self.cwd_input.deinit();
}

pub fn resetCwdInput(self: *Self, path: []const u8) void {
    if (self.cwd_input) |cwd_input| {
        cwd_input.deinit();
    }

    self.*.cwd_input = CwdInput.init(
        self._allocator,
        path,
        self.entry_list,
    );
}

fn go_back(entry_list: *EntryList) !void {
    if (entry_list.paths_stack.items.len < 2) return;

    const removed = entry_list.*.paths_stack.pop();
    if (removed) |path| {
        entry_list._allocator.free(path);
    }
    try entry_list.changeDirWithoutPushingToStack(entry_list.paths_stack.getLast());
}

fn go_up(entry_list: *EntryList) !void {
    const current_path_op = entry_list.paths_stack.getLastOrNull();

    if (current_path_op) |current_path| {
        if (std.mem.eql(u8, current_path, "/"))
            return;

        var dir = try std.fs.openDirAbsolute(current_path, .{ .iterate = false });
        defer dir.close();
        const go_up_absolute_path = try dir.realpathAlloc(entry_list._allocator, "..");
        defer entry_list._allocator.free(go_up_absolute_path);

        try entry_list.changeDir(go_up_absolute_path);
    }
}

fn goBackWrapper(ptr: *anyopaque) anyerror!void {
    const entry_list: *EntryList = @ptrCast(@alignCast(ptr));
    try go_back(entry_list);
}

fn goUpWrapper(ptr: *anyopaque) anyerror!void {
    const entry_list: *EntryList = @ptrCast(@alignCast(ptr));
    try go_up(entry_list);
}

pub fn render(self: *Self) !void {
    cl.UI()(cl.ElementDeclaration{
        .id = .ID("Navigation"),
        .layout = .{
            .direction = .left_to_right,
            .sizing = .{ .h = .fit, .w = .grow },
            .padding = .all(4),
            .child_alignment = .{ .x = .center, .y = .center },
            .child_gap = 4,
        },
        .background_color = theme.background.secondary,
    })({
        const go_back_closure = ClickHandler{
            .ptr = self.entry_list,
            .handleClickFn = goBackWrapper,
        };
        var go_back_button = Button.init(
            go_back_closure,
            "back_button",
            "BACK",
            self.entry_list.paths_stack.items.len < 2,
        );
        try go_back_button.render();

        const go_up_closure = ClickHandler{
            .ptr = self.entry_list,
            .handleClickFn = goUpWrapper,
        };
        var go_up_button = Button.init(
            go_up_closure,
            "up_button",
            "UP",
            std.mem.eql(u8, self.entry_list.paths_stack.getLast(), "/"),
        );
        try go_up_button.render();

        try self.cwd_input.render();
    });
}
