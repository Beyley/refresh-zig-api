# refresh-zig-api

Zig bindings for the [Refresh](https://github.com/LittleBigRefresh/Refresh) v3 API

We target the latest [Mach Nominated Version](https://machengine.org/about/nominated-zig/).

## Using through the package manager

Add the following dependency to your `build.zig.zon`

```zig
.refresh_api = .{
    .url = "git+https://github.com/LittleBigRefresh/refresh-api-zig#REPLACE_WITH_LATEST_COMMIT_HASH",
},
```

You will recieve an error, telling you to add a `hash` field to the dependency, do so.

Next, add the following to your `build.zig`

```zig
const refresh_api_zig = b.dependency("refresh_api", .{});

exe = b.addExecutable(...);
exe.addModule("api", refresh_api_zig.module("refresh-api-zig"));
```

Then, in your source code, you can import the API as such

```zig
const Api = @import("api");
```
