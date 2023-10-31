const std = @import("std");
const helpers = @import("helpers.zig");

const RefreshApiError = struct {
    name: []const u8,
    message: []const u8,
    statusCode: i32,
};

///Returns a type representing a full API response
fn RefreshApiResponse(comptime T: type) type {
    return struct {
        ///Whether the API call was successful
        success: bool,
        ///The returned API error
        @"error": ?RefreshApiError = null,
        //The returned API data
        data: ?T = null,
    };
}

pub const GameLocation = struct {
    x: i32,
    y: i32,
};

pub const GameUser = struct {
    userId: []const u8,
    username: []const u8,
    iconHash: []const u8,
    description: []const u8,
    location: GameLocation,
    //TODO: see if theres a better type for these,
    //      im not sure the Zig stdlib has something for this though
    joinDate: []const u8,
    lastLoginDate: []const u8,
};

pub const TokenGame = enum(i32) {
    little_big_planet_1 = 0,
    little_big_planet_2 = 1,
    little_big_planet_3 = 2,
    little_big_planet_vita = 3,
    little_big_planet_psp = 4,
    website = 5,
};

pub const GameSkillRewardCondition = enum(i32) {
    score = 0,
    time = 1,
    lives = 2,
};

pub const GameSkillReward = struct {
    id: i32,
    enabled: bool,
    title: ?[]const u8,
    requiredAmount: f32,
    conditionType: GameSkillRewardCondition,
};

pub const GameLevelType = enum(i32) {
    normal = 0,
    versus = 1,
    cutscene = 2,
};

pub const GameLevel = struct {
    levelId: i32,
    publisher: GameUser,
    title: []const u8,
    iconHash: []const u8,
    description: []const u8,
    location: GameLocation,
    rootLevelHash: []const u8,
    gameVersion: TokenGame,
    //TODO: see if theres a better type for these,
    //      im not sure the Zig stdlib has something for this though
    publishDate: []const u8,
    updateDate: []const u8,
    //TODO: should these be `u3` instead to cause errors when the API returns weird/invalid data?
    minPlayers: i32,
    maxPlayers: i32,
    enforceMinMaxPlayers: bool,
    sameScreenGame: bool,
    skillRewards: []const GameSkillReward,
    yayRatings: i32,
    booRatings: i32,
    hearts: i32,
    uniquePlays: i32,
    teamPicked: bool,
    levelType: GameLevelType,
    isLocked: bool,
    isSubLevel: bool,
    isCopyable: bool,
};

const ApiGameLevelResponse = RefreshApiResponse(GameLevel);

const ApiError = error{
    DataNullWhenSuccess,
    ErrorNullWhenFailure,
    UnknownApiError,
    ApiNotFoundError,
};

pub const Error =
    ApiError ||
    std.fmt.BufPrintError ||
    std.http.Client.ConnectError ||
    std.http.Client.RequestError ||
    std.http.Client.Request.WaitError ||
    std.http.Client.Request.FinishError ||
    std.json.ParseError(std.json.Reader(std.json.default_buffer_size, std.http.Client.Request.Reader));

fn makeRequest(
    allocator: std.mem.Allocator,
    comptime T: type,
    _uri: std.Uri,
    path: []const u8,
    method: std.http.Method,
    request_body: ?[]const u8,
) Error!std.json.Parsed(T) {
    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    var uri = _uri;
    uri.path = path;

    //Create a request to the Instance v3 API to get server info
    var request = try client.open(
        method,
        uri,
        .{ .allocator = allocator },
        .{},
    );
    defer request.deinit();

    //Send the request to the server
    try request.send(.{});
    //If the request has a body, send it to the server as well
    if (request_body) |body| try request.writeAll(body);

    //Finish the request
    try request.finish();
    try request.wait();

    var reader = request.reader();

    var json_reader = std.json.reader(allocator, reader);
    defer json_reader.deinit();

    return try std.json.parseFromTokenSource(
        T,
        allocator,
        &json_reader,
        .{
            //When runtime safety is enabled, crash if theres unknown fields
            .ignore_unknown_fields = !std.debug.runtime_safety,
        },
    );
}

fn ApiResponse(comptime T: type) type {
    return struct {
        const Self = @This();

        ///The arena allocator storing the underlying memory
        arena: std.heap.ArenaAllocator,
        ///The response from the server
        response: union(enum) {
            ///An error response
            error_response: struct {
                api_error: Error,
                message: []const u8,
            },
            ///The returned data
            data: T,
        },

        pub fn deinit(self: *Self) void {
            //Deinit the arena, freeing the data
            self.arena.deinit();
            //Set self to undefined, so safety checks catch further usage
            self.* = undefined;
        }
    };
}

fn mostBytesForInt(comptime T: type) comptime_int {
    return @intFromFloat(@floor(@log10(@as(comptime_float, std.math.maxInt(T)))) + 1);
}

pub fn getLevelById(allocator: std.mem.Allocator, uri: std.Uri, id: i32) Error!ApiResponse(GameLevel) {
    const endpoint = "/api/v3/levels/id/";
    const max_request_length = comptime mostBytesForInt(i32) + endpoint.len;

    var path_buf: [max_request_length]u8 = undefined;
    var stream = std.io.fixedBufferStream(&path_buf);
    try std.fmt.format(stream.writer(), endpoint ++ "{d}", .{id});

    const path = path_buf[0..stream.pos];

    var request = try makeRequest(allocator, RefreshApiResponse(GameLevel), uri, path, .GET, null);
    defer request.deinit();

    var arena = std.heap.ArenaAllocator.init(allocator);
    errdefer arena.deinit();

    if (request.value.success)
        if (request.value.data) |data| {
            var copied_data = try helpers.deepCopy(arena.allocator(), data);
            return .{
                .arena = arena,
                .response = .{ .data = copied_data },
            };
        } else return ApiError.DataNullWhenSuccess
    else if (request.value.@"error") |api_error| {
        var err = ApiError.UnknownApiError;
        if (std.mem.eql(u8, api_error.name, "ApiNotFoundError")) err = ApiError.ApiNotFoundError;
        var copied_message = try arena.allocator().dupe(u8, api_error.message);
        return .{
            .arena = arena,
            .response = .{
                .error_response = .{
                    .api_error = err,
                    .message = copied_message,
                },
            },
        };
    } else return ApiError.ErrorNullWhenFailure;
}
