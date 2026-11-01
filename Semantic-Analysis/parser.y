%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <stdarg.h>

extern int yylex();
extern int yylineno;
extern FILE *yyin;
void yyerror(const char *s);

/* --- Semantic Symbol Tracking --- */
#define MAX_SYMBOLS 200
struct SemSymbol {
    char name[50];
    int type; 
    int is_initialized;
} sem_symtab[MAX_SYMBOLS];

int sem_sym_count = 0;
char temp_decl_vars[50][50];
int temp_decl_count = 0;

void add_temp_decl(char* name) {
    if (temp_decl_count < 50) strcpy(temp_decl_vars[temp_decl_count++], name);
}

int get_sem_idx(char* name) {
    for(int i = 0; i < sem_sym_count; i++) {
        if(strcasecmp(sem_symtab[i].name, name) == 0) return i;
    }
    return -1;
}

void register_sem_var(char* name, int type) {
    if (get_sem_idx(name) != -1) {
        fprintf(stderr, "Semantic Error: multiple declarations of variable '%s'\n", name);
        exit(1);
    }
    strcpy(sem_symtab[sem_sym_count].name, name);
    sem_symtab[sem_sym_count].type = type;
    sem_symtab[sem_sym_count].is_initialized = 0;
    sem_sym_count++;
}

/* --- AST Struct definitions --- */
typedef enum { typeCon, typeId, typeOpr, typeStr } NodeType;

typedef struct nodeTypeTag {
    NodeType type;
    int dataType; 
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
void check_semantics(Node *p, int is_lhs);
void print_ast_graph(Node *p, int level);

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
%type <nPtr> expr stmt stmt_or_block statement_list

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
        check_semantics($4, 0);
        printf("No semantic errors.\n\n--- Abstract Syntax Tree Graph ---\n");
        print_ast_graph($4, 0);
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
        for(int i = 0; i < temp_decl_count; i++) register_sem_var(temp_decl_vars[i], $3);
        temp_decl_count = 0; 
    }
    | var_list COLON ARRAY LBRACKET INT_CONST RANGE INT_CONST RBRACKET OF type SEMICOLON {
        for(int i = 0; i < temp_decl_count; i++) register_sem_var(temp_decl_vars[i], 10 + $10);
        temp_decl_count = 0; 
    }
    ;

