%{
#include <stdio.h>
#include <stdlib.h>

int line_num = 1;

void print_token(const char* lexeme, const char* token_type) {
    printf("%d\t%s\t%s\n", line_num, lexeme, token_type);
}
%}

%option caseless
%option noyywrap

LETTER      [a-zA-Z]
DIGIT       [0-9]

%%

\n          { line_num++; }
[ \t\r]+    { /* Ignore whitespace */ }
"//".*      { /* Ignore single-line comments */ }

"program"|"integer"|"real"|"boolean"|"char"|"var"|"to"|"downto"|"if"|"then"|"else"|"while"|"for"|"do"|"array"|"of"|"and"|"or"|"not"|"begin"|"end"|"read"|"write" {
    print_token(yytext, "KEYWORD");
}

{LETTER}({LETTER}|{DIGIT}|_)* {
    print_token(yytext, "IDENTIFIER");
}

{DIGIT}+ {
    print_token(yytext, "NUMBER");
}

\"[^\"\n]*\" {
    print_token(yytext, "STRING");
}

":="                       { print_token(yytext, "ASSIGNOP"); }
"+"|"-"|"*"|"/"|"%"        { print_token(yytext, "ARITHOP"); }
"="|"<>"|"<"|">"|"<="|">=" { print_token(yytext, "RELOP"); }

".."                       { print_token(yytext, "RANGE"); }
";"                        { print_token(yytext, "SEMICOLON"); }
","                        { print_token(yytext, "COMMA"); }
":"                        { print_token(yytext, "COLON"); }
"("                        { print_token(yytext, "LPAREN"); }
")"                        { print_token(yytext, "RPAREN"); }
"["                        { print_token(yytext, "LBRACKET"); }
"]"                        { print_token(yytext, "RBRACKET"); }
"."                        { print_token(yytext, "PERIOD"); }

.                          { /* Ignore unrecognized characters safely */ }

%%

int main (int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <input_file>\n", argv[0]);
        return 1;
    }
    extern FILE *yyin;
    yyin = fopen(argv[1], "r");
    if (yyin == NULL) {
        fprintf(stderr, "Error: cannot open file '%s'\n", argv[1]);
        return 1;
    }
    yylex();
    fclose(yyin);
    return 0;
}