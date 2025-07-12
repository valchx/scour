const std = @import("std");
const cl = @import("zclay");
const rl = @import("raylib");

const Utils = @import("../utils.zig");
const theme = @import("../theme.zig");
const ClickHandler = @import("./Interfaces/click_handler.zig");

const Self = @This();

click_click_handler: ?ClickHandler,

label: []const u8,
hovered: bool = false,
disabled: bool = true,
id_suffix: []const u8,

pub fn init(
    click_handler: ?ClickHandler,
    id_suffix: []const u8,
    label: []const u8,
    disabled: bool,
) Self {
    return Self{
        .click_click_handler = click_handler,
        .id_suffix = id_suffix,
        .label = label,
        .disabled = disabled,
    };
}

pub fn getBackgroundColor(self: Self) cl.Color {
    if (self.disabled) {
        return theme.background.primary;
    }

    if (self.hovered) {
        return theme.entryItem.background.hovered;
    }

    return theme.entryItem.background.default;
}

fn onClick(self: Self) !void {
    if (self.disabled) return;

    if (self.click_click_handler) |click_handler| {
        try click_handler.handleClick();
    }
}

pub fn render(self: *Self) !void {
    const id = cl.ElementId.localID(self.id_suffix);
    cl.UI()(cl.ElementDeclaration{
        .id = id,
        .layout = cl.LayoutConfig{
            .sizing = .{ .w = .fit, .h = .fit },
            .child_alignment = .{ .x = .center, .y = .center },
            .padding = .all(8),
        },
        .background_color = self.getBackgroundColor(),
    })({
        if (rl.isMouseButtonPressed(.left) and cl.pointerOver(id)) {
            try self.onClick();
        }

        self.hovered = cl.pointerOver(id);

        cl.text(self.label, .{ .font_size = 24, .color = theme.entryItem.text.primary });
    });
}
