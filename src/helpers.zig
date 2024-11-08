const std = @import("std");

pub fn deepCopy(allocator: std.mem.Allocator, value: anytype) !@TypeOf(value) {
    const T = @TypeOf(value);

    const TypeInfo = @typeInfo(T);

    var new_val: T = undefined;

    switch (TypeInfo) {
        .void,
        .bool,
        .int,
        .float,
        .type,
        .noreturn,
        .comptime_float,
        .comptime_int,
        .undefined,
        .null,
        .error_set,
        .@"enum",
        .@"fn",
        .@"opaque",
        .frame,
        .@"anyframe",
        .vector,
        .enum_literal,
        .pointer,
        .array,
        .optional,
        .error_union,
        .@"union",
        => new_val = try copyField(allocator, value),
        .@"struct" => inline for (TypeInfo.@"struct".fields) |field| {
            @field(new_val, field.name) = try copyField(allocator, @field(value, field.name));
        },
    }

    return new_val;
}

fn copyField(allocator: std.mem.Allocator, value: anytype) !@TypeOf(value) {
    const T = @TypeOf(value);
    const TypeInfo = @typeInfo(T);
    switch (TypeInfo) {
        .void,
        .bool,
        .int,
        .float,
        .type,
        .noreturn,
        .comptime_float,
        .comptime_int,
        .undefined,
        .null,
        .error_set,
        .@"enum",
        .@"fn",
        .@"opaque",
        .frame,
        .@"anyframe",
        .vector,
        .enum_literal,
        .array,
        => return value,
        .pointer => |ptr_info| {
            switch (ptr_info.size) {
                .One => {
                    const copy = try allocator.create(T);
                    errdefer allocator.destroy(copy);

                    copy.* = deepCopy(allocator, value.*);

                    return copy;
                },
                .Slice => {
                    const copy = try allocator.alloc(ptr_info.child, value.len);
                    errdefer allocator.free(copy);

                    for (value, copy) |item1, *item2| {
                        item2.* = try copyField(allocator, item1);
                    }

                    return copy;
                },
                .Many, .C => @compileError("TODO"),
            }
        },
        .@"struct" => return try deepCopy(allocator, value),
        .optional => {
            return if (value) |val|
                try deepCopy(allocator, val)
            else
                null;
        },
        .error_union => @compileError("TODO"),
        .@"union" => {
            switch (value) {
                inline else => |val| {
                    return try copyField(allocator, val);
                },
            }
        },
    }
}
