%{
#include <stdio.h>
#include <stdlib.h>
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
"integer"   { return INTEGER; }
"real"      { return REAL; }
"boolean"   { return BOOLEAN; }
"char"      { return CHAR; }
"begin"     { return BEGIN_KEY; }
"end"       { return END_KEY; }
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

{LETTER}({LETTER}|{DIGIT}|_)* { return IDENTIFIER; }
{DIGIT}+                      { return NUMBER; }
\"[^\"\n]*\"                  { return STRING; }

":="        { return ASSIGNOP; }
".."        { return RANGE; }
"<>"        { return NEQ; }
"<="        { return LEQ; }
">="        { return GEQ; }
"<"         { return '<'; }
">"         { return '>'; }
"="         { return '='; }
"+"         { return '+'; }
"-"         { return '-'; }
"*"         { return '*'; }
"/"         { return '/'; }
"%"         { return '%'; }

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