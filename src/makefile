all: analise

analise: bison flex comp

bison:
	bison -d wladus.y

flex:
	flex -o lex.yy.c wladus.l

comp:
	gcc wladus.tab.c lex.yy.c -o prog

test:
	./prog -tt < ../examples/valid0.w
	./prog -tt < ../examples/valid1.w
	./prog -tt < ../examples/valid2.w
	./prog -tt < ../examples/invalid1.w
	./prog -tt < ../examples/invalid2.w
	./prog -tt < ../examples/invalid3.w
	./prog -tt < ../examples/invalid4.w
	./prog -tt < ../examples/invalid5.w
	./prog -tt < ../examples/invalid6.w
