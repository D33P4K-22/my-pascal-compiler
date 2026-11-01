%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <stdarg.h>

extern int yylex();
extern FILE *yyin;
void yyerror(const char *s);

/* --- Symbol Table & Memory --- */
#define MAX_SYMBOLS 100
#define MAX_ARRAY_SIZE 100

typedef enum { TYPE_INT_VAL, TYPE_REAL_VAL, TYPE_BOOL_VAL, TYPE_CHAR_VAL } VarType;

struct Symbol {
    char name[50];
    VarType type;
    int is_array;
    int low_bound;
    int high_bound;
    double val;
    double arr_vals[MAX_ARRAY_SIZE];
} symtab[MAX_SYMBOLS];

int sym_count = 0;
char temp_vars[50][50];
int temp_var_count = 0;

int find_symbol(const char *name) {
    for (int i = 0; i < sym_count; i++) {
        if (strcasecmp(symtab[i].name, name) == 0) return i;
    }
    return -1;
}

void add_symbol(const char *name, VarType type) {
    if (find_symbol(name) != -1) return;
    strcpy(symtab[sym_count].name, name);
    symtab[sym_count].type = type;
    symtab[sym_count].is_array = 0;
    symtab[sym_count].val = 0;
    sym_count++;
}

void add_array_symbol(const char *name, int low, int high, VarType elem_type) {
    if (find_symbol(name) != -1) return;
    strcpy(symtab[sym_count].name, name);
    symtab[sym_count].type = elem_type;
    symtab[sym_count].is_array = 1;
    symtab[sym_count].low_bound = low;
    symtab[sym_count].high_bound = high;
    for (int i = 0; i < MAX_ARRAY_SIZE; i++) symtab[sym_count].arr_vals[i] = 0;
    sym_count++;
}

void print_symbol_table() {
    printf("\nVariable\t|\tType\t\t|\tValue\n");
    for (int i = 0; i < sym_count; i++) {
        if (symtab[i].is_array) {
            char type_str[50];
            char *elem_str = "integer";
            if (symtab[i].type == TYPE_REAL_VAL) elem_str = "real";
            else if (symtab[i].type == TYPE_BOOL_VAL) elem_str = "boolean";
            else if (symtab[i].type == TYPE_CHAR_VAL) elem_str = "char";

            sprintf(type_str, "%s [%d..%d]", elem_str, symtab[i].low_bound, symtab[i].high_bound);
            printf("%s\t\t|\t%s\t|\t{", symtab[i].name, type_str);
            int size = symtab[i].high_bound - symtab[i].low_bound + 1;
            for (int j = 0; j < size; j++) {
                printf("%g%s", symtab[i].arr_vals[j], (j == size - 1) ? "" : ",");
            }
            printf("}\n");
        } else {
            char *type_str = "integer";
            if (symtab[i].type == TYPE_REAL_VAL) type_str = "real";
            else if (symtab[i].type == TYPE_BOOL_VAL) type_str = "boolean";
            else if (symtab[i].type == TYPE_CHAR_VAL) type_str = "char";

            printf("%s\t\t|\t%s\t\t|\t", symtab[i].name, type_str);
            if (symtab[i].type == TYPE_BOOL_VAL) {
                printf("%s\n", (symtab[i].val != 0) ? "true" : "false");
            } else if (symtab[i].type == TYPE_REAL_VAL) {
                printf("%g\n", symtab[i].val);
            } else {
                printf("%d\n", (int)symtab[i].val);
            }
        }
    }
}

/* --- AST Struct definitions --- */
typedef enum { typeCon, typeId, typeOpr, typeStr } NodeType;

typedef struct nodeTypeTag {
    NodeType type;
    int is_boolean_expr;
    union {
        double conValue;     
        char *idName;     
        char *strValue;
        struct {
            int oper;                   
            int nops;                   
            struct nodeTypeTag **op;  
        } opr;
    };
} Node;

Node *opr(int oper, int nops, ...);
Node *id(char *name);
Node *con(double value);
Node *strNode(char *s);
double execute(Node *p);

%}

%union {
    int ival;
    float fval;
    char* str;
    struct nodeTypeTag *nPtr;
}

