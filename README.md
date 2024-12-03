# monkeyz
Implementation of the monkey programming language in zig. It's roughly the same as my previous [implementation](https://github.com/B1nus/monkey) where I was following the book [Writing an interpreter in Go](https://interpreterbook.com/) but in another language to prove that I've learned how to do it myself. I learned zig through ziglings and doing an entire Advent of Code in zig. It was really helpfull!

# Usage
Compile the interpreter with `$ zig build-exe interpreter.zig` and run with `$ ./interpreter`. Without any arguments it starts an interactive shell (Also known as REPL), you can also provide a file path for it to interpret as the command line argument: `$ ./interpreter samples/map`.
