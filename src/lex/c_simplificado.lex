/* scanner for simplified C language with support to string operations */
%option noyywrap
%option yylineno

%{
#include <string.h>

#define RESET      "\033[0m"
#define RED        "\033[31m"             /* Red */
#define BOLDGRAY   "\033[1m\033[38m"      /* Bold Gray */

int inside_string = 0;
int column_number = 1;
char input_filename[0xFFF];


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
  lex_print(token);
  mvcol();
}

void error_message(){
  printf(RED "error:" RESET);
  printf(" unrecognized char %s\n", yytext);
  printf("\t from ");
  printf(BOLDGRAY "%s:%d:%d\n" RESET, input_filename, yylineno, column_number);
}

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
{TYPE}                                { add_token("TYPE"); }
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

{IDENTIFIER}                          { add_token("IDENTIFIER"); }

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
}