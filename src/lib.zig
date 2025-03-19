pub const Error = error {
    ///When attempting to append more elements than capacity
    Overflow,
};

///Secure memset
pub inline fn memsetSecure(comptime T: type, ptr: []volatile T, value: T) void {
    @memset(ptr, value);
}

fn take(comptime T: type, ptr: *T) T {
    const result = ptr.*;
    ptr.* = undefined;
    return result;
}

fn maxInt(comptime T: type) comptime_int {
    const info = @typeInfo(T);
    const bit_count = info.int.bits;
    if (bit_count == 0) return 0;
    return (1 << (bit_count - @intFromBool(info.int.signedness == .signed))) - 1;
}

fn size_type(comptime LEN: usize) type {
    comptime {
        const USIZE_SIZE = maxInt(usize);

        if (LEN <= maxInt(u8)) {
            return u8;
        } else if (USIZE_SIZE >= maxInt(u16) and LEN <= maxInt(u16)) {
            return u16;
        } else if (USIZE_SIZE >= maxInt(u32) and LEN <= maxInt(u32)) {
            return u32;
        } else {
            return usize;
        }
    }
}

///Creates new fixed capacity array type
pub fn Array(comptime T: type, comptime LEN: usize) type {
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

            ///Returns slice of available elements
            pub fn as_slice_mut(self: *@This()) []T {
                return (&self.items)[0..self.cursor];
            }

            ///Returns slice with uninitialized items
            ///
            ///These items maybe `undefined` hence it is up to user to treat it with care
            pub fn as_slice_uninit(self: *@This()) []T {
                return (&self.items)[self.cursor..];
            }

            ///Sets length of the array, assuming it is correct
            ///
            ///This is to be used with as_slice_uninit() to perform initialization of elements
            pub fn set_len(self: *@This(), new_len: usize) void {
                self.cursor = @truncate(new_len);
            }

            ///Resets length
            pub inline fn clear(self: *@This()) void {
                self.set_len(0);
            }

            ///Resizes buffer with default values
            ///
            ///Does nothing if current length is already appropriate otherwise, if new_len is less than current, it truncates
            pub fn resize(self: *@This(), new_len: usize, default_value: *const T) !void {
                if (new_len > @This().capacity()) {
                    return Error.Overflow;
                } else if (new_len < self.cursor) {
                    self.set_len(new_len);
                } else if (new_len != self.cursor) {
                    const to_init = (&self.items)[self.cursor..new_len];
                    @memset(to_init, default_value.*);
                    self.set_len(new_len);
                }
            }

            ///Initializes array with specified `default_value`
            pub fn fill(self: *@This(), default_value: T) void {
                @memset(&self.items, default_value);
                self.cursor = @truncate(LEN);
            }

            ///Initializes array with specified `default_value`, guaranteeing no optimization would remove memset
            pub fn fill_secure(self: *@This(), default_value: T) void {
                memsetSecure(T, &self.items, default_value);
                self.cursor = @truncate(LEN);
            }

            ///Appends elements to the end of array
            pub fn push_back(self: *@This(), item: T) !void {
                if (self.cursor >= LEN) {
                    return Error.Overflow;
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

            ///Accesses first element, if has any
            pub fn front(self: *@This()) ?*T {
                if (self.empty()) {
                    return null;
                }

                return &self.items[0];
            }

            ///Accesses last element, if has any
            pub fn back(self: *@This()) ?*T {
                if (self.empty()) {
                    return null;
                }

                return &self.items[self.cursor - 1];
            }
        };
    }
}
