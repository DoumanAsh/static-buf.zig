const std = @import("std");
const testing = std.testing;
const mem = std.mem;
const buf = @import("static-buf");

test "create zero buf" {
    const ZeroBuf = buf.Buf(u8, 0);
    try testing.expect(ZeroBuf.capacity() == 0);

    const buffer = ZeroBuf.new();
    try testing.expect(buffer.len() == 0);

    const buffer_slice = buffer.as_slice();
    try testing.expect(buffer_slice.len == 0);
}

test "create some buf" {
    const ZeroBuf = buf.Buf(u8, 5);
    try testing.expect(ZeroBuf.capacity() == 5);

    var buffer = ZeroBuf.new();
    try testing.expect(buffer.len() == 0);

    var buffer_slice = buffer.as_slice();
    try testing.expect(buffer_slice.len == 0);

    buffer.append(1) catch {};
    try testing.expect(buffer.len() == 1);
    try testing.expect(buffer.remaining() == 4);
    buffer.append(2) catch {};
    try testing.expect(buffer.len() == 2);
    try testing.expect(buffer.remaining() == 3);
    buffer.append(3) catch {};
    try testing.expect(buffer.len() == 3);
    try testing.expect(buffer.remaining() == 2);
    buffer.append(4) catch {};
    try testing.expect(buffer.len() == 4);
    try testing.expect(buffer.remaining() == 1);
    buffer.append(5) catch {};
    try testing.expect(buffer.len() == 5);
    try testing.expect(buffer.remaining() == 0);
    buffer.append(5) catch {};
    try std.testing.expect(buffer.append(6) == buf.BufError.Overflow);
    try testing.expect(buffer.remaining() == 0);

    buffer_slice = buffer.as_slice();
    try testing.expect(buffer_slice.len == 5);
    try testing.expect(mem.eql(u8, buffer_slice, &.{1, 2, 3, 4, 5}));
}