var_list:
    IDENTIFIER { add_temp_decl($1); }
    | var_list COMMA IDENTIFIER { add_temp_decl($3); } ;  type: TYPE_INT    { $$ = 1; }
    | TYPE_REAL { $$= 2; } \vert{} TYPE_BOOL {$$ = 3; }
    | TYPE_CHAR { $$ = 4; } ;  statement_list: stmt_or_block { $$ = $1; } \vert{} statement_list stmt_or_block {$$ = opr(';', 2, $1, $2); } ;  stmt_or_block: stmt SEMICOLON { $$ = $1; } \vert{} BEGIN_BLOCK statement_list END_BLOCK SEMICOLON {$$ = $2; } \vert{} BEGIN_BLOCK statement_list END_BLOCK {$$ = $2; } ;  stmt: IDENTIFIER ASSIGN expr { $$ = opr(ASSIGN, 2, id($1), $3); } \vert{} IDENTIFIER LBRACKET expr RBRACKET ASSIGN expr {$$ = opr(ASSIGN, 2, opr(ARRAY, 2, id($1), $3), $6); } \vert{} READ LPAREN expr RPAREN {$$ = opr(READ, 1, $3); } \vert{} WRITE LPAREN expr RPAREN {$$ = opr(WRITE, 1, $3); } \vert{} IF expr THEN stmt_or_block \%prec LOWER_THAN_ELSE {$$ = opr(IF, 2, $2, $4); } \vert{} IF expr THEN stmt_or_block ELSE stmt_or_block {$$ = opr(IF, 3, $2, $4, $6); } \vert{} WHILE expr DO stmt_or_block {$$ = opr(WHILE, 2, $2, $4); } \vert{} FOR IDENTIFIER ASSIGN expr TO expr DO stmt_or_block {$$ = opr(FOR, 4, id($2), $4, $6, $8); } \vert{} FOR IDENTIFIER ASSIGN expr DOWNTO expr DO stmt_or_block {$$ = opr(DOWNTO, 4, id($2), $4, $6, $8); } ;  expr: expr PLUS expr { $$ = opr(PLUS, 2, $1, $3); } \vert{} expr MINUS expr {$$ = opr(MINUS, 2, $1, $3); } \vert{} expr MULT expr {$$ = opr(MULT, 2, $1, $3); } \vert{} expr DIV expr {$$ = opr(DIV, 2, $1, $3); } \vert{} expr MOD expr {$$ = opr(MOD, 2, $1, $3); } \vert{} expr EQ expr {$$ = opr(EQ, 2, $1, $3); } \vert{} expr NEQ expr {$$ = opr(NEQ, 2, $1, $3); } \vert{} expr LT expr {$$ = opr(LT, 2, $1, $3); } \vert{} expr GT expr {$$ = opr(GT, 2, $1, $3); } \vert{} expr LEQ expr {$$ = opr(LEQ, 2, $1, $3); } \vert{} expr GEQ expr {$$ = opr(GEQ, 2, $1, $3); } \vert{} expr AND expr {$$ = opr(AND, 2, $1, $3); } \vert{} expr OR expr {$$ = opr(OR, 2, $1, $3); } \vert{} NOT expr {$$ = opr(NOT, 1, $2); } \vert{} LPAREN expr RPAREN {$$ = $2; } \vert{} INT_CONST {$$ = con($1); $$->dataType = 1; } \vert{} REAL_CONST {$$ = con($1); $$->dataType = 2; } \vert{} TRUE_CONST {$$ = con(1); $$->dataType = 3; } \vert{} FALSE_CONST {$$ = con(0); $$->dataType = 3; } \vert{} STRING_LITERAL {$$ = strNode($1); } \vert{} IDENTIFIER {$$ = id($1); } \vert{} IDENTIFIER LBRACKET expr RBRACKET {$$ = opr(ARRAY, 2, id($1), $3); }
    ;

%%

Node *con(double value) {
    Node *p = malloc(sizeof(Node));
    p->type = typeCon;
    p->conValue = value;
    return p;
}

Node *id(char *name) {
    Node *p = malloc(sizeof(Node));
    p->type = typeId;
    p->idName = strdup(name);
    return p;
}

Node *strNode(char *s) {
    Node *p = malloc(sizeof(Node));
    p->type = typeStr;
    p->strValue = strdup(s);
    p->dataType = 4;
    return p;
}

Node *opr(int oper, int nops, ...) {
    va_list ap;
    Node *p = malloc(sizeof(Node));
    p->opr.op = malloc(nops * sizeof(Node *));
    p->type = typeOpr;
    p->opr.oper = oper;
    p->opr.nops = nops;
    va_start(ap, nops);
    for (int i = 0; i < nops; i++) p->opr.op[i] = va_arg(ap, Node*);
    va_end(ap);
    return p;
}

