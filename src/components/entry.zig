const std = @import("std");
const cl = @import("zclay");

const theme = @import("../theme.zig");

pub const Entry = struct {
    name: []const u8,
    kind: std.fs.Dir.Entry.Kind,
    selected: bool,

    pub fn init(name: []const u8, kind: std.fs.Dir.Entry.Kind) @This() {
        return .{
            .name = name,
            .kind = kind,
            .selected = false,
        };
    }

    fn getBackgroundColor(self: @This(), hovered: bool) cl.Color {
        if (self.selected) {
            return theme.entryItem.background.selected;
        }

        if (hovered) {
            return theme.entryItem.background.hovered;
        }

        return theme.entryItem.background.default;
    }

    pub fn render(self: @This(), index: u32) void {
        const id = cl.ElementId.IDI("Entry", index);
        cl.UI()(cl.ElementDeclaration{
            .id = id,
            .layout = cl.LayoutConfig{
                .sizing = .{ .w = .grow, .h = .fixed(50) },
                .padding = .{ .left = 16 },
                .child_alignment = .{ .x = .left, .y = .center },
            },
            .background_color = self.getBackgroundColor(cl.hovered()),
        })({
            cl.text(self.name, .{ .font_size = 24, .color = theme.entryItem.text.primary });
        });
    }
};
