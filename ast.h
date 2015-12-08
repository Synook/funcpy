#ifndef FUNCPY_AST_H
#define FUNCPY_AST_H

typedef struct program_struct program_t;
typedef struct function_struct function_t;
typedef struct params_struct params_t;
typedef struct expression_struct expression_t;
typedef struct func_call_struct func_call_t;
typedef struct args_struct args_t;
typedef struct literal_struct literal_t;

struct program_struct {
  function_t *function;
  program_t *program;
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
  literal_t *literal;
};

struct func_call_struct {
  char *name;
  args_t *args;
};

struct args_struct {
  expression_t *expression;
  args_t *args;
};

struct literal_struct {
  char *value;
};

#endif
