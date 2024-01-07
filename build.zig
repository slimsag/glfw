const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const shared = b.option(bool, "shared", "Build as a shared library") orelse false;

    const use_x11 = b.option(bool, "x11", "Build with X11. Only useful on Linux") orelse true;
    const use_wl = b.option(bool, "wayland", "Build with Wayland. Only useful on Linux") orelse true;

    const use_opengl = b.option(bool, "opengl", "Build with OpenGL; deprecated on MacOS") orelse false;
    const use_gles = b.option(bool, "gles", "Build with GLES; not supported on MacOS") orelse false;
    const use_metal = b.option(bool, "metal", "Build with Metal; only supported on MacOS") orelse true;

    const lib = std.Build.Step.Compile.create(b, .{
        .name = "glfw",
        .kind = .lib,
        .linkage = if (shared) .dynamic else .static,
        .root_module = .{
            .target = target,
            .optimize = optimize,
        },
    });

    lib.linkLibC();

    if (shared) {
        lib.defineCMacro("_GLFW_BUILD_DLL", "1");
    }

    lib.installHeadersDirectory("include/GLFW", "GLFW");

    if (target.result.os.tag == .macos) {
        // MacOS: this must be defined for macOS 13.3 and older.
        // Critically, this MUST NOT be included as a -D__kernel_ptr_semantics flag. If it is,
        // then this macro will not be defined even if `defineCMacro` was also called!
        lib.defineCMacro("__kernel_ptr_semantics", "");
        @import("xcode_frameworks").addPaths(lib);
    }

    const include_src_flag = "-Isrc";

    switch (target.result.os.tag) {
        .windows => {
            lib.linkSystemLibrary("gdi32");
            lib.linkSystemLibrary("user32");
            lib.linkSystemLibrary("shell32");

            if (use_opengl) {
                lib.linkSystemLibrary("opengl32");
            }

            if (use_gles) {
                lib.linkSystemLibrary("GLESv3");
            }

            const flags = [_][]const u8{ "-D_GLFW_WIN32", include_src_flag };
            lib.addCSourceFiles(.{
                .files = &base_sources,
                .flags = &flags,
            });
            lib.addCSourceFiles(.{
                .files = &windows_sources,
                .flags = &flags,
            });
        },
        .macos => {
            // Transitive dependencies, explicit linkage of these works around
            // ziglang/zig#17130
            lib.linkFramework("CFNetwork");
            lib.linkFramework("ApplicationServices");
            lib.linkFramework("ColorSync");
            lib.linkFramework("CoreText");
            lib.linkFramework("ImageIO");

            // Direct dependencies
            lib.linkSystemLibrary("objc");
            lib.linkFramework("IOKit");
            lib.linkFramework("CoreFoundation");
            lib.linkFramework("AppKit");
            lib.linkFramework("CoreServices");
            lib.linkFramework("CoreGraphics");
            lib.linkFramework("Foundation");

            if (use_metal) {
                lib.linkFramework("Metal");
            }

            if (use_opengl) {
                lib.linkFramework("OpenGL");
            }

            const flags = [_][]const u8{ "-D_GLFW_COCOA", include_src_flag };
            lib.addCSourceFiles(.{
                .files = &base_sources,
                .flags = &flags,
            });
            lib.addCSourceFiles(.{
                .files = &macos_sources,
                .flags = &flags,
            });
        },

        // everything that isn't windows or mac is linux :P
        else => {
            var sources = std.BoundedArray([]const u8, 64).init(0) catch unreachable;
            var flags = std.BoundedArray([]const u8, 16).init(0) catch unreachable;

            sources.appendSlice(&base_sources) catch unreachable;
            sources.appendSlice(&linux_sources) catch unreachable;

            if (use_x11) {
                sources.appendSlice(&linux_x11_sources) catch unreachable;
                flags.append("-D_GLFW_X11") catch unreachable;
            }

            if (use_wl) {
                lib.defineCMacro("WL_MARSHAL_FLAG_DESTROY", "1");

                sources.appendSlice(&linux_wl_sources) catch unreachable;
                flags.append("-D_GLFW_WAYLAND") catch unreachable;
                flags.append("-Wno-implicit-function-declaration") catch unreachable;
            }

            flags.append(include_src_flag) catch unreachable;

            lib.addCSourceFiles(.{
                .files = sources.slice(),
                .flags = flags.slice(),
            });
        },
    }
    link(b, lib);
    b.installArtifact(lib);
}