void check_semantics(Node *p, int is_lhs) {
    if (!p) return;
    
    if (p->type == typeCon || p->type == typeStr) return;
    
    if (p->type == typeId) {
        int idx = get_sem_idx(p->idName);
        if (idx == -1) {
            fprintf(stderr, "Semantic Error: undeclared variable '%s'\n", p->idName);
            exit(1);
        }
        if (!is_lhs && sem_symtab[idx].is_initialized == 0) {
            fprintf(stderr, "Semantic Error: variable '%s' used before assignment\n", p->idName);
            exit(1);
        }
        p->dataType = sem_symtab[idx].type;
        return;
    }
    
    if (p->type == typeOpr) {
        switch (p->opr.oper) {
            case ';':
                check_semantics(p->opr.op[0], 0);
                check_semantics(p->opr.op[1], 0);
                break;

            case ASSIGN:
                check_semantics(p->opr.op[1], 0); 
                check_semantics(p->opr.op[0], 1); 
                {
                    int targetType = p->opr.op[0]->dataType;
                    int exprType = p->opr.op[1]->dataType;
                    if (targetType != exprType) {
                        char *vName = (p->opr.op[0]->type == typeId) ? p->opr.op[0]->idName : p->opr.op[0]->opr.op[0]->idName;
                        fprintf(stderr, "Semantic Error: type mismatch in assignment to variable '%s'\n", vName);
                        exit(1);
                    }
                    if (p->opr.op[0]->type == typeId) {
                        sem_symtab[get_sem_idx(p->opr.op[0]->idName)].is_initialized = 1;
                    } else if (p->opr.op[0]->type == typeOpr && p->opr.op[0]->opr.oper == ARRAY) {
                        sem_symtab[get_sem_idx(p->opr.op[0]->opr.op[0]->idName)].is_initialized = 1;
                    }
                }
                break;

            case READ:
                if (p->opr.op[0]->type != typeId && 
                    !(p->opr.op[0]->type == typeOpr && p->opr.op[0]->opr.oper == ARRAY)) {
                    fprintf(stderr, "Semantic Error: READ argument must be a valid destination variable\n");
                    exit(1);
                }
                check_semantics(p->opr.op[0], 1);
                if (p->opr.op[0]->type == typeId) {
                    sem_symtab[get_sem_idx(p->opr.op[0]->idName)].is_initialized = 1;
                } else if (p->opr.op[0]->type == typeOpr && p->opr.op[0]->opr.oper == ARRAY) {
                    sem_symtab[get_sem_idx(p->opr.op[0]->opr.op[0]->idName)].is_initialized = 1;
                }
                break;

            case WRITE:
                check_semantics(p->opr.op[0], 0);
                break;

            case ARRAY:
                check_semantics(p->opr.op[0], is_lhs); 
                check_semantics(p->opr.op[1], 0); 
                {
                    int arrType = p->opr.op[0]->dataType;
                    if (arrType <= 10) {
                        fprintf(stderr, "Semantic Error: variable '%s' is not an array\n", p->opr.op[0]->idName);
                        exit(1);
                    }
                    if (p->opr.op[1]->dataType != 1) {
                        fprintf(stderr, "Semantic Error: Array index expression must be an integer\n");
                        exit(1);
                    }
                    p->dataType = arrType - 10; 
                }
                break;

            case PLUS: case MINUS: case MULT:
                check_semantics(p->opr.op[0], 0);
                check_semantics(p->opr.op[1], 0);
                if (p->opr.op[0]->dataType != p->opr.op[1]->dataType) {
                    fprintf(stderr, "Semantic Error: type mismatch inside arithmetic operation\n");
                    exit(1);
                }
                if (p->opr.op[0]->dataType != 1 && p->opr.op[0]->dataType != 2) {
                    fprintf(stderr, "Semantic Error: arithmetic operation requires numeric operands\n");
                    exit(1);
                }
                p->dataType = p->opr.op[0]->dataType;
                break;

            case DIV:
                check_semantics(p->opr.op[0], 0);
                check_semantics(p->opr.op[1], 0);
                if ((p->opr.op[0]->dataType != 1 && p->opr.op[0]->dataType != 2) ||
                    (p->opr.op[1]->dataType != 1 && p->opr.op[1]->dataType != 2)) {
                    fprintf(stderr, "Semantic Error: division requires numeric operands\n");
                    exit(1);
                }
                p->dataType = 2; 
                break;

            case MOD:
                check_semantics(p->opr.op[0], 0);
                check_semantics(p->opr.op[1], 0);
                if (p->opr.op[0]->dataType != 1 || p->opr.op[1]->dataType != 1) {
                    fprintf(stderr, "Semantic Error: modulo operator requires integer operands\n");
                    exit(1);
                }
                p->dataType = 1; 
                break;

            case LT: case GT: case LEQ: case GEQ: case EQ: case NEQ:
                check_semantics(p->opr.op[0], 0);
                check_semantics(p->opr.op[1], 0);
                if (!((p->opr.op[0]->dataType == 1 || p->opr.op[0]->dataType == 2) &&
                      (p->opr.op[1]->dataType == 1 || p->opr.op[1]->dataType == 2))) {
                    if (p->opr.op[0]->dataType != p->opr.op[1]->dataType) {
                        fprintf(stderr, "Semantic Error: type mismatch in relational comparison\n");
                        exit(1);
                    }
                }
                p->dataType = 3; 
                break;

            case AND: case OR:
                check_semantics(p->opr.op[0], 0);
                check_semantics(p->opr.op[1], 0);
                if (p->opr.op[0]->dataType != 3 || p->opr.op[1]->dataType != 3) {
                    fprintf(stderr, "Semantic Error: logical operations require boolean operands\n");
                    exit(1);
                }
                p->dataType = 3;
                break;

            case NOT:
                check_semantics(p->opr.op[0], 0);
                if (p->opr.op[0]->dataType != 3) {
                    fprintf(stderr, "Semantic Error: NOT operator requires a boolean operand\n");
                    exit(1);
                }
                p->dataType = 3;
                break;

            case IF:
                check_semantics(p->opr.op[0], 0);
                if (p->opr.op[0]->dataType != 3) {
                    fprintf(stderr, "Semantic Error: IF condition must be boolean\n");
                    exit(1);
                }
                check_semantics(p->opr.op[1], 0);
                if (p->opr.nops == 3) {
                    check_semantics(p->opr.op[2], 0);
                }
                break;

            case WHILE:
                check_semantics(p->opr.op[0], 0);
                if (p->opr.op[0]->dataType != 3) {
                    fprintf(stderr, "Semantic Error: WHILE condition must be boolean\n");
                    exit(1);
                }
                check_semantics(p->opr.op[1], 0);
                break;

            case FOR: case DOWNTO:
                check_semantics(p->opr.op[0], 1); 
                if (p->opr.op[0]->dataType != 1 && p->opr.op[0]->dataType != 4) {
                    fprintf(stderr, "Semantic Error: FOR loop control variable must be an integer or char\n");
                    exit(1);
                }
                check_semantics(p->opr.op[1], 0);
                check_semantics(p->opr.op[2], 0);
                if (p->opr.op[1]->dataType != p->opr.op[0]->dataType || 
                    p->opr.op[2]->dataType != p->opr.op[0]->dataType) {
                    fprintf(stderr, "Semantic Error: FOR loop range limits must match control variable type\n");
                    exit(1);
                }
                sem_symtab[get_sem_idx(p->opr.op[0]->idName)].is_initialized = 1;
                check_semantics(p->opr.op[3], 0);
                break;
        }
    }
}

void print_ast_graph(Node *p, int level) {
    if (!p) return;
    for (int i = 0; i < level; i++) printf("  ");
    
    switch (p->type) {
        case typeCon: printf("[Constant: %g]\n", p->conValue); break;
        case typeId:  printf("[Identifier: %s]\n", p->idName); break;
        case typeStr: printf("[Literal/String: %s]\n", p->strValue); break;
        case typeOpr: {
            if (p->opr.oper == ';') printf("[Statement List]\n");
            else if (p->opr.oper == ASSIGN) printf("[Assignment (:=)]\n");
            else printf("[Operator: %c / TokenID: %d]\n", p->opr.oper < 128 ? p->opr.oper : ' ', p->opr.oper);
            
            for (int i = 0; i < p->opr.nops; i++) {
                print_ast_graph(p->opr.op[i], level + 1);
            }
            break;
        }
    }
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
