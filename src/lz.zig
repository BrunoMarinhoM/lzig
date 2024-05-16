const std = @import("std");
const print = std.debug.print;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

pub const Color = enum {
    red,
    green,
    blue,
    yellow,
    orange,
    cyan,
    purple,
    lgray,
    dgray,
    lred,
    lgreen,
    noColor,
};

pub const ANSCI_COL = struct {
    color: Color,
    code: []const u8,

    const Self = @This();

    pub fn init(col: Color, bold: bool) ANSCI_COL {
        const boldness = if (bold) "1" else "0";
        return .{ .color = col, .code = switch (col) {
            .red => "\x1B[" ++ boldness ++ ";31m",
            .green => "\x1B[0" ++ boldness ++ ";32m",
            .orange => "\x1B[0" ++ boldness ++ ";33m",
            .blue => "\x1B[0" ++ boldness ++ ";34m",
            .purple => "\x1B[0" ++ boldness ++ ";35m",
            .cyan => "\x1B[0" ++ boldness ++ ";36m",
            .lgray => "\x1B[0" ++ boldness ++ ";37m",
            .dgray => "\x1B[0" ++ boldness ++ ";38m",
            .lred => "\x1B[0" ++ boldness ++ ";39m",
            .lgreen => "\x1B[0" ++ boldness ++ ";40m",
            .yellow => "\x1B[0" ++ boldness ++ ";41m",
            .noColor => "\x1B[0m",
        } };
    }
};

pub const ListOfEntries = struct {
    list: *std.ArrayList(*std.fs.Dir.Entry),
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn init(alloc: std.mem.Allocator) !ListOfEntries {
        const list = try alloc.create(std.ArrayList(*std.fs.Dir.Entry));
        list.* = std.ArrayList(*std.fs.Dir.Entry).init(alloc);
        return .{
            .list = list,
            .allocator = alloc,
        };
    }

    pub fn append(self: Self, item: std.fs.Dir.Entry) !void {
        const new_item_ptr = try self.allocator.create(std.fs.Dir.Entry);
        const item_name_ptr = try self.allocator.alloc(u8, item.name.len);
        std.mem.copyForwards(u8, item_name_ptr, item.name);

        new_item_ptr.* = std.fs.Dir.Entry{
            .name = item_name_ptr,
            .kind = item.kind,
        };

        try self.list.append(new_item_ptr);
    }

    pub fn deinit(self: Self) !void {
        for (self.list.items) |item| {
            self.allocator.free(item.name);
            self.allocator.destroy(item);
        }

        self.list.deinit();
    }
};

pub fn main() !void {
    var cwd = std.fs.cwd();
    var arr = try ListOfEntries.init(allocator);
    defer {
        arr.deinit() catch {};
    }

    var pwd_dir = try cwd.openDir(".", .{ .iterate = true });

    var itt = pwd_dir.iterate();

    while (try itt.next()) |item| {
        try arr.append(item);
    }

    const stdout = std.io.getStdOut();

    const stdoutw = stdout.writer();

    outter: for (arr.list.items) |item| {
        for (item.name) |letter| {
            if (!std.ascii.isASCII(letter)) {
                continue :outter;
            }
        }

        if (item.name[0] != ".".*[0]) {
            if (item.kind == .directory) {
                const fmt_name = try std.mem.concat(allocator, u8, &[_][]const u8{ ANSCI_COL.init(.blue, true).code, item.name, ANSCI_COL.init(.noColor, false).code });
                _ = try stdoutw.print("{s}", .{fmt_name});
                _ = try stdoutw.print("\n", .{});
            } else {
                const fmt_name = try std.mem.concat(allocator, u8, &[_][]const u8{ ANSCI_COL.init(.lgray, false).code, item.name, ANSCI_COL.init(.noColor, false).code });
                _ = try stdoutw.print("{s}", .{fmt_name});
                _ = try stdoutw.print("\n", .{});
            }
        }
    }
    pwd_dir.close();
}
