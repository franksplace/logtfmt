const std = @import("std");

const timezone_offset_hours = -7;

const DateTime = struct {
    year: i32,
    month: u8,
    day: u8,
    hour: u8,
    minute: u8,
    second: u8,
};

fn fromTimestamp(ts: i64) DateTime {
    var z = ts;
    const sec: u8 = @intCast(@mod(z, 60));
    z = @divTrunc(z, 60);
    const min: u8 = @intCast(@mod(z, 60));
    z = @divTrunc(z, 60);
    const hour: u8 = @intCast(@mod(z, 24));
    var days = @divTrunc(z, 24);

    var year: i32 = 1970;
    var month: u8 = 1;
    var day: u8 = 1;

    while (true) {
        const leap = (@mod(year, 4) == 0 and (@mod(year, 100) != 0 or @mod(year, 400) == 0));
        var days_in_year: i32 = 365;
        if (leap) days_in_year = 366;
        if (days >= days_in_year) {
            days -= days_in_year;
            year += 1;
        } else {
            break;
        }
    }

    const month_lengths = [_]u8{ 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };
    var i: usize = 0;
    while (i < 12) : (i += 1) {
        var ml = month_lengths[i];
        if (i == 1 and (@mod(year, 4) == 0 and (@mod(year, 100) != 0 or @mod(year, 400) == 0))) {
            ml += 1;
        }
        if (days >= ml) {
            days -= ml;
            month += 1;
        } else {
            break;
        }
    }
    day += @intCast(days);

    return DateTime{
        .year = year,
        .month = month,
        .day = day,
        .hour = hour,
        .minute = min,
        .second = sec,
    };
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    const now_ns = std.time.nanoTimestamp();
    const now_us = @divTrunc(now_ns, 1000);

    const epoch_secs_utc = @divTrunc(now_us, 1_000_000);
    const micros: u32 = @intCast(@mod(now_us, 1_000_000));

    const epoch_secs_local_i128 = epoch_secs_utc + timezone_offset_hours * 3600;

    if (epoch_secs_local_i128 < std.math.minInt(i64) or epoch_secs_local_i128 > std.math.maxInt(i64)) {
        return error.TimestampOutOfRange;
    }
    const epoch_secs_local: i64 = @intCast(epoch_secs_local_i128);

    const dt = fromTimestamp(epoch_secs_local);

    const offset_sign = if (timezone_offset_hours >= 0) '+' else '-';
    const abs_offset = if (timezone_offset_hours < 0) -timezone_offset_hours else timezone_offset_hours;

    const year_u32: u32 = @intCast(dt.year);
    try stdout.print(
        "{d:0>4}-{d:0>2}-{d:0>2}T{d:0>2}:{d:0>2}:{d:0>2}.{d:0>6}{c}{d:0>2}00\n",
        .{
            year_u32,
            dt.month,
            dt.day,
            dt.hour,
            dt.minute,
            dt.second,
            micros,
            offset_sign,
            abs_offset,
        },
    );
}
