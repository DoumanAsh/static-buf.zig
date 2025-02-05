pub const BufError = error {
    ///When attempting to append more elements than capacity
    Overflow,
};

fn take(comptime T: type, ptr: *T) T {
    const result = ptr.*;
    ptr.* = undefined;
    return result;
}

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

            ///Creates new instance
            pub inline fn new() @This() {
                return .{
                };
            }

            ///Returns container capacity
            pub inline fn capacity() cursor_type {
                return @truncate(LEN);
            }

            ///Returns number of elements inside container
            pub fn len(self: *const @This()) cursor_type {
                return self.cursor;
            }

            ///Returns available capacity
            pub fn remaining(self: *const @This()) cursor_type {
                return capacity() - self.cursor;
            }

            ///Checks whether the container is empty
            pub fn empty(self: *const @This()) bool {
                return self.cursor == 0;
            }

            ///Returns slice of available elements
            pub fn as_slice(self: *const @This()) []const T {
                return (&self.items)[0..self.cursor];
            }

            ///Appends elements to the end of array
            pub fn push_back(self: *@This(), item: T) !void {
                if (self.cursor >= LEN) {
                    return BufError.Overflow;
                }
                self.items[self.cursor] = item;
                self.cursor = self.cursor + 1;
            }

            ///Removes the last element.
            pub fn pop_back(self: *@This()) ?T {
                if (self.empty()) {
                    return null;
                }

                self.cursor -= 1;
                return take(T, &self.items[self.cursor]);
            }
        };
    }
}
