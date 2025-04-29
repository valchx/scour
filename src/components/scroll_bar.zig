const cl = @import("zclay");
const rl = @import("raylib");

const theme = @import("../theme.zig");

const Self = @This();

parent_id: cl.ElementId,
parent_x_offset: f32,

pub fn init(
    parent_id: cl.ElementId,
    parent_x_offset: f32,
) Self {
    return .{
        .parent_id = parent_id,
        .parent_x_offset = parent_x_offset,
    };
}

pub fn render(self: Self) void {
    const scroll_delta = cl.getScrollContainerData(self.parent_id);
    if (scroll_delta.content_dimensions.h > 0 and scroll_delta.content_dimensions.h > scroll_delta.scroll_container_dimensions.h) {
        const containerH = scroll_delta.scroll_container_dimensions.h;
        const contentH = scroll_delta.content_dimensions.h;

        const y_offset = -(scroll_delta.scroll_position.y / contentH) * containerH;
        const thumb_height = (containerH / contentH) * containerH;
        const thumb_width = 20;

        const scroll_bar_thumb_id = cl.ElementId.localID("scroll-bar-thumb");

        cl.UI()(
            cl.ElementDeclaration{
                .id = cl.ElementId.localID("scroll-bar"),
                .floating = .{
                    .attach_to = cl.FloatingAttachToElement.to_parent,
                    .offset = .{
                        .y = 0,
                        .x = -self.parent_x_offset,
                    },
                    .zIndex = 1,
                    .parentId = self.parent_id.id,
                    .attach_points = .{
                        .element = .right_top,
                        .parent = .right_top,
                    },
                },
                .layout = .{
                    .sizing = .{
                        .h = .grow,
                        .w = .fixed(thumb_width + 4),
                    },
                },
                .background_color = theme.scrollBar.bar,
            },
        )({});

        cl.UI()(
            cl.ElementDeclaration{
                .id = scroll_bar_thumb_id,
                .floating = .{
                    .attach_to = cl.FloatingAttachToElement.to_parent,
                    .offset = .{
                        .y = y_offset,
                        .x = -2 - self.parent_x_offset,
                    },
                    .zIndex = 1,
                    .parentId = self.parent_id.id,
                    .attach_points = .{
                        .element = .right_top,
                        .parent = .right_top,
                    },
                },
                .layout = .{
                    .sizing = .{
                        .h = .fixed(thumb_height),
                        .w = .fixed(thumb_width),
                    },
                },
                .background_color = theme.scrollBar.thumb,
            .corner_radius = .all(5)
            },
        )({});

        // TODO : Not working properly
        // if (rl.isMouseButtonDown(.left) and cl.pointerOver(scroll_bar_thumb_id)) {
        //     const scroll_container_data = cl.getScrollContainerData(self.parent_id);
        //     scroll_container_data.scroll_position.*.y -= rl.getMouseDelta().y;
        // }
    }
}
