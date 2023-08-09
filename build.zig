const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // TODO: uncomment this once hexops/mach#902 is fixed.
    // b.dependency may not be called inside pub fn build if we want to use this package via the
    // package manager transitively.
    _ = target;
    _ = optimize;

    // const shared = b.option(bool, "shared", "Build as a shared library") orelse false;

    // const use_x11 = b.option(bool, "x11", "Build with X11. Only useful on Linux") orelse true;
    // const use_wl = b.option(bool, "wayland", "Build with Wayland. Only useful on Linux") orelse true;

    // const use_opengl = b.option(bool, "opengl", "Build with OpenGL; deprecated on MacOS") orelse false;
    // const use_gles = b.option(bool, "gles", "Build with GLES; not supported on MacOS") orelse false;
    // const use_metal = b.option(bool, "metal", "Build with Metal; only supported on MacOS") orelse true;

    // const lib = std.Build.CompileStep.create(b, .{
    //     .name = "glfw",
    //     .kind = .lib,
    //     .linkage = if (shared) .dynamic else .static,
    //     .target = target,
    //     .optimize = optimize,
    // });

    // lib.linkLibC();

    // if (shared) {
    //     lib.defineCMacro("_GLFW_BUILD_DLL", "1");
    // }

    // lib.installHeadersDirectory("include/GLFW", "GLFW");

    // lib.linkLibrary(b.dependency("vulkan_headers", .{
    //     .target = target,
    //     .optimize = optimize,
    // }).artifact("vulkan-headers"));

    // if (lib.target_info.target.os.tag == .macos) {
    //     // MacOS: this must be defined for macOS 13.3 and older.
    //     // Critically, this MUST NOT be included as a -D__kernel_ptr_semantics flag. If it is,
    //     // then this macro will not be defined even if `defineCMacro` was also called!
    //     lib.defineCMacro("__kernel_ptr_semantics", "");
    //     @import("xcode_frameworks").addPaths(b, lib);
    // }

    // const include_src_flag = "-Isrc";

    // switch (lib.target_info.target.os.tag) {
    //     .windows => {
    //         lib.linkSystemLibraryName("gdi32");
    //         lib.linkSystemLibraryName("user32");
    //         lib.linkSystemLibraryName("shell32");

    //         if (use_opengl) {
    //             lib.linkSystemLibraryName("opengl32");
    //         }

    //         if (use_gles) {
    //             lib.linkSystemLibraryName("GLESv3");
    //         }

    //         const flags = [_][]const u8{ "-D_GLFW_WIN32", include_src_flag };
    //         lib.addCSourceFiles(&base_sources, &flags);
    //         lib.addCSourceFiles(&windows_sources, &flags);
    //     },
    //     .macos => {
    //         lib.linkSystemLibraryName("objc");
    //         lib.linkFramework("IOKit");
    //         lib.linkFramework("CoreFoundation");
    //         lib.linkFramework("AppKit");
    //         lib.linkFramework("CoreServices");
    //         lib.linkFramework("CoreGraphics");
    //         lib.linkFramework("Foundation");

    //         if (use_metal) {
    //             lib.linkFramework("Metal");
    //         }

    //         if (use_opengl) {
    //             lib.linkFramework("OpenGL");
    //         }

    //         const flags = [_][]const u8{ "-D_GLFW_COCOA", include_src_flag };
    //         lib.addCSourceFiles(&base_sources, &flags);
    //         lib.addCSourceFiles(&macos_sources, &flags);
    //     },

    //     // everything that isn't windows or mac is linux :P
    //     else => {
    //         var sources = std.BoundedArray([]const u8, 64).init(0) catch unreachable;
    //         var flags = std.BoundedArray([]const u8, 16).init(0) catch unreachable;

    //         sources.appendSlice(&base_sources) catch unreachable;
    //         sources.appendSlice(&linux_sources) catch unreachable;

    //         if (use_x11) {
    //             lib.linkLibrary(b.dependency("x11_headers", .{
    //                 .target = target,
    //                 .optimize = optimize,
    //             }).artifact("x11-headers"));

    //             sources.appendSlice(&linux_x11_sources) catch unreachable;
    //             flags.append("-D_GLFW_X11") catch unreachable;
    //         }

    //         if (use_wl) {
    //             lib.linkLibrary(b.dependency("wayland_headers", .{
    //                 .target = target,
    //                 .optimize = optimize,
    //             }).artifact("wayland-headers"));

    //             lib.defineCMacro("WL_MARSHAL_FLAG_DESTROY", "1");

    //             sources.appendSlice(&linux_wl_sources) catch unreachable;
    //             flags.append("-D_GLFW_WAYLAND") catch unreachable;
    //             flags.append("-Wno-implicit-function-declaration") catch unreachable;
    //         }

    //         flags.append(include_src_flag) catch unreachable;

    //         lib.addCSourceFiles(sources.slice(), flags.slice());
    //     },
    // }
    // b.installArtifact(lib);
}

