/* scanner for simplified C language with support to string operations */
%option noyywrap
%option yylineno

%{
#include <stdio.h>
#include <string.h>
#include "c_simplificado.tab.h"

void error();
extern int yylineno;

int inside_string = 0;
%}

%s STRING

letter        [a-zA-Z]
digit         [0-9]

identifier    {letter}({letter}|{digit})*
integer       {digit}+
decimal       {digit}+"."{digit}+
str           (\\.|[^"\\])*
type          ("int"|"float"|"void"|"string")

whitespace    [ \t]+

comment       "//".*

eq            "="
ceq           "=="
cne           "!="
clt           "<"
cle           "<="
cgt           ">"
cge           ">="

quotes        \"

%%

[ \n]                                 { yylineno = yylineno + 1; }
{type}                                { yylval.id = (char *) strdup(yytext); return TIPO; }
"while"                               { return WHILE; }
"if"                                  { return IF; }
"else"                                { return ELSE; }
"return"                              { return RETURN; }

<INITIAL,STRING>{quotes}              {
                                        if(inside_string) { BEGIN(0); inside_string--; }
                                        else              { BEGIN(STRING); inside_string++; }
                                      }
<STRING>{str}                         { return STR; }

{eq}                                  { return EQ; }
{ceq}                                 { return CEQ; }
{cne}                                 { return CNE; }
{clt}                                 { return CLT; }
{cle}                                 { return CLE; }
{cgt}                                 { return CGT; }
{cge}                                 { return CGE; }


{integer}                             { 
                                        yylval.num = atoi(yytext);
                                        return NUM;
                                      }
{decimal}                             {
                                        yylval.dec = atof(yytext);
                                        return DEC;
                                      }

{identifier}                          {
                                        yylval.id = (char *) strdup(yytext);
                                        return ID;
                                      }
";"                                   { return SEMICOLON; }
{whitespace}                          {}
{comment}                             {}

.                                     { return yytext[0]; }

%%

void error(){
  printf("Other input");
}
