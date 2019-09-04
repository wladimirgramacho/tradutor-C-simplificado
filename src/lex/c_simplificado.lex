/* scanner for simplified C language with support to string operations */
%option noyywrap
%option yylineno

%{
#define RESET      "\033[0m"
#define RED        "\033[31m"             /* Red */
#define BOLDGRAY   "\033[1m\033[38m"      /* Bold Gray */

int inside_string = 0;
int column_number = 1;
char input_filename[0xFFF];

void mvcol(int length){
  column_number += length;
}

void rscol(){
  column_number = 1;
}

void lex_print(char * str){
  printf("Lex: %-35s (%s)\n", yytext, str);
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

VAR           {ID}({OPENBRA}{NUM}{CLOSEBRA})?

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


{COND}                                { lex_print("conditional keyword"); mvcol(yyleng); }
{TYPE}                                { lex_print("type keyword"); mvcol(yyleng); }
{LOOP}                                { lex_print("loop keyword"); mvcol(yyleng); }
{RETURN}                              { lex_print("return keyword"); mvcol(yyleng); }

{OPENPAR}                             { lex_print("open parentheses"); mvcol(yyleng); }
{CLOSEPAR}                            { lex_print("close parentheses"); mvcol(yyleng); }
{OPENBRA}                             { lex_print("open brackets"); mvcol(yyleng); }
{CLOSEBRA}                            { lex_print("close brackets"); mvcol(yyleng); }
{OPENCURL}                            { lex_print("open curly braces"); mvcol(yyleng); }
{CLOSECURL}                           { lex_print("close curly braces"); mvcol(yyleng); }
<STRING>{OPENSTRINT}                  {
                                        lex_print("open string interpolation");
                                        BEGIN(0);
                                        mvcol(yyleng);
                                      }
<INITIAL,STRING>{QUOTES}              {
                                        lex_print("quotes");
                                        mvcol(yyleng);
                                        if(inside_string) { BEGIN(0);inside_string--; }
                                        else              { BEGIN(STRING);inside_string++; }
                                      }
{COLON}                               { lex_print("colon"); mvcol(yyleng); }
{ADDOP}                               { lex_print("addop"); mvcol(yyleng); }
{MULOP}                               { lex_print("mulop"); mvcol(yyleng); }
{EQ}                                  { lex_print("equal operator"); mvcol(yyleng); }
{RELOP}                               { lex_print("conditional operator"); mvcol(yyleng); }

{NUM}+                                { lex_print("integer"); mvcol(yyleng); }
<STRING>{STR}                         { lex_print("string"); mvcol(yyleng); }

{VAR}                                 { lex_print("identifier"); mvcol(yyleng); }

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