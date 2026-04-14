pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .sanitize_c = .off,
    });

    // zig-config/config.h replaces the autoconf-generated config.h
    lib_mod.addCMacro("HAVE_CONFIG_H", "1");
    lib_mod.addIncludePath(b.path("zig-config"));
    lib_mod.addIncludePath(b.path("include"));
    lib_mod.addIncludePath(b.path("lib/driver"));

    lib_mod.addCSourceFiles(.{ .files = &common_sources });

    switch (target.result.os.tag) {
        .windows => {
            lib_mod.addCSourceFiles(.{ .files = &.{
                "lib/driver/MSWindows/aspi32.c",
                "lib/driver/MSWindows/win32.c",
                "lib/driver/MSWindows/win32_ioctl.c",
            } });
        },
        .macos => {
            lib_mod.linkFramework("IOKit", .{});
            lib_mod.linkFramework("CoreFoundation", .{});
            lib_mod.addCSourceFiles(.{ .files = &.{
                "lib/driver/osx.c",
            } });
        },
        .freebsd => {
            lib_mod.addCSourceFiles(.{ .files = &.{
                "lib/driver/FreeBSD/freebsd.c",
                "lib/driver/FreeBSD/freebsd_cam.c",
                "lib/driver/FreeBSD/freebsd_ioctl.c",
            } });
        },
        else => {
            lib_mod.addCSourceFiles(.{ .files = &.{
                "lib/driver/gnu_linux.c",
            } });
        },
    }

    const lib = b.addLibrary(.{
        .name = "cdio",
        .root_module = lib_mod,
    });

    lib.installHeadersDirectory(b.path("include"), "", .{});
    lib.installHeadersDirectory(b.path("zig-config/cdio"), "cdio", .{});
    b.installArtifact(lib);
}

const common_sources = [_][]const u8{
    // driver core
    "lib/driver/_cdio_generic.c",
    "lib/driver/_cdio_stdio.c",
    "lib/driver/_cdio_stream.c",
    "lib/driver/abs_path.c",
    "lib/driver/audio.c",
    "lib/driver/cd_types.c",
    "lib/driver/cdio.c",
    "lib/driver/cdtext.c",
    "lib/driver/device.c",
    "lib/driver/disc.c",
    "lib/driver/ds.c",
    "lib/driver/logging.c",
    "lib/driver/memory.c",
    "lib/driver/read.c",
    "lib/driver/realpath.c",
    "lib/driver/sector.c",
    "lib/driver/track.c",
    "lib/driver/utf8.c",
    "lib/driver/util.c",
    // image backends (for opening .iso files / disc images)
    "lib/driver/image_common.c",
    "lib/driver/image/bincue.c",
    "lib/driver/image/cdrdao.c",
    "lib/driver/image/nrg.c",
    // MMC (Multimedia Commands — required for CD audio reads)
    "lib/driver/mmc/mmc.c",
    "lib/driver/mmc/mmc_hl_cmds.c",
    "lib/driver/mmc/mmc_ll_cmds.c",
    "lib/driver/mmc/mmc_util.c",
    // ISO 9660 filesystem
    "lib/iso9660/iso9660.c",
    "lib/iso9660/iso9660_fs.c",
    "lib/iso9660/rock.c",
    "lib/iso9660/xa.c",
    // UDF filesystem
    "lib/udf/filemode.c",
    "lib/udf/udf.c",
    "lib/udf/udf_file.c",
    "lib/udf/udf_fs.c",
    "lib/udf/udf_time.c",
};

const std = @import("std");
const Build = std.Build;
