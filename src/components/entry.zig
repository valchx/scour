const std = @import("std");
const cl = @import("zclay");
const rl = @import("raylib");

const theme = @import("../theme.zig");

const Self = @This();

all_entries: []Self,
name: []const u8,
kind: std.fs.Dir.Entry.Kind,
selected: bool,
hovered: bool,

pub fn init(
    name: []const u8,
    kind: std.fs.Dir.Entry.Kind,
    all_entries: []Self,
) Self {
    return Self{
        .name = name,
        .kind = kind,
        .selected = false,
        .hovered = false,
        .all_entries = all_entries,
    };
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

fn onClick(self: *@This()) void {
    for (self.*.all_entries) |*entry| {
        if (entry.*.selected) {
            entry.*.selected = false;
        }
    }

    self.*.selected = true;
}

pub fn render(self: *Self, index: u32) void {
    const id = cl.ElementId.IDI("Entry-", index);
    cl.UI()(cl.ElementDeclaration{
        .id = id,
        .layout = cl.LayoutConfig{
            .sizing = .{ .w = .grow, .h = .fixed(50) },
            .padding = .{ .left = 16 },
            .child_alignment = .{ .x = .left, .y = .center },
        },
        .background_color = self.*.getBackgroundColor(cl.hovered()),
    })({
        if (rl.isMouseButtonPressed(.left) and cl.pointerOver(id)) {
            self.onClick();
        }

        self.hovered = cl.pointerOver(id);

        cl.text(self.*.name, .{ .font_size = 24, .color = theme.entryItem.text.primary });
        if (self.*.kind == .directory) {
            cl.text("/", .{ .font_size = 24, .color = theme.entryItem.text.primary });
        }
    });
}
