# funcpy
A purely functional language that compiles to Python. Basically this works by translating the funcpy functions into many, many Python lambdas. Uses Flex/Bison to do the actual parsing.

To try it out:
```
$ make
$ cd examples
$ ../funcpy test
```

## To do
* Includes
* Comments
* List comprehension
* Pattern matching
* Guards
* *Monads* - very important. At least an IO interface with stdin/stdout.
* Ideally, some sort of non-functional representation where new types (probably monads) can be defined for file IO, networking or anything that can't be represented functionally.
