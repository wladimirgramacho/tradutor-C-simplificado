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


{COND}                                          { printf("Lex: %-35s (conditional keyword)\n", yytext); mvcol(yyleng); }
{TYPE}                                          { printf("Lex: %-35s (type keyword)\n", yytext); mvcol(yyleng); }
{LOOP}                                          { printf("Lex: %-35s (loop keyword)\n", yytext); mvcol(yyleng); }
{RETURN}                                        { printf("Lex: %-35s (return keyword)\n", yytext); mvcol(yyleng); }

{OPENPAR}                                       { printf("Lex: %-35s (open parentheses)\n", yytext); mvcol(yyleng); }
{CLOSEPAR}                                      { printf("Lex: %-35s (close parentheses)\n", yytext); mvcol(yyleng); }
{OPENBRA}                                       { printf("Lex: %-35s (open brackets)\n", yytext); mvcol(yyleng); }
{CLOSEBRA}                                      { printf("Lex: %-35s (close brackets)\n", yytext); mvcol(yyleng); }
{OPENCURL}                                      { printf("Lex: %-35s (open curly braces)\n", yytext); mvcol(yyleng); }
{CLOSECURL}                                     { printf("Lex: %-35s (close curly braces)\n", yytext); mvcol(yyleng); }
<STRING>{OPENSTRINT}                            {
                                                  printf("Lex: %-35s (open string interpolation)\n", yytext);
                                                  BEGIN(0);
                                                  mvcol(yyleng);
                                                }
<INITIAL,STRING>{QUOTES}                        {
                                                  printf("Lex: %-35s (quotes)\n", yytext);
                                                  if(inside_string) { BEGIN(0);inside_string--; }
                                                  else              { BEGIN(STRING);inside_string++; }
                                                  mvcol(yyleng);
                                                }
{COLON}                                         { printf("Lex: %-35s (colon)\n", yytext); mvcol(yyleng); }
{ADDOP}                                         { printf("Lex: %-35s (addop)\n", yytext ); mvcol(yyleng); }
{MULOP}                                         { printf("Lex: %-35s (mulop)\n", yytext ); mvcol(yyleng); }
{EQ}                                            { printf("Lex: %-35s (equal operator)\n", yytext ); mvcol(yyleng); }
{RELOP}                                         { printf("Lex: %-35s (conditional operator)\n", yytext ); mvcol(yyleng); }

{NUM}+                                          { printf("Lex: %-35d (integer)\n", atoi( yytext )); mvcol(yyleng); }
<STRING>{STR}                                   { printf("Lex: %-35s (string)\n", yytext ); mvcol(yyleng); }

{VAR}                                           { printf("Lex: %-35s (identifier)\n", yytext); mvcol(yyleng); }

{COMMENT}                                       { /* eat up one-line comments */ }
{WHITESPACE}                                    { mvcol(yyleng); }
{NEWLINE}                                       { rscol(yyleng); }

.                                               {
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