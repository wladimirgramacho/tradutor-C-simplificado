/* scanner for simplified C language with support to string operations */
%option noyywrap
%option yylineno

%{
#include <stdio.h>
#include <string.h>
#include "wladus.tab.h"

void yyerror(const char *s);
extern int yylineno;

int inside_string = 0;
%}

%s STRING EXP

letter              [a-zA-Z]
digit               [0-9]
identifier          {letter}({letter}|{digit}|_)*
integer             {digit}+
decimal             {digit}+"."{digit}+
str                 (\\.|[^"#{}\\])*
type                int|float|void|string

whitespace          [ \t\n]+
comment             "//".*

eq                  "="

ceq                 "=="
cne                 "!="
clt                 "<"
cle                 "<="
cgt                 ">"
cge                 ">="

plus                "+"
minus               "-"
mult                "*"
div                 "/"
mod                 "%"

quotes              \"
interpol_start      "#{"
interpol_end        "}"

%%

{type}                                { yylval.id = (char *) strdup(yytext); return TYPE; }
"while"                               { return WHILE; }
"if"                                  { return IF; }
"else"                                { return ELSE; }
"return"                              { return RETURN; }
"write"                               { return WRITE; }
"read"                                { return READ; }

<INITIAL,STRING>{quotes}              {
                                        if(inside_string) { BEGIN(0); inside_string--; return QUOTES; }
                                        else              { BEGIN(STRING); inside_string++; return QUOTES; }
                                      }
<STRING>{str}                         { yylval.str = (char *) strdup(yytext); return STR; }
<STRING>{interpol_start}              {
                                        if(inside_string) { BEGIN(EXP); return ITP_START; }
                                        else              { return yytext[0]; }
                                      }
<EXP>{interpol_end}                   {
                                        if(inside_string) { BEGIN(STRING); return ITP_END; }
                                        else              { return yytext[0]; }
                                      }

<INITIAL,EXP>{eq}                     { return EQ; }
<INITIAL,EXP>{ceq}                    { return CEQ; }
<INITIAL,EXP>{cne}                    { return CNE; }
<INITIAL,EXP>{clt}                    { return CLT; }
<INITIAL,EXP>{cle}                    { return CLE; }
<INITIAL,EXP>{cgt}                    { return CGT; }
<INITIAL,EXP>{cge}                    { return CGE; }

<INITIAL,EXP>{plus}                   { return '+'; }
<INITIAL,EXP>{minus}                  { return '-'; }
<INITIAL,EXP>{mult}                   { return '*'; }
<INITIAL,EXP>{div}                    { return '/'; }
<INITIAL,EXP>{mod}                    { return '%'; }


<INITIAL,EXP>{integer}                { 
                                        yylval.str = (char *) strdup(yytext);
                                        return NUM;
                                      }
<INITIAL,EXP>{decimal}                {
                                        yylval.str = (char *) strdup(yytext);
                                        return DEC;
                                      }
<INITIAL,EXP>{identifier}             {
                                        yylval.id = (char *) strdup(yytext);
                                        return ID;
                                      }

<INITIAL,EXP>{whitespace}             {}
{comment}                             {}

.                                     { return yytext[0]; }

%%

int has_error = 0;

void yyerror(const char *s){
  fprintf(stderr, "%d: %s\n", yylineno, s);
  has_error = 1;
}
