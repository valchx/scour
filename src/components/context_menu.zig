const cl = @import("zclay");
const rl = @import("raylib");

const theme = @import("../theme.zig");
const ClickHandler = @import("./Interfaces/click_handler.zig");

const Self = @This();

pub const Option = struct {
    label: []const u8,
    click_handler: ClickHandler,
};

pub const Props = struct {
    pos: cl.Vector2,
    parent_id: cl.ElementId,
    options: []const Option,
};

fn getEntryBackgroundColor(is_hovered: bool) cl.Color {
    if (is_hovered) {
        return theme.contextMenu.entry.hovered;
    }

    return theme.contextMenu.entry.background;
}

pub fn render(props: Props) !void {
    cl.UI()(cl.ElementDeclaration{
        .id = cl.getElementId("ContextMenu"),
        .floating = .{
            .attach_to = .to_root,
            .parentId = props.parent_id.id,
            .offset = props.pos,
        },
        .layout = cl.LayoutConfig{
            .direction = .top_to_bottom,
            .sizing = .{ .w = .fit, .h = .fit },
            .child_alignment = .{ .x = .center, .y = .center },
            .padding = .all(8),
            .child_gap = 4,
        },
        .background_color = theme.background.primary,
    })({
        for (props.options, 0..) |option, i| {
            const item_id = cl.ElementId.IDI("ContextMenuItem-", @intCast(i));
            const is_hovered = cl.pointerOver(item_id);
            cl.UI()(cl.ElementDeclaration{
                .id = item_id,
                .layout = cl.LayoutConfig{
                    .sizing = .{ .w = .grow, .h = .fit },
                    .padding = .all(8),
                    .child_alignment = .{ .x = .left, .y = .center },
                },
                .background_color = getEntryBackgroundColor(is_hovered),
            })({
                if (rl.isMouseButtonPressed(.left) and cl.pointerOver(item_id)) {
                    try option.click_handler.handleClick();
                }

                cl.text(option.label, .{
                    .font_size = 24,
                    .color = theme.entryItem.text.primary,
                });
            });
        }
    });
}
