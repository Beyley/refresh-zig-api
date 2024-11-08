const std = @import("std");
const testing = std.testing;
const options = @import("options");

pub const Api = @import("api");

const uri = std.Uri.parse(options.integration_url) catch @compileError("Unable to parse test URI");

comptime {
    std.testing.refAllDecls(@This());
}

test "get level" {
    const test_level_id: i32 = 100;

    const res = try Api.getLevelById(testing.allocator, uri, test_level_id);
    defer res.deinit();

    switch (res.response) {
        .data => |data| {
            try testing.expectEqual(test_level_id, data.levelId);
        },
        .error_response => |err| {
            std.log.err("Got unexpected error {s} with message {s} from API\n", .{ @errorName(err.api_error), err.message });
            return err.api_error;
        },
    }
}

test "get level id invalid" {
    const test_level_id: i32 = std.math.maxInt(i32);

    const res = try Api.getLevelById(testing.allocator, uri, test_level_id);
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

test "get instance info" {
    const res = try Api.getInstanceInformation(testing.allocator, uri);
    defer res.deinit();

    switch (res.response) {
        .data => |data| {
            try testing.expectEqualStrings("LittleBigRefresh", data.instanceName);
            try testing.expectEqualStrings("The community's quality-of-life experience for LBP.", data.instanceDescription);
        },
        .error_response => |err| {
            std.log.err("Got unexpected error {s} with message {s} from API\n", .{ @errorName(err.api_error), err.message });
            return err.api_error;
        },
    }
}

test "get instance statistics" {
    const res = try Api.getStatistics(testing.allocator, uri);
    defer res.deinit();

    switch (res.response) {
        .data => |data| {
            _ = data;
        },
        .error_response => |err| {
            std.log.err("Got unexpected error {s} with message {s} from API\n", .{ @errorName(err.api_error), err.message });
            return err.api_error;
        },
    }
}

test "get instance documentation" {
    const res = try Api.getDocumentation(testing.allocator, uri);
    defer res.deinit();

    switch (res.response) {
        .list => |list| {
            _ = list;
        },
        .error_response => |err| {
            std.log.err("Got unexpected error {s} with message {s} from API\n", .{ @errorName(err.api_error), err.message });
            return err.api_error;
        },
    }
}

test "get user" {
    const res = try Api.getUserByUsername(testing.allocator, uri, "Beyley");
    defer res.deinit();

    switch (res.response) {
        .data => |data| {
            try testing.expectEqualStrings("Beyley", data.username);
        },
        .error_response => |err| {
            std.log.err("Got unexpected error {s} with message {s} from API\n", .{ @errorName(err.api_error), err.message });
            return err.api_error;
        },
    }
}

test "get invalid name fails" {
    const res = try Api.getUserByUsername(testing.allocator, uri, "I_AM_NOT_REAL");
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

test "get user room" {
    const res = try Api.getRoomByUsername(testing.allocator, uri, "Beyley");
    defer res.deinit();

    switch (res.response) {
        .data => |data| {
            try testing.expectEqualStrings("Beyley", data.playerIds[0].username);
        },
        .error_response => |err| {
            std.log.err("Got unexpected error {s} with message {s} from API\n", .{ @errorName(err.api_error), err.message });
            return err.api_error;
        },
    }
}

test "get invalid user room fails" {
    const res = try Api.getRoomByUsername(testing.allocator, uri, "I_AM_NOT_REAL");
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
