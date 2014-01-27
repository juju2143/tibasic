all: tibasic

tibasic.tab.c tibasic.tab.h: tibasic.y
	bison -d tibasic.y

lex.yy.c: tibasic.l tibasic.tab.h
	flex tibasic.l

tibasic: lex.yy.c tibasic.tab.c tibasic.tab.h
	g++ lex.yy.c tibasic.tab.c -lfl -lreadline -Wno-write-strings -o tibasic -g

clean:
	rm lex.yy.c tibasic.tab.c tibasic.tab.h tibasic
