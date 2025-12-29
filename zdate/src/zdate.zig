//
// Copyright 2025 Frank Stutz
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

    var my_tz: Timezone = try Timezone.tzLocal(allocator);
    defer my_tz.deinit();
    const now_local: Datetime = try Datetime.now(.{ .tz = &my_tz });

    const ns = now_local.nanosecond;

    // yyyy-mm-ddTHH:MM:SS.NNNNNNNNN<offset>
    println(
        "{d:0>4}-{d:0>2}-{d:0>2}T{d:0>2}:{d:0>2}:{d:0>2}.{d:0>9}{f}",
        .{
            now_local.year,
            now_local.month,
            now_local.day,
            now_local.hour,
            now_local.minute,
            now_local.second,
            ns,
            now_local, // {f} uses zdt’s Datetime formatter (with offset). [web:74][web:47]
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
