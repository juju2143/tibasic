%{
#include <cstdio>
#include <cstring>
#include <iostream>
#include <string>
#include <map>
#include <unistd.h>
#include <sys/wait.h>
using namespace std;

extern "C" int yylex();
extern "C" int yyparse();
extern "C" FILE* yyin;
extern int linenum;
extern int charnum;
void yyerror(const char *s);
void execute(char* file);
char* filename;
char* program;

struct cmp_str
{
	bool operator()(char const *a, char const *b)
	{
		return strcmp(a, b) < 0;
	}
};

float ans;
map<char*, float, cmp_str> vars;
map<char*, char*, cmp_str> svars;
%}

%union {
	float nval;
	char* sval;
	char* nvar;
	char* svar;
	char* file;
}

%token DISP
%token INPUT
%token ANS
%token ENDL
%token SEP
%token ASSIGN

%token <nval> NUMBER;
%token <sval> STRING;
%token <nvar> NVAR;
%token <svar> SVAR;
%token <file> INCL;

%type <nval> expr;
%type <sval> sexpr;

%left ASSIGN
%left '+' '-'
%left '*' '/'
%right UMINUS

%start tibasic
%%

tibasic:
	lines
	;
lines:
	lines line
	| line
	;
ENDLS:
	ENDLS ENDL
	| ENDL
	;
expr:
	NUMBER { $$ = $1; }
	| ANS { $$ = ans; }
	| NVAR { $$ = vars[$1]; }
	| expr '*' expr { $$ = $1 * $3; }
	| expr '/' expr { $$ = $1 / $3; }
	| expr '+' expr { $$ = $1 + $3; }
	| expr '-' expr { $$ = $1 - $3; }
	| '-' expr %prec UMINUS { $$ = 0 - $2; }
	| '(' expr ')' { $$ = $2; }
	| expr ASSIGN NVAR { $$ = $1; vars[$3] = $1; }
	;
sexpr:
	STRING { $$ = $1; }
	| SVAR { $$ = svars[$1]; }
//	| sexpr '+' sexpr { $$ = $1 + $3; }
	| sexpr ASSIGN SVAR { $$ = $1; svars[$3] = $1; }
	;
disp_line:
	DISP expr ENDLS { cout << $2 << endl; }
	| DISP sexpr ENDLS { cout << $2 << endl; }
	;
input_line:
	INPUT sexpr ',' SVAR ENDLS { cout << $2; cin >> svars[$4]; }
	| INPUT sexpr ',' NVAR ENDLS { cout << $2; cin >> vars[$4]; }
	| INPUT SVAR ENDLS { cout << "?"; cin >> svars[$2]; }
	| INPUT NVAR ENDLS { cout << "?"; cin >> vars[$2]; }
	;
line:
	disp_line
	| input_line
	| INCL ENDLS { execute($1); }
	| expr ENDLS { ans = $1; }
	| sexpr ENDLS
	;
%%
/*
exprs:
	exprs ',' expr { $$ = $1 << $3; }
	exprs ',' sexpr { $$ = $1 << $3; }
	| expr { $$=$1; }
	| sexpr { $$=$1; }
	;
*/
main(int argc, char** argv) {
	FILE* input;
	program = argv[0];
	if(argc > 1)
	{
		filename = argv[1];
		input = fopen(filename, "r");
		if(!input)
		{
			strcat(filename, ".tib");
			input = fopen(filename, "r");
			if(!input)
			{
				cout << argv[0] << ": " << filename << ": Cannot open file" << endl;
				return -1;
			}
		}
	}
	else
	{
		filename = "stdin";
		input = stdin;
	}
	yyin = input;
	do
	{
		yyparse();
	} while (!feof(yyin));
}

void yyerror(const char *s) {
	cout << filename << ":" << linenum << ":" << charnum << ": " << s << endl;
	exit(-1);
}

void execute(char* file)
{
	pid_t pid = fork();
	int status;
	if(pid<0)
	{
		cout << "Error loading " << filename << endl;
		return;
	}
	if(pid != 0)
	{
		waitpid(pid, &status, 0);
	}
	else
	{
		char* args[2] = { program, file };
		execve(program, args, 0);
	}
}
