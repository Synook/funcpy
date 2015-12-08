typedef struct char_stack_struct char_stack_t;
struct char_stack_struct {
  char *value;
  char_stack_t *next;
};

char_stack_t *stack_new();
char *stack_pop(char_stack_t *);
void stack_push(char_stack_t *, char *);
