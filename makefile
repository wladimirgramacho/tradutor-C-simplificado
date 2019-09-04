flex:
	flex -o src/lex/lex.yy.c src/lex/c_simplificado.lex
	gcc -o src/lex/lexer -lfl src/lex/lex.yy.c 
	./src/lex/lexer examples/valid1.code
	./src/lex/lexer examples/valid2.code
	./src/lex/lexer examples/invalid1.code
	./src/lex/lexer examples/invalid2.code
