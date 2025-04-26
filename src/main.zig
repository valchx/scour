const std = @import("std");
const rl = @import("raylib");
const cl = @import("zclay");

const renderer = @import("raylib_render_clay.zig");

const fileList = @import("./components/file_list.zig");

fn loadFont(file_data: ?[]const u8, font_id: u16, font_size: i32) !void {
    renderer.raylib_fonts[font_id] = try rl.loadFontFromMemory(".ttf", file_data, font_size * 2, null);
    rl.setTextureFilter(renderer.raylib_fonts[font_id].?.texture, .bilinear);
}

fn loadImage(comptime path: [:0]const u8) !rl.Texture2D {
    const texture = try rl.loadTextureFromImage(try rl.loadImageFromMemory(@ptrCast(std.fs.path.extension(path)), @embedFile(path)));
    rl.setTextureFilter(texture, .bilinear);
    return texture;
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // init clay
    const min_memory_size: u32 = cl.minMemorySize();
    const memory = try allocator.alloc(u8, min_memory_size);
    defer allocator.free(memory);
    const arena: cl.Arena = cl.createArenaWithCapacityAndMemory(memory);
    _ = cl.initialize(arena, .{ .h = 1000, .w = 1000 }, .{});
    cl.setMeasureTextFunction(void, {}, renderer.measureText);

    // init raylib
    rl.setConfigFlags(.{
        .msaa_4x_hint = true,
        .window_resizable = true,
    });
    rl.initWindow(1000, 1000, "Scour");
    rl.setWindowMinSize(300, 100);
    rl.setTargetFPS(120);

    // load assets
    try loadFont(@embedFile("./resources/Roboto-Regular.ttf"), 0, 24);

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

        cl.beginLayout();
        fileList.render();
        var render_commands = cl.endLayout();

        rl.beginDrawing();
        try renderer.clayRaylibRender(&render_commands, allocator);
        rl.endDrawing();
    }
}
