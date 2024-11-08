# refresh-zig-api

Zig bindings for the [Refresh](https://github.com/LittleBigRefresh/Refresh) v3 API

We target the latest [Mach Nominated Version](https://machengine.org/about/nominated-zig/).

## Using through the package manager

Run the following command

```bash
zig fetch --save git+https://github.com/LittleBigRefresh/refresh-api-zig
```

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
