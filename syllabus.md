## Syllabus

This is the preliminary list of proposed lecture topics and readings. See the [dateline](dateline.html) for what we actually end up doing as the course evolves.

### Intro to Functional Programming in OCaml
* History and background
* Basic OCaml coding with simple data, lists, and functions
* The `List` library and combinatorial programming
* Variants
* Programming with persistent data structures
* Records
* Elementary modules (`struct`, `sig`, existential types) 
* Side effects: state, exceptions, I/O, mutable data structure libraries
* More modules: functors, first-class modules, `include`, more data structure libraries

### Specification
* Specifying program behavior
* Type-directed programming
* Pre- and post-conditions, `assert`
* Data structure invariants
* Reasoning about programs by induction

### Testing
* Review of testing principles
* Unit testing with `OUnit2`
* Code coverage with `Bisect`
* Random testing with `Base_quickcheck`

### Idiomatic Functional Programming
* Functional programming principles: concision, modularity, avoiding effects
* Functional programming idioms: DRY, interfaces, combinators
* Efficiency in FP
* Idiomatic FP by example: code reviews of well-written OCaml
* OO vs Imperative vs FP; the expression problem

###  Advanced OCaml
* The type sorts of OCaml; Existential types
* Module sharing constraints, first-class modules
* Phantom types
* GADTs

### Encoding effects with monads

* Implicit state threading with persistent data structures
* Implicit exception encoding with `Ok/Error`
* Officially encoding exceptions: the exception monad
* The monad laws
* Using the exception monad: syntactic sugar, examples
* More monads and their uses: I/O, state, nondeterminism
* Asynchronous programming with Lwt

### Algebraic Effects (aka the mother of all effects)
* Multicore OCaml's `effect` and `continue`/`discontinue`
* Encoding control effects with the MOAF: coroutines, generators, promises, asynchronous I/O
* Control effects code reviews

### Multicore Programming
* Multicore OCaml threads, channels, async/await, etc.

## OCaml Tools and miscelanea 
(Smaller topics injected as tangents or for self-study)

* Visual Studio Code's OCaml Platform
* `utop` and top-level directives
* `dune`
* Making standalone OCaml executables
* Basic `ppx` extensions (`deriving` etc)
* Optional and named function arguments
* Advanced pattern matching formats
* `|>` and `@@` syntax

##  Resources

* [Real World OCaml 2nd Edition](https://dev.realworldocaml.org/toc.html) - a comprehensive book focusing on the software engineering side of OCaml
* [Learn OCaml](https://ocaml-sf.org/learn-ocaml-public/) - a series of online exercises to teach yourself OCaml

## Related course materials
* [Cornell CS3110 book](https://www.cs.cornell.edu/courses/cs3110/2020sp/textbook/) - book used in a sophomore-level course on functional programming
* [Advanced Functional Programming](https://www.cl.cam.ac.uk/teaching/1718/L28/) - a course taught at Cambridge focusing on the deeper principles behind modern OCaml.
* [Functional Programming](https://www.cs.princeton.edu/courses/archive/fall21/cos326/schedule.php) - a course taught at Princeton focusing more on program correctness.

## Meta-resources
* [Awesome OCaml](https://github.com/ocaml-community/awesome-ocaml) - a curated list of OCaml resources
* [Ocaml.org](https://ocaml.org) - the central clearinghouse for all things OCaml, includes lists of [tutorials](https://ocaml.org/learn/tutorials/), [books](https://ocaml.org/learn/books.html), and [videos](https://ocaml.org/community/media.html).