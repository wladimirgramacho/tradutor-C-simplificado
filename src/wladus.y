%error-verbose
%debug
%locations

%{
#include <stdio.h>
#include "uthash.h"


int yylex();
int yyerror(const char *s);
struct node* add_node(int data);
void add_symbol(char *name, char *type);

struct node {
  int data;
  struct node *left;
  struct node *right;
};

struct symbol {
  char *name;         // key field
  char *type;
  UT_hash_handle hh;  // makes this structure hashable
};

struct symbol *symbol_table = NULL;

%}

%union {
  char *id;
  int num;
  double dec;
  char *str;
}

 
%token <id> ID
%token <id> TIPO
%token <num> NUM
%token <dec> DEC
%token <str> STR
%token WHILE IF ELSE RETURN WRITE READ
%token EQ CEQ CNE CLT CLE CGT CGE
%token PLUS MINUS MULT DIV
%token QUOTES
%token INTERPOL_START INTERPOL_END
%right EQ
%left '+' '-'
%left '*' '/'

%start prog
%%

prog:
  declarations
;

declarations:
  declarations declaration
| declaration
;

declaration:
  var_declaration
| fun_declaration
;

var_declaration:
  TIPO ID ';'                                   { add_symbol($2, $1); }
| TIPO ID '[' NUM ']' ';'                       { add_symbol($2, $1); }
;

fun_declaration:
  TIPO ID '(' params ')' compound_statement
;

params:
| param_list
;

param_list:
  param_list ',' TIPO param
| TIPO param
;

param:
  ID
| ID '[' ']'
;

compound_statement:
  '{' local_declarations statement_list '}'
;

local_declarations:
  local_declarations var_declaration
|
;

statement_list:
| statement_list statement
;

statement:
  expression_statement
| conditional_statement
| iteration_statement
| RETURN return_statement
;

expression_statement:
  expression ';'
;

conditional_statement:
  IF '(' expression ')' compound_statement
| IF '(' expression ')' compound_statement ELSE  compound_statement
;

iteration_statement:
  WHILE '(' expression ')' compound_statement
;

return_statement:
  expression ';'
| ';'
;

expression:
  var EQ expression
| simple_expression
;

var:
  ID
| ID '[' expression ']'
;

simple_expression:
  op_expression cond_op op_expression
| op_expression
;

cond_op:
  CEQ
| CNE
| CLT
| CLE
| CGT
| CGE
;

op_expression:
  op_expression op term
| term
;

op:
  PLUS
| MINUS
| MULT
| DIV
;

term:
  '(' simple_expression ')'
| var
| call
| NUM
| DEC
| QUOTES string QUOTES
;

call:
  ID '(' args ')'
| WRITE '(' simple_expression ')'
| READ '(' var ')'
;

args:
| arg_list
;

arg_list:
  arg_list ',' simple_expression
| simple_expression
;

string:
| string STR
| string INTERPOL_START simple_expression INTERPOL_END
;

%%

struct node* add_node(int data){
  struct node* node = (struct node*)malloc(sizeof(struct node));
  node->data = data;
  node->left = NULL;
  node->right = NULL;

  return node;
}

void add_symbol(char *name, char *type){
  struct symbol *s;

  HASH_FIND_INT(symbol_table, &name, s);
  if(s==NULL){
    s = malloc(sizeof(struct symbol));

    s->name = (char *) strdup(name);
    s->type = (char *) strdup(type);

    HASH_ADD_INT(symbol_table, name, s);
  }
}

void print_symbol_table() {
  struct symbol *s;

  printf("======  SYMBOL TABLE ======\n");
  printf("NAME\t\tTYPE\n");
  for(s=symbol_table; s != NULL; s=s->hh.next) {
    printf("%s\t\t%s\n", s->name, s->type);
  }
}

void free_symbol_table(){
  struct symbol *s;
  for(s=symbol_table; s != NULL; s=s->hh.next) {
    HASH_DEL(symbol_table, s);
    free(s);
  }
}


int main(){
  yyparse();
  print_symbol_table();
  free_symbol_table();
  return 0;
}