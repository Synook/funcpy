#include "genpython.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void print_expr(FILE *, expression_t *);
void print_literal(FILE *, literal_t *);
char *transform_name(char *s);

void genpython(FILE *f, program_t *program) {
  //fprintf(f, "from primitives import *\n");
  do {
    if (program->function != NULL) {
      function_t *function = program->function;
      params_t *params = function->params;
      fprintf(f, "%s = ", transform_name(function->name));
      while (params != NULL) {
        fprintf(f, "lambda %s: ", transform_name(params->name));
        params = params->params;
      }
      if (function->params != NULL) fprintf(f, "lambda: ");
      print_expr(f, function->expression);
      if (function->params != NULL) fprintf(f, "()");
    } else if (program->pythonblock != NULL) {
      fprintf(f, "%s", program->pythonblock->python);
    } else {
      fprintf(f, "from %s import *", program->include->filename);
    }
    fprintf(f, "\n");

  } while ((program = program->program));
  fprintf(f, "if __name__ == '__main__': fpy_main()\n");
}

void print_expr(FILE *f, expression_t *expr) {
  if (expr->literal == NULL) {
    if (expr->func_call->args != NULL) fprintf(f, "(");
    fprintf(f, "%s", transform_name(expr->func_call->name));
    args_t *args = expr->func_call->args;
    while (args != NULL) {
      fprintf(f, "(");
      print_expr(f, args->expression);
      args = args->args;
      fprintf(f, ")");
    }
    if (expr->func_call->args != NULL) fprintf(f, ")");
  } else {
    print_literal(f, expr->literal);
  }
}

void print_literal(FILE *f, literal_t *literal) {
  fprintf(f, "lit(%s)", literal->value);
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
