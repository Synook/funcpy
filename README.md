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
