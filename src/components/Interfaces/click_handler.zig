const Self = @This();

ptr: *anyopaque,
vtable: VTable,

pub const VTable = struct {
    handleClickFn: *const fn (ptr: *anyopaque) anyerror!void,
};

pub fn handleClick(self: Self) anyerror!void {
    try self.vtable.handleClickFn(self.ptr);
}
