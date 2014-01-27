%{
#include <cstdio>
#include <cstring>
#include <iostream>
#include <string>
#include <map>
#include <unistd.h>
#include <sys/wait.h>
#include <getopt.h>
#include <readline/readline.h>
#include <readline/history.h>
using namespace std;

typedef struct yy_buffer_state *YY_BUFFER_STATE;
extern "C" int yylex();
extern "C" int yyparse();
extern YY_BUFFER_STATE yy_scan_string(const char*);
extern YY_BUFFER_STATE yy_scan_bytes(const char*, size_t);
extern void yy_delete_buffer(YY_BUFFER_STATE);
extern "C" FILE* yyin;
extern int linenum;
extern int charnum;
void yyerror(const char *s);
void execute(char* file);
char* filename;
char* program;
int interactive = 0;
int returned_ans = 0;

struct cmp_str
{
	bool operator()(char const *a, char const *b)
	{
		return strcmp(a, b) < 0;
	}
};

float ans;
char* sans;
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
	| expr ENDLS { ans = $1; returned_ans = 1; }
	| sexpr ENDLS { sans = $1; returned_ans = 2; }
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
void print_usage()
{
	cout << "Usage: " << program << " [options] [filename]" << endl;
	cout << "Interprets TI-BASIC file filename. If not given, interprets stdin." << endl;
	cout << "  -i, --interactive	Runs as interactive shell" << endl;
	cout << "  -h, --help		Shows help" << endl;
	cout << endl;
}
int main(int argc, char** argv) {
	FILE* input;
	program = argv[0];
	int c;
	static struct option long_options[] = {
		{"help",	no_argument,	0,	'h'},
		{"interactive",	no_argument,	0,	'i'},
	};
	int long_index = 0;
	while((c = getopt_long(argc, argv, "hi", long_options, &long_index))!= -1)
	{
		switch(c)
		{
			case 'h': print_usage();
				exit(EXIT_SUCCESS);
				break;
			case 'i': interactive = 1;
				break;
		}
	}
	if(optind < argc)
	{
		filename = argv[optind];
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
		filename = "-";
		input = stdin;
	}
	if(interactive != 1 || filename != "-")
	{
		yyin = input;
		do
		{
			yyparse();
		} while (!feof(yyin));
	}
	if(interactive)
	{
		yyin = NULL;
		rl_bind_key ('\t', rl_insert);
		char* line_read = (char*)NULL;
		do
		{
			if(line_read)
			{
				free(line_read);
				line_read = (char*)NULL;
			}

			line_read = readline("");
			
			if(!line_read) break;

			if(line_read && *line_read)
			{
				add_history(line_read);
				strcat(line_read, "\n\0\0");
				yy_scan_bytes(line_read, strlen(line_read)+2);
				yyparse();
				if(returned_ans == 1)
					cout << ans << endl;
				if(returned_ans == 2)
					cout << sans << endl;
				returned_ans = 0;
			}
		} while (1);
	}
}

void yyerror(const char *s) {
	cout << filename << ":" << linenum << ":" << charnum << ": " << s << endl;
	if(interactive != 1) exit(-1);
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
