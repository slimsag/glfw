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
    lib.addIncludePath(b.path("include"));
    lib.linkLibC();
    addPaths(&lib.root_module);

    if (shared) lib.defineCMacro("_GLFW_BUILD_DLL", "1");

    lib.installHeadersDirectory(b.path("include/GLFW"), "GLFW", .{});
    // GLFW headers depend on these headers, so they must be distributed too.
    if (b.lazyDependency("vulkan_headers", .{
        .target = target,
        .optimize = optimize,
    })) |dep| {
        lib.installLibraryHeaders(dep.artifact("vulkan-headers"));
    }
    if (target.result.os.tag == .linux) {
        if (b.lazyDependency("x11_headers", .{
            .target = target,
            .optimize = optimize,
        })) |dep| {
            lib.linkLibrary(dep.artifact("x11-headers"));
            lib.installLibraryHeaders(dep.artifact("x11-headers"));
        }
        if (b.lazyDependency("wayland_headers", .{
            .target = target,
            .optimize = optimize,
        })) |dep| {
            lib.linkLibrary(dep.artifact("wayland-headers"));
            lib.installLibraryHeaders(dep.artifact("wayland-headers"));
        }
    }

    if (target.result.isDarwin()) {
        // MacOS: this must be defined for macOS 13.3 and older.
        lib.defineCMacro("__kernel_ptr_semantics", "");
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
    b.installArtifact(lib);
}

pub fn addPaths(mod: *std.Build.Module) void {
    if (mod.resolved_target.?.result.os.tag == .macos) @import("xcode_frameworks").addPaths(mod);
}

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
