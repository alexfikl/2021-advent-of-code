// --- Part One ---
//
// As the submarine drops below the surface of the ocean, it automatically
// performs a sonar sweep of the nearby sea floor. On a small screen, the
// sonar sweep report (your puzzle input) appears: each line is a measurement
// of the sea floor depth as the sweep looks further and further away from the
// submarine.
//
// For example, suppose you had the following report::
//
//      199
//      200
//      208
//      210
//      200
//      207
//      240
//      269
//      260
//      263
//
// This report indicates that, scanning outward from the submarine, the sonar
// sweep found depths of 199, 200, 208, 210, and so on.
//
// The first order of business is to figure out how quickly the depth increases,
// just so you know what you're dealing with - you never know if the keys will
// get carried into deeper water by an ocean current or a fish or something.
//
// To do this, count the number of times a depth measurement increases from
// the previous measurement. (There is no measurement before the first
// measurement.) In the example above, the changes are as follows::
//
//      199 (N/A - no previous measurement)
//      200 (increased)
//      208 (increased)
//      210 (increased)
//      200 (decreased)
//      207 (increased)
//      240 (increased)
//      269 (increased)
//      260 (decreased)
//      263 (increased)
//
// In this example, there are 7 measurements that are larger than the
// previous measurement.
//
// How many measurements are larger than the previous measurement?
//
// Your puzzle answer was 1477.
//
// --- Part Two ---
//
// Considering every single measurement isn't as useful as you expected:
// there's just too much noise in the data.
//
// Instead, consider sums of a three-measurement sliding window. Again
// considering the above example::
//
//      199  A
//      200  A B
//      208  A B C
//      210    B C D
//      200  E   C D
//      207  E F   D
//      240  E F G
//      269    F G H
//      260      G H
//      263        H
//
// Start by comparing the first and second three-measurement windows. The
// measurements in the first window are marked A (199, 200, 208); their sum
// is 199 + 200 + 208 = 607. The second window is marked B (200, 208, 210); its
// sum is 618. The sum of measurements in the second window is larger than the
// sum of the first, so this first comparison increased.
//
// Your goal now is to count the number of times the sum of measurements in
// this sliding window increases from the previous sum. So, compare A with B,
// then compare B with C, then C with D, and so on. Stop when there aren't
// enough measurements left to create a new three-measurement sum.
//
// In the above example, the sum of each three-measurement window is as
// follows:
//
// A: 607 (N/A - no previous sum)
// B: 618 (increased)
// C: 618 (no change)
// D: 617 (decreased)
// E: 647 (increased)
// F: 716 (increased)
// G: 769 (increased)
// H: 792 (increased)
//
// In this example, there are 5 sums that are larger than the previous sum.
//
// Consider sums of a three-measurement sliding window. How many sums are
// larger than the previous sum?
//
// Your puzzle answer was 1523.

const std = @import("std");
const fs = std.fs;

// {{{ helpers

fn read_from_file(allocator: *std.mem.Allocator, filename: []const u8, nlines: u32) ![]u32 {
    var file = try fs.cwd().openFile(filename, .{ .read = true });
    defer file.close();

    var reader = std.io.bufferedReader(file.reader());
    var in_stream = reader.reader();

    var measurements = try allocator.alloc(u32, nlines);

    var buffer: [32]u8 = undefined;
    var i: u32 = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        measurements[i] = try std.fmt.parseInt(u32, line, 10);

        i += 1;
        if (i >= nlines) {
            break;
        }
    }

    if (i < nlines) {
        std.debug.print("Read too few lines?", .{});
    }
    return measurements;
}

// }}}

// {{{ part one

fn count_measurement_increases(measurements: []u32) u32 {
    var counter: u32 = 0;
    var i: u32 = 0;

    while (i < measurements.len - 1) {
        counter += @boolToInt(measurements[i] < measurements[i + 1]);
        i += 1;
    }

    return counter;
}

// }}}

// {{{ part two

fn count_measurement_windowed_increases(measurements: []u32, window: u32) u32 {
    var counter: u32 = 0;
    var i: u32 = 0;
    var previous_window: u32 = 0;
    var current_window: u32 = 0;

    // get first window
    while (i < window) {
        previous_window += measurements[i];
        i += 1;
    }

    // go through the array and update the previous / current windows and check
    while (i < measurements.len) {
        current_window = (previous_window - measurements[i - window]) + measurements[i];
        counter += @boolToInt(previous_window < current_window);

        previous_window = current_window;
        i += 1;
    }

    return counter;
}

// }}}

pub fn main() void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var measurements = read_from_file(&gpa.allocator, "input.txt", 2000) catch {
        std.debug.print("Couldn't read file.", .{});
        return;
    };
    defer gpa.allocator.free(measurements);

    std.debug.print("Your puzzle answer was {d}.\n",
        .{count_measurement_increases(measurements)});
    std.debug.print("Your puzzle answer was {d}.\n",
        .{count_measurement_windowed_increases(measurements, 3)});
}
