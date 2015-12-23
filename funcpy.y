%{
  #include <stdio.h>
  #include <stdlib.h>
  #include <string.h>
  #include "ast.h"
  #include "genpython.h"
  #include "stack.h"

  // stuff from flex that bison needs to know about:
  extern int yylex();
  extern int yyparse();
  extern FILE *yyin;
  program_t *funcpy_program;
  void parse(FILE *, FILE *);
  char *concat(char *, char *);
  char_stack_t *files;
  expression_t *cons_expr;

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
  include_t* include;
  define_t *define;
  define_args_t *define_args;
  define_arg_params_t *define_arg_params;
}

%token ALIAS
%token SEMICOLON
%token LPAREN;
%token RPAREN;
%token LBRACKET;
%token RBRACKET;
%token INCLUDE;
%token COMMA;
%token LAMBDA;
%token DEFINE;
%token MEMBER;

%token <id> NUMBER;
%token <id> ID;
%token <id> STRING;
%token <id> PYTHONBLOCK;

%type <program> program funcpy;
%type <function> function;
%type <params> params;
%type <expression> expression;
%type <func_call> func_call;
%type <args> args;
%type <expression> list;
%type <include> include;
%type <define> define;
%type <define_args> define_args;
%type <define_arg_params> define_arg_params;

%%

funcpy:
  program {
    funcpy_program = $1;
  }
  ;

program:
  include program {
    program_t *f;
    STRUCT_NEW(f, program_t);
    f->include = $1;
    f->program = $2;
    $$ = f;
  }
  | define program {
    program_t *program;
    STRUCT_NEW(program, program_t);
    program->define = $1;
    program->program = $2;
    $$ = program;
  }
  |
  function program {
    program_t *f;
    STRUCT_NEW(f, program_t);
    f->function = $1;
    f->program = $2;
    $$ = f;
  }
  | PYTHONBLOCK program {
    program_t *f;
    STRUCT_NEW(f, program_t);
    f->pythonblock = malloc(sizeof(pythonblock_t));
    f->pythonblock->python = $1;
    f->program = $2;
    $$ = f;
  }
  | {
    $$ = NULL;
  }
  ;

include:
  INCLUDE ID SEMICOLON {
    include_t *include = malloc(sizeof(include_t));
    char *name = $2;
    include->filename = name;
    stack_push(files, name);
    $$ = include;
  }
  ;

define:
  ID DEFINE define_args SEMICOLON {
    define_t *define;
    STRUCT_NEW(define, define_t);
    define->type = $1;
    define->define_args = $3;
    $$ = define;
  }
  ;

define_args:
  ID define_args {
    define_args_t *define_args;
    STRUCT_NEW(define_args, define_args_t);
    define_args->id = $1;
    define_args->define_args = $2;
    $$ = define_args;
  }
  | LPAREN ID define_arg_params RPAREN define_args {
    define_args_t *define_args;
    STRUCT_NEW(define_args, define_args_t);
    define_args->id = $2;
    define_args->arg_params = $3;
    define_args->define_args = $5;
    $$ = define_args;
  }
  | {
    $$ = NULL;
  }
  ;

define_arg_params:
  ID define_arg_params {
    define_arg_params_t *arg_params;
    STRUCT_NEW(arg_params, define_arg_params_t);
    arg_params->id = $1;
    arg_params->arg_params = $2;
    $$ = arg_params;
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
    expression_t *expression;
    STRUCT_NEW(expression, expression_t);
    expression->func_call = $2;
    $$ = expression;
  }
  | LPAREN LAMBDA params ALIAS expression RPAREN {
    lambda_t *lambda;
    STRUCT_NEW(lambda, lambda_t);
    lambda->params = $3;
    lambda->expression = $5;
    expression_t *expression;
    STRUCT_NEW(expression, expression_t);
    expression->lambda = lambda;
    $$ = expression;
  }
  | ID {
    expression_t *expression;
    STRUCT_NEW(expression, expression_t);
    expression->id = $1;
    $$ = expression;
  }
  | NUMBER {
    expression_t *expression;
    STRUCT_NEW(expression, expression_t);
    expression->literal = $1;
    $$ = expression;
  }
  | STRING {
    expression_t *expression;
    STRUCT_NEW(expression, expression_t);
    expression->literal = $1;
    $$ = expression;
  }
  | LBRACKET list RBRACKET {
    $$ = $2;
  }
  ;

list:
  expression COMMA list {
    expression_t *expression;
    STRUCT_NEW(expression, expression_t);
    expression->func_call = malloc(sizeof(func_call_t));
    expression->func_call->expression = cons_expr;
    expression->func_call->args = malloc(sizeof(args_t));
    expression->func_call->args->expression = $1;
    expression->func_call->args->args = malloc(sizeof(args_t));
    expression->func_call->args->args->expression = $3;
    expression->func_call->args->args->args = NULL;
    $$ = expression;
  }
  | expression {
    expression_t *expression;
    STRUCT_NEW(expression, expression_t);

    expression->func_call = malloc(sizeof(func_call_t));
    expression->func_call->expression = cons_expr;
    expression->func_call->args = malloc(sizeof(args_t));
    expression->func_call->args->expression = $1;
    expression->func_call->args->args = malloc(sizeof(args_t));

    STRUCT_NEW(expression->func_call->args->args->expression, expression_t);
    expression->func_call->args->args->expression->id = "[]";
    expression->func_call->args->args->args = NULL;
    $$ = expression;
  }
  | {
    expression_t *expression;
    STRUCT_NEW(expression, expression_t);
    expression->id = "[]";
    $$ = expression;
  }

func_call:
  expression args {
    func_call_t *func_call = malloc(sizeof(func_call_t));
    func_call->expression = $1;
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
  if (args < 2) {
    printf("error: not enough args\n");
    exit(-1);
  }
  char *name;

  files = stack_new();
  STRUCT_NEW(cons_expr, expression_t);
  cons_expr->id = ":";

  stack_push(files, argv[1]);
  while ((name = stack_pop(files))) {
    printf("%s.fpy -> ", name);
  //printf("%s -> %s\n", argv[1], argv[2]);
    FILE *infile = fopen(concat(name, ".fpy"), "r");
    FILE *outfile = fopen(concat(name, ".py"), "w");
    parse(infile, outfile);
    printf("%s.py\n", name);
  }
	/*do {
		yyparse();
	} while (!feof(yyin));
  genpython(funcpy_program);*/
}

void parse(FILE *infile, FILE *outfile) {
  yyin = infile;
  do {
		yyparse();
	} while (!feof(yyin));
  genpython(outfile, funcpy_program);
}

char *concat(char *a, char *b) {
  char *concated = malloc(strlen(a) + strlen(b) + 1);
  concated[strlen(a) + strlen(b)] = '\0';
  sprintf(concated, "%s%s", a, b);
  return concated;
}

void yyerror(const char *s) {
	printf("error: %s\n", s);
	// might as well halt now:
	exit(-1);
}
