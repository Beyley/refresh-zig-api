const std = @import("std");

pub fn deepCopy(allocator: std.mem.Allocator, value: anytype) !@TypeOf(value) {
    const T = @TypeOf(value);

    const TypeInfo = @typeInfo(T);

    var new_val: T = undefined;

    switch (TypeInfo) {
        .Void,
        .Bool,
        .Int,
        .Float,
        .Type,
        .NoReturn,
        .ComptimeFloat,
        .ComptimeInt,
        .Undefined,
        .Null,
        .ErrorSet,
        .Enum,
        .Fn,
        .Opaque,
        .Frame,
        .AnyFrame,
        .Vector,
        .EnumLiteral,
        .Pointer,
        .Array,
        .Optional,
        .ErrorUnion,
        .Union,
        => new_val = try copyField(allocator, value),
        .Struct => inline for (TypeInfo.Struct.fields) |field| {
            @field(new_val, field.name) = try copyField(allocator, @field(value, field.name));
        },
    }

    return new_val;
}

fn copyField(allocator: std.mem.Allocator, value: anytype) !@TypeOf(value) {
    const T = @TypeOf(value);
    const TypeInfo = @typeInfo(T);
    switch (TypeInfo) {
        .Void,
        .Bool,
        .Int,
        .Float,
        .Type,
        .NoReturn,
        .ComptimeFloat,
        .ComptimeInt,
        .Undefined,
        .Null,
        .ErrorSet,
        .Enum,
        .Fn,
        .Opaque,
        .Frame,
        .AnyFrame,
        .Vector,
        .EnumLiteral,
        .Array,
        => return value,
        .Pointer => |ptr_info| {
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
        .Struct => return try deepCopy(allocator, value),
        .Optional => {
            return if (value) |val|
                try deepCopy(allocator, val)
            else
                null;
        },
        .ErrorUnion => @compileError("TODO"),
        .Union => {
            switch (value) {
                inline else => |val| {
                    return try copyField(allocator, val);
                },
            }
        },
    }
}
