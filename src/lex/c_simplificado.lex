/* scanner for simplified C language with support to string operations */
%option noyywrap
%{
%}

letter        [a-zA-Z]
digit         [0-9]

ID            {letter}({letter}|{digit})*
NUM           {digit}{digit}*
STRING        (\\.|[^"#{}\\])*

COND          if|else
TYPE          int|string|void
LOOP          while
RETURN        return

ADDOP         "+"|"-"
MULOP         "*"|"/"

COMMENT       "//".*
WHITESPC      [ \t\n]+


%%


{TYPE}" "{ID}\;         { printf("Lex: %-35s (var declaration)\n", yytext); }
{COND}                  { printf("Lex: %-35s (conditional keyword)\n", yytext); }
{TYPE}                  { printf("Lex: %-35s (type keyword)\n", yytext); }
{LOOP}                  { printf("Lex: %-35s (loop keyword)\n", yytext); }
{RETURN}                { printf("Lex: %-35s (return keyword)\n", yytext); }

{NUM}+                  { printf("Lex: %-35d (integer)\n", atoi( yytext )); }
{ID}                    { printf("Lex: %-35s (identifier)\n", yytext ); }

\"{STRING}\"            { printf("Lex: %-35s (string)\n", yytext ); }

{ADDOP}                 { printf("Lex: %-35s (addop)\n", yytext ); }
{MULOP}                 { printf("Lex: %-35s (mulop)\n", yytext ); }

{COMMENT}                { /* eat up one-line comments */ }

{WHITESPC}               { /* eat up whitespace */ }
.                       { printf( "Unrecognized character: %s\n", yytext ); }

%%


int main() {
  yylex();
}