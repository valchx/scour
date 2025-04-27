const std = @import("std");

const Entry = @import("./components/entry.zig");

pub fn getEntriesProps(allocator: std.mem.Allocator, dir: std.fs.Dir) ![]Entry {
    var iterator = dir.iterate();
    var entries = std.ArrayList(Entry).init(allocator);

    while (try iterator.next()) |dirEntry| {
        const entryProps = Entry.init(
            try allocator.dupe(u8, dirEntry.name),
            dirEntry.kind,
            &[_]Entry{},
        );
        try entries.append(entryProps);
    }

    const final_entries = entries.items;
    for (final_entries) |*entry| {
        entry.all_entries = final_entries;
    }

    return final_entries;
}
