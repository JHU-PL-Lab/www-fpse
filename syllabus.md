## Syllabus

This is the preliminary list of proposed lecture topics and readings. See the [dateline](dateline.html) for what we actually end up doing as the course evolves.

### Intro to Functional Programming in OCaml
* History and background
* Basic OCaml coding with simple data, lists, and functions
* Basic OCaml library usage
* Basic build tool usage

### The Full OCaml Feature Set
* Data structures
* Types and type inference
* Modules and Functors
* Side effects: Mutation, Exceptions, I/O and the `Stdio` library
* Libraries from Jane Street's [`Base`](https://ocaml.janestreet.com/ocaml-core/latest/doc/base/index.html): `Map`, `Hashtbl`, etc.
* Defining Comparisions

### The Modern OCaml Ecosystem
* Building projects with `dune`
* Documenting projects with `ocamldoc`
* Principles of testing;  `ounit` testing

### Idiomatic Functional Programming
* Refactoring functional programs to be more idiomatic (modular / separation of concerns)
* Type-directed programming, type-aided extension and debugging
* Comparing different programming models: OO vs Imperative vs FP; the expression problem

### Specifying Programs
* Specifying properties of programs
    - Referential transparency
    - Abstract interfaces
* Invariants
    - Data structure Invariants, recursive function invariants

###  Advanced OCaml Features
* Advanced modules: nested modules, first-class modules, writing functors
* Advanced types: weak polymorphism, covariant types, GADTs, etc.

### Advanced Testing
* Code coverage, `Bisect`
* Automated test generation aka property-based testing, `QCheck`

### Monads

#### Monads Warm-up
* State passing and exception encoding
* The continuation-passing style (CPS) transformation
* The `Async` library and promises

#### Monads proper
* Monads, monad laws
* Monad programming 

### Metaprogramming: ppx extensions

### Under the hood of functional language runtimes

#### FP in other languages

-   JavaScript, [React hooks](https://reactjs.org/docs/hooks-intro.html), and [ReasonReact](https://reasonml.github.io/reason-react/)
-   Python
-   Java lambdas
- Elm

##  Resources

* [Real World OCaml 2nd Edition](https://dev.realworldocaml.org/toc.html)
* [Cornell book](https://www.cs.cornell.edu/courses/cs3110/2020sp/textbook/)
* [Awesome OCaml](https://github.com/ocaml-community/awesome-ocaml)
