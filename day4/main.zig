// --- Day 4: Giant Squid ---
//
// --- Part One ---
//
// You're already almost 1.5km (almost a mile) below the surface of the ocean,
// already so deep that you can't see any sunlight. What you can see, however,
// is a giant squid that has attached itself to the outside of your submarine.
//
// Maybe it wants to play bingo?
//
// Bingo is played on a set of boards each consisting of a 5x5 grid of numbers.
// Numbers are chosen at random, and the chosen number is marked on all boards
// on which it appears. (Numbers may not appear on all boards.) If all numbers
// in any row or any column of a board are marked, that board wins. (Diagonals
// don't count.)
//
// The submarine has a bingo subsystem to help passengers (currently, you and
// the giant squid) pass the time. It automatically generates a random order
// in which to draw numbers and a random set of boards (your puzzle input).
// For example:
//
//      7,4,9,5,11,17,23,2,0,14,21,24,10,16,13,6,15,25,12,22,18,20,8,19,3,26,1
//
//      22 13 17 11  0
//       8  2 23  4 24
//      21  9 14 16  7
//       6 10  3 18  5
//       1 12 20 15 19
//
//       3 15  0  2 22
//       9 18 13 17  5
//      19  8  7 25 23
//      20 11 10 24  4
//      14 21 16 12  6
//
//      14 21 17 24  4
//      10 16 15  9 19
//      18  8 23 26 20
//      22 11 13  6  5
//       2  0 12  3  7
//
// After the first five numbers are drawn (7, 4, 9, 5, and 11), there are no
// winners, but the boards are marked as follows (shown here adjacent to each
// other to save space):
//
//      22 13 17 11  0         3 15  0  2 22        14 21 17 24  4
//       8  2 23  4 24         9 18 13 17  5        10 16 15  9 19
//      21  9 14 16  7        19  8  7 25 23        18  8 23 26 20
//       6 10  3 18  5        20 11 10 24  4        22 11 13  6  5
//       1 12 20 15 19        14 21 16 12  6         2  0 12  3  7
//
// After the next six numbers are drawn (17, 23, 2, 0, 14, and 21), there are
// still no winners:
//
//      22 13 17 11  0         3 15  0  2 22        14 21 17 24  4
//       8  2 23  4 24         9 18 13 17  5        10 16 15  9 19
//      21  9 14 16  7        19  8  7 25 23        18  8 23 26 20
//       6 10  3 18  5        20 11 10 24  4        22 11 13  6  5
//       1 12 20 15 19        14 21 16 12  6         2  0 12  3  7
//
// Finally, 24 is drawn:
//
//      22 13 17 11  0         3 15  0  2 22        14 21 17 24  4
//       8  2 23  4 24         9 18 13 17  5        10 16 15  9 19
//      21  9 14 16  7        19  8  7 25 23        18  8 23 26 20
//       6 10  3 18  5        20 11 10 24  4        22 11 13  6  5
//       1 12 20 15 19        14 21 16 12  6         2  0 12  3  7
//
// At this point, the third board wins because it has at least one complete
// row or column of marked numbers (in this case, the entire top row is marked:
// 14 21 17 24 4).
//
// The score of the winning board can now be calculated. Start by finding the
// sum of all unmarked numbers on that board; in this case, the sum is 188.
// Then, multiply that sum by the number that was just called when the board
// won, 24, to get the final score, 188 * 24 = 4512.
//
// To guarantee victory against the giant squid, figure out which board will
// win first. What will your final score be if you choose that board?
//
// Your puzzle answer was 25410.
//
// --- Part Two ---
//
// On the other hand, it might be wise to try a different strategy: let the
// giant squid win.
//
// You aren't sure how many bingo boards a giant squid could play at once, so
// rather than waste time counting its arms, the safe thing to do is to figure
// out which board will win last and choose that one. That way, no matter which
// boards it picks, it will win for sure.
//
// In the above example, the second board is the last to win, which happens
// after 13 is eventually called and its middle column is completely marked.
// If you were to keep playing until this point, the second board would have
// a sum of unmarked numbers equal to 148 for a final score of 148 * 13 = 1924.
//
// Figure out which board will win last. Once it wins, what would its final
// score be?
//
// Your puzzle answer was ???.

const std = @import("std");
const fs = std.fs;

const Answer = struct {
    unmarked_sum: u32 = 0,
    win_number: u32 = 0,
};

