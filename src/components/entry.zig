const std = @import("std");
const cl = @import("zclay");

const theme = @import("../theme.zig");

pub const Props = struct {
    name: []const u8,
    kind: std.fs.Dir.Entry.Kind,
    selected: bool,
    hovered: bool,

    pub fn init(name: []const u8, kind: std.fs.Dir.Entry.Kind) @This() {
        return .{
            .name = name,
            .kind = kind,
            .selected = false,
            .hovered = false,
        };
    }
};

fn getBackgroundColor(props: Props) cl.Color {
    if (props.selected) {
        return theme.entryItem.background.selected;
    }

    if (props.hovered) {
        return theme.entryItem.background.hovered;
    }

    return theme.entryItem.background.default;
}

pub fn render(props: Props, index: u32) void {
    cl.UI()(.{
        .id = .IDI("Entry", index),
        .layout = cl.LayoutConfig{
            .sizing = .{ .w = .grow, .h = .fixed(50) },
            .padding = .{ .left = 16 },
            .child_alignment = .{ .x = .left, .y = .center },
        },
        .background_color = getBackgroundColor(props),
    })({
        cl.text(props.name, .{ .font_size = 24, .color = theme.entryItem.text.primary });
    });
}
