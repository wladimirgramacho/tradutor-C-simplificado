all: analise

analise: bison flex comp

bison:
	bison -d wladus.y

flex:
	flex -o lex.yy.c wladus.l

comp:
	gcc wladus.tab.c lex.yy.c -o prog

test:
	./prog < ../examples/valid0.w
# 	./prog < ../examples/valid1.w
	./prog < ../examples/valid2.w
	./prog < ../examples/invalid1.w
	./prog < ../examples/invalid2.w
	./prog < ../examples/invalid3.w
	./prog < ../examples/invalid4.w
	./prog < ../examples/invalid5.w
