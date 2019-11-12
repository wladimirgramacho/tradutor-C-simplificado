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
identifier          {letter}({letter}|{digit})*
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
                                        if(inside_string) { BEGIN(0); return ITP_END; }
                                        else              { return yytext[0]; }
                                      }

<INITIAL,EXP>{eq}                     { yylval.op = (char *) strdup(yytext); return EQ; }
<INITIAL,EXP>{ceq}                    { yylval.op = (char *) strdup(yytext); return CEQ; }
<INITIAL,EXP>{cne}                    { yylval.op = (char *) strdup(yytext); return CNE; }
<INITIAL,EXP>{clt}                    { yylval.op = (char *) strdup(yytext); return CLT; }
<INITIAL,EXP>{cle}                    { yylval.op = (char *) strdup(yytext); return CLE; }
<INITIAL,EXP>{cgt}                    { yylval.op = (char *) strdup(yytext); return CGT; }
<INITIAL,EXP>{cge}                    { yylval.op = (char *) strdup(yytext); return CGE; }

<INITIAL,EXP>{plus}                   { yylval.op = (char *) strdup(yytext); return PLUS; }
<INITIAL,EXP>{minus}                  { yylval.op = (char *) strdup(yytext); return MINUS; }
<INITIAL,EXP>{mult}                   { yylval.op = (char *) strdup(yytext); return MULT; }
<INITIAL,EXP>{div}                    { yylval.op = (char *) strdup(yytext); return DIV; }


<INITIAL,EXP>{integer}                { 
                                        yylval.num = atoi(yytext);
                                        return NUM;
                                      }
<INITIAL,EXP>{decimal}                {
                                        yylval.dec = atof(yytext);
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

void yyerror(const char *s){
  fprintf(stderr, "%d: %s %s\n", yylineno, s, yytext);
}
