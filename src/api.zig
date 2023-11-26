const std = @import("std");
const helpers = @import("helpers.zig");

const max_bunkum_path_length = 1024;

const RefreshApiError = struct {
    name: []const u8,
    message: []const u8,
    statusCode: i32,
};

///Returns a type representing a full API response
fn RefreshApiResponse(comptime DataType: type) type {
    return struct {
        ///Whether the API call was successful
        success: bool,
        ///The returned API error
        @"error": ?RefreshApiError = null,
        //The returned API data
        data: ?DataType = null,
    };
}

const ListInformation = struct {
    nextPageIndex: i32,
    totalItems: i32,
};

///Returns a type representing a full API List response
fn RefreshApiListResponse(comptime ListItemType: type) type {
    return struct {
        listInfo: ?ListInformation,
        ///Whether the API call was successful
        success: bool,
        ///The returned API error
        @"error": ?RefreshApiError = null,
        //The returned API data
        data: ?[]const ListItemType = null,
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
    _,
};

pub const GameSkillRewardCondition = enum(i32) {
    score = 0,
    time = 1,
    lives = 2,
    _,
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
    _,
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
    score: f32,
};

pub const AssetSafetyLevel = enum(i32) {
    safe = 0,
    potentially_unwanted = 1,
    dangerous = 2,
    _,
};

pub const GameAnnouncement = struct {
    announcementId: []const u8,
    title: []const u8,
    text: []const u8,
    createdAt: []const u8,
};

pub const GameRoomPlayer = struct {
    username: []const u8,
    userId: ?[]const u8,
};

pub const RoomState = enum(i32) {
    /// The room isn't doing much at the moment
    idle = 0,
    /// The room is waiting in a loading screen
    loading = 1,
    /// The room is looking for another group to join
    diving_in = 3,
    /// The room is looking for another group to join them
    waiting_for_players = 4,
    _,
};

pub const RoomMood = enum(u8) {
    rejecting_all = 0,
    rejecting_all_but_friends = 1,
    rejecting_only_friends = 2,
    allowing_all = 3,
    _,
};

pub const RoomSlotType = enum(u8) {
    story = 0,
    online = 1,
    moon = 2,
    pod = 5,
    _,
};

pub const TokenPlatform = enum(i32) {
    ps3 = 0,
    rpcs3 = 1,
    vita = 2,
    website = 3,
    psp = 4,
    _,
};

pub const GameRoom = struct {
    roomId: []const u8,
    playerIds: []const GameRoomPlayer,
    roomState: RoomState,
    roomMood: RoomMood,
    levelType: RoomSlotType,
    levelId: i32,
    platform: TokenPlatform,
    game: TokenGame,
};

pub const RichPresenceConfiguration = struct {
    applicationId: []const u8,
    partyIdPrefix: []const u8,
    assetConfiguration: struct {
        useApplicationAssets: bool,
        podAsset: ?[]const u8,
        moonAsset: ?[]const u8,
        remoteMoonAsset: ?[]const u8,
        developerAsset: ?[]const u8,
        developerAdventureAsset: ?[]const u8,
        dlcAsset: ?[]const u8,
        fallbackAsset: ?[]const u8,
    },
};

pub const InstanceInformation = struct {
    instanceName: []const u8,
    instanceDescription: []const u8,
    softwareName: []const u8,
    softwareVersion: []const u8,
    softwareType: []const u8,
    softwareSourceUrl: []const u8,
    softwareLicenseName: []const u8,
    softwareLicenseUrl: []const u8,
    registrationEnabled: bool,
    maximumAssetSafetyLevel: AssetSafetyLevel,
    announcements: []const GameAnnouncement,
    richPresenceConfiguration: RichPresenceConfiguration,
    maintenanceModeEnabled: bool,
    grafanaDashboardUrl: ?[]const u8,
};

const Statistics = struct {
    totalLevels: i32,
    totalUsers: i32,
    activeUsers: i32,
    totalPhotos: i32,
    totalEvents: i32,
    currentRoomCount: i32,
    currentIngamePlayersCount: i32,
    requestStatistics: struct {
        totalRequests: i64,
        apiRequests: i64,
        legacyApiRequests: i64,
        gameRequests: i64,
    },
};

const ApiRoute = struct {
    method: []const u8,
    routeUri: []const u8,
    summary: []const u8,
    authenticationRequired: bool,
    minimumRole: ?enum(i8) {
        /// An administrator of the instance. This user has all permissions, including the ability to manage other administrators.
        admin = 127,
        /// A standard user. Can play the game, log in, play levels, review them, etc.
        user = 0,
        /// A user with read-only permissions. May log in and play, but cannot do things such as publish levels or post comments.
        restricted = -126,
        /// A user that has been banned. Cannot log in, or do anything.
        banned = -127,
    },
    parameters: []const struct {
        name: []const u8,
        type: enum {
            Route,
            Query,
        },
        summary: []const u8,
    },
    potentialErrors: []const struct {
        name: []const u8,
        occursWhen: []const u8,
    },
};

const ApiError = error{
    DataNullWhenSuccess,
    ErrorNullWhenFailure,
    UnknownApiError,
    ApiNotFoundError,
    ListResponseMissingListInfo,
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

    const reader = request.reader();

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

fn ApiListResponse(comptime T: type) type {
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
            list: struct {
                info: ListInformation,
                data: []const T,
            },
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

pub fn getInstanceInformation(allocator: std.mem.Allocator, uri: std.Uri) Error!ApiResponse(InstanceInformation) {
    const endpoint = "/api/v3/instance";

    var request = try makeRequest(
        allocator,
        RefreshApiResponse(InstanceInformation),
        uri,
        endpoint,
        .GET,
        null,
    );
    defer request.deinit();

    var arena = std.heap.ArenaAllocator.init(allocator);
    errdefer arena.deinit();

    return try toApiResponse(&arena, InstanceInformation, request);
}

pub fn getStatistics(allocator: std.mem.Allocator, uri: std.Uri) Error!ApiResponse(Statistics) {
    const endpoint = "/api/v3/statistics";

    var request = try makeRequest(
        allocator,
        RefreshApiResponse(Statistics),
        uri,
        endpoint,
        .GET,
        null,
    );
    defer request.deinit();

    var arena = std.heap.ArenaAllocator.init(allocator);
    errdefer arena.deinit();

    return try toApiResponse(&arena, Statistics, request);
}

pub fn getDocumentation(allocator: std.mem.Allocator, uri: std.Uri) Error!ApiListResponse(ApiRoute) {
    const endpoint = "/api/v3/documentation";

    var request = try makeRequest(
        allocator,
        RefreshApiListResponse(ApiRoute),
        uri,
        endpoint,
        .GET,
        null,
    );
    defer request.deinit();

    var arena = std.heap.ArenaAllocator.init(allocator);
    errdefer arena.deinit();

    return try toApiListResponse(&arena, ApiRoute, request);
}

pub fn getLevelById(allocator: std.mem.Allocator, uri: std.Uri, id: i32) Error!ApiResponse(GameLevel) {
    const endpoint = "/api/v3/levels/id/";
    const max_request_length = comptime mostBytesForInt(i32) + endpoint.len;

    var path_buf: [max_request_length]u8 = undefined;
    var stream = std.io.fixedBufferStream(&path_buf);
    try std.fmt.format(stream.writer(), endpoint ++ "{d}", .{id});

    const path = path_buf[0..stream.pos];

    var request = try makeRequest(
        allocator,
        RefreshApiResponse(GameLevel),
        uri,
        path,
        .GET,
        null,
    );
    defer request.deinit();

    var arena = std.heap.ArenaAllocator.init(allocator);
    errdefer arena.deinit();

    return try toApiResponse(&arena, GameLevel, request);
}

pub fn getUserByUsername(allocator: std.mem.Allocator, uri: std.Uri, username: []const u8) Error!ApiResponse(GameUser) {
    var path_buf: [max_bunkum_path_length]u8 = undefined;
    var stream = std.io.fixedBufferStream(&path_buf);
    try std.fmt.format(stream.writer(), "/api/v3/users/name/{s}", .{username});

    const path = path_buf[0..stream.pos];

    var request = try makeRequest(
        allocator,
        RefreshApiResponse(GameUser),
        uri,
        path,
        .GET,
        null,
    );
    defer request.deinit();

    var arena = std.heap.ArenaAllocator.init(allocator);
    errdefer arena.deinit();

    return try toApiResponse(&arena, GameUser, request);
}

pub fn getRoomByUsername(allocator: std.mem.Allocator, uri: std.Uri, username: []const u8) Error!ApiResponse(GameRoom) {
    var path_buf: [max_bunkum_path_length]u8 = undefined;
    var stream = std.io.fixedBufferStream(&path_buf);
    try std.fmt.format(stream.writer(), "/api/v3/rooms/username/{s}", .{username});

    const path = path_buf[0..stream.pos];

    var request = try makeRequest(
        allocator,
        RefreshApiResponse(GameRoom),
        uri,
        path,
        .GET,
        null,
    );
    defer request.deinit();

    var arena = std.heap.ArenaAllocator.init(allocator);
    errdefer arena.deinit();

    return try toApiResponse(&arena, GameRoom, request);
}

fn toApiResponse(arena: *std.heap.ArenaAllocator, comptime T: type, request: anytype) Error!ApiResponse(T) {
    if (request.value.success)
        if (request.value.data) |data| {
            const copied_data = try helpers.deepCopy(arena.allocator(), data);
            return .{
                .arena = arena.*,
                .response = .{ .data = copied_data },
            };
        } else return ApiError.DataNullWhenSuccess
    else if (request.value.@"error") |api_error| {
        var err = ApiError.UnknownApiError;

        if (std.mem.eql(u8, api_error.name, "ApiNotFoundError")) err = ApiError.ApiNotFoundError;

        const copied_message = try arena.allocator().dupe(u8, api_error.message);
        return .{
            .arena = arena.*,
            .response = .{
                .error_response = .{
                    .api_error = err,
                    .message = copied_message,
                },
            },
        };
    } else return ApiError.ErrorNullWhenFailure;
}

fn toApiListResponse(arena: *std.heap.ArenaAllocator, comptime T: type, request: anytype) Error!ApiListResponse(T) {
    if (request.value.success)
        if (request.value.data) |data| {
            if (request.value.listInfo) |info| {
                const copied_data = try helpers.deepCopy(arena.allocator(), data);
                return .{
                    .arena = arena.*,
                    .response = .{
                        .list = .{
                            .info = info,
                            .data = copied_data,
                        },
                    },
                };
            } else return ApiError.ListResponseMissingListInfo;
        } else return ApiError.DataNullWhenSuccess
    else if (request.value.@"error") |api_error| {
        var err = ApiError.UnknownApiError;

        if (std.mem.eql(u8, api_error.name, "ApiNotFoundError")) err = ApiError.ApiNotFoundError;

        const copied_message = try arena.allocator().dupe(u8, api_error.message);
        return .{
            .arena = arena.*,
            .response = .{
                .error_response = .{
                    .api_error = err,
                    .message = copied_message,
                },
            },
        };
    } else return ApiError.ErrorNullWhenFailure;
}
