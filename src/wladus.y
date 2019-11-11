%error-verbose
%debug
%locations

%{
#include <stdio.h>
#include "uthash.h"

int yylex();
int yyerror(const char *s);

typedef struct param {
  char *name;
  char *type;
  struct param *next;
} param;

struct ast_node* add_ast_node(char *data, int node_type, struct ast_node *left, struct ast_node *right);
struct ast_node* add_ast_func_node(char *data, char *func_name, param *params, struct ast_node *func_body);
struct ast_node* add_ast_cond_node(char *data, struct ast_node *condition, struct ast_node *if_branch, struct ast_node *else_branch);
struct ast_node* add_ast_iter_node(char *data, struct ast_node *condition, struct ast_node *while_branch);
struct ast_node* add_ast_op_node(char *data, char *operator, struct ast_node *left, struct ast_node *right);
struct ast_node* add_ast_call_node(char *data, char *func_name, struct ast_node *args);
struct ast_node* add_ast_int_node(char *data, int value);
struct ast_node* add_ast_float_node(char *data, float value);
struct ast_node* add_ast_str_node(char *data, struct ast_node *append, char *value);
struct ast_node* add_ast_interpol_str_node(char *data, struct ast_node *append, struct ast_node *expression);
void add_symbol(char *name, char *type, char symbol_type, struct ast_node *ast_node, param *param);
struct ast_node* add_ast_var_node(char *data, char *type, char *name);
param* add_param(char *type, char *name, param *next);

struct ast_node {
  int node_type;
  char *data;
  struct ast_node *left;
  struct ast_node *right;
};

struct ast_func_node { // function declarations
  int node_type;
  char *data;
  char *func_name;
  param *params;
  struct ast_node *func_body;
};

struct ast_var_node { // variables
  int node_type;
  char *data;
  char *type;
  char *name;
};

struct ast_cond_node { // conditional statements
  int node_type;
  char *data;
  struct ast_node *condition;
  struct ast_node *if_branch;
  struct ast_node *else_branch;
};

struct ast_iter_node { // for "while" statements
  int node_type;
  char *data;
  struct ast_node *condition;
  struct ast_node *while_branch;
};

struct ast_op_node { // operation statements
  int node_type;
  char *data;
  struct ast_node *left;
  struct ast_node *right;
  char *operator;
};

struct ast_call_node { // function calls
  int node_type;
  char *data;
  char *func_name;
  struct ast_node *args;
};

struct ast_int_node { // for constant integers
  int node_type;
  char *data;
  int value;
};

struct ast_float_node { // for constant floats
  int node_type;
  char *data;
  float value;
};

struct ast_str_node { // for constant strings
  int node_type;
  char *data;
  struct ast_node *append;
  char *value;
};

struct ast_interpol_str_node { // for string interpolation
  int node_type;
  char *data;
  struct ast_node *append;
  struct ast_node *expression;
};

struct symbol_node {
  char *name;                     // key field
  char *type;                     // int | float | string | void
  char symbol_type;               // 'V' or 'F'
  UT_hash_handle hh;              // makes this structure hashable
  struct {
    struct ast_node *func_body;   // function body
    param *param_list;
    struct symbol_node *symbols;
  } func_fields;
};

struct symbol_node *symbol_table = NULL;
struct ast_node* syntax_tree;
%}

%union {
  char *id;
  char *type;
  char *op;

  int num;
  double dec;
  char *str;

  struct ast_node *ast;
  struct param *param;
}

 
%token <id> ID
%token <type> TYPE
%token <num> NUM
%token <dec> DEC
%token <str> STR
%token WHILE IF ELSE RETURN WRITE READ
%token <op> EQ CEQ CNE CLT CLE CGT CGE
%token <op> PLUS MINUS MULT DIV
%token QUOTES
%token INTERPOL_START INTERPOL_END
%right EQ
%left '+' '-'
%left '*' '/'

%type <ast> prog declarations declaration var_declaration func_declaration
%type <ast> local_declarations statement_list compound_statement statement 
%type <ast> expression_statement conditional_statement iteration_statement return_statement
%type <ast> expression var simple_expression op_expression term call args arg_list string

%type <param> params

%start prog
%%

prog:
  declarations                                  { syntax_tree = add_ast_node("program", 'A', NULL, $1); }
;

declarations:
  declarations declaration                      { $$ = add_ast_node("declarations", 'A', $1, $2); }