pub fn link(b: *std.Build, step: *std.Build.Step.Compile) void {
    step.addIncludePath(.{ .path = "include" });
    if (step.rootModuleTarget().isDarwin()) @import("xcode_frameworks").addPaths(step);
    const target_triple: []const u8 = step.rootModuleTarget().zigTriple(b.allocator) catch @panic("OOM");
    const cpu_opts: []const u8 = step.root_module.resolved_target.?.query.serializeCpuAlloc(b.allocator) catch @panic("OOM");
    step.addIncludePath(b.dependency("vulkan_headers", .{}).path("include"));
    step.linkLibrary(b.dependency("x11_headers", .{
        .target = target_triple,
        .optimize = step.root_module.optimize.?,
        .cpu = cpu_opts,
    }).artifact("x11-headers"));
    step.addIncludePath(b.dependency("wayland_headers", .{}).path("include"));
    step.addIncludePath(b.dependency("wayland_headers", .{}).path("wayland-generated"));
}

pub fn link2(b: *std.Build, m: *std.Build.Module) void {
    m.addIncludePath(.{ .path = "include" });
    if (m.resolved_target != null and m.resolved_target.?.result.isDarwin()) @import("xcode_frameworks").addPaths2(m);
    m.addIncludePath(b.dependency("vulkan_headers", .{}).path("include"));
    m.linkLibrary(b.dependency("x11_headers", .{}).artifact("x11-headers"));
    m.addIncludePath(b.dependency("wayland_headers", .{}).path("include"));
    m.addIncludePath(b.dependency("wayland_headers", .{}).path("wayland-generated"));
}

// fn sdkPath(comptime suffix: []const u8) []const u8 {
//     if (suffix[0] != '/') @compileError("suffix must be an absolute path");
//     return comptime blk: {
//         const root_dir = std.fs.path.dirname(@src().file) orelse ".";
//         break :blk root_dir ++ suffix;
//     };
// }

const base_sources = [_][]const u8{
    "src/context.c",
    "src/egl_context.c",
    "src/init.c",
    "src/input.c",
    "src/monitor.c",
    "src/null_init.c",
    "src/null_joystick.c",
    "src/null_monitor.c",
    "src/null_window.c",
    "src/osmesa_context.c",
    "src/platform.c",
    "src/vulkan.c",
    "src/window.c",
};

const linux_sources = [_][]const u8{
    "src/linux_joystick.c",
    "src/posix_module.c",
    "src/posix_poll.c",
    "src/posix_thread.c",
    "src/posix_time.c",
    "src/xkb_unicode.c",
};

const linux_wl_sources = [_][]const u8{
    "src/wl_init.c",
    "src/wl_monitor.c",
    "src/wl_window.c",
};

const linux_x11_sources = [_][]const u8{
    "src/glx_context.c",
    "src/x11_init.c",
    "src/x11_monitor.c",
    "src/x11_window.c",
};

const windows_sources = [_][]const u8{
    "src/wgl_context.c",
    "src/win32_init.c",
    "src/win32_joystick.c",
    "src/win32_module.c",
    "src/win32_monitor.c",
    "src/win32_thread.c",
    "src/win32_time.c",
    "src/win32_window.c",
};

const macos_sources = [_][]const u8{
    // C sources
    "src/cocoa_time.c",
    "src/posix_module.c",
    "src/posix_thread.c",

    // ObjC sources
    "src/cocoa_init.m",
    "src/cocoa_joystick.m",
    "src/cocoa_monitor.m",
    "src/cocoa_window.m",
    "src/nsgl_context.m",
};
