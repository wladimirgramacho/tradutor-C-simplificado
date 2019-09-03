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

IF            if
ELSE          else
COND_STMT     {IF}{OPENPAR}{CLOSEPAR}{OPENCURL}{STMT_LIST}{CLOSECURL}({ELSE}{OPENCURL}{CLOSECURL})?

STMT_LIST     ({STMT})*
STMT          {EXP_STMT}

EXP_STMT      {EXP}
EXP           {WS}{VAR}" "{EQ}" "{NUM}{WS}

TYPE          int|string|void
LOOP          while
RETURN        return

ADDOP         "+"|"-"
MULOP         "*"|"/"
EQ            "="

OPENPAR       "("
CLOSEPAR      ")"
OPENBRA       "["
CLOSEBRA      "]"
OPENCURL      "{"
CLOSECURL      "}"

COMMENT       "//".*
WS            [ \t\n]+


%%


{TYPE}" "{VAR}\;                                { printf("Lex: %-35s (var declaration)\n", yytext); }
{ID}{OPENPAR}{CLOSEPAR}\;                       { printf("Lex: %-35s (function call)\n", yytext); }
{COND_STMT}                                     { printf("Lex: %-35s (conditional keyword)\n", yytext); }
{TYPE}                                          { printf("Lex: %-35s (type keyword)\n", yytext); }
{LOOP}                                          { printf("Lex: %-35s (loop keyword)\n", yytext); }
{RETURN}                                        { printf("Lex: %-35s (return keyword)\n", yytext); }

{NUM}+                                          { printf("Lex: %-35d (integer)\n", atoi( yytext )); }
{ID}                                            { printf("Lex: %-35s (identifier)\n", yytext ); }

\"{STRING}\"                                    { printf("Lex: %-35s (string)\n", yytext ); }

{ADDOP}                                         { printf("Lex: %-35s (addop)\n", yytext ); }
{MULOP}                                         { printf("Lex: %-35s (mulop)\n", yytext ); }

{COMMENT}                                       { /* eat up one-line comments */ }

{WS}                                            { /* eat up whitespace */ }

.                                               { printf( "Unrecognized character: %s\n", yytext ); }
%%


int main() {
  yylex();
}