| declaration                                   { $$ = add_ast_node("declarations", 'A', NULL, $1); }
;

declaration:
  var_declaration                               { $$ = add_ast_node("declaration", 'A', NULL, $1); }
| func_declaration                              { $$ = add_ast_node("declaration", 'A', NULL, $1); }
;

var_declaration:
  TYPE ID ';'                                   { $$ = add_ast_var_node("var_declaration", $1, $2); add_symbol($2, $1, 'V', NULL, NULL); }
;

func_declaration:
  TYPE ID '(' params ')' compound_statement     { $$ = add_ast_func_node("func_declaration", $2, $4, $6); add_symbol($2, $1, 'F', $6, $4); }
;

params:
  TYPE ID ',' params                            { $$ = add_param($1, $2, $4); }
| TYPE ID                                       { $$ = add_param($1, $2, NULL); }
|                                               { $$ = NULL; }
;


compound_statement:
  '{' local_declarations statement_list '}'     { $$ = add_ast_node("compound_statement", 'A', $2, $3); }
;

local_declarations:
  local_declarations var_declaration            { $$ = add_ast_node("local_declarations", 'A', $1, $2); }
|                                               { $$ = NULL; }
;

statement_list:
  statement_list statement                      { $$ = add_ast_node("statement_list", 'A', $1, $2); }
|                                               { $$ = NULL; }
;

statement:
  expression_statement                          { $$ = add_ast_node("statement", 'A', NULL, $1); }
| conditional_statement                         { $$ = add_ast_node("statement", 'A', NULL, $1); }
| iteration_statement                           { $$ = add_ast_node("statement", 'A', NULL, $1); }
| return_statement                              { $$ = add_ast_node("statement", 'A', NULL, $1); }
;

expression_statement:
  expression ';'                                { $$ = add_ast_node("expression_statement", 'A', NULL, $1); }
;

conditional_statement:
  IF '(' expression ')' compound_statement      { $$ = add_ast_cond_node("conditional_statement", $3, $5, NULL); }
| IF '(' expression ')' compound_statement ELSE  compound_statement { $$ = add_ast_cond_node("conditional_statement", $3, $5, $7); }
;

iteration_statement:
  WHILE '(' expression ')' compound_statement   { $$ = add_ast_iter_node("iteration_statement", $3, $5); }
;

return_statement:
  RETURN expression ';'                         { $$ = add_ast_node("return_statement", 'A', NULL, $2); }
| RETURN ';'                                    { $$ = add_ast_node("return_statement", 'A', NULL, NULL); }
;

expression:
  var EQ expression                             { $$ = add_ast_op_node("expression", $2, $1, $3); }
| simple_expression                             { $$ = add_ast_node("expression", 'A', NULL, $1); }
;

var:
  ID                                            { $$ = add_ast_var_node("var", "", $1); }
;

simple_expression:
  op_expression CEQ op_expression               { $$ = add_ast_op_node("simple_expression", $2, $1, $3); }
| op_expression CNE op_expression               { $$ = add_ast_op_node("simple_expression", $2, $1, $3); }
| op_expression CLT op_expression               { $$ = add_ast_op_node("simple_expression", $2, $1, $3); }
| op_expression CLE op_expression               { $$ = add_ast_op_node("simple_expression", $2, $1, $3); }
| op_expression CGT op_expression               { $$ = add_ast_op_node("simple_expression", $2, $1, $3); }
| op_expression CGE op_expression               { $$ = add_ast_op_node("simple_expression", $2, $1, $3); }
| op_expression                                 { $$ = add_ast_node("simple_expression", 'A', NULL, $1); }
;

op_expression:
  op_expression PLUS term                       { $$ = add_ast_op_node("op_expression", $2, $1, $3); }
| op_expression MINUS term                      { $$ = add_ast_op_node("op_expression", $2, $1, $3); }
| op_expression MULT term                       { $$ = add_ast_op_node("op_expression", $2, $1, $3); }
| op_expression DIV term                        { $$ = add_ast_op_node("op_expression", $2, $1, $3); }
| term                                          { $$ = add_ast_node("op_expression", 'A', NULL, $1); }
;

term:
  '(' simple_expression ')'                     { $$ = $2; }
| var                                           { $$ = $1; }
| call                                          { $$ = $1; }
| NUM                                           { $$ = add_ast_int_node("NUM", $1); }
| DEC                                           { $$ = add_ast_float_node("NUM", $1); }
| QUOTES string QUOTES                          { $$ = add_ast_node("term", 'A', NULL, $2); }
;

