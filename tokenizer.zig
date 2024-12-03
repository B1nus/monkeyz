const std = @import("std");

pub const Token = struct {
    start: u32,
    end: u32, // Inclusive
    tag: Tag,

    pub const Tag = enum {
        @"if",
        @"and",
        @"or",
        true,
        false,
        @"else",
        @"return",
        function,
        let,
        identifier,
        lparen,
        rparen,
        lbracket,
        rbracket,
        comma,
        lbrace,
        rbrace,
        asterisk,
        slash,
        minus,
        plus,
        equal,
        double_equal,
        less,
        more,
        less_equal,
        more_equal,
        integer,
        semicolon,
        invalid,
        eof,
    };

    pub const keywords = std.StaticStringMap(Tag).initComptime(.{
        .{ "if", .@"if" },
        .{ "and", .@"and" },
        .{ "or", .@"or" },
        .{ "true", .true },
        .{ "false", .false },
        .{ "else", .@"else" },
        .{ "return", .@"return" },
        .{ "fn", .function },
        .{ "let", .let },
    });
};

pub const Lexer = struct {
    buffer: [:0]const u8,
    index: u32,

    pub fn init(buffer: [:0]const u8) Lexer {
        return .{
            .buffer = buffer,
            .index = if (std.mem.startsWith(u8, buffer, "\xEF\xBB\xBF")) 3 else 0, // A whacky check I need to do.
        };
    }

    const State = enum {
        start,
        equal,
        invalid,
        integer,
        identifier,
    };

    pub fn next(self: *Lexer) Token {
        var token: Token = .{ .start = self.index, .end = undefined, .tag = undefined };
        state: switch (State.start) {
            .start => {
                // End of file
                if (self.index >= self.buffer.len) {
                    token.end = token.start;
                    token.tag = .eof;
                    return token;
                }

                switch (self.buffer[self.index]) {
                    '+' => token.tag = .plus,
                    '-' => token.tag = .minus,
                    '*' => token.tag = .asterisk,
                    '/' => token.tag = .slash,
                    '(' => token.tag = .lparen,
                    ')' => token.tag = .rparen,
                    '[' => token.tag = .lbracket,
                    ']' => token.tag = .rbracket,
                    '{' => token.tag = .lbrace,
                    '}' => token.tag = .rbrace,
                    ',' => token.tag = .comma,
                    ';' => token.tag = .semicolon,
                    '=' => continue :state .equal,
                    '\n', '\t', '\r', ' ' => {
                        self.index += 1;
                        token.start = self.index;
                        continue :state .start;
                    },
                    'a'...'z', 'A'...'Z' => {
                        continue :state .identifier;
                    },
                    '0'...'9' => {
                        continue :state .integer;
                    },
                    else => continue :state .invalid,
                }
                self.index += 1;
            },
            .equal => {
                self.index += 1;
                if (self.buffer[self.index] == '=') {
                    self.index += 1;
                    token.tag = .double_equal;
                } else {
                    token.tag = .equal;
                }
            },
            .identifier => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    'a'...'z', 'A'...'Z', '0'...'9', '_' => {
                        continue :state .identifier;
                    },
                    else => {
                        if (Token.keywords.get(self.buffer[token.start..self.index])) |keyword| {
                            token.tag = keyword;
                        } else {
                            token.tag = .identifier;
                        }
                    },
                }
            },
            .integer => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    '0'...'9', '_' => {
                        continue :state .integer;
                    },
                    else => token.tag = .integer,
                }
            },
            .invalid => {
                self.index += 1;
                const c = self.buffer[self.index];
                if ((c == 0 and self.index == self.buffer.len) or c == '\n') {
                    token.tag = .invalid;
                } else {
                    continue :state .invalid;
                }
            },
        }
        token.end = self.index - 1; // Inclusive
        return token;
    }
};

const assert = std.debug.assert;
test "single character tokens" {
    var lexer = Lexer.init("+-*/  () }{ [ ] , ; =    ==");
    assert(lexer.next().tag == .plus);
    assert(lexer.next().tag == .minus);
    assert(lexer.next().tag == .asterisk);
    assert(lexer.next().tag == .slash);
    assert(lexer.next().tag == .lparen);
    assert(lexer.next().tag == .rparen);
    assert(lexer.next().tag == .rbrace);
    assert(lexer.next().tag == .lbrace);
    assert(lexer.next().tag == .lbracket);
    assert(lexer.next().tag == .rbracket);
    assert(lexer.next().tag == .comma);
    assert(lexer.next().tag == .semicolon);
    assert(lexer.next().tag == .equal);
    assert(lexer.next().tag == .double_equal);
    assert(lexer.next().tag == .eof);
}

test "function" {
    var lexer = Lexer.init("let add = fn(x,y) { return x + y; };");
    assert(lexer.next().tag == .let);
    assert(lexer.next().tag == .identifier);
    assert(lexer.next().tag == .equal);
    assert(lexer.next().tag == .function);
    assert(lexer.next().tag == .lparen);
    assert(lexer.next().tag == .identifier);
    assert(lexer.next().tag == .comma);
    assert(lexer.next().tag == .identifier);
    assert(lexer.next().tag == .rparen);
    assert(lexer.next().tag == .lbrace);
    assert(lexer.next().tag == .@"return");
    assert(lexer.next().tag == .identifier);
    assert(lexer.next().tag == .plus);
    assert(lexer.next().tag == .identifier);
    assert(lexer.next().tag == .semicolon);
    assert(lexer.next().tag == .rbrace);
    assert(lexer.next().tag == .semicolon);
}

test "if" {
    var lexer = Lexer.init("let x = if (x == 5 and skibidi_gyatt) {true} else {false};");
    assert(lexer.next().tag == .let);
    assert(lexer.next().tag == .identifier);
    assert(lexer.next().tag == .equal);
    assert(lexer.next().tag == .@"if");
    assert(lexer.next().tag == .lparen);
    const x = lexer.next();
    assert(x.tag == .identifier);
    assert(x.start == 12);
    assert(x.end == 12);
    assert(lexer.next().tag == .double_equal);
    assert(lexer.next().tag == .integer);
    assert(lexer.next().tag == .@"and");
    const z = lexer.next();
    assert(z.tag == .identifier);
    assert(z.start == 23);
    assert(z.end == 35);
    assert(lexer.next().tag == .rparen);
    assert(lexer.next().tag == .lbrace);
    assert(lexer.next().tag == .true);
    assert(lexer.next().tag == .rbrace);
    assert(lexer.next().tag == .@"else");
    assert(lexer.next().tag == .lbrace);
    assert(lexer.next().tag == .false);
    assert(lexer.next().tag == .rbrace);
    assert(lexer.next().tag == .semicolon);
}
