/* scanner for simplified C language with support to string operations */
%option noyywrap
%option yylineno

%{
#include <string.h>

#define RESET      "\033[0m"
#define RED        "\033[31m"             /* Red */
#define BOLDGRAY   "\033[1m\033[38m"      /* Bold Gray */

typedef struct symbol {
  char type[30];
  char name[200];
  int address;
  struct symbol *next;
} symbol;

typedef struct error {
  char name[400];
  struct error* next;
} error;

int inside_string = 0;
int column_number = 1;
char input_filename[0xFFF];
symbol *symbol_table = (symbol*)0;
error *errors= (error*)0;
char* currentType;
int address = 0;

void push_symbol(char *sym_name){
  symbol *aux = (symbol*) malloc(sizeof(symbol));
  strcpy(aux->name, sym_name);
  strcpy(aux->type, currentType);
  aux->address = address;
  aux->next = symbol_table;
  address++;
  symbol_table = aux;
}

symbol* find_symbol( char * sym_name){
  symbol *aux = symbol_table;
  while(aux!= NULL){    
    if(strcmp(aux->name, sym_name) == 0){
      return aux; 
    }
    aux = aux->next;
  }
  return 0;
}

void print_symbol_table(){
  symbol *aux = symbol_table;
  printf("Type\t Name\t\t Address\n");
  while(aux!= NULL){
    printf("%-8s %-15s %d\n", aux->type, aux->name, aux->address);
    aux = aux->next;
  }
}

void push_error(error **list, char *error_name){
  error *aux = (error*) malloc(sizeof(error));
  strcpy(aux->name,error_name);
  aux->next = (*list);
  (*list) = aux;
}

void print_errors(error **list){
  error *aux = *list;
  while(aux!= NULL){    
    printf("%s\n", aux->name);
    aux = aux->next;
  }
  printf("\n");
}

int list_length(error **list){
  int length = 0;
  error *aux = *list;

  while(aux!= NULL){    
    aux = aux->next;
    length++;
  }
  return length;
}

void push_symbol_table(char * sym_name){
  symbol* s = find_symbol(sym_name);
  if(!s){
    push_symbol(sym_name);
  }
}

void lex_print(char * str){
  printf("Lex: %-35s (%s)\n", yytext, str);
}

void mvcol(){
  column_number += yyleng;
}

void rscol(){
  column_number = 1;
}

void add_token(char * token){
  // lex_print(token);
  mvcol();
}

void error_message(){
  printf(RED "error:" RESET);
  printf(" unrecognized char %s\n", yytext);
  printf("\t from ");
  printf(BOLDGRAY "%s:%d:%d\n" RESET, input_filename, yylineno, column_number);
}

void print_color_red(){
  printf("%s", RED);
};
void print_color_end(){
  printf("%s", RESET);
};

%}

%s STRING

letter        [a-zA-Z]
digit         [0-9]

ID            {letter}({letter}|{digit})*
NUM           {digit}{digit}*
STR           (\\.|[^"#{}\\])*

IDENTIFIER    {ID}({OPENBRA}{NUM}{CLOSEBRA})?

COND          if|else

TYPE          int|string|void
LOOP          while
RETURN        return

ADDOP         "+"|"-"
MULOP         "*"|"/"
EQ            "="
CEQ           "=="
CNE           "!="
CLT           "<"
CLE           "<="
CGT           ">"
CGE           ">="
RELOP         {CEQ}|{CNE}|{CLT}|{CLE}|{CGT}|{CGE}

OPENPAR       "("
CLOSEPAR      ")"
OPENBRA       "["
CLOSEBRA      "]"
OPENCURL      "{"
CLOSECURL     "}"
OPENSTRINT    "#{"
QUOTES        \"
COLON         ";"

COMMENT       "//".*
WHITESPACE    [ \t]+
NEWLINE       "\n"

%%

{COND}                                { add_token("COND"); }
{TYPE}                                { 
                                        currentType = calloc(1, strlen(yytext)+1);
                                        strcpy(currentType, yytext);
                                      }
{LOOP}                                { add_token("LOOP"); }
{RETURN}                              { add_token("RETURN"); }

{OPENPAR}                             { add_token("OPENPAR"); }
{CLOSEPAR}                            { add_token("CLOSEPAR"); }
{OPENBRA}                             { add_token("OPENBRA"); }
{CLOSEBRA}                            { add_token("CLOSEBRA"); }
{OPENCURL}                            { add_token("OPENCURL"); }
{CLOSECURL}                           { add_token("CLOSECURL"); }
<STRING>{OPENSTRINT}                  {
                                        add_token("OPENSTRINT");
                                        BEGIN(0);
                                      }
<INITIAL,STRING>{QUOTES}              {
                                        add_token("QUOTES");
                                        if(inside_string) { BEGIN(0);inside_string--; }
                                        else              { BEGIN(STRING);inside_string++; }
                                      }
{COLON}                               { add_token("COLON"); }
{ADDOP}                               { add_token("ADDOP"); }
{MULOP}                               { add_token("MULOP"); }
{EQ}                                  { add_token("EQ"); }
{RELOP}                               { add_token("RELOP"); }

{NUM}+                                { add_token("INT"); }
<STRING>{STR}                         { add_token("STRING"); }

{IDENTIFIER}                          { push_symbol_table(yytext); add_token("IDENTIFIER"); }

{COMMENT}                             { /* eat up one-line comments */ }
{WHITESPACE}                          { mvcol(yyleng); }
{NEWLINE}                             { rscol(yyleng); }

.                                     {
                                        error_message();
                                        mvcol(yyleng);
                                      }
%%

void main (int argc, char **argv){
  if (argc>0){
    sprintf(input_filename, "%s", argv[1]);
    yyin = fopen(argv[1], "r");
  }
  else {
    yyin = stdin;
  }

  yylex();
  if(list_length(&errors) > 0){
    print_color_red();
    print_errors(&errors);
    print_color_end();
  }
  print_symbol_table();   
}