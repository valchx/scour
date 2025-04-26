const cl = @import("zclay");

pub const background = struct {
    pub const primary: cl.Color = .{ 27, 28, 30, 255 };
    pub const secondary: cl.Color = .{ 35, 35, 38, 255 };
};

pub const fileItem = struct {
    pub const primary: cl.Color = .{ 55, 161, 228, 255 };
    pub const secondary: cl.Color = .{ 19, 67, 98, 255 };
};

pub const text = struct {
    pub const primary: cl.Color = .{ 250, 250, 255, 255 };
};
