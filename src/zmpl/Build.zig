const std = @import("std");
const builtin = @import("builtin");

build: *std.Build,
lib: *std.Build.Step.Compile,
templates_path: []const u8,

const Self = @This();

const TemplateDef = struct {
    lazy_path: std.Build.LazyPath,
    name: []const u8,
    module_name: []const u8,
};

pub fn init(
    build: *std.Build,
    lib: *std.Build.Step.Compile,
    templates_path: []const u8,
) Self {
    return .{
        .build = build,
        .lib = lib,
        .templates_path = templates_path,
    };
}

pub fn compile(
    self: *Self,
    comptime Template: type,
    comptime options: type,
) !*std.Build.Module {
    var template_defs = std.ArrayList(TemplateDef).init(self.build.allocator);

    var write_files = self.build.addWriteFiles();

    self.compileTemplates(&template_defs, Template, options) catch |err| {
        switch (err) {
            error.TemplateDirectoryNotFound => {
                std.debug.print(
                    "[zmpl] Template directory `{s}` not found, skipping compilation.\n",
                    .{self.templates_path},
                );
            },
            else => return err,
        }
    };

    var buf = std.ArrayList(u8).init(self.build.allocator);
    const writer = buf.writer();
    defer buf.deinit();

    try writer.writeAll(
        \\// Zmpl template manifest.
        \\// This file is automatically generated at build time and should not be manually modified.
        \\
        \\const std = @import("std");
        \\const zmpl = @import("zmpl");
        \\
        \\pub const Template = struct {
        \\   name: []const u8,
        \\   render: zmpl.Data.RenderFn,
        \\   renderWithLayout: *const fn(Template, *zmpl.Data) anyerror![]const u8,
        \\};
        \\
        \\pub fn find(name: []const u8) ?Template {
        \\    for (templates) |template| {
        \\        if (std.mem.eql(u8, name, template.name)) return template;
        \\    } else {
        \\        return null;
        \\    }
        \\}
        \\pub const templates = [_]Template{
        \\
    );
    for (template_defs.items) |template_def| {
        try writer.writeAll(try std.fmt.allocPrint(
            self.build.allocator,
            \\    .{{
            \\        .name = "{s}",
            \\        .render = @import("{s}").render,
            \\        .renderWithLayout = @import("{s}").renderWithLayout,
            \\    }},
            \\
        ,
            .{
                template_def.name,
                template_def.module_name,
                template_def.module_name,
            },
        ));
    }
    try writer.writeAll("};\n");
    const lazy_path = write_files.add("zmpl.manifest.zig", buf.items);

    const manifest_module = self.build.addModule("zmpl.manifest", .{ .root_source_file = lazy_path });
    manifest_module.addImport("zmpl", self.build.modules.get("zmpl").?);

    for (template_defs.items) |template_def| {
        const template_module = self.build.createModule(.{ .root_source_file = template_def.lazy_path });
        template_module.addImport("zmpl", self.build.modules.get("zmpl").?);
        manifest_module.addImport(template_def.module_name, template_module);
    }
    self.lib.root_module.addImport("zmpl.manifest", manifest_module);

    return manifest_module;
}

fn compileTemplates(
    self: *Self,
    array: *std.ArrayList(TemplateDef),
    comptime Template: type,
    comptime options: type,
) !void {
    const paths = try self.findTemplates();
    var dir = try std.fs.cwd().openDir(self.templates_path, .{});
    defer dir.close();

    for (paths.items) |path| {
        var write_files = self.build.addWriteFiles();
        std.debug.print("[zmpl] Compiling template: {s}\n", .{path});
        const output_path = try std.fs.path.join(
            self.build.allocator,
            &[_][]const u8{ "templates", path },
        );

        var file = try dir.openFile(path, .{});
        const size = (try file.stat()).size;
        const buffer = try self.build.allocator.alloc(u8, size);
        const content = try dir.readFile(path, buffer);
        var template = Template.init(self.build.allocator, path, content);
        const output = try template.compile(options);

        const module_name = try std.mem.replaceOwned(u8, self.build.allocator, output_path, "\\", "/");

        const lazy_path = write_files.add(output_path, output);
        const template_def: TemplateDef = .{
            .lazy_path = lazy_path,
            .name = try template.identifier(),
            .module_name = module_name,
        };

        try array.append(template_def);
    }
}

fn findTemplates(self: *Self) !std.ArrayList([]const u8) {
    var array = std.ArrayList([]const u8).init(self.build.allocator);
    var dir = std.fs.cwd().openDir(self.templates_path, .{ .iterate = true }) catch |err| {
        switch (err) {
            error.FileNotFound => return error.TemplateDirectoryNotFound,
            else => return err,
        }
    };

    var walker = try dir.walk(self.build.allocator);
    defer walker.deinit();

    while (try walker.next()) |entry| {
        if (entry.kind != .file) continue;
        const extension = std.fs.path.extension(entry.path);
        if (!std.mem.eql(u8, extension, ".zmpl")) continue;
        try array.append(try self.build.allocator.dupe(u8, entry.path));
    }
    return array;
}
