/* scanner for simplified C language with support to string operations */
%option noyywrap
%option yylineno

%{
#include <stdio.h>
#include <string.h>
#include "wladus.tab.h"

void error();
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

whitespace          [ \t]+
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

[ \n]                                 { yylineno = yylineno + 1; }
{type}                                { yylval.id = (char *) strdup(yytext); return TIPO; }
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
<STRING>{str}                         { return STR; }
<STRING>{interpol_start}              {
                                        if(inside_string) { BEGIN(EXP); return INTERPOL_START; }
                                        else              { return yytext[0]; }
                                      }
<EXP>{interpol_end}                   {
                                        if(inside_string) { BEGIN(0); return INTERPOL_END; }
                                        else              { return yytext[0]; }
                                      }

<INITIAL,EXP>{eq}                     { return EQ; }
<INITIAL,EXP>{ceq}                    { return CEQ; }
<INITIAL,EXP>{cne}                    { return CNE; }
<INITIAL,EXP>{clt}                    { return CLT; }
<INITIAL,EXP>{cle}                    { return CLE; }
<INITIAL,EXP>{cgt}                    { return CGT; }
<INITIAL,EXP>{cge}                    { return CGE; }

<INITIAL,EXP>{plus}                   { return PLUS; }
<INITIAL,EXP>{minus}                  { return MINUS; }
<INITIAL,EXP>{mult}                   { return MULT; }
<INITIAL,EXP>{div}                    { return DIV; }


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
";"                                   { return SEMICOLON; }
<INITIAL,EXP>{whitespace}             {}
{comment}                             {}

.                                     { return yytext[0]; }

%%

void error(){
  printf("Other input");
}
