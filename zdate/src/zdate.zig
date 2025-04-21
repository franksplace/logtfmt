const std = @import("std");
const builtin = @import("builtin");

const zdt = @import("zdt");
const Datetime = zdt.Datetime;
const Timezone = zdt.Timezone;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var my_tz: Timezone = try Timezone.tzLocal(allocator);
    defer my_tz.deinit();
    const now_local: Datetime = try Datetime.now(.{ .tz = &my_tz });

    println("{%Y-%m-%dT%H}:{%M}:{%S}.{d:0>6}{%z}", .{ now_local, now_local, now_local, now_local.nanosecond / 1000, now_local });
}

fn println(comptime fmt: []const u8, args: anytype) void {
    const stdout = std.io.getStdOut().writer();
    nosuspend stdout.print(fmt ++ "\n", args) catch return;
}
