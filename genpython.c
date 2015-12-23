#include "genpython.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void print_expr(FILE *, expression_t *);
void print_func(FILE *, params_t *, expression_t *, int);
char *transform_name(char *s);
void transform_case(function_t *function);
int is_case(function_t *function);

void genpython(FILE *f, program_t *program) {
  //fprintf(f, "from primitives import *\n");
  do {
    if (program->function != NULL) {
      function_t *function = program->function;
      params_t *params = function->params;
      char *py_name = transform_name(function->name);
      fprintf(f, "%s = ", py_name);
      int do_case = is_case(function);
      if (do_case) {
        transform_case(function);
        fprintf(f, "(lambda %s: ", py_name);
      }
      print_func(f, function->params, function->expression, 1);
      if (do_case) {
        fprintf(f, ")(%s)", py_name);
      }
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
        fprintf(f, "%s = ", transform_name(args->id));
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

void transform_case(function_t *function) {
  expression_t *expression = function->expression;
  expression->func_call->expression->id = "?";
  args_t *false_arg;
  STRUCT_NEW(false_arg, args_t);
  STRUCT_NEW(false_arg->expression, expression_t);
  STRUCT_NEW(false_arg->expression->func_call, func_call_t);
  STRUCT_NEW(false_arg->expression->func_call->expression, expression_t);
  false_arg->expression->func_call->expression->id = function->name;
  params_t *params = function->params;
  args_t *current = NULL;
  while (params != NULL) {
    args_t *new_arg;
    STRUCT_NEW(new_arg, args_t);
    STRUCT_NEW(new_arg->expression, expression_t);
    new_arg->expression->id = params->name;
    if (current == NULL) {
      false_arg->expression->func_call->args = new_arg;
    } else {
      current->args = new_arg;
    }
    current = new_arg;
    params = params->params;
  }
  expression->func_call->args->args->args = false_arg;
}

int is_case(function_t *function) {
  expression_t *expression;
  return (
    (expression = function->expression) != NULL &&
    expression->func_call != NULL &&
    expression->func_call->expression->id != NULL &&
    !strcmp(expression->func_call->expression->id, "case")
  );
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
