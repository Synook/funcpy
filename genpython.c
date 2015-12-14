#include "genpython.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void print_expr(FILE *, expression_t *);
void print_func(FILE *, params_t *, expression_t *, int);
char *transform_name(char *s);

void genpython(FILE *f, program_t *program) {
  //fprintf(f, "from primitives import *\n");
  do {
    if (program->function != NULL) {
      function_t *function = program->function;
      params_t *params = function->params;
      fprintf(f, "%s = ", transform_name(function->name));
      print_func(f, function->params, function->expression, 1);
    } else if (program->pythonblock != NULL) {
      fprintf(f, "%s", program->pythonblock->python);
    } else if (program->include != NULL) {
      fprintf(f, "from %s import *", program->include->filename);
    } else if (program->define != NULL) {
      fprintf(f, "class %s(Type): pass\n", program->define->type);
      define_args_t *args = program->define->define_args;
      while (args != NULL) {
        define_arg_params_t *first_arg_param = args->arg_params;
        define_arg_params_t *arg_param = args->arg_params;
        fprintf(f, "fpy_%s = ", args->id);
        while (arg_param != NULL) {
          fprintf(f, "lambda: lambda %s: ", arg_param->id);
          arg_param = arg_param->arg_params;
        }
        fprintf(f, "lambda: %s('%s'", program->define->type, args->id);
        arg_param = first_arg_param;
        while (arg_param != NULL) {
          fprintf(f, ", %s=%s", arg_param->id, arg_param->id);
          arg_param = arg_param->arg_params;
        }
        fprintf(f, ")\n");
        args = args->define_args;
      }
    }
    fprintf(f, "\n");

  } while ((program = program->program));
  fprintf(f, "if __name__ == '__main__': fpy_main()\n");
}

void print_func(FILE *f, params_t *params, expression_t *expression, int pad) {
  int dummy_lambda = params != NULL && pad;
  while (params != NULL) {
    fprintf(f, "lambda: lambda %s: ", transform_name(params->name));
    params = params->params;
  }
  if (dummy_lambda) fprintf(f, "lambda: (");
  print_expr(f, expression);
  if (dummy_lambda) fprintf(f, ")()");
}

void print_expr(FILE *f, expression_t *expr) {
  if (expr->func_call != NULL) {
    fprintf(f, "(");
    print_expr(f, expr->func_call->expression);
    args_t *args = expr->func_call->args;
    while (args != NULL) {
      fprintf(f, "()(");
      print_expr(f, args->expression);
      args = args->args;
      fprintf(f, ")");
    }
    fprintf(f, ")");
  } else if (expr->lambda != NULL) {
    fprintf(f, "(");
    print_func(f, expr->lambda->params, expr->lambda->expression, 0);
    fprintf(f, ")");
  } else if (expr->literal != NULL) {
    fprintf(f, "lit(%s)", expr->literal);
  } else {
    fprintf(f, "%s", transform_name(expr->id));
  }
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
