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

View `fpy/standard.fpy` for more code and the standard library, or the [wiki](https://github.com/Synook/funcpy/wiki) for more information.

## Typing

A big problem is typing. In Haskell and similar, polymorphism is obtained by specifying type constraints on functions. This allows function overloading, which is necessary for higher-order functions to work in a type-agnostic manner (e.g., a function which might apply fmap over a functor without knowing what type of functor it is). Such type recognition does not come easily in Python, especially with regard to function types.

Possible solution: function combination. For example, I can define fmap for Maybe as `fmap f v -> (case (type v "Maybe") (? (isa v "Just") (Just (f (get v "value")) Nothing)))`, then we can generate:


 but then if later we have another functor, say `Container`, we can do `fmap f v -> ((case (type v "Container")) (Container (f (get v "value"))))` which will then do (because of the case):
 ```
fmap = lambda: lambda f: lambda: lambda v: lambda: choice()(<expr for case>)()(<expr for container>)()(fmap)()
 ```

Need base case: perhaps a base statement e.g. `fmap: cases;` or similar to indicate such a function.
