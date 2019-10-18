all: analise

analise: bison flex comp

bison:
	bison -d wladus.y

flex:
	flex -o lex.yy.c wladus.l

comp:
	gcc wladus.tab.c lex.yy.c -o prog

test:
	./prog -t < ../examples/valid0.code
	./prog -t < ../examples/valid1.code
	./prog -t < ../examples/valid2.code
	./prog -t < ../examples/invalid1.code
	./prog -t < ../examples/invalid2.code
	./prog -t < ../examples/invalid3.code
