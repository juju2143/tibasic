all: tibasic

tibasic.tab.c tibasic.tab.h: tibasic.y
	bison -d tibasic.y

lex.yy.c: tibasic.l tibasic.tab.h
	flex tibasic.l

tibasic: lex.yy.c tibasic.tab.c tibasic.tab.h
	g++ tibasic.tab.c lex.yy.c -Wno-write-strings -o tibasic

clean:
	rm lex.yy.c tibasic.tab.c tibasic.tab.h tibasic
