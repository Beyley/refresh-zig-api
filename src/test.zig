const std = @import("std");
const testing = std.testing;
const options = @import("options");

const Api = @import("api");

const uri = std.Uri.parse(options.integration_url) catch @compileError("Unable to parse test URI");

test "get level" {
    const test_level_id: i32 = 2;

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

test "get instance info" {
    var res = try Api.getInstanceInformation(testing.allocator, uri);
    defer res.deinit();

    switch (res.response) {
        .data => |data| {
            try testing.expectEqualStrings("Beyley's Test Instance", data.instanceName);
            try testing.expectEqualStrings("this is an instance description, i have nothing to put here. stop reading now. HEY stop it!!!", data.instanceDescription);
        },
        .error_response => |err| {
            std.debug.print("Got unexpected error {s} with message {s} from API\n", .{ @errorName(err.api_error), err.message });
            return err.api_error;
        },
    }
}

test "get instance statistics" {
    var res = try Api.getStatistics(testing.allocator, uri);
    defer res.deinit();

    switch (res.response) {
        .data => |data| {
            _ = data;
        },
        .error_response => |err| {
            std.debug.print("Got unexpected error {s} with message {s} from API\n", .{ @errorName(err.api_error), err.message });
            return err.api_error;
        },
    }
}

test "get instance documentation" {
    var res = try Api.getDocumentation(testing.allocator, uri);
    defer res.deinit();

    switch (res.response) {
        .list => |list| {
            _ = list;
        },
        .error_response => |err| {
            std.debug.print("Got unexpected error {s} with message {s} from API\n", .{ @errorName(err.api_error), err.message });
            return err.api_error;
        },
    }
}

test "get user" {
    var res = try Api.getUserByUsername(testing.allocator, uri, "Beyley");
    defer res.deinit();

    switch (res.response) {
        .data => |data| {
            try testing.expectEqualStrings("Beyley", data.username);
        },
        .error_response => |err| {
            std.debug.print("Got unexpected error {s} with message {s} from API\n", .{ @errorName(err.api_error), err.message });
            return err.api_error;
        },
    }
}

test "get invalid name fails" {
    var res = try Api.getUserByUsername(testing.allocator, uri, "I_AM_NOT_REAL");
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
    var res = try Api.getRoomByUsername(testing.allocator, uri, "Beyley");
    defer res.deinit();

    switch (res.response) {
        .data => |data| {
            try testing.expectEqualStrings("Beyley", data.playerIds[0].username);
        },
        .error_response => |err| {
            std.debug.print("Got unexpected error {s} with message {s} from API\n", .{ @errorName(err.api_error), err.message });
            return err.api_error;
        },
    }
}

test "get invalid user room fails" {
    var res = try Api.getRoomByUsername(testing.allocator, uri, "I_AM_NOT_REAL");
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