%token PROGRAM VAR BEGIN_BLOCK END_BLOCK READ WRITE IF THEN ELSE WHILE DO FOR TO DOWNTO ARRAY OF
%token TYPE_INT TYPE_REAL TYPE_BOOL TYPE_CHAR
%token COLON SEMICOLON COMMA PERIOD LPAREN RPAREN LBRACKET RBRACKET RANGE
%token ASSIGN EQ NEQ LT GT LEQ GEQ PLUS MINUS MULT DIV MOD AND OR NOT
%token TRUE_CONST FALSE_CONST

%token <str> IDENTIFIER STRING_LITERAL
%token <ival> INT_CONST
%token <fval> REAL_CONST

%type <ival> type
%type <nPtr> expr statement statement_list

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE
%left OR
%left AND
%left LT GT EQ NEQ LEQ GEQ
%left PLUS MINUS
%left MULT DIV MOD
%right NOT

%%

program:
    program_header var_sections BEGIN_BLOCK statement_list END_BLOCK PERIOD {
        execute($4);
        print_symbol_table();
    }
    ;

program_header:
    /* empty */
    | PROGRAM IDENTIFIER SEMICOLON
    ;

var_sections:
    /* empty */
    | var_list_sections
    ;

var_list_sections:
    VAR decl_list
    | var_list_sections VAR decl_list
    ;

decl_list:
    decl_line
    | decl_list decl_line
    ;

decl_line:
    var_list COLON type SEMICOLON {
        for (int i = 0; i < temp_var_count; i++) add_symbol(temp_vars[i], (VarType)($3 - 1));
        temp_var_count = 0;
    }
    | var_list COLON ARRAY LBRACKET INT_CONST RANGE INT_CONST RBRACKET OF type SEMICOLON {
        for (int i = 0; i < temp_var_count; i++) add_array_symbol(temp_vars[i], $5, $7, (VarType)($10 - 1));
        temp_var_count = 0;
    }
    ;

var_list:
    IDENTIFIER { strcpy(temp_vars[temp_var_count++], $1); }
    | var_list COMMA IDENTIFIER { strcpy(temp_vars[temp_var_count++], $3); }
    ;

type:
    TYPE_INT    { $$ = 1; }
    | TYPE_REAL { $$ = 2; }
    | TYPE_BOOL { $$ = 3; }
    | TYPE_CHAR { $$ = 4; }
    ;

statement_list:
    statement { $$ = $1; }
    | statement_list SEMICOLON statement { $$ = opr(';', 2, $1, $3); }
    | statement_list SEMICOLON { $$ = $1; }
    ;

statement:
    /* empty */ { $$ = NULL; }
    | IDENTIFIER ASSIGN expr { $$ = opr(ASSIGN, 2, id($1), $3); }
    | IDENTIFIER LBRACKET expr RBRACKET ASSIGN expr { $$ = opr(ASSIGN, 2, opr(ARRAY, 2, id($1), $3), $6); }
    | READ LPAREN expr RPAREN { $$ = opr(READ, 1, $3); }
    | WRITE LPAREN expr RPAREN { $$ = opr(WRITE, 1, $3); }
    | IF expr THEN statement %prec LOWER_THAN_ELSE { $$ = opr(IF, 2, $2, $4); }
    | IF expr THEN statement ELSE statement { $$ = opr(IF, 3, $2, $4, $6); }
    | WHILE expr DO statement { $$ = opr(WHILE, 2, $2, $4); }
    | FOR IDENTIFIER ASSIGN expr TO expr DO statement { $$ = opr(FOR, 4, id($2), $4, $6, $8); }
    | FOR IDENTIFIER ASSIGN expr DOWNTO expr DO statement { $$ = opr(DOWNTO, 4, id($2), $4, $6, $8); }
    | BEGIN_BLOCK statement_list END_BLOCK { $$ = $2; }
    ;

