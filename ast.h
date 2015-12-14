#ifndef FUNCPY_AST_H
#define FUNCPY_AST_H

typedef struct program_struct program_t;
typedef struct include_struct include_t;
typedef struct function_struct function_t;
typedef struct params_struct params_t;
typedef struct expression_struct expression_t;
typedef struct func_call_struct func_call_t;
typedef struct args_struct args_t;
typedef struct pythonblock_struct pythonblock_t;
typedef struct lambda_struct lambda_t;
typedef struct define_struct define_t;
typedef struct define_args_struct define_args_t;
typedef struct define_arg_params_struct define_arg_params_t;

struct program_struct {
  function_t *function;
  include_t *include;
  pythonblock_t *pythonblock;
  define_t *define;
  program_t *program;
};

struct define_struct {
  char *type;
  define_args_t *define_args;
};

struct define_args_struct {
  char *id;
  define_arg_params_t *arg_params;
  define_args_t *define_args;
};

struct define_arg_params_struct {
  char *id;
  define_arg_params_t *arg_params;
};

struct pythonblock_struct {
  char *python;
};

struct include_struct {
  char *filename;
};

struct function_struct {
  char *name;
  params_t *params;
  expression_t *expression;
};

struct params_struct {
  char *name;
  params_t *params;
};

struct expression_struct {
  func_call_t *func_call;
  lambda_t *lambda;
  char *literal;
  char *id;
};

struct lambda_struct {
  params_t *params;
  expression_t *expression;
};

struct func_call_struct {
  expression_t *expression;
  args_t *args;
};

struct args_struct {
  expression_t *expression;
  args_t *args;
};

#define STRUCT_NEW(V, T) \
do { V = malloc(sizeof(T)); \
  memset(V, 0, sizeof(T)); \
} while (0)

#endif
