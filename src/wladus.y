%error-verbose
%debug
%locations

%{
#include <stdio.h>
#include "uthash.h"
#include "utstring.h"
#include "utstack.h"

int yylex();
int yyerror(const char *s);
extern int yylex_destroy(void);

typedef struct simple_symbol_node {
  char *name;
  char dtype;
  char symbol_type;
  int scope_level;
  struct simple_symbol_node *next;
} simple_symbol_node;

typedef struct scope {
  char *scope_name;
  int scope_level;
  struct scope *next;
} scope;

typedef struct symbol_node {
  char *name;                     // key field
  char type;                      // 'i'nt | 'f'loat | 's'tring | 'v'oid
  char symbol_type;               // 'V' (variable) | 'F' (function) | 'P' (parameter)
  int scope_level;                // 0 for global variables and functions, 1..n inside functions
  UT_hash_handle hh;              // makes this structure hashable
  struct {
    struct ast_node *func_body;   // function body
    simple_symbol_node *symbols;  // params and variables inside function scope
  } func_fields;
} symbol_node;

struct ast_node {
  int node_type;
  char dtype;
  struct ast_node *left;
  struct ast_node *right;
  union {
    int integer;
    float decimal;
    char *string;
    char *operator;
    char *func_name;
  };
};

void gen(char * operation, int v1, int v2);

struct ast_node* add_ast_node(int node_type, struct ast_node *left, struct ast_node *right);

void add_symbol(char *name, char *type, char symbol_type);
symbol_node* find_symbol(char *name);
simple_symbol_node* create_simple_symbol_node(char *name, char dtype, char symbol_type, int scope_level);

void error_not_declared(char *symbol_type, char *name);
void error_redeclaration(char *symbol_type, char *name);
void error_type_mismatch(char left_dtype, char right_dtype);

int mismatch(char left_dtype, char right_dtype);

char type_to_dtype(char *type);
char * dtype_to_type(char dtype);

struct symbol_node *symbol_table = NULL;
struct ast_node* syntax_tree = NULL;
struct scope* scope_stack = NULL;
UT_string *tac_code[999999];

extern int has_error;
%}

