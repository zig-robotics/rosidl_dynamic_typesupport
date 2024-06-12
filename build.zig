const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const linkage = b.option(std.builtin.LinkMode, "linkage", "Specify static or dynamic linkage") orelse .dynamic;
    const upstream = b.dependency("rosidl_dynamic_typesupport", .{});

    var rosidl_dynamic_typesupport = std.Build.Step.Compile.create(b, .{
        .root_module = .{
            .target = target,
            .optimize = optimize,
        },
        .name = "rosidl_dynamic_typesupport",
        .kind = .lib,
        .linkage = linkage,
    });

    rosidl_dynamic_typesupport.linkLibCpp();
    rosidl_dynamic_typesupport.addIncludePath(upstream.path("include"));

    const rcutils_dep = b.dependency("rcutils", .{
        .target = target,
        .optimize = optimize,
        .linkage = linkage,
    });
    rosidl_dynamic_typesupport.linkLibrary(rcutils_dep.artifact("rcutils"));

    const rosidl_dep = b.dependency("rosidl", .{
        .target = target,
        .optimize = optimize,
        .linkage = linkage,
    });

    rosidl_dynamic_typesupport.linkLibrary(rosidl_dep.artifact("rosidl_runtime_c"));
    rosidl_dynamic_typesupport.addIncludePath(rosidl_dep.builder.dependency("rosidl", .{}).path("rosidl_typesupport_interface/include")); // grab the underlying rosidl dependency for now, until header only libraries are figured out

    rosidl_dynamic_typesupport.addCSourceFiles(.{
        .root = upstream.path(""),
        .files = &.{
            "src/api/serialization_support.c",
            "src/api/dynamic_data.c",
            "src/api/dynamic_type.c",
            "src/dynamic_message_type_support_struct.c",
            "src/identifier.c",
        },
    });

    rosidl_dynamic_typesupport.installHeadersDirectory(
        upstream.path("include"),
        "",
        .{},
    );
    b.installArtifact(rosidl_dynamic_typesupport);
}