call:
  ID '(' args ')'                               { $$ = add_ast_call_node("call", $1, $3); }
| WRITE '(' simple_expression ')'               { $$ = add_ast_call_node("call", "write", $3); }
| READ '(' var ')'                              { $$ = add_ast_call_node("call", "read", $3); }
;

args:
  arg_list                                      { $$ = add_ast_node("args", 'A', NULL, $1); }
|                                               { $$ = NULL; }
;

arg_list:
  arg_list ',' simple_expression                { $$ = add_ast_node("arg_list", 'A', $1, $3); }
| simple_expression                             { $$ = add_ast_node("arg_list", 'A', NULL, $1); }
;

string:
  string STR                                    { $$ = add_ast_str_node("string", $1, $2); }
| string INTERPOL_START simple_expression INTERPOL_END { $$ = add_ast_interpol_str_node("string", $1, $3); }
|                                               { $$ = NULL; }
;

%%

struct ast_node* add_ast_node(char *data, int node_type, struct ast_node *left, struct ast_node *right){
  struct ast_node* ast_node = (struct ast_node*)malloc(sizeof(struct ast_node));

  ast_node->node_type = node_type;
  ast_node->data = (char *) strdup(data);
  ast_node->left = left;
  ast_node->right = right;

  return ast_node;
}

struct ast_node* add_ast_func_node(char *data, char *func_name, param *params, struct ast_node *func_body){
  struct ast_func_node* ast_node = (struct ast_func_node*)malloc(sizeof(struct ast_func_node));

  ast_node->node_type = 'F';
  ast_node->data = (char *) strdup(data);
  ast_node->func_name = (char *) strdup(func_name);
  ast_node->params = params;
  ast_node->func_body = func_body;

  return (struct ast_node *) ast_node;
}

struct ast_node* add_ast_cond_node(char *data, struct ast_node *condition, struct ast_node *if_branch, struct ast_node *else_branch){
  struct ast_cond_node* ast_node = (struct ast_cond_node*)malloc(sizeof(struct ast_cond_node));

  ast_node->node_type = 'C';
  ast_node->data = (char *) strdup(data);
  ast_node->condition = condition;
  ast_node->if_branch = if_branch;
  ast_node->else_branch = else_branch;

  return (struct ast_node *) ast_node;
}

struct ast_node* add_ast_iter_node(char *data, struct ast_node *condition, struct ast_node *while_branch){
  struct ast_iter_node* ast_node = (struct ast_iter_node*)malloc(sizeof(struct ast_iter_node));

  ast_node->node_type = 'W';
  ast_node->data = (char *) strdup(data);
  ast_node->condition = condition;
  ast_node->while_branch = while_branch;

  return (struct ast_node *) ast_node;
}

struct ast_node* add_ast_var_node(char *data, char *type, char *name){
  struct ast_var_node* ast_node = (struct ast_var_node*)malloc(sizeof(struct ast_var_node));

  ast_node->node_type = 'V';
  ast_node->data = (char *) strdup(data);
  ast_node->type = (char *) strdup(type);
  ast_node->name = (char *) strdup(name);

  return (struct ast_node *) ast_node;
}

struct ast_node* add_ast_op_node(char *data, char *operator, struct ast_node *left, struct ast_node *right){
  struct ast_op_node* ast_node = (struct ast_op_node*)malloc(sizeof(struct ast_op_node));

  ast_node->node_type = 'O';
  ast_node->data = (char *) strdup(data);
  ast_node->operator = (char *) strdup(operator);
  ast_node->left = left;
  ast_node->right = right;

  return (struct ast_node *) ast_node;
}

struct ast_node* add_ast_call_node(char *data, char *func_name, struct ast_node *args){
  struct ast_call_node* ast_node = (struct ast_call_node*)malloc(sizeof(struct ast_call_node));

  ast_node->node_type = 'L';
  ast_node->data = (char *) strdup(data);
  ast_node->func_name = (char *) strdup(func_name);
  ast_node->args = args;
}

struct ast_node* add_ast_int_node(char *data, int value){
  struct ast_int_node* ast_node = (struct ast_int_node*)malloc(sizeof(struct ast_int_node));

  ast_node->node_type = 'I';
  ast_node->data = (char *) strdup(data);
  ast_node->value = value;

  return (struct ast_node *) ast_node;
}

