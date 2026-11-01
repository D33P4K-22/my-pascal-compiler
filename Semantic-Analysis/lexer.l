%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "y.tab.h"

int line_num = 1;
%}

%option caseless
%option noyywrap

LETTER      [a-zA-Z]
DIGIT       [0-9]

%%

\n          { line_num++; }
[ \t\r]+    { /* Ignore whitespace */ }
"//".*      { /* Ignore single-line comments */ }

"program"   { return PROGRAM; }
"var"       { return VAR; }
"integer"   { return TYPE_INT; }
"real"      { return TYPE_REAL; }
"boolean"   { return TYPE_BOOL; }
"char"      { return TYPE_CHAR; }
"begin"     { return BEGIN_BLOCK; }
"end"       { return END_BLOCK; }
"if"        { return IF; }
"then"      { return THEN; }
"else"      { return ELSE; }
"while"     { return WHILE; }
"do"        { return DO; }
"for"       { return FOR; }
"to"        { return TO; }
"downto"    { return DOWNTO; }
"array"     { return ARRAY; }
"of"        { return OF; }
"and"       { return AND; }
"or"        { return OR; }
"not"       { return NOT; }
"read"      { return READ; }
"write"     { return WRITE; }
"true"      { return TRUE_CONST; }
"false"     { return FALSE_CONST; }

{LETTER}({LETTER}|{DIGIT}|_)* { yylval.str = strdup(yytext); return IDENTIFIER; }
{DIGIT}+\.{DIGIT}+            { yylval.fval = atof(yytext); return REAL_CONST; }
{DIGIT}+                      { yylval.ival = atoi(yytext); return INT_CONST; }
\"[^\"\n]*\"                  { yylval.str = strdup(yytext); return STRING_LITERAL; }

":="        { return ASSIGN; }
".."        { return RANGE; }
"<>"        { return NEQ; }
"<="        { return LEQ; }
">="        { return GEQ; }
"<"         { return LT; }
">"         { return GT; }
"="         { return EQ; }
"+"         { return PLUS; }
"-"         { return MINUS; }
"*"         { return MULT; }
"/"         { return DIV; }
"%"         { return MOD; }

";"         { return SEMICOLON; }
":"         { return COLON; }
","         { return COMMA; }
"."         { return PERIOD; }
"("         { return LPAREN; }
")"         { return RPAREN; }
"["         { return LBRACKET; }
"]"         { return RBRACKET; }

.           { /* Ignore unrecognized characters */ }

%%
