#include <stdlib.h>
#include "stack.h"

char_stack_t *stack_new() {
  char_stack_t *stack = malloc(sizeof(char_stack_t));
  stack->value = NULL;
  stack->next = NULL;
  return stack;
}

char *stack_pop(char_stack_t *stack) {
  if (stack != NULL && stack->next != NULL) {
    char *value = stack->next->value;
    char_stack_t *next_next = stack->next->next;
    free(stack->next);
    stack->next = next_next;
    return value;
  } else {
    return NULL;
  }
}
void stack_push(char_stack_t *stack, char *value) {
  char_stack_t *new = stack_new();
  new->value = value;
  new->next = stack->next;
  stack->next = new;
}
