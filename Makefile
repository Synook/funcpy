all:
	bison -d funcpy.y
	flex funcpy.l
	gcc -o funcpy funcpy.tab.c lex.yy.c genpython.c stack.c
