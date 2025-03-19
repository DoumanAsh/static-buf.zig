const std = @import("std");
const testing = std.testing;
const mem = std.mem;
const debug = std.debug;
const buf = @import("static-buf");

test "create zero buf" {
    const ZeroArray = buf.Array(u8, 0);
    try testing.expect(ZeroArray.capacity() == 0);

    const buffer = ZeroArray.new();
    try testing.expect(buffer.len() == 0);

    const buffer_slice = buffer.as_slice();
    try testing.expect(buffer_slice.len == 0);
}

fn maxInt(comptime T: type) comptime_int {
    const info = @typeInfo(T);
    const bit_count = info.Int.bits;
    if (bit_count == 0) return 0;
    return (1 << (bit_count - @intFromBool(info.Int.signedness == .signed))) - 1;
}

test "len type" {
    const ArrayU8 = buf.Array(u8, 255);
    try testing.expect(@typeInfo(ArrayU8).@"struct".fields[1].type == u8);

    const ArrayU16 = buf.Array(u8, 65_535);
    try testing.expect(@typeInfo(ArrayU16).@"struct".fields[1].type == u16);

    const ArrayU32 = buf.Array(u8, 4_294_967_295);
    try testing.expect(@typeInfo(ArrayU32).@"struct".fields[1].type == u32);
}

test "fill buf" {
    const SIZE = 65_535;
    const Array = buf.Array(u8, SIZE);
    try testing.expect(Array.capacity() == SIZE);

    var buffer = Array.new();
    buffer.fill(5);
    try testing.expect(buffer.len() == 65_535);
    try testing.expect(mem.allEqual(u8, buffer.as_slice(), 5));
    buffer.fill_secure(1);
    try testing.expect(buffer.len() == 65_535);
    try testing.expect(mem.allEqual(u8, buffer.as_slice(), 1));
}

test "resize buf" {
    const Array = buf.Array(u8, 10);
    try testing.expect(Array.capacity() == 10);
    try testing.expect(@sizeOf(Array) == 11);

    var buffer = Array.new();
    try testing.expect(buffer.len() == 0);
    try testing.expect(buffer.empty());
    try testing.expect(buffer.as_slice_uninit().len == 10);

    try buffer.resize(5, &1);
    try testing.expect(buffer.len() == 5);
    try testing.expect(!buffer.empty());
    try testing.expect(buffer.as_slice_uninit().len == 5);
    try testing.expect(mem.eql(u8, buffer.as_slice(), &.{1, 1, 1, 1, 1}));

    try buffer.resize(10, &2);
    try testing.expect(buffer.len() == 10);
    try testing.expect(!buffer.empty());
    try testing.expect(buffer.as_slice_uninit().len == 0);
    try testing.expect(mem.eql(u8, buffer.as_slice(), &.{1, 1, 1, 1, 1, 2, 2, 2, 2, 2}));

    try buffer.resize(6, &3);
    try testing.expect(buffer.len() == 6);
    try testing.expect(!buffer.empty());
    try testing.expect(buffer.as_slice_uninit().len == 4);
    try testing.expect(mem.eql(u8, buffer.as_slice(), &.{1, 1, 1, 1, 1, 2}));

    buffer.clear();
    try testing.expect(buffer.len() == 0);
    try testing.expect(buffer.empty());
    try testing.expect(buffer.as_slice_uninit().len == 10);
    //Clear doesn't reset values itself, so expected behavior that uninitialized part of array remains the same
    try testing.expect(mem.eql(u8, buffer.as_slice_uninit(), &.{1, 1, 1, 1, 1, 2, 2, 2, 2, 2}));
}

test "create some buf" {
    const Array = buf.Array(u8, 5);
    try testing.expect(Array.capacity() == 5);

    var buffer = Array.new();
    try testing.expect(buffer.len() == 0);
    try testing.expect(buffer.empty());

    var buffer_slice = buffer.as_slice();
    try testing.expect(buffer_slice.len == 0);
    try testing.expect(buffer.front() == null);
    try testing.expect(buffer.back() == null);

    buffer.push_back(1) catch {};
    try testing.expect(buffer.len() == 1);
    try testing.expect(buffer.remaining() == 4);
    try testing.expect(!buffer.empty());
    try testing.expect(buffer.front().?.* == 1);
    try testing.expect(buffer.back().?.* == 1);

    buffer.push_back(2) catch {};
    try testing.expect(buffer.len() == 2);
    try testing.expect(buffer.remaining() == 3);
    try testing.expect(!buffer.empty());
    try testing.expect(buffer.front().?.* == 1);
    try testing.expect(buffer.back().?.* == 2);

    buffer.push_back(3) catch {};
    try testing.expect(buffer.len() == 3);
    try testing.expect(buffer.remaining() == 2);
    try testing.expect(!buffer.empty());
    try testing.expect(buffer.front().?.* == 1);
    try testing.expect(buffer.back().?.* == 3);

    buffer.push_back(4) catch {};
    try testing.expect(buffer.len() == 4);
    try testing.expect(buffer.remaining() == 1);
    try testing.expect(!buffer.empty());
    try testing.expect(buffer.front().?.* == 1);
    try testing.expect(buffer.back().?.* == 4);

    buffer.push_back(5) catch {};
    try testing.expect(buffer.len() == 5);
    try testing.expect(buffer.remaining() == 0);
    try testing.expect(!buffer.empty());
    try testing.expect(buffer.front().?.* == 1);
    try testing.expect(buffer.back().?.* == 5);

    buffer.push_back(5) catch {};
    try std.testing.expect(buffer.push_back(6) == buf.Error.Overflow);
    try testing.expect(buffer.remaining() == 0);
    try testing.expect(!buffer.empty());

    buffer_slice = buffer.as_slice();
    try testing.expect(buffer_slice.len == 5);
    try testing.expect(mem.eql(u8, buffer_slice, &.{1, 2, 3, 4, 5}));
    try testing.expect(buffer.front().?.* == 1);

    try testing.expect(buffer.pop_back() == 5);
    try testing.expect(buffer.len() == 4);
    try testing.expect(buffer.remaining() == 1);

    try testing.expect(buffer.pop_back() == 4);
    try testing.expect(buffer.len() == 3);
    try testing.expect(buffer.remaining() == 2);

    try testing.expect(buffer.pop_back() == 3);
    try testing.expect(buffer.len() == 2);
    try testing.expect(buffer.remaining() == 3);

    try testing.expect(buffer.pop_back() == 2);
    try testing.expect(buffer.len() == 1);
    try testing.expect(buffer.remaining() == 4);

    try testing.expect(buffer.pop_back() == 1);
    try testing.expect(buffer.len() == 0);
    try testing.expect(buffer.remaining() == 5);

    try testing.expect(buffer.empty());
}
