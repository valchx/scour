const std = @import("std");

const entry = @import("./components/entry.zig");

pub fn getEntriesProps(allocator: std.mem.Allocator, dir: std.fs.Dir) ![]const entry.Props {
    var iterator = dir.iterate();
    var entries = std.ArrayList(entry.Props).init(allocator);

    while (try iterator.next()) |dirEntry| {
        const entryProps = entry.Props.init(try allocator.dupe(u8, dirEntry.name), dirEntry.kind);
        try entries.append(entryProps);
    }

    return entries.items;
}
