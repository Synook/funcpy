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