struct ast_node* add_ast_float_node(char *data, float value){
  struct ast_float_node* ast_node = (struct ast_float_node*)malloc(sizeof(struct ast_float_node));

  ast_node->node_type = 'D';
  ast_node->data = (char *) strdup(data);
  ast_node->value = value;

  return (struct ast_node *) ast_node;
}

struct ast_node* add_ast_str_node(char *data, struct ast_node *append, char *value){
  struct ast_str_node* ast_node = (struct ast_str_node*)malloc(sizeof(struct ast_str_node));

  ast_node->node_type = 'S';
  ast_node->data = (char *) strdup(data);
  ast_node->append = append;
  ast_node->value = (char *) strdup(value);

  return (struct ast_node *) ast_node;
}

struct ast_node* add_ast_interpol_str_node(char *data, struct ast_node *append, struct ast_node *expression){
  struct ast_interpol_str_node* ast_node = (struct ast_interpol_str_node*)malloc(sizeof(struct ast_interpol_str_node));

  ast_node->node_type = 'T';
  ast_node->data = (char *) strdup(data);
  ast_node->append = append;
  ast_node->expression = expression;

  return (struct ast_node *) ast_node;
}

void print_params(param *param, int depth){
  if(param == NULL) return;

  printf("%*s", depth, "");
  printf("%s", param->type);
  printf("%s", param->name);
  print_params(param->next, depth);
}

void print_ast_node(struct ast_node *s, int depth) {
  if(s == NULL) return;

  printf("%*s", depth, "");
  printf("%s", s->data);

  switch (s->node_type){
    case 'A':
      printf("\n");
      print_ast_node(s->left, depth + 1);
      print_ast_node(s->right, depth + 1);
      break;
    case 'F':
      {
        struct ast_func_node *node = (struct ast_func_node *) s;
        printf(" (%s)\n", node->func_name);
        if(node->params) print_params(node->params, depth+1);
        print_ast_node(node->func_body, depth+1);
      }
      break;
    case 'V':
      {
        struct ast_var_node *node = (struct ast_var_node *) s;
        printf(" (%s %s)\n", node->type, node->name);
      }
      break;
    case 'O':
      {
        struct ast_op_node *node = (struct ast_op_node *) s;
        printf(" (%s)\n", node->operator);
        print_ast_node(s->left, depth + 1);
        print_ast_node(s->right, depth + 1);
      }
      break;
    case 'C':
      {
        struct ast_cond_node *node = (struct ast_cond_node *) s;
        printf("\n");
        printf("%*s", depth, "");
        printf("-- condition --\n");
        print_ast_node(node->condition, depth + 1);

        printf("%*s", depth, "");
        printf("-- if body --\n");
        print_ast_node(node->if_branch, depth + 1);

        if(node->else_branch) {
          printf("%*s", depth, "");
          printf("-- else body --\n");
          print_ast_node(node->else_branch, depth + 1);
        }
      }
      break;
    case 'W':
      {
        struct ast_iter_node *node = (struct ast_iter_node *) s;
        printf("\n");
        printf("%*s", depth, "");
        printf("-- condition --\n");
        print_ast_node(node->condition, depth + 1);

        printf("%*s", depth, "");
        printf("-- while body --\n");
        print_ast_node(node->while_branch, depth + 1);
      }
      break;
    case 'L':
      {
        struct ast_call_node *node = (struct ast_call_node *) s;
        printf(" (%s)\n", node->func_name);
        print_ast_node(node->args, depth + 1);
      }
      break;
    case 'I':
      {
        struct ast_int_node *node = (struct ast_int_node *) s;
        printf(" (%d)\n", node->value);
      }
      break;
    case 'D':
      {
        struct ast_float_node *node = (struct ast_float_node *) s;
        printf(" (%lf)\n", node->value);
      }
      break;
    case 'S':
      {
        struct ast_str_node *node = (struct ast_str_node *) s;
        printf(" (%s)\n", node->value);
        print_ast_node(node->append, depth + 1);
      }
      break;
    case 'T':
      {
        struct ast_interpol_str_node *node = (struct ast_interpol_str_node *) s;
        printf("\n");
        print_ast_node(node->append, depth + 1);
        print_ast_node(node->expression, depth + 1);
      }
      break;
  }  
}

void print_syntax_tree() {
  struct ast_node *s = syntax_tree;

  printf("======  SYNTAX TREE ======\n");
  print_ast_node(s, 0);
  printf("\n");
}

