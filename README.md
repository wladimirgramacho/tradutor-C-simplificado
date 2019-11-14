# wladus-lang
Programming Language (mini-C) implemented during Compilers couse at the University of Brasília.

### Usage
First of all, change to the `src/` directory:
```
cd src/
```

To compile the lexer and parser, run:
```
make all
```

To run with examples (valid and invalid `.w` files)

```
make test
```

### Output
The output of the program will be the errors of the program, if found. If you pass the option `-tt` when running the example, the symbol tree and the annotated syntax tree will be printed. The examples on the makefile have this option set by default.