expr:
    expr PLUS expr { $$ = opr(PLUS, 2, $1, $3); }
    | expr MINUS expr { $$ = opr(MINUS, 2, $1, $3); }
    | expr MULT expr { $$ = opr(MULT, 2, $1, $3); }
    | expr DIV expr { $$ = opr(DIV, 2, $1, $3); }
    | expr MOD expr { $$ = opr(MOD, 2, $1, $3); }
    | expr EQ expr { $$ = opr(EQ, 2, $1, $3); $$->is_boolean_expr = 1; }
    | expr NEQ expr { $$ = opr(NEQ, 2, $1, $3); $$->is_boolean_expr = 1; }
    | expr LT expr { $$ = opr(LT, 2, $1, $3); $$->is_boolean_expr = 1; }
    | expr GT expr { $$ = opr(GT, 2, $1, $3); $$->is_boolean_expr = 1; }
    | expr LEQ expr { $$ = opr(LEQ, 2, $1, $3); $$->is_boolean_expr = 1; }
    | expr GEQ expr { $$ = opr(GEQ, 2, $1, $3); $$->is_boolean_expr = 1; }
    | expr AND expr { $$ = opr(AND, 2, $1, $3); $$->is_boolean_expr = 1; }
    | expr OR expr { $$ = opr(OR, 2, $1, $3); $$->is_boolean_expr = 1; }
    | NOT expr { $$ = opr(NOT, 1, $2); $$->is_boolean_expr = 1; }
    | LPAREN expr RPAREN { $$ = $2; }
    | INT_CONST { $$ = con($1); }
    | REAL_CONST { $$ = con($1); }
    | TRUE_CONST { $$ = con(1); $$->is_boolean_expr = 1; }
    | FALSE_CONST { $$ = con(0); $$->is_boolean_expr = 1; }
    | STRING_LITERAL { $$ = strNode($1); }
    | IDENTIFIER { $$ = id($1); }
    | IDENTIFIER LBRACKET expr RBRACKET { $$ = opr(ARRAY, 2, id($1), $3); }
    ;

%%

Node *con(double value) {
    Node *p = malloc(sizeof(Node));
    p->type = typeCon;
    p->conValue = value;
    p->is_boolean_expr = 0;
    return p;
}

Node *id(char *name) {
    Node *p = malloc(sizeof(Node));
    p->type = typeId;
    p->idName = strdup(name);
    p->is_boolean_expr = 0;
    return p;
}

Node *strNode(char *s) {
    Node *p = malloc(sizeof(Node));
    p->type = typeStr;
    p->strValue = strdup(s);
    p->is_boolean_expr = 0;
    return p;
}

Node *opr(int oper, int nops, ...) {
    va_list ap;
    Node *p = malloc(sizeof(Node));
    p->opr.op = malloc(nops * sizeof(Node *));
    p->type = typeOpr;
    p->opr.oper = oper;
    p->opr.nops = nops;
    p->is_boolean_expr = 0;
    va_start(ap, nops);
    for (int i = 0; i < nops; i++) p->opr.op[i] = va_arg(ap, Node*);
    va_end(ap);
    return p;
}