// TODO: remove this once hexops/mach#902 is fixed.
pub fn lib(
    b: *std.Build,
    optimize: std.builtin.OptimizeMode,
    target: std.zig.CrossTarget,
) *std.Build.Step.Compile {
    const shared = false;

    const use_x11 = true;
    const use_wl = true;

    const use_opengl = false;
    const use_gles = false;
    const use_metal = true;

    const l = std.Build.CompileStep.create(b, .{
        .name = "glfw",
        .kind = .lib,
        .linkage = if (shared) .dynamic else .static,
        .target = target,
        .optimize = optimize,
    });

    l.linkLibC();

    if (shared) {
        l.defineCMacro("_GLFW_BUILD_DLL", "1");
    }

    // l.installHeadersDirectory("include/GLFW", "GLFW");

    l.linkLibrary(b.dependency("vulkan_headers", .{
        .target = target,
        .optimize = optimize,
    }).artifact("vulkan-headers"));

    if (l.target_info.target.os.tag == .macos) {
        // MacOS: this must be defined for macOS 13.3 and older.
        // Critically, this MUST NOT be included as a -D__kernel_ptr_semantics flag. If it is,
        // then this macro will not be defined even if `defineCMacro` was also called!
        l.defineCMacro("__kernel_ptr_semantics", "");
        @import("xcode_frameworks").addPaths(b, l);
    }

    const include_src_flag = "-Isrc";

    switch (l.target_info.target.os.tag) {
        .windows => {
            l.linkSystemLibraryName("gdi32");
            l.linkSystemLibraryName("user32");
            l.linkSystemLibraryName("shell32");

            if (use_opengl) {
                l.linkSystemLibraryName("opengl32");
            }

            if (use_gles) {
                l.linkSystemLibraryName("GLESv3");
            }

            const flags = [_][]const u8{ "-D_GLFW_WIN32", include_src_flag };
            l.addCSourceFiles(&base_sources, &flags);
            l.addCSourceFiles(&windows_sources, &flags);
        },
        .macos => {
            l.linkSystemLibraryName("objc");
            l.linkFramework("IOKit");
            l.linkFramework("CoreFoundation");
            l.linkFramework("AppKit");
            l.linkFramework("CoreServices");
            l.linkFramework("CoreGraphics");
            l.linkFramework("Foundation");

            if (use_metal) {
                l.linkFramework("Metal");
            }

            if (use_opengl) {
                l.linkFramework("OpenGL");
            }

            const flags = [_][]const u8{ "-D_GLFW_COCOA", include_src_flag };
            l.addCSourceFiles(&base_sources, &flags);
            l.addCSourceFiles(&macos_sources, &flags);
        },

        // everything that isn't windows or mac is linux :P
        else => {
            var sources = std.BoundedArray([]const u8, 64).init(0) catch unreachable;
            var flags = std.BoundedArray([]const u8, 16).init(0) catch unreachable;

            sources.appendSlice(&base_sources) catch unreachable;
            sources.appendSlice(&linux_sources) catch unreachable;

            if (use_x11) {
                l.linkLibrary(b.dependency("x11_headers", .{
                    .target = target,
                    .optimize = optimize,
                }).artifact("x11-headers"));

                sources.appendSlice(&linux_x11_sources) catch unreachable;
                flags.append("-D_GLFW_X11") catch unreachable;
            }

            if (use_wl) {
                l.linkLibrary(b.dependency("wayland_headers", .{
                    .target = target,
                    .optimize = optimize,
                }).artifact("wayland-headers"));

                l.defineCMacro("WL_MARSHAL_FLAG_DESTROY", "1");

                sources.appendSlice(&linux_wl_sources) catch unreachable;
                flags.append("-D_GLFW_WAYLAND") catch unreachable;
                flags.append("-Wno-implicit-function-declaration") catch unreachable;
            }

            flags.append(include_src_flag) catch unreachable;

            l.addCSourceFiles(sources.slice(), flags.slice());
        },
    }
    // b.installArtifact(l);
    return l;
}

