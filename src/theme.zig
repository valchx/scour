const cl = @import("zclay");

pub const background = struct {
    pub const primary: cl.Color = .{ 27, 28, 30, 255 };
    pub const secondary: cl.Color = .{ 35, 35, 38, 255 };
};

pub const scrollBar = struct {
    pub const bar: cl.Color = .{ 35, 35, 38, 255 };
    pub const thumb: cl.Color = .{ 73, 73, 79, 255 };
};

pub const cwdInput = struct {
    pub const background: cl.Color = .{ 27, 28, 30, 255 };
    pub const text: cl.Color = .{ 250, 250, 255, 255 };
};

pub const entryItem = struct {
    pub const background = struct {
        pub const default: cl.Color = .{ 19, 67, 98, 255 };
        pub const selected: cl.Color = .{ 55, 161, 228, 255 };
        pub const hovered: cl.Color = .{ 24, 95, 138, 255 };
    };
    pub const text = struct {
        pub const primary: cl.Color = .{ 250, 250, 255, 255 };
    };
};
