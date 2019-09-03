/* scanner for simplified C language with support to string operations */
%option noyywrap
%option yylineno

%{
int inside_string = 0;
char input_filename[0xFFF];
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
WS            [ \t\n]+


%%


{COND}                                          { printf("Lex: %-35s (conditional keyword)\n", yytext); }
{TYPE}                                          { printf("Lex: %-35s (type keyword)\n", yytext); }
{LOOP}                                          { printf("Lex: %-35s (loop keyword)\n", yytext); }
{RETURN}                                        { printf("Lex: %-35s (return keyword)\n", yytext); }

{OPENPAR}                                       { printf("Lex: %-35s (open parentheses)\n", yytext); }
{CLOSEPAR}                                      { printf("Lex: %-35s (close parentheses)\n", yytext); }
{OPENBRA}                                       { printf("Lex: %-35s (open brackets)\n", yytext); }
{CLOSEBRA}                                      { printf("Lex: %-35s (close brackets)\n", yytext); }
{OPENCURL}                                      { printf("Lex: %-35s (open curly braces)\n", yytext); }
{CLOSECURL}                                     { printf("Lex: %-35s (close curly braces)\n", yytext); }
<STRING>{OPENSTRINT}                            {
                                                  printf("Lex: %-35s (open string interpolation)\n", yytext);
                                                  BEGIN(0);
                                                }
<INITIAL,STRING>{QUOTES}                        {
                                                  printf("Lex: %-35s (quotes)\n", yytext);
                                                  if(inside_string) { BEGIN(0);inside_string--; }
                                                  else              { BEGIN(STRING);inside_string++; }
                                                }
{COLON}                                         { printf("Lex: %-35s (colon)\n", yytext); }
{ADDOP}                                         { printf("Lex: %-35s (addop)\n", yytext ); }
{MULOP}                                         { printf("Lex: %-35s (mulop)\n", yytext ); }
{EQ}                                            { printf("Lex: %-35s (equal operator)\n", yytext ); }
{RELOP}                                         { printf("Lex: %-35s (conditional operator)\n", yytext ); }

{NUM}+                                          { printf("Lex: %-35d (integer)\n", atoi( yytext )); }
<STRING>{STR}                                   { printf("Lex: %-35s (string)\n", yytext ); }

{VAR}                                           { printf("Lex: %-35s (identifier)\n", yytext); }

{COMMENT}                                       { /* eat up one-line comments */ }
{WS}                                            { /* eat up whitespace */ }

.                                               {
                                                  printf("error: unrecognized char %s\n", yytext);
                                                  printf("\t from %s:%d\n", input_filename, yylineno);
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