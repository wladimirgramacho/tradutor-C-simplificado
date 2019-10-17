%{
#include <stdio.h>

int yylex();
int yyerror(char *s);

%}

%union {
  char *id;
  int num;
  double dec;
  char *str;
}

%token SEMICOLON
 
%token <id> ID
%token <id> TIPO
%token <num> NUM
%token <dec> DEC
%token <str> STR
%token WHILE IF ELSE RETURN
%token EQ CEQ CNE CLT CLE CGT CGE 
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
  TIPO ID SEMICOLON
| TIPO ID '[' NUM ']' SEMICOLON
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
  expression SEMICOLON
;

conditional_statement:
  IF '(' expression ')' compound_statement
| IF '(' expression ')' compound_statement ELSE  compound_statement
;

iteration_statement:
  WHILE '(' expression ')' compound_statement
;

return_statement:
  expression SEMICOLON
| SEMICOLON
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
  op_expression relop op_expression
| op_expression
;

relop:
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
  '+'
| '-'
|  '*'
| '/'
;

term:
  '(' expression ')'
| var
| call
| NUM
| DEC
| '"' string '"'
;

call:
  ID '(' args ')'
;

args:
| arg_list
;

arg_list:
  arg_list ',' expression
| expression
;

string:
| STR
;

%%

int yyerror(char *s){
  printf("%s \n", s);
  return 0;
}

int main(){
  yyparse();
  return 0;
}