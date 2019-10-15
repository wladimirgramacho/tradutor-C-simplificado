/* scanner for simplified C language with support to string operations */
%option noyywrap
%option yylineno

%{
#include <stdio.h>
#include <string.h>
#include "c_simplificado.tab.h"

void error();
%}

letter        [a-zA-Z]
digit         [0-9]

identifier    {letter}({letter}|{digit})*
number        {digit}+
whitespace    [ \t\n]+
type          ("int"|"float"|"void"|"string")

comment       "//".*

eq            "="
ceq           "=="
cne           "!="
clt           "<"
cle           "<="
cgt           ">"
cge           ">="

%%

{type}                                { yylval.id = (char *) strdup(yytext); return TIPO; }
"while"                               { return WHILE; }
"if"                                  { return IF; }
"else"                                { return ELSE; }
"return"                              { return RETURN; }

{eq}                                  { return EQ; }
{ceq}                                 { return CEQ; }
{cne}                                 { return CNE; }
{clt}                                 { return CLT; }
{cle}                                 { return CLE; }
{cgt}                                 { return CGT; }
{cge}                                 { return CGE; }


{number}                              { 
                                        yylval.num = atoi(yytext);
                                        return NUM;
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
