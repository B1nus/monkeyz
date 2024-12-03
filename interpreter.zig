const tokenizer = @import("tokenizer.zig");
const std = @import("std");
const stdout = std.io.getStdOut().writer();
const ally = std.heap.page_allocator;

pub fn main() !void {
    if (std.os.argv.len == 2) {
        // TODO: Interpret File
        unreachable;
    } else if (std.os.argv.len == 1) {
        // Interactive terminal
        const stdin = std.io.getStdIn().reader();
        try stdout.print("Welcome to the Monkey Programming language! Feel free to start typing.\n\n", .{});

        while (true) {
            try stdout.print(">> ", .{});

            var buffer = std.ArrayList(u8).init(ally);
            while (!(buffer.items.len >= 2 and buffer.items[buffer.items.len - 1] == '\n' and buffer.items[buffer.items.len - 2] == '\n')) {
                try buffer.append(try stdin.readByte());
            }
            var lexer = tokenizer.Lexer.init(@ptrCast(buffer.items));
            var token = lexer.next();

            while (token.tag != tokenizer.Token.Tag.eof) : (token = lexer.next()) {
                try stdout.print("{any}\n", .{token});
            }
        }
    }
}
