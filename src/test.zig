const std = @import("std");
const testing = std.testing;

const Api = @import("api");

const uri = std.Uri.parse("https://lbp.littlebigrefresh.com") catch @compileError("Unable to parse test URI");

test "get level id 1" {
    const test_level_id: i32 = 1;

    var res = try Api.getLevelById(testing.allocator, uri, test_level_id);
    defer res.deinit();

    switch (res.response) {
        .data => |data| {
            try testing.expectEqual(test_level_id, data.levelId);
        },
        .error_response => |err| {
            std.debug.print("Got unexpected error {s} with message {s} from API\n", .{ @errorName(err.api_error), err.message });
            return err.api_error;
        },
    }
}

test "get level id invalid" {
    const test_level_id: i32 = std.math.maxInt(i32);

    var res = try Api.getLevelById(testing.allocator, uri, test_level_id);
    defer res.deinit();

    switch (res.response) {
        .data => |data| {
            _ = data;
            try testing.expect(false);
        },
        .error_response => |err| {
            try testing.expectEqual(Api.Error.ApiNotFoundError, err.api_error);
        },
    }
}
