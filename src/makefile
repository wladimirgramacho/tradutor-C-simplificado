all: analise

analise: bison flex comp

bison:
	bison -d wladus.y

flex:
	flex -o lex.yy.c wladus.l

comp:
	gcc wladus.tab.c lex.yy.c -o prog

test:
	./prog -tt < ../examples/valid0.code
	./prog -tt < ../examples/valid1.code
	./prog -tt < ../examples/valid2.code
# 	./prog -tt < ../examples/invalid1.code
# 	./prog -tt < ../examples/invalid2.code
# 	./prog -tt < ../examples/invalid3.code
