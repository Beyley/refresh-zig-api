const std = @import("std");
const helpers = @import("helpers.zig");

comptime {
    std.testing.refAllDecls(@This());
}

// No URIs can exceed this length, matches https://github.com/LittleBigRefresh/Bunkum/blob/927d7d6113de00857076d052c4dabd8e8abf6d3d/Bunkum.Listener/BunkumListener.cs#L31
const max_bunkum_path_length = 1024;

/// An error returned by the API
const RefreshApiError = struct {
    /// The name of the error
    name: []const u8,
    /// The error message contents
    message: []const u8,
    /// The status code of the response
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

/// The list information
const ListInformation = struct {
    /// The index of the next page
    nextPageIndex: i32,
    /// The total amount of items in the list (not the returned amount)
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

/// The location of some object on a moon
pub const GameLocation = struct {
    /// The X position
    x: i32,
    /// The Y position
    y: i32,
};

/// Represents a registered user
pub const GameUser = struct {
    /// The ID of the user
    userId: []const u8,
    /// The username of the user
    username: []const u8,
    /// The hash of the user's icon
    iconHash: []const u8,
    /// The description of the user
    description: []const u8,
    /// The location the user's profile photo is on their moon
    location: GameLocation,
    //TODO: see if theres a better type for these,
    //      im not sure the Zig stdlib has something for this though
    /// The date they joined the server
    joinDate: []const u8,
    /// The last time the user was logged into the server
    lastLoginDate: []const u8,
};

/// Represents one of the LBP games
pub const TokenGame = enum(i32) {
    /// LittleBigPlanet 1
    little_big_planet_1 = 0,
    /// LittleBigPlanet 2
    little_big_planet_2 = 1,
    /// LittleBigPlanet 3
    little_big_planet_3 = 2,
    /// LittleBigPlanet Vita
    little_big_planet_vita = 3,
    /// LittleBigPlanet Portable
    little_big_planet_psp = 4,
    /// The website
    website = 5,
    _,
};

/// The type of condition required to get a reward
pub const GameSkillRewardCondition = enum(i32) {
    /// The condition is X amount of score
    score = 0,
    /// The condition is within X amount of time
    time = 1,
    /// The condition is within X amount of lives
    lives = 2,
    _,
};

/// A skill reward
pub const GameSkillReward = struct {
    /// The ID of the reward
    id: i32,
    /// Whether the reward is enabled or not
    enabled: bool,
    /// The title of the reward
    title: ?[]const u8,
    /// The required amount of the condition to get the reward
    requiredAmount: f32,
    /// The condition type
    conditionType: GameSkillRewardCondition,
};

/// The type of the level
pub const GameLevelType = enum(i32) {
    /// A normal nevel
    normal = 0,
    /// A versus level
    versus = 1,
    /// A cutscene
    cutscene = 2,
    _,
};

/// A level uploaded the server
pub const GameLevel = struct {
    /// The ID of the level
    levelId: i32,
    /// The publisher of the level
    publisher: GameUser,
    /// The title of the level
    title: []const u8,
    /// The hash of the level's icon
    iconHash: []const u8,
    /// The description of the level
    description: []const u8,
    /// The location the level is at on the user's moon
    location: GameLocation,
    /// The hash of the root level asset
    rootLevelHash: []const u8,
    /// The game the level was uploaded for
    gameVersion: TokenGame,
    //TODO: see if theres a better type for these,
    //      im not sure the Zig stdlib has something for this though
    /// The publish date of the level
    publishDate: []const u8,
    /// The most recent time the level was updated
    updateDate: []const u8,
    /// The minimum amount of players that are needed to play the level
    minPlayers: u3,
    /// The maximum amount of players that can play the level at once
    maxPlayers: u3,
    /// Whether or not min/max players is enforced
    enforceMinMaxPlayers: bool,
    /// Whether or not all players should share a single screen
    sameScreenGame: bool,
    /// The rewards for completing the level
    skillRewards: []const GameSkillReward,
    /// The amount of yay ratings the level has recieved
    yayRatings: i32,
    /// The amount of boo ratings the level has recieved
    booRatings: i32,
    /// The amount of hearts the level has recieved
    hearts: i32,
    /// The amount of unique plays the level has
    uniquePlays: i32,
    /// Whether or not the level is team picked or not
    teamPicked: bool,
    /// The type of the level
    levelType: GameLevelType,
    /// Whether or not the level is locked
    isLocked: bool,
    /// Whether or not the level is a sub-level
    isSubLevel: bool,
    /// Whether or not the level is copyable
    isCopyable: bool,
    /// The cool-levels score
    score: f32,
};

/// The safety level of an asset
pub const AssetSafetyLevel = enum(i32) {
    /// The asset is guarenteed safe
    safe = 0,
    /// The asset may be unwanted, and break the "vanilla" feel of the server
    potentially_unwanted = 1,
    /// The asset is dangerous, and could cause problems for users
    dangerous = 2,
    _,
};

/// An announcement from the server
pub const GameAnnouncement = struct {
    /// The ID of the announcement
    announcementId: []const u8,
    /// The title of the announcement
    title: []const u8,
    /// The text of the announcement
    text: []const u8,
    /// When the announcement was created at
    createdAt: []const u8,
};

/// A player inside of a room
pub const GameRoomPlayer = struct {
    /// The username of the player
    username: []const u8,
    /// The ID of the player, null means the player is a local player, so theres no account associated
    userId: ?[]const u8,
};

/// The state of the room, eg. what is currently happening in it?
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

/// The mood of a room, eg. who is allowed into the room
pub const RoomMood = enum(u8) {
    /// Rejecting all users
    rejecting_all = 0,
    /// Rejecting all users but friends
    rejecting_all_but_friends = 1,
    /// Rejecting only friends
    rejecting_only_friends = 2,
    /// Allowing all users
    allowing_all = 3,
    _,
};

/// The slot type of the room, eg. what is the type of slot is the room in
pub const RoomSlotType = enum(u8) {
    /// A story level
    story = 0,
    /// A user-uploaded online level
    online = 1,
    /// A moon
    moon = 2,
    /// A pod
    pod = 5,
    _,
};

/// The platform the token is on
pub const TokenPlatform = enum(i32) {
    /// Official PS3 server
    ps3 = 0,
    /// Official RPCN server
    rpcs3 = 1,
    /// Official Vita server
    vita = 2,
    /// Refresh website
    website = 3,
    /// Official PSP server
    psp = 4,
    _,
};

/// Details about a room
pub const GameRoom = struct {
    /// The ID of the room
    roomId: []const u8,
    /// The players that are in the room
    playerIds: []const GameRoomPlayer,
    /// The state of the room
    roomState: RoomState,
    /// The mood of the room
    roomMood: RoomMood,
    /// The slot type the room is currently in
    levelType: RoomSlotType,
    /// The level id of the room, if applicable
    levelId: i32,
    /// The platform the room was created on
    platform: TokenPlatform,
    /// The game the room was created on
    game: TokenGame,
};

/// The server's Discord rich presence configuration
pub const RichPresenceConfiguration = struct {
    /// The application ID to give to discord
    applicationId: []const u8,
    /// The prefix to put before all parties
    partyIdPrefix: []const u8,
    /// The asset configuration
    assetConfiguration: struct {
        /// Whether to use Discord application assets or remote assets
        useApplicationAssets: bool,
        /// The asset to display when the user is in the pod
        podAsset: ?[]const u8,
        /// The asset to display when the user is in their own moon
        moonAsset: ?[]const u8,
        /// The asset to display when the user in in someone else's moon
        remoteMoonAsset: ?[]const u8,
        /// The asset to display when the user is in a developer level
        developerAsset: ?[]const u8,
        /// The asset to display when the user is in a developer adventure
        developerAdventureAsset: ?[]const u8,
        /// The asset to display when the user is in a DLC level
        dlcAsset: ?[]const u8,
        /// The asset to display when no other asset is applicable
        fallbackAsset: ?[]const u8,
    },
};

/// The information about the connected instance
pub const InstanceInformation = struct {
    /// The display name of the instance
    instanceName: []const u8,
    /// The description of the instance
    instanceDescription: []const u8,
    /// The name of the software running the server
    softwareName: []const u8,
    /// The version of the software running the server
    softwareVersion: []const u8,
    /// The type of software running the server
    softwareType: []const u8,
    /// The URL to the server's source code
    softwareSourceUrl: []const u8,
    /// The name of the license the server uses
    softwareLicenseName: []const u8,
    /// The URL of the license the server uses
    softwareLicenseUrl: []const u8,
    /// Whether or not registration is enabled on the server
    registrationEnabled: bool,
    /// The maximum asset safety level allowed on the server
    maximumAssetSafetyLevel: AssetSafetyLevel,
    /// All current announcements on the server
    announcements: []const GameAnnouncement,
    /// The rich presence configration of the server
    richPresenceConfiguration: RichPresenceConfiguration,
    /// Whether or not maintenance mode is enabled on the server
    maintenanceModeEnabled: bool,
    /// The URL to the grafana dashboard
    grafanaDashboardUrl: ?[]const u8,
};

/// Various statistics about the server
const Statistics = struct {
    /// The total count of uploaded levels
    totalLevels: i32,
    /// The total count of created users
    totalUsers: i32,
    /// The total count of active users
    activeUsers: i32,
    /// The total count of uploaded photos
    totalPhotos: i32,
    /// The total count of events
    totalEvents: i32,
    /// The current active room count
    currentRoomCount: i32,
    /// The count of players that are currently ingame
    currentIngamePlayersCount: i32,
    /// Statistics related to request counts
    requestStatistics: struct {
        /// The total count of requests made
        totalRequests: i64,
        /// The total count of API requests made
        apiRequests: i64,
        /// The total count of legacy API requests made
        legacyApiRequests: i64,
        /// The total count of game requests made
        gameRequests: i64,
    },
};

/// Represents an API route in the documentation
const ApiRoute = struct {
    /// The HTTP method that the route uses
    method: []const u8,
    /// The URI of the route
    routeUri: []const u8,
    /// The summary of the route
    summary: []const u8,
    /// Whether or not the route requires authentication
    authenticationRequired: bool,
    /// The minimum role required to access the route
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
    /// The parameters the endpoint takes
    parameters: []const struct {
        /// The name of the parameter
        name: []const u8,
        /// The type of the parameter
        type: enum {
            /// The parameter is somewhere in the route
            Route,
            /// The parameter is sent through the HTTP query string
            Query,
        },
        /// The summary of the parameter
        summary: []const u8,
    },
    /// A list of potential errors that the route could return
    potentialErrors: []const struct {
        /// The name of the error
        name: []const u8,
        /// Details about when the error could occur
        occursWhen: []const u8,
    },
};

/// Zig error counterparts of all API errors
const ApiError = error{
    /// Returned when data is null after a successful API call
    DataNullWhenSuccess,
    /// Returned when error is null after a failed API call
    ErrorNullWhenFailure,
    /// An unknown API error occurred
    UnknownApiError,
    /// The requested resource was not found
    ApiNotFoundError,
    /// The list response is missing the list info
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

/// Gets the information about an instance
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

/// Gets various statistics about the server
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

/// Gets the documentation of all the API routes exposed by the server
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

/// Gets a level by its ID
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

/// Gets a user by their username
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

/// Gets any room that contains a certain user
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
