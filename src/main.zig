const std = @import("std");
const rl = @import("raylib");
const cl = @import("zclay");

const Utils = @import("./utils.zig");

const renderer = @import("raylib_render_clay.zig");

const EntryList = @import("./components/entry_list.zig");

pub fn main() !void {
    const page_allocator = std.heap.page_allocator;

    // init clay
    const min_memory_size: u32 = cl.minMemorySize();
    const memory = try page_allocator.alloc(u8, min_memory_size);
    defer page_allocator.free(memory);
    const arena: cl.Arena = cl.createArenaWithCapacityAndMemory(memory);
    _ = cl.initialize(arena, .{ .h = 1000, .w = 1000 }, .{});
    cl.setMeasureTextFunction(void, {}, renderer.measureText);

    // init raylib
    rl.setConfigFlags(.{
        .msaa_4x_hint = true,
        .window_resizable = true,
    });
    rl.initWindow(1280, 820, "Scour");
    rl.setWindowMinSize(300, 100);
    rl.setTargetFPS(120);

    // load assets
    try Utils.loadFont(@embedFile("./resources/Roboto-Regular.ttf"), 0, 24);

    // State
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};

    var entries_arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer entries_arena.deinit();
    const entries_allocator = entries_arena.allocator();
    var entries = EntryList.init(entries_allocator);
    defer entries.deinit();
    const absolute_path = try std.fs.cwd().realpathAlloc(entries_allocator, "./");
    try entries.changeDir(absolute_path);

    var debug_mode_enabled = false;
    while (!rl.windowShouldClose()) {
        if (rl.isKeyPressed(.d)) {
            debug_mode_enabled = !debug_mode_enabled;
            cl.setDebugModeEnabled(debug_mode_enabled);
        }

        const mouse_pos = rl.getMousePosition();
        cl.setPointerState(.{
            .x = mouse_pos.x,
            .y = mouse_pos.y,
        }, rl.isMouseButtonDown(.left));

        const scroll_delta = rl.getMouseWheelMoveV().multiply(.{ .x = 6, .y = 6 });
        cl.updateScrollContainers(
            false,
            .{ .x = scroll_delta.x, .y = scroll_delta.y },
            rl.getFrameTime(),
        );

        cl.setLayoutDimensions(.{
            .w = @floatFromInt(rl.getScreenWidth()),
            .h = @floatFromInt(rl.getScreenHeight()),
        });

        // Update State
        entries.computeNextEntries();

        // Draw
        cl.beginLayout();
        try entries.render();
        var render_commands = cl.endLayout();

        rl.beginDrawing();
        try renderer.clayRaylibRender(&render_commands, page_allocator);
        rl.endDrawing();
    }
}
