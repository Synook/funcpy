%{
  #include <stdio.h>
  #include <stdlib.h>
  #include "ast.h"
  #include "genpython.h"

  // stuff from flex that bison needs to know about:
  extern int yylex();
  extern int yyparse();
  extern FILE *yyin;
  program_t *funcpy_program;

  void yyerror(const char *s);
%}

%union {
	char *id;

  program_t *program;
  function_t *function;
  params_t *params;
  expression_t *expression;
  func_call_t *func_call;
  args_t *args;
  literal_t *literal_struct;
}

%token ALIAS
%token SEMICOLON
%token LPAREN;
%token RPAREN;
%token LBRACKET;
%token RBRACKET;
%token INCLUDE;
%token COMMA;

%token <id> NUMBER
%token <id> ID

%type <program> program funcpy;
%type <function> function;
%type <params> params;
%type <expression> expression;
%type <func_call> func_call;
%type <args> args;
%type <expression> list;

%%

funcpy:
  program {
    funcpy_program = $1;
  }
  ;

program:
  function program {
    program_t *f = malloc(sizeof(program_t));
    f->function = $1;
    f->program = $2;
    $$ = f;
  }
  | {
    $$ = NULL;
  }
  ;

function:
  ID params ALIAS expression SEMICOLON {
    function_t *f = malloc(sizeof(function_t));
    f->name = $1;
    f->params = $2;
    f->expression = $4;
    $$ = f;
  }
  ;

params:
  ID params {
    params_t *params = malloc(sizeof(params_t));
    params->name = $1;
    params->params = $2;
    $$ = params;
  }
  | {
    $$ = NULL;
  }
  ;

expression:
  LPAREN func_call RPAREN {
    expression_t *expression = malloc(sizeof(expression_t));
    expression->literal = NULL;
    expression->func_call = $2;
    $$ = expression;
  }
  | ID {
    func_call_t *func_call = malloc(sizeof(func_call_t));
    func_call->name = $1;
    func_call->args = NULL;

    expression_t *expression = malloc(sizeof(expression_t));
    expression->literal = NULL;
    expression->func_call = func_call;
    $$ = expression;
  }
  | NUMBER {
    literal_t *literal = malloc(sizeof(literal_t));
    literal->value = $1;

    expression_t *expression = malloc(sizeof(expression_t));
    expression->literal = literal;
    expression->func_call = NULL;
    $$ = expression;
  }
  | LBRACKET list RBRACKET {
    $$ = $2;
  }
  ;

list:
  expression COMMA list {
    expression_t *expression = malloc(sizeof(expression_t));
    expression->literal = NULL;
    expression->func_call = malloc(sizeof(func_call_t));
    expression->func_call->name = ":";
    expression->func_call->args = malloc(sizeof(args_t));
    expression->func_call->args->expression = $1;
    expression->func_call->args->args = malloc(sizeof(args_t));
    expression->func_call->args->args->expression = $3;
    expression->func_call->args->args->args = NULL;
    $$ = expression;
  }
  | expression {
    expression_t *expression = malloc(sizeof(expression_t));
    expression->literal = NULL;
    expression->func_call = malloc(sizeof(func_call_t));
    expression->func_call->name = ":";
    expression->func_call->args = malloc(sizeof(args_t));
    expression->func_call->args->expression = $1;
    expression->func_call->args->args = malloc(sizeof(args_t));
    expression->func_call->args->args->expression = malloc(sizeof(expression_t));
    expression->func_call->args->args->expression->literal = NULL;
    expression->func_call->args->args->expression->func_call = malloc(sizeof(func_call_t));
    expression->func_call->args->args->expression->func_call->name = "emptylist";
    expression->func_call->args->args->expression->func_call->args = NULL;
    expression->func_call->args->args->args = NULL;
    $$ = expression;
  }
  | {
    expression_t *expression = malloc(sizeof(expression_t));
    expression->literal = NULL;
    expression->func_call = malloc(sizeof(func_call_t));
    expression->func_call->name = "emptylist";
    expression->func_call->args = NULL;
    $$ = expression;
  }

func_call:
  ID args {
    func_call_t *func_call = malloc(sizeof(func_call_t));
    func_call->name = $1;
    func_call->args = $2;
    $$ = func_call;
  }
  ;

args:
  expression args {
    args_t *args = malloc(sizeof(args_t));
    args->expression = $1;
    args->args = $2;
    $$ = args;
  }
  | {
    $$ = NULL;
  }
  ;

%%

int main(int args, char **argv) {
	do {
		yyparse();
	} while (!feof(yyin));
  genpython(funcpy_program);
}

void yyerror(const char *s) {
	printf("error: %s\n", s);
	// might as well halt now:
	exit(-1);
}
