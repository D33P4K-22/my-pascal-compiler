%{
#include <stdio.h>
#include <stdlib.h>

extern int yylex();
extern int line_num;
extern FILE *yyin;
void yyerror(const char *s);
%}

%token PROGRAM VAR INTEGER REAL BOOLEAN CHAR BEGIN_KEY END_KEY
%token IF THEN ELSE WHILE DO FOR TO DOWNTO ARRAY OF AND OR NOT READ WRITE
%token ASSIGNOP RANGE NEQ LEQ GEQ
%token SEMICOLON COLON COMMA PERIOD LPAREN RPAREN LBRACKET RBRACKET
%token IDENTIFIER NUMBER STRING

/* Operator precedence and associativity (lowest to highest) */
%left OR
%left AND
%left '<' '>' '=' NEQ LEQ GEQ
%left '+' '-'
%left '*' '/' '%'
%right NOT

%%

program:
    PROGRAM IDENTIFIER SEMICOLON var_section block PERIOD
    ;

var_section:
    /* empty */
    | VAR decl_list
    ;

decl_list:
    decl
    | decl_list decl
    ;

decl:
    id_list COLON type SEMICOLON
    | id_list COLON ARRAY LBRACKET NUMBER RANGE NUMBER RBRACKET OF type SEMICOLON
    ;

id_list:
    IDENTIFIER
    | id_list COMMA IDENTIFIER
    ;

type:
    INTEGER | REAL | BOOLEAN | CHAR
    ;

block:
    BEGIN_KEY stmt_list END_KEY
    ;

stmt_list:
    stmt
    | stmt_list stmt
    ;

stmt:
    assign_stmt
    | read_stmt
    | write_stmt
    | cond_stmt
    | loop_stmt
    | block SEMICOLON
    ;

assign_stmt:
    variable ASSIGNOP expr SEMICOLON
    ;

variable:
    IDENTIFIER
    | IDENTIFIER LBRACKET expr RBRACKET
    ;

var_list:
    variable
    | var_list COMMA variable
    ;

read_stmt:
    READ LPAREN variable RPAREN SEMICOLON
    ;

write_stmt:
    WRITE LPAREN STRING RPAREN SEMICOLON
    | WRITE LPAREN var_list RPAREN SEMICOLON
    ;

cond_stmt:
    IF expr THEN block SEMICOLON
    | IF expr THEN block ELSE block SEMICOLON
    ;

loop_stmt:
    WHILE expr DO block SEMICOLON
    | FOR IDENTIFIER ASSIGNOP expr direction expr DO block SEMICOLON
    ;

direction:
    TO | DOWNTO
    ;

expr:
    variable
    | NUMBER
    | expr '+' expr
    | expr '-' expr
    | expr '*' expr
    | expr '/' expr
    | expr '%' expr
    | expr '<' expr
    | expr '>' expr
    | expr '=' expr
    | expr NEQ expr
    | expr LEQ expr
    | expr GEQ expr
    | expr AND expr
    | expr OR expr
    | NOT expr
    | LPAREN expr RPAREN
    ;

%%

void yyerror(const char *s) {
    (void)s;
    printf("syntax error\n");
    exit(0);
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <input_file>\n", argv[0]);
        return 1;
    }
    yyin = fopen(argv[1], "r");
    if (yyin == NULL) {
        fprintf(stderr, "Error: cannot open file '%s'\n", argv[1]);
        return 1;
    }

    yyparse();
    printf("valid input\n");
    fclose(yyin);
    return 0;
}