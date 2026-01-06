//
// Copyright 2025-2026 Frank Stutz
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
const std = @import("std");
const builtin = @import("builtin");

const zdt = @import("zdt");
const Datetime = zdt.Datetime;
const Timezone = zdt.Timezone;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var local_tz: Timezone = try Timezone.tzLocal(allocator);
    defer local_tz.deinit();

    const now_local: Datetime = try Datetime.now(.{ .tz = &local_tz });

    const utc_offset = now_local.utc_offset orelse {
        std.debug.print("Failed to get UTC offset\n", .{});
        return error.UTCOffsetError;
    };
    const offset_seconds = utc_offset.seconds_east;
    const offset_minutes: i32 = @intCast(@divTrunc(offset_seconds, 60));

    const sign_char: u8 = if (offset_minutes < 0) '-' else '+';
    const abs_minutes: i32 = if (offset_minutes < 0) -offset_minutes else offset_minutes;
    const off_hh: u8 = @intCast(@divTrunc(abs_minutes, 60));
    const off_mm: u8 = @intCast(@rem(abs_minutes, 60));

    const us = now_local.nanosecond / 1000;

    // YYYY-MM-DDTHH:MM:SS.uuuuuu-tzoffset (4 digit) (4 digit)
    println(
        "{d:0>4}-{d:0>2}-{d:0>2}T{d:0>2}:{d:0>2}:{d:0>2}.{d:0>6}{c}{d:0>2}{d:0>2}",
        .{
            @as(u16, @intCast(now_local.year)),
            now_local.month,
            now_local.day,
            now_local.hour,
            now_local.minute,
            now_local.second,
            us,
            sign_char,
            off_hh,
            off_mm,
        },
    );
}

fn println(comptime fmt: []const u8, args: anytype) void {
    var stdout_buffer: [256]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    nosuspend stdout.print(fmt ++ "\n", args) catch return;
    nosuspend stdout.flush() catch return;
}