pub fn addPaths(step: *std.build.CompileStep) void {
    step.addIncludePath(.{ .path = sdkPath("/include") });
}

fn sdkPath(comptime suffix: []const u8) []const u8 {
    if (suffix[0] != '/') @compileError("suffix must be an absolute path");
    return comptime blk: {
        const root_dir = std.fs.path.dirname(@src().file) orelse ".";
        break :blk root_dir ++ suffix;
    };
}

// TODO: remove sdkPath usage below once hexops/mach#902 is fixed.
const base_sources = [_][]const u8{
    sdkPath("/src/context.c"),
    sdkPath("/src/egl_context.c"),
    sdkPath("/src/init.c"),
    sdkPath("/src/input.c"),
    sdkPath("/src/monitor.c"),
    sdkPath("/src/null_init.c"),
    sdkPath("/src/null_joystick.c"),
    sdkPath("/src/null_monitor.c"),
    sdkPath("/src/null_window.c"),
    sdkPath("/src/osmesa_context.c"),
    sdkPath("/src/platform.c"),
    sdkPath("/src/vulkan.c"),
    sdkPath("/src/window.c"),
};

const linux_sources = [_][]const u8{
    sdkPath("/src/linux_joystick.c"),
    sdkPath("/src/posix_module.c"),
    sdkPath("/src/posix_poll.c"),
    sdkPath("/src/posix_thread.c"),
    sdkPath("/src/posix_time.c"),
    sdkPath("/src/xkb_unicode.c"),
};

const linux_wl_sources = [_][]const u8{
    sdkPath("/src/wl_init.c"),
    sdkPath("/src/wl_monitor.c"),
    sdkPath("/src/wl_window.c"),
};

const linux_x11_sources = [_][]const u8{
    sdkPath("/src/glx_context.c"),
    sdkPath("/src/x11_init.c"),
    sdkPath("/src/x11_monitor.c"),
    sdkPath("/src/x11_window.c"),
};

const windows_sources = [_][]const u8{
    sdkPath("/src/wgl_context.c"),
    sdkPath("/src/win32_init.c"),
    sdkPath("/src/win32_joystick.c"),
    sdkPath("/src/win32_module.c"),
    sdkPath("/src/win32_monitor.c"),
    sdkPath("/src/win32_thread.c"),
    sdkPath("/src/win32_time.c"),
    sdkPath("/src/win32_window.c"),
};

const macos_sources = [_][]const u8{
    // C sources
    sdkPath("/src/cocoa_time.c"),
    sdkPath("/src/posix_module.c"),
    sdkPath("/src/posix_thread.c"),

    // ObjC sources
    sdkPath("/src/cocoa_init.m"),
    sdkPath("/src/cocoa_joystick.m"),
    sdkPath("/src/cocoa_monitor.m"),
    sdkPath("/src/cocoa_window.m"),
    sdkPath("/src/nsgl_context.m"),
};