double execute(Node *p) {
    if (!p) return 0;
    
    if (p->type == typeCon) return p->conValue;
    
    if (p->type == typeId) {
        int idx = find_symbol(p->idName);
        if (idx != -1) return symtab[idx].val;
        return 0;
    }

    if (p->type == typeStr) return 0;

    if (p->type == typeOpr) {
        switch (p->opr.oper) {
            case ';':
                execute(p->opr.op[0]);
                return execute(p->opr.op[1]);

            case ASSIGN:
                if (p->opr.op[0]->type == typeId) {
                    int idx = find_symbol(p->opr.op[0]->idName);
                    if (idx != -1) {
                        symtab[idx].val = execute(p->opr.op[1]);
                    }
                } else if (p->opr.op[0]->type == typeOpr && p->opr.op[0]->opr.oper == ARRAY) {
                    int idx = find_symbol(p->opr.op[0]->opr.op[0]->idName);
                    int arr_idx = (int)execute(p->opr.op[0]->opr.op[1]);
                    if (idx != -1) {
                        int offset = arr_idx - symtab[idx].low_bound;
                        if (offset >= 0 && offset < MAX_ARRAY_SIZE) {
                            symtab[idx].arr_vals[offset] = execute(p->opr.op[1]);
                        }
                    }
                }
                return 0;

            case ARRAY: {
                int idx = find_symbol(p->opr.op[0]->idName);
                int arr_idx = (int)execute(p->opr.op[1]);
                if (idx != -1) {
                    int offset = arr_idx - symtab[idx].low_bound;
                    if (offset >= 0 && offset < MAX_ARRAY_SIZE) {
                        return symtab[idx].arr_vals[offset];
                    }
                }
                return 0;
            }

            case WRITE: {
                Node *arg = p->opr.op[0];
                if (arg->type == typeStr) {
                    char temp[256];
                    strcpy(temp, arg->strValue + 1);
                    temp[strlen(temp) - 1] = '\0';
                    printf("%s\n", temp);
                } else {
                    double val = execute(arg);
                    if (arg->is_boolean_expr) {
                        printf("%s\n", (val != 0) ? "true" : "false");
                    } else if (arg->type == typeId) {
                        int idx = find_symbol(arg->idName);
                        if (idx != -1 && symtab[idx].type == TYPE_BOOL_VAL) {
                            printf("%s\n", (val != 0) ? "true" : "false");
                        } else {
                            printf("%g\n", val);
                        }
                    } else {
                        printf("%g\n", val);
                    }
                }
                return 0;
            }

            case READ: {
                double in_val;
                if (scanf("%lf", &in_val) == 1) {
                    if (p->opr.op[0]->type == typeId) {
                        int idx = find_symbol(p->opr.op[0]->idName);
                        if (idx != -1) symtab[idx].val = in_val;
                    }
                }
                return 0;
            }

            case PLUS:  return execute(p->opr.op[0]) + execute(p->opr.op[1]);
            case MINUS: return execute(p->opr.op[0]) - execute(p->opr.op[1]);
            case MULT:  return execute(p->opr.op[0]) * execute(p->opr.op[1]);
            case DIV:   return execute(p->opr.op[0]) / execute(p->opr.op[1]);
            case MOD:   return (int)execute(p->opr.op[0]) % (int)execute(p->opr.op[1]);

            case EQ:    return execute(p->opr.op[0]) == execute(p->opr.op[1]);
            case NEQ:   return execute(p->opr.op[0]) != execute(p->opr.op[1]);
            case LT:    return execute(p->opr.op[0]) < execute(p->opr.op[1]);
            case GT:    return execute(p->opr.op[0]) > execute(p->opr.op[1]);
            case LEQ:   return execute(p->opr.op[0]) <= execute(p->opr.op[1]);
            case GEQ:   return execute(p->opr.op[0]) >= execute(p->opr.op[1]);

            case AND:   return execute(p->opr.op[0]) && execute(p->opr.op[1]);
            case OR:    return execute(p->opr.op[0]) || execute(p->opr.op[1]);
            case NOT:   return !execute(p->opr.op[0]);

            case IF:
                if (execute(p->opr.op[0])) {
                    execute(p->opr.op[1]);
                } else if (p->opr.nops == 3) {
                    execute(p->opr.op[2]);
                }
                return 0;

            case WHILE:
                while (execute(p->opr.op[0])) {
                    execute(p->opr.op[1]);
                }
                return 0;

            case FOR: {
                int idx = find_symbol(p->opr.op[0]->idName);
                double start = execute(p->opr.op[1]);
                double end = execute(p->opr.op[2]);
                if (idx != -1) {
                    for (symtab[idx].val = start; symtab[idx].val <= end; symtab[idx].val++) {
                        execute(p->opr.op[3]);
                    }
                }
                return 0;
            }

            case DOWNTO: {
                int idx = find_symbol(p->opr.op[0]->idName);
                double start = execute(p->opr.op[1]);
                double end = execute(p->opr.op[2]);
                if (idx != -1) {
                    for (symtab[idx].val = start; symtab[idx].val >= end; symtab[idx].val--) {
                        execute(p->opr.op[3]);
                    }
                }
                return 0;
            }
        }
    }
    return 0;
}

void yyerror(const char *s) {
    fprintf(stderr, "syntax error\n");
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <input_file>\n", argv[0]);
        return 1;
    }
    yyin = fopen(argv[1], "r");
    if (!yyin) {
        fprintf(stderr, "Error: cannot open file '%s'\n", argv[1]);
        return 1;
    }
    yyparse();
    fclose(yyin);
    return 0;
}
