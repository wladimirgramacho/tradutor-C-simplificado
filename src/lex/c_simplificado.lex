/* scanner for simplified C language with support to string operations */
%option noyywrap
%{
%}

letter        [a-zA-Z]
digit         [0-9]

ID            {letter}({letter}|{digit})*
NUM           {digit}{digit}*
STRING        (\\.|[^"#{}\\])*

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
{COLON}                                         { printf("Lex: %-35s (colon)\n", yytext); }
{ADDOP}                                         { printf("Lex: %-35s (addop)\n", yytext ); }
{MULOP}                                         { printf("Lex: %-35s (mulop)\n", yytext ); }
{EQ}                                            { printf("Lex: %-35s (equal operator)\n", yytext ); }
{RELOP}                                         { printf("Lex: %-35s (conditional operator)\n", yytext ); }


{NUM}+                                          { printf("Lex: %-35d (integer)\n", atoi( yytext )); }
\"{STRING}\"                                    { printf("Lex: %-35s (string)\n", yytext ); }

{VAR}                                           { printf("Lex: %-35s (identifier)\n", yytext); }

{COMMENT}                                       { /* eat up one-line comments */ }

{WS}                                            { /* eat up whitespace */ }

.                                               { printf( "Unrecognized character: %s\n", yytext ); }
%%


int main() {
  yylex();
}