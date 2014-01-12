%{
#include <iostream>
#include "tibasic.tab.h"
using namespace std;
#define YY_DECL extern "C" int yylex()
int linenum = 1;
int charnum = 1;
%}
%option noyywrap
%x SBLOCK
%%
[ \t]			;
([0-9]*\.?[0-9]+)	{ yylval.nval = atof(yytext); return NUMBER; }
[A-Z]			{ yylval.nvar = strdup(yytext); return NVAR; }
\"			{ BEGIN(SBLOCK); }
<SBLOCK>(\\.|[^\":\n])*	{ yylval.sval = strdup(yytext); return STRING; }
<SBLOCK>\"		{ BEGIN(INITIAL); }
<SBLOCK>[\n:]		{ BEGIN(INITIAL); ++linenum; charnum=1; return ENDL; }
<SBLOCK>"->"		{ BEGIN(INITIAL); return ASSIGN; }
Str[0-9]		{ yylval.svar = strdup(yytext); return SVAR; }
Disp			{ return DISP; }
Input			{ return INPUT; }
Ans			{ return ANS; }
"->"			{ return ASSIGN; }
[\+\-\*\/,\(\)]		{ return yytext[0]; }
[\n:]			{ ++linenum; charnum=1; return ENDL; }
.			{ ++charnum; };
%%
