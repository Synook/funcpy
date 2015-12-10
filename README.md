# funcpy
A purely functional language that compiles to Python. Basically this works by translating the funcpy functions into many, many Python lambdas. Uses Flex/Bison to do the actual parsing.

To try it out:
```bash
$ make
$ cd fpy
$ ../funcpy test
```

A very short guide to the language:
```
times a b -> (* a b); # required parens and prefix notation
largerThanOne -> (filter (< 1)); # argument omission
timesListByTwo -> (map (\x -> (* x 2))); # lambdas
main -> (dirty_print (timesListByTwo [1,2])); # dirty_print, the only IO for now
```

View `fpy/standard.fpy` for more code and the standard library.

## To do
* List comprehension (not really necessary)
* Pattern matching (not really necessary)
* Guards (not really necessary)
* Better includes (e.g., if can't find .fpy then assume .py exists; search multiple directories, etc.)
* *Monads* - very important. At least an IO interface with stdin/stdout.
* Ideally, some sort of non-functional representation where new types (probably monads) can be defined for file IO, networking or anything that can't be represented functionally.

## Technical details

As mentioned before, the compilation basically involves translating the language into Python lambdas. For example, consider the following code.

```
include standard;
frepeat f v -> (: v (frepeat f (f v)));
main -> (take 3 (frepeat (+ 1) 0));
```

This defines a simple function, `frepeat`, which generates an infinitely long list by recursively applying `f` to the previous element, starting with `v`. For example, `(take 3 (frepeat (+ 1) 0))` will return `[0,1,2]` (`take n` simply returns the first *n* elements of the passed list).

The above line will be compiled by funcpy into the following Python code (newlines added for clarity):

```python
from standard import * # include standard;
fpy_frepeat = lambda: lambda fpy_f: lambda: lambda fpy_v: lambda: (
  (sym_5800()(fpy_v)()(
    (fpy_frepeat()(fpy_f)()((fpy_f()(fpy_v))))
  ))
)() # frepeat f v -> (: v (frepeat f (f v)));
fpy_main = (
  fpy_take()(lit(3))()(
    (fpy_frepeat()((sym_4300()(lit(1))))()(lit(0)))
  )
) # main -> (take 3 (frepeat (+ 1) 0));
if __name__ == '__main__': fpy_main() # (evaluates main)
```

As is evident, `frepeat` simply becomes a sequence of lambda functions representing the arguments to the function. Internally, identifiers are prepended with `fpy_`, while symbols are converted into their ASCII codes and prepended with `sym_`. Also note that literals are wrapped in the `lit` function, making them constant functions of their own (because functional).

### Why so many lambdas?

One thing that may seem odd about the translation is the amount of lambdas generated: five in total for two actual arguments.

```
lambda: lambda fpy_f: lambda: lambda fpy_v: lambda:
```

There is a good reason for this, however. Consider how we might represent this function if writing directly in Python. An immediately obvious approach may be to define it as a single function, with two arguments (assume here `cons` is equivalent to the `:` function):

```python
frepeat = lambda f, v: cons(v, frepeat(f, v))
frepeat(lambda a: a + 1, 0)
```

There are a few problems with this. Most obvious is that this function is not *curried*, and does not support partial application. This can be easily fixed:

```python
frepeat = lambda f: lambda v: cons(v, frepeat(f)(v))
frepeat(lambda a: a + 1)(0)
```

The second problem, however, is more insidious. `frepeat` in theory generates an infinitely long list. This obviously is not a decidable result, however if we pass it to another function that truncates or otherwise only inspects a finite number of elements from the list, then it would still be valid. As defined above, however, this is not going to happen: as soon as both arguments are passed to the function it will immediately try to recurse infinitely, resulting in a stack overflow.

Some method, therefore, of continuing to defer evaluation of the function itself is necessary. This would allow for `frepeat` to reference itself, without evaluating itself immediately. A simple way to achieve this would be to insert an additional lambda at the end, as such:

```python
frepeat = lambda f: lambda v: lambda: (cons(v, frepeat(f)(v)))()
frepeat(lambda a: a + 1)(0)
```

It then becomes the responsibility of the function calling `frepeat` to make the final function call and evaluate the expression. If the function does not need further elements in the list, then it can stop evaluation without recursing infinitely. In fact, `frepeat(lambda a: a + 1)(0)` would not result in any actual evaluation, since it returns a function in itself. Only when that is called finally will the result be computed:

```python
cons = lambda x: lambda xs: lambda: (x, xs)
head = lambda xs: lambda: xs()[0]()
head(frepeat(lambda a: a + 1)(0))() # will result in the evaluation of v, but not even f(v)
```

This causes another problem, however: if we want to partially apply a function, then the `lambda:` at the end becomes an issue. Consider what happens if we define another function, `increaseFrom`, to be `frepeat(lambda a)`. In this case we should be able to partially apply it like below, since frepeat(f) is a function in itself. However, since the compiler doesn't know the arity (number of arguments) for `frepeat`, it will automatically put `()` at the end so the function is evaluated.

```python
increaseFrom = lambda: frepeat(lambda a: a + 1)()
```

This would be incorrect! `frepeat(f)` is supposed to take one argument, and so this will cause a runtime error.

One possible way to get around this would be to insert an extra lambda after *every* argument, to get for example:

```python
frepeat = lambda f: lambda: lambda v: lambda: (cons(v, frepeat(f)(v)))()
```

This would solve the problem described earlier, since we can freely place `()` after every argument given when `frepeat` is called.

What if we, however, now wanted to simply alias frepeat? We would get the line below, because we have no way of telling how many arguments `frepeat` takes: maybe it actually doesn't have any, in which case the `()` would be required as we saw earlier.

```python
actually_frepeat = lambda: frepeat()
```

This would still be incorrect in the `frepeat` case, because the first lambda for the function still takes one argument. Therefore, a lambda is also needed before the first actual argument:

```python
frepeat = lambda: lambda f: lambda: lambda v: lambda: (cons(v, frepeat(f)(v)))()
```

Then, when we want to call `frepeat`, we can simply place `()` before each argument, and the result even after applying all arguments, will still be a function in itself. Responsibility for calling the final `()`, then, is devolved to the body of the calling function, just like before.

```python
increaseFrom = lambda: frepeat()(lambda a: a + 1)() # good
actually_frepeat = lambda: frepeat() # also good (the lambda re-applies the arity-0 function)
actually_frepeat = frepeat # also good (this optimisation is made by the compiler for 0-arity aliases)
head()(frepeat()(lambda a: a + 1)()(0))()
```
