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
  literal_t *literal;
  include_t* include;
}

%token ALIAS
%token SEMICOLON
%token LPAREN;
%token RPAREN;
%token LBRACKET;
%token RBRACKET;
%token INCLUDE;
%token COMMA;

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

%%

funcpy:
  program {
    funcpy_program = $1;
  }
  ;

program:
  include program {
    program_t *f = malloc(sizeof(program_t));
    f->include = $1;
    f->function = NULL;
    f->pythonblock = NULL;
    f->program = $2;
    $$ = f;
  }
  |
  function program {
    program_t *f = malloc(sizeof(program_t));
    f->function = $1;
    f->include = NULL;
    f->pythonblock = NULL;
    f->program = $2;
    $$ = f;
  }
  | PYTHONBLOCK program {
    program_t *f = malloc(sizeof(program_t));
    f->function = NULL;
    f->include = NULL;
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
    expression->id = NULL;
    expression->func_call = $2;
    $$ = expression;
  }
  | ID {
    expression_t *expression = malloc(sizeof(expression_t));
    expression->literal = NULL;
    expression->func_call = NULL;
    expression->id = $1;
    $$ = expression;
  }
  | NUMBER {
    literal_t *literal = malloc(sizeof(literal_t));
    literal->value = $1;

    expression_t *expression = malloc(sizeof(expression_t));
    expression->literal = literal;
    expression->func_call = NULL;
    expression->id = NULL;
    $$ = expression;
  }
  | STRING {
    literal_t *literal = malloc(sizeof(literal_t));
    literal->value = $1;

    expression_t *expression = malloc(sizeof(expression_t));
    expression->literal = literal;
    expression->func_call = NULL;
    expression->id = NULL;
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
    expression->id = NULL;
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
    expression_t *expression = malloc(sizeof(expression_t));
    expression->literal = NULL;
    expression->id = NULL;

    expression->func_call = malloc(sizeof(func_call_t));
    expression->func_call->expression = cons_expr;
    expression->func_call->args = malloc(sizeof(args_t));
    expression->func_call->args->expression = $1;
    expression->func_call->args->args = malloc(sizeof(args_t));

    expression->func_call->args->args->expression = malloc(sizeof(expression_t));
    expression->func_call->args->args->expression->id = "emptylist";
    expression->func_call->args->args->expression->literal = NULL;
    expression->func_call->args->args->expression->func_call = NULL;
    expression->func_call->args->args->args = NULL;
    $$ = expression;
  }
  | {
    expression_t *expression = malloc(sizeof(expression_t));
    expression->literal = NULL;
    expression->func_call = NULL;
    expression->id = "emptylist";
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
  cons_expr = malloc(sizeof(expression_t));
  cons_expr->literal = NULL;
  cons_expr->func_call = NULL;
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
