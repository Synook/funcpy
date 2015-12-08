#include "genpython.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void print_expr(expression_t *);
void print_literal(literal_t *);
char *transform_name(char *s);

void genpython(program_t *program) {
  printf("from primitives import *\n");
  do {
    function_t *f = program->function;
    params_t *params = f->params;
    printf("%s = ", transform_name(f->name));
    while (params != NULL) {
      printf("lambda %s: ", transform_name(params->name));
      params = params->params;
    }
    if (f->params != NULL) printf("lambda: ");
    print_expr(f->expression);
    if (f->params != NULL) printf("()");
    printf("\n");

  } while ((program = program->program));
  printf("fpy_main()\n");
}

void print_expr(expression_t *expr) {
  if (expr->literal == NULL) {
    if (expr->func_call->args != NULL) printf("(");
    printf("%s", transform_name(expr->func_call->name));
    args_t *args = expr->func_call->args;
    while (args != NULL) {
      printf("(");
      print_expr(args->expression);
      args = args->args;
      printf(")");
    }
    if (expr->func_call->args != NULL) printf(")");
  } else {
    print_literal(expr->literal);
  }
}

void print_literal(literal_t *literal) {
  printf("lit(%s)", literal->value);
}

char *transform_name(char *s) {
  if ((s[0] < 'A' || s[0] > 'Z') && (s[0] < 'a' || s[0] > 'z') && strlen(s) <= 2) {
    char *new = malloc(9);
    new[7] = '\0';
    sprintf(new, "sym_%02i%02i", s[0], s[1]);
    return new;
  } else {
    char *new = malloc(strlen(s) + 5);
    new[strlen(s) + 4] = '\0';
    sprintf(new, "fpy_%s", s);
    return new;
  }

}
