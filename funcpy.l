%option noyywrap

%{
  #include <string.h>
  #include "ast.h"
  #include "funcpy.tab.h"
  #define YY_DECL extern int yylex()
%}

%%

"->" { return ALIAS; }
";" { return SEMICOLON; }
"(" { return LPAREN; }
")" { return RPAREN; }
"[" { return LBRACKET; }
"]" { return RBRACKET; }
"include" { return INCLUDE; }
"," { return COMMA; }
\"([^\"]|[^\\]\\\")*\" {
  yylval.id = strdup(yytext);
  return STRING;
}

[0-9]+(\.[0-9]*)? {
  yylval.id = strdup(yytext);
  return NUMBER;
}

([a-zA-Z][a-zA-Z0-9_']*|[+*/><=?!:-]{1,2}) {
  yylval.id = strdup(yytext);
  return ID;
}

[ \t\n\r]

%%
