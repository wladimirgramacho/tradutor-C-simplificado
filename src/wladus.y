%error-verbose
%debug
%locations

%{
#include <stdio.h>
#include "uthash.h"


int yylex();
int yyerror(const char *s);
struct node* add_node(int data);

struct node {
  int data;
  struct node *left;
  struct node *right;
};

struct symbol {
  int id;
  char name[10];
  UT_hash_handle hh; /* makes this structure hashable */
};

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
  TIPO ID ';'
| TIPO ID '[' NUM ']' ';'
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

void add_symbol(struct symbol *s){
  // HASH_ADD_INT(users, id, s);
}


int main(){
  yyparse();
  return 0;
}