const Board = struct {
    entries: [25]u8,
    // bit i in `mask` is set if the corresponding entry was drawn
    mask: u25 = 0,
};

fn board_is_winning(mask: u25) bool {
    const patterns = [_]u25 {
        // columns
        0b1000010000100001000010000,
        0b0100001000010000100001000,
        0b0010000100001000010000100,
        0b0001000010000100001000010,
        0b0000100001000010000100001,
        // rows
        0b1111100000000000000000000,
        0b0000011111000000000000000,
        0b0000000000111110000000000,
        0b0000000000000001111100000,
        0b0000000000000000000011111,
    };

    for (patterns) |pattern| {
        if (mask & pattern == pattern) {
            return true;
        }
    }
    return false;
}

fn board_score(board: Board) u32 {
    // sum up all the entries that have not been drawn in the board
    var score: u32 = 0;

    for (board.entries) |entry, i| {
       var mask = @as(u25, 1) << @intCast(u5, i);
       if (mask & board.mask == 0) {
           score += entry;
       }
    }

    return score;
}

fn get_answer_from_file(
        allocator: std.mem.Allocator, filename: []const u8,
        ndraws: u32, nboards: u32,
        prefer_last_board: bool) !Answer {
    var file = try fs.cwd().openFile(filename, .{ .read = true });
    defer file.close();

    var reader = std.io.bufferedReader(file.reader());
    var in_stream = reader.reader();
    var buffer: [512]u8 = undefined;

    // {{{ get draws

    var draws = try allocator.alloc(u32, ndraws);
    defer allocator.free(draws);

    // NOTE: first line always contains a comma-separated list of draws
    if (try in_stream.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        var i: u32 = 0;
        var it = std.mem.tokenize(u8, line, ",");

        while (it.next()) |item| {
            draws[i] = try std.fmt.parseInt(u32, item, 10);
            i += 1;
        }

        std.debug.assert(i == ndraws);
    } else {
        unreachable;
    }

    // }}}

    // {{{ get boards

    if (nboards == 0) {
        return Answer{};
    }

    var boards = try allocator.alloc(Board, nboards);
    defer allocator.free(boards);

    {
        var i: u32 = 0;
        var j: u32 = 0;

        while (try in_stream.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
            if (line.len == 0) {
                // pass to the next board
                std.debug.assert(i == 0 or j == 25);

                i += 1;
                j = 0;
                boards[i - 1].mask = 0;
            } else {
                // read line into current board
                var it = std.mem.tokenize(u8, line, " ");
                while (it.next()) |item| {
                    boards[i - 1].entries[j] = try std.fmt.parseInt(u8, item, 10);
                    j += 1;
                }
            }
        }

        std.debug.assert(i == nboards);
    }

    // }}}

    var unmarked_sum: u32 = 0;
    var win_number: u32 = 0;

    outer: for (draws) |draw| {
        for (boards) |*board| {
            for (board.entries) |entry, i| {
                if (entry == draw) {
                    var entry_mask = @as(u25, 1) << @intCast(u5, i);
                    board.mask |= entry_mask;


                    if (board_is_winning(board.mask)) {
                        unmarked_sum = board_score(board.*);
                        win_number = draw;

                        break :outer;
                    }
                }
            }
        }

    }

    return Answer{
        .unmarked_sum = unmarked_sum,
        .win_number = win_number,
    };
}

pub fn main() void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var alloc = gpa.allocator();
    defer _ = gpa.deinit();

    var prefer_last_board = false;  // false == part 1 and true == part 2
    var example = get_answer_from_file(alloc, "example.txt", 27, 3, prefer_last_board) catch |err| {
        std.debug.print("Couldn't read file: {s}", .{@errorName(err)});
        return;
    };

    std.debug.print("sum {d} last {d}\n", .{example.unmarked_sum, example.win_number});
    std.debug.print("Your example answer was {d}.\n", .{example.unmarked_sum * example.win_number});

    var answer = get_answer_from_file(alloc, "input.txt", 100, 100, prefer_last_board) catch |err| {
        std.debug.print("Couldn't read file: {s}", .{@errorName(err)});
        return;
    };

    std.debug.print("sum {d} last {d}\n", .{answer.unmarked_sum, answer.win_number});
    std.debug.print("Your puzzle answer was {d}.\n", .{answer.unmarked_sum * answer.win_number});
}