%union {
  char *id;
  char *type;
  char *op;

  int num;
  double dec;
  char *str;

  struct ast_node *ast;
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
%token ITP_START ITP_END
%right EQ
%left '+' '-'
%left '*' '/'

%type <ast> prog declarations declaration var_declaration func_declaration params
%type <ast> local_declarations statement_list compound_statement statement local_var_declaration
%type <ast> expression_statement conditional_statement iteration_statement return_statement
%type <ast> expression var simple_expression op_expression term call args arg_list string

%start prog
%%

prog:
  declarations                                  { syntax_tree = $1; }
;

declarations:
  declarations declaration                      { $$ = add_ast_node('A', $1, $2); }
| declaration                                   { $$ = $1; }
;

declaration:
  var_declaration                               { $$ = $1; }
| func_declaration                              { $$ = $1; }
;

var_declaration:
  TYPE ID ';'                                   { $$ = NULL; add_symbol($2, $1, 'V'); free($1); free($2); }
;

func_declaration:
  TYPE ID                                       {
                                                  add_symbol($2, $1, 'F');
                                                  scope *new_scope = (scope *)malloc(sizeof *new_scope);
                                                  new_scope->scope_name = (char *) strdup($2);
                                                  new_scope->scope_level = 1;
                                                  STACK_PUSH(scope_stack, new_scope);
                                                }
  '(' params ')'                                { ; }
  compound_statement                            {
                                                  $$ = add_ast_node('F', NULL, $8);
                                                  $$->dtype = type_to_dtype($1);
                                                  $$->func_name = (char *) strdup($2);

                                                  symbol_node *s = find_symbol($2);
                                                  s->func_fields.func_body = $8;

                                                  scope *old_scope;
                                                  STACK_POP(scope_stack, old_scope);
                                                  free(old_scope->scope_name);
                                                  free(old_scope);
                                                  scope_stack = NULL;
                                                  free($1);
                                                  free($2);
                                                }
;

params:
  params ',' TYPE ID                            { $$ = $1; add_symbol($4, $3, 'P'); free($3); free($4); }
| TYPE ID                                       { $$ = NULL; add_symbol($2, $1, 'P'); free($1); free($2); }
|                                               { $$ = NULL; }
;

compound_statement:
  '{' local_declarations statement_list '}'     { $$ = add_ast_node('A', $2, $3); }
;

local_declarations:
  local_declarations local_var_declaration      { $$ = add_ast_node('A', $1, $2); }
|                                               { $$ = NULL; }
;

local_var_declaration:
  TYPE ID ';'                                   {
                                                  $$ = add_ast_node('V', NULL, NULL);
                                                  $$->dtype = type_to_dtype($1);
                                                  add_symbol($2, $1, 'V');
                                                  free($1);
                                                  free($2);
                                                }

statement_list:
  statement_list statement                      { $$ = add_ast_node('A', $1, $2); }
|                                               { $$ = NULL; }
;

statement:
  expression_statement                          { $$ = $1; }
| conditional_statement                         { $$ = $1; }
| iteration_statement                           { $$ = $1; }
| return_statement                              { $$ = $1; }
;

expression_statement:
  expression ';'                                { $$ = $1; }
| error ';'                                     { $$ = NULL; }
;

conditional_statement:
  startIf '(' expression ')' compound_statement {
                                                  $$ = add_ast_node('C', add_ast_node('c', $3, $5), NULL);
                                                  scope *old_scope;
                                                  STACK_POP(scope_stack, old_scope);
                                                  free(old_scope->scope_name);
                                                  free(old_scope);
                                                }
| startIf '(' expression ')' compound_statement {
                                                  scope *old_scope;
                                                  STACK_POP(scope_stack, old_scope);
                                                  free(old_scope->scope_name);
                                                  free(old_scope);
                                                }
  ELSE                                          {
                                                  scope *new_scope = (scope *)malloc(sizeof *new_scope);
                                                  scope *top = STACK_TOP(scope_stack);
                                                  new_scope->scope_name = (char *) strdup(top->scope_name);
                                                  new_scope->scope_level = top->scope_level + 1;
                                                  STACK_PUSH(scope_stack, new_scope);
                                                }
  compound_statement                            {
                                                  $$ = add_ast_node('C', add_ast_node('c', $3, $5), $9);
                                                  scope *old_scope;
                                                  STACK_POP(scope_stack, old_scope);
                                                  free(old_scope->scope_name);
                                                  free(old_scope);
                                                }
;

startIf:
  IF                                            {
                                                  scope *new_scope = (scope *)malloc(sizeof *new_scope);
                                                  scope *top = STACK_TOP(scope_stack);
                                                  new_scope->scope_name = (char *) strdup(top->scope_name);
                                                  new_scope->scope_level = top->scope_level + 1;
                                                  STACK_PUSH(scope_stack, new_scope);
                                                }
;

iteration_statement:
  WHILE '(' expression ')' compound_statement   { $$ = add_ast_node('W', $3, $5); }
;

return_statement:
  RETURN expression ';'                         { $$ = $2; }
| RETURN ';'                                    { $$ = NULL; }
;

expression:
  var EQ expression                             {
                                                  if(mismatch($1->dtype, $3->dtype)){ error_type_mismatch($1->dtype, $3->dtype); }
                                                  else {
                                                    $$ = add_ast_node('O', $1, $3);
                                                    $$->operator = $2;
                                                    $$->dtype = $1->dtype;
                                                  }

                                                }
| simple_expression                             { $$ = $1; }
;

var:
  ID                                            {
                                                  $$ = add_ast_node('V', NULL, NULL);
                                                  symbol_node *s = find_symbol($1);
                                                  if(s == NULL){ error_not_declared("variable", $1); }
                                                  else { $$->dtype = s->type; }
                                                  free($1);
                                                }
;

simple_expression:
  op_expression CEQ op_expression               { $$ = add_ast_node('O', $1, $3); $$->operator = $2; if(mismatch($1->dtype, $3->dtype)){ error_type_mismatch($1->dtype, $3->dtype); } else { $$->dtype = $1->dtype; } }
| op_expression CNE op_expression               { $$ = add_ast_node('O', $1, $3); $$->operator = $2; if(mismatch($1->dtype, $3->dtype)){ error_type_mismatch($1->dtype, $3->dtype); } else { $$->dtype = $1->dtype; } }
| op_expression CLT op_expression               { $$ = add_ast_node('O', $1, $3); $$->operator = $2; if(mismatch($1->dtype, $3->dtype)){ error_type_mismatch($1->dtype, $3->dtype); } else { $$->dtype = $1->dtype; } }
| op_expression CLE op_expression               { $$ = add_ast_node('O', $1, $3); $$->operator = $2; if(mismatch($1->dtype, $3->dtype)){ error_type_mismatch($1->dtype, $3->dtype); } else { $$->dtype = $1->dtype; } }
| op_expression CGT op_expression               { $$ = add_ast_node('O', $1, $3); $$->operator = $2; if(mismatch($1->dtype, $3->dtype)){ error_type_mismatch($1->dtype, $3->dtype); } else { $$->dtype = $1->dtype; } }
| op_expression CGE op_expression               { $$ = add_ast_node('O', $1, $3); $$->operator = $2; if(mismatch($1->dtype, $3->dtype)){ error_type_mismatch($1->dtype, $3->dtype); } else { $$->dtype = $1->dtype; } }
| op_expression                                 { $$ = $1; }
;

op_expression:
  op_expression PLUS term                       { $$ = add_ast_node('O', $1, $3); $$->operator = $2; if(mismatch($1->dtype, $3->dtype)){ error_type_mismatch($1->dtype, $3->dtype); } else { $$->dtype = $1->dtype; } gen("add", $1->integer, $3->integer); }
| op_expression MINUS term                      { $$ = add_ast_node('O', $1, $3); $$->operator = $2; if(mismatch($1->dtype, $3->dtype)){ error_type_mismatch($1->dtype, $3->dtype); } else { $$->dtype = $1->dtype; } }
| op_expression MULT term                       { $$ = add_ast_node('O', $1, $3); $$->operator = $2; if(mismatch($1->dtype, $3->dtype)){ error_type_mismatch($1->dtype, $3->dtype); } else { $$->dtype = $1->dtype; } }
| op_expression DIV term                        { $$ = add_ast_node('O', $1, $3); $$->operator = $2; if(mismatch($1->dtype, $3->dtype)){ error_type_mismatch($1->dtype, $3->dtype); } else { $$->dtype = $1->dtype; } }
| term                                          { $$ = $1; }
;

term:
  '(' simple_expression ')'                     { $$ = $2; }
| var                                           { $$ = $1; }
| call                                          {
                                                  $$ = $1;
                                                  symbol_node *s = find_symbol($1->func_name);
                                                  if(s != NULL){ $$->dtype = s->type; }
                                                }
| NUM                                           { $$ = add_ast_node('I', NULL, NULL); $$->integer = $1; $$->dtype = 'i'; }
| DEC                                           { $$ = add_ast_node('D', NULL, NULL); $$->decimal = $1; $$->dtype = 'f'; }
| QUOTES string QUOTES                          { $$ = $2; $$->dtype = 's'; }
;

call:
  ID '(' args ')'                               {
                                                  $$ = add_ast_node('L', NULL, $3);
                                                  $$->func_name = (char *) strdup($1);
                                                  symbol_node *s = find_symbol($1);
                                                  if(s == NULL) error_not_declared("function", $1);
                                                  free($1);
                                                }
| WRITE '(' simple_expression ')'               { $$ = add_ast_node('L', NULL, $3); $$->func_name = (char *) strdup("write"); }
| READ '(' var ')'                              { $$ = add_ast_node('L', NULL, $3); $$->func_name = (char *) strdup("read"); }
;

args:
  arg_list                                      { $$ = $1; }
|                                               { $$ = NULL; }
;

arg_list:
  arg_list ',' simple_expression                { $$ = add_ast_node('A', $1, $3); }
| simple_expression                             { $$ = $1; }
;

string:
  string STR                                    { $$ = add_ast_node('S', NULL, $1); $$->string = (char *) strdup("string"); free($2); }
| string ITP_START simple_expression ITP_END    { $$ = add_ast_node('T', $1, $3);  $$->string = (char *) strdup("interpolated string"); }
|                                               { $$ = add_ast_node('S', NULL, NULL);  $$->string = (char *) strdup("empty string"); }
;

%%

void gen(char * operation, int v1, int v2){
  utstring_new(tac_code[1]);
  utstring_printf(tac_code[1], "%s $0, %d, %d\n", operation, v1, v2);
  utstring_new(tac_code[2]);
  utstring_printf(tac_code[2], "print $0\n");
}

struct ast_node* add_ast_node(int node_type, struct ast_node *left, struct ast_node *right){
  struct ast_node* ast_node = (struct ast_node*)calloc(1, sizeof(struct ast_node));

  ast_node->node_type = node_type;
  ast_node->left = left;
  ast_node->right = right;
  ast_node->dtype = '0'; // empty dtype

  return ast_node;
}

void print_ast_node(struct ast_node *s, int depth) {
  if(s == NULL) return;

  if(s->node_type == 'A'){
    print_ast_node(s->left, depth);
    print_ast_node(s->right, depth);
    return;
  }

  printf("%*s", depth, "");

  switch (s->node_type){
    case 'T':
      print_ast_node(s->left, depth + 1);
      print_ast_node(s->right, depth + 1);
      break;
    case 'F':
      {
        printf("%s \t\t type = %s\n", s->func_name, dtype_to_type(s->dtype));

        print_ast_node(s->right, depth+1);
      }
      break;
    case 'O':
      {
        printf(" (%s) \t\t type = %s\n", s->operator, dtype_to_type(s->dtype));
        print_ast_node(s->left, depth + 1);
        print_ast_node(s->right, depth + 1);
      }
      break;
    case 'c':
      {
        printf("if\n");

        printf("%*s", depth + 1, "");
        printf("-- condition --\n");
        print_ast_node(s->left, depth + 2);

        printf("%*s", depth + 1, "");
        printf("-- body --\n");
        print_ast_node(s->right, depth + 2);
      }
      break;
    case 'C':
      {
        print_ast_node(s->left, depth);

        if(s->right) {
          printf("%*s", depth + 1, "");
          printf("-- else --\n");
          print_ast_node(s->right, depth + 2);
        }
      }
      break;
    
    case 'W':
      {
        printf("while\n");

        printf("%*s", depth + 1, "");
        printf("-- condition --\n");
        print_ast_node(s->left, depth + 2);

        printf("%*s", depth + 1, "");
        printf("-- body --\n");
        print_ast_node(s->right, depth + 2);
      }
      break;
    case 'L':
      {
        printf(" (%s)\n", s->func_name);
        print_ast_node(s->left, depth + 1);
        print_ast_node(s->right, depth + 1);
      }
      break;
    case 'I':
      {
        printf(" (%d) \t\t type = %s\n", s->integer, dtype_to_type(s->dtype));
      }
      break;
    case 'D':
      {
        printf(" (%lf) \t\t type = %s\n", s->decimal, dtype_to_type(s->dtype));
      }
      break;
    case 'S':
      {
        printf(" (%s)\n", s->string);
        print_ast_node(s->left, depth + 1);
        print_ast_node(s->right, depth + 1);
      }
      break;
    case 'V':
      {
        printf(" (ID) \t\t type = %s\n", dtype_to_type(s->dtype));
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

void free_syntax_tree(struct ast_node *s){
  if(s == NULL) return;

  switch (s->node_type){
    case 'A':
    case 'C':
    case 'c':
    case 'W':
    case 'V':
      if(s->left) free_syntax_tree(s->left);
      if(s->right) free_syntax_tree(s->right);
      free(s);
      break;
    case 'F':
      {
        free(s->func_name);
        free_syntax_tree(s->right);
        free(s);
      }
      break;
    case 'O':
      {
        free(s->operator);
        if(s->left) free_syntax_tree(s->left);
        if(s->right) free_syntax_tree(s->right);
        free(s);
      }
      break;
    case 'L':
      {
        free(s->func_name);
        if(s->left) free_syntax_tree(s->left);
        if(s->right) free_syntax_tree(s->right);
        free(s);
      }
      break;
    case 'I':
      {
        free(s);
      }
      break;
    case 'D':
      {
        free(s);
      }
      break;
    case 'S':
      {
        free(s->string);
        if(s->left) free_syntax_tree(s->left);
        if(s->right) free_syntax_tree(s->right);
        free(s);
      }
      break;
    case 'T':
      {
        free(s->string);
        if(s->left) free_syntax_tree(s->left);
        if(s->right) free_syntax_tree(s->right);
        free(s);
      }
      break;
  }
}

char type_to_dtype(char *type){
  if(strcmp(type, "int") == 0) { return 'i'; }
  else if(strcmp(type, "float") == 0) { return 'f'; }
  else if(strcmp(type, "string") == 0) { return 's'; }
  else if(strcmp(type, "void") == 0) { return 'v'; }
}

char * dtype_to_type(char dtype){
  if(dtype == 'i') { return "int"; }
  else if(dtype == 'f') { return "float"; }
  else if(dtype == 's') { return "string"; }
  else if(dtype == 'v') { return "void"; }
}

symbol_node* build_symbol(char *name, char *type, char symbol_type, int scope_level){
  symbol_node *s = (symbol_node *)malloc(sizeof *s);

  s->name = (char *) strdup(name);
  s->type = type_to_dtype(type);
  s->symbol_type = symbol_type;
  s->scope_level = scope_level;
  if(symbol_type == 'F'){
    s->func_fields.symbols = NULL;
  }

  return s;
}

symbol_node* find_symbol(char *name){
  symbol_node *s;

  HASH_FIND_STR(symbol_table, name, s);
  if(s != NULL) return s;

  scope * top = STACK_TOP(scope_stack);
  HASH_FIND_STR(symbol_table, top->scope_name, s);

  simple_symbol_node *tmp;
  for (tmp = s->func_fields.symbols; tmp != NULL && (strcmp(tmp->name, name) != 0); tmp = tmp->next);

  return (symbol_node *) tmp;
}

void add_symbol(char *name, char *type, char symbol_type){
  symbol_node *s;
  scope * top;

  if(symbol_type == 'F') {
    HASH_FIND_STR(symbol_table, name, s);
    if(s == NULL){ // function not declared -> add to symbol table
      s = build_symbol(name, type, symbol_type, 0);
      HASH_ADD_STR(symbol_table, name, s);
    }
    else { // function already declared -> error
      error_redeclaration("function", name);
      return;
    }
  }
  else {
    if(STACK_TOP(scope_stack) == NULL){ // is not inside scope
      HASH_FIND_STR(symbol_table, name, s);
      if(s == NULL){ // global variable not declared -> add to symbol table
        s = build_symbol(name, type, symbol_type, 0);
        HASH_ADD_STR(symbol_table, name, s);
      }
      else { // global variable already declared -> error
        error_redeclaration("variable", name);
        return;
      }
    }
    else { // is inside scope
      HASH_FIND_STR(symbol_table, name, s);
      top = STACK_TOP(scope_stack);
      if(s != NULL && top->scope_level == s->scope_level){ // local variable is declared as global variable -> error
        error_redeclaration("variable", name);
        return;
      }
      HASH_FIND_STR(symbol_table, top->scope_name, s);

      simple_symbol_node *tmp, *new_node;

      char dtype = type_to_dtype(type);
      new_node = create_simple_symbol_node(name, dtype, symbol_type, top->scope_level);

      if(s->func_fields.symbols == NULL){
        s->func_fields.symbols = new_node;
        return;
      }

      for (tmp = s->func_fields.symbols; tmp->next != NULL; tmp = tmp->next){
        if(strcmp(tmp->name, name) == 0 && tmp->scope_level == top->scope_level){ // local variable is already declared in function -> error
          error_redeclaration("variable", name);
          free(new_node->name);
          free(new_node);
          return;
        }
      }
      if(strcmp(tmp->name, name) == 0 && tmp->scope_level == top->scope_level){ // local variable is already declared in function -> error
        error_redeclaration("variable", name);
        free(new_node->name);
        free(new_node);
        return;
      }
      tmp->next = new_node;
    }
  }
}

simple_symbol_node* create_simple_symbol_node(char *name, char dtype, char symbol_type, int scope_level){
  simple_symbol_node *new_node = (simple_symbol_node *)malloc(sizeof *new_node);
  new_node->name = (char *) strdup(name);
  new_node->dtype = dtype;
  new_node->symbol_type = symbol_type;
  new_node->scope_level = scope_level;
  new_node->next = NULL;
  return new_node;
}

int mismatch(char left_dtype, char right_dtype){
  return left_dtype != '0' && right_dtype != '0' && left_dtype != right_dtype;
}

void error_not_declared(char *symbol_type, char *name){
  char * error_message = (char *)malloc(50 * sizeof(char));
  sprintf(error_message, "semantic error, %s '%s' was not declared", symbol_type, name);
  yyerror(error_message);
  free(error_message);
}

void error_redeclaration(char *symbol_type, char *name){
  char * error_message = (char *)malloc(50 * sizeof(char));
  sprintf(error_message, "semantic error, %s '%s' was already declared", symbol_type, name);
  yyerror(error_message);
  free(error_message);
}

void error_type_mismatch(char left_dtype, char right_dtype){
  char * error_message = (char *)malloc(50 * sizeof(char));
  char * left = (char *)malloc(7 * sizeof(char));
  char * right = (char *)malloc(7 * sizeof(char));
  strcpy(left, dtype_to_type(left_dtype));
  strcpy(right, dtype_to_type(right_dtype));
  sprintf(error_message, "semantic error, ‘%s‘ type mismatch with ‘%s‘", left, right);
  yyerror(error_message);
  free(error_message);
}

void print_symbol_table() {
  symbol_node *s;

  printf("===============  SYMBOL TABLE ===============\n");
  printf("NAME\t\tTYPE\t\tSYMBOL_TYPE\t\tSCOPE SYMBOLS\n");
  for(s=symbol_table; s != NULL; s=s->hh.next) {
    printf("%s\t\t%s\t\t%c", s->name, dtype_to_type(s->type), s->symbol_type);
    if(s->symbol_type == 'F'){
      simple_symbol_node *ss;
      printf("\t\t\t");
      for (ss = s->func_fields.symbols; ss != NULL; ss = ss->next){
        printf("(%c) %s %s", ss->symbol_type, dtype_to_type(ss->dtype), ss->name);
        if (ss->scope_level > 1) printf(" [%d]", ss->scope_level);
        printf(", ");
      }
    }
    printf("\n");
  }
}

void free_simple_symbol_node(simple_symbol_node * node){
  if(node == NULL) return;
  free_simple_symbol_node(node->next);
  free(node->name);
  free(node);
}

void free_symbol_table(){
  symbol_node *s, *tmp;

  HASH_ITER(hh, symbol_table, s, tmp) {
    HASH_DEL(symbol_table, s);
    free(s->name);
    s->func_fields.func_body = NULL;
    free_simple_symbol_node(s->func_fields.symbols);
    free(s);
  }
}

int main (int argc, char **argv){
  int print_table = 0;
  int print_tree = 0;

  if(argc > 1 && !strcmp(argv[1], "-t")){
    print_table = 1;
  }

  if(argc > 1 && !strcmp(argv[1], "-tt")){
    print_table = 1;
    print_tree = 1;
  }

  utstring_new(tac_code[0]);
  utstring_printf(tac_code[0], ".code\n");

  yyparse();
  yylex_destroy();

  if(!has_error && print_table) print_symbol_table();
  if(!has_error && print_tree) print_syntax_tree();
  free_symbol_table();
  free_syntax_tree(syntax_tree);

  for (int i = 0; i < 3; ++i){
    printf("%s", utstring_body(tac_code[i]));
  }

  return 0;
}