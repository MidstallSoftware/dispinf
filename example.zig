const std = @import("std");
const dispinf = @import("dispinf");

const alloc = std.heap.page_allocator;

pub fn main() !void {
    var args = try std.process.ArgIterator.initWithAllocator(alloc);
    defer args.deinit();

    _ = args.next();

    const path = blk: {
        const tmp = args.next() orelse return error.MissingArgument;
        if (std.fs.path.isAbsolute(tmp)) break :blk try alloc.dupe(u8, tmp);

        const cwd = try std.process.getCwdAlloc(alloc);
        defer alloc.free(cwd);
        break :blk try std.fs.path.join(alloc, &.{ cwd, tmp });
    };

    const file = try std.fs.openFileAbsolute(path, .{});
    defer file.close();

    const edid = try dispinf.Edid.initFile(file);
    std.debug.print("{}\n", .{edid});
}
