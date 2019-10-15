all: analise

analise: bison flex comp

bison:
	bison -d c_simplificado.y

flex:
	flex -o lex.yy.c novo_c_simplificado.l

comp:
	gcc c_simplificado.tab.c lex.yy.c -o prog

test:
	./prog ../examples/valid0.code
#	./prog ../examples/valid1.code
# 	./prog examples/valid2.code
# 	./prog examples/invalid1.code
# 	./prog examples/invalid2.code