void free_params(param *param){
  if(param == NULL) return;
  free(param->type);
  free(param->name);
  free_params(param->next);
  free(param);
}

void free_syntax_tree(struct ast_node *s){
  if(s == NULL) return;

  free(s->data);
  switch (s->node_type){
    case 'A':
      if(s->left) free_syntax_tree(s->left);
      if(s->right) free_syntax_tree(s->right);
      free(s);
      break;
    case 'F':
      {
        struct ast_func_node *node = (struct ast_func_node *) s;
        if(node->params) free_params(node->params);
        free(node->func_name);
        free_syntax_tree(node->func_body);
        free(node);
      }
      break;
    case 'V':
      {
        struct ast_var_node *node = (struct ast_var_node *) s;
        free(node->type);
        free(node->name);
        free(node);
      }
      break;
    case 'O':
      {
        struct ast_op_node *node = (struct ast_op_node *) s;
        free(node->operator);
        if(node->left) free_syntax_tree(node->left);
        if(node->right) free_syntax_tree(node->right);
        free(node);
      }
      break;
    case 'C':
      {
        struct ast_cond_node *node = (struct ast_cond_node *) s;
        free_syntax_tree(node->condition);
        free_syntax_tree(node->if_branch);
        if(node->else_branch) free_syntax_tree(node->else_branch);
        free(node);
      }
      break;
    case 'W':
      {
        struct ast_iter_node *node = (struct ast_iter_node *) s;
        free_syntax_tree(node->condition);
        free_syntax_tree(node->while_branch);
        free(node);
      }
      break;
    case 'L':
      {
        struct ast_call_node *node = (struct ast_call_node *) s;
        free(node->func_name);
        free_syntax_tree(node->args);
        free(node);
      }
      break;
    case 'I':
      {
        struct ast_int_node *node = (struct ast_int_node *) s;
        free(node);
      }
      break;
    case 'D':
      {
        struct ast_float_node *node = (struct ast_float_node *) s;
        free(node);
      }
      break;
    case 'S':
      {
        struct ast_str_node *node = (struct ast_str_node *) s;
        free(node->value);
        if(node->append) free(node->append);
        free(node);
      }
      break;
    case 'T':
      {
        struct ast_interpol_str_node *node = (struct ast_interpol_str_node *) s;
        if(node->append) free(node->append);
        if(node->expression) free(node->expression);
        free(node);
      }
      break;
  }
}

void add_symbol(char *name, char *type, char symbol_type, struct ast_node *ast_node, param *param){
  struct symbol_node *s;

  HASH_FIND_STR(symbol_table, name, s);
  if(s == NULL){
    s = (struct symbol_node *)malloc(sizeof *s);

    s->name = (char *) strdup(name);
    s->type = (char *) strdup(type);
    s->symbol_type = symbol_type;

    if(symbol_type = 'F') {
      s->func_fields.func_body = ast_node;
      s->func_fields.param_list = param;
    }

    HASH_ADD_STR(symbol_table, name, s);
  }
}

param* add_param(char *type, char *name, param *next){
  param *p;

  p = (param *)malloc(sizeof *p);

  p->type = (char *) strdup(type);
  p->name = (char *) strdup(name);
  p->next = next;
  return p;
}

void print_symbol_table() {
  struct symbol_node *s;

  printf("===============  SYMBOL TABLE ===============\n");
  printf("NAME\t\tTYPE\t\tSYMBOL_TYPE\n");
  for(s=symbol_table; s != NULL; s=s->hh.next) {
    printf("%s\t\t%s\t\t%c\n", s->name, s->type, s->symbol_type);
  }
}

void free_symbol_table(){
  struct symbol_node *s, *tmp;

  HASH_ITER(hh, symbol_table, s, tmp) {
    HASH_DEL(symbol_table, s);
    free(s->name);
    free(s->type);
    s->func_fields.func_body = NULL;
    free(s);
  }
}

void main (int argc, char **argv){
  int print_table = 0;
  int print_tree = 0;

  if(argc > 1 && !strcmp(argv[1], "-t")){
    print_table = 1;
  }

  if(argc > 1 && !strcmp(argv[1], "-tt")){
    print_table = 1;
    print_tree = 1;
  }

  yyparse();

  if(print_table) print_symbol_table();
  if(print_tree) print_syntax_tree();
  free_symbol_table();
  free_syntax_tree(syntax_tree);
}