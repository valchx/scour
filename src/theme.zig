const cl = @import("zclay");

const defaults = struct {
    pub const background_dark: cl.Color = .{ 27, 28, 30, 255 };
    pub const background_light: cl.Color = .{ 35, 35, 38, 255 };
    pub const grey: cl.Color = .{ 73, 73, 79, 255 };
    pub const primary: cl.Color = .{ 55, 161, 228, 255 };
    pub const secondary: cl.Color = .{ 19, 67, 98, 255 };
    pub const accent: cl.Color = .{ 24, 95, 138, 255 };
    pub const text: cl.Color = .{ 250, 250, 255, 255 };
};

pub const background = struct {
    pub const primary = defaults.background_dark;
    pub const secondary = defaults.background_light;
};

pub const scrollBar = struct {
    pub const bar = defaults.background_light;
    pub const thumb = defaults.grey;
};

pub const cwdInput = struct {
    pub const background = defaults.background_dark;
    pub const text = defaults.text;
};

pub const entryItem = struct {
    pub const background = struct {
        pub const default = defaults.secondary;
        pub const selected = defaults.primary;
        pub const hovered = defaults.accent;
    };
    pub const text = struct {
        pub const primary = defaults.text;
    };
};

pub const contextMenu = struct {
    pub const backgound = defaults.background_dark;
    pub const entry = struct {
        pub const background = defaults.background_light;
        pub const hovered = defaults.accent;
    };
};
