ptr: *anyopaque,
handleClickFn: *const fn (ptr: *anyopaque) anyerror!void,

pub fn handleClick(self: @This()) anyerror!void {
    try self.handleClickFn(self.ptr);
}
