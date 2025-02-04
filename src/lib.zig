pub const BufError = error {
    ///When attempting to append more elements than capacity
    Overflow,
};

fn maxInt(comptime T: type) comptime_int {
    const info = @typeInfo(T);
    const bit_count = info.Int.bits;
    if (bit_count == 0) return 0;
    return (1 << (bit_count - @intFromBool(info.Int.signedness == .signed))) - 1;
}

fn size_type(comptime LEN: usize) type {
    comptime {
        if (LEN <= maxInt(u8)) {
            return u8;
        } else if (LEN <= maxInt(u16)) {
            return u16;
        } else if (LEN <= maxInt(u32)) {
            return u32;
        } else if (LEN <= maxInt(usize)) {
            return usize;
        } else {
            @compileError("LEN doesn't fit usize");
        }
    }
}

pub fn Buf(comptime T: type, comptime LEN: usize) type {
    comptime {
        const cursor_type = size_type(LEN);

        return struct {
            items: [LEN]T = undefined,
            cursor: cursor_type = 0,

            pub fn new() @This() {
                return .{
                };
            }

            pub fn capacity() cursor_type {
                return @truncate(LEN);
            }

            pub fn len(self: *const @This()) cursor_type {
                return self.cursor;
            }

            pub fn remaining(self: *const @This()) cursor_type {
                return capacity() - self.cursor;
            }

            pub fn as_slice(self: *const @This()) []const T {
                return (&self.items)[0..self.cursor];
            }

            pub fn append(self: *@This(), item: T) !void {
                if (self.cursor >= LEN) {
                    return BufError.Overflow;
                }
                self.items[self.cursor] = item;
                self.cursor = self.cursor + 1;
            }
        };
    }
}
