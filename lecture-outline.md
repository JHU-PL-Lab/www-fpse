# Lecture Outline

### Near term topics
* side effects, with more and more realistic examples
* Nested modules, top loop vs file modules. (#use doesn't make a module for example #mod_use does though)
* dune utop, #use_output "dune top";; (wrote that in basic-modules, briefly cover it)
* ppx_deriving_json for HW2

### Topics left to hit from early part of outline
* Keep making more real examples of programs!
* Type-directed programming examples would be good
* Operators as functions and making your own infix syntax - `let (^^) x y = x * y` kind of thing.  see RWOC prefix and infix operators.
* `begin`/`end` to replace parens
* Advanced patterns - `p when e`, `'a' .. 'z'`, `as x`, or `|` patterns in let...  Cornell 3.1.7

## Types
* Type inference and weak polymorphism
* Equality on and Pretty printing declated data types with `ppx_deriving`
* Type-driven development - very important topic to touch on somewhere; fits well with GADTS.

## More Modules
- Modules defined in the top loop
- Using that syntax to define nested modules
- include
- first-class modules
- `Core`'s set library
- high-level discussion of witness stuff.



## Side effects

### Mutation
* Standard mutation topics: ref, mutable records, arrays.  Printing earlier - ?
* sequencing; `ignore(3+4); print_string "hi"` to avoid warnings.  Cornell 8.3
* `==` vs `=` - Cornell 8.6
* Mutable stack eg - Cornell 8.8; get a Base alternative example, e.g. `Hashtbl` (see libraries)
* Weakly polymorphic types `‘_a` - Cornell 8.8 (save details on this for advanced types below?)

### Exceptions
See RWOC Error/Exceptions chapter.
* lack of exception effects in types is old-fashioned.  Using option types or Ok/Error is often better.
* `match f x with exception _ -> blah | ...` shorthand syntax

### I/O and Stdio
* Basic printing
* `Stdio`
    - Channels, etc

## Libraries
Do libraries with modules as the `Core` modules need understanding of functors, abstraction, etc

* [`Core`](https://ocaml.janestreet.com/ocaml-core/latest/doc/core/index.html)
    - `Map` (and `List.Assoc` a bit).  RWOC 13.
    - `Hashtbl`, good example of mutable code.  RWOC 13

* Command line parsing - RWOC ch14
* JSON data - RWOC ch15

## Build/Package/Test in Ocaml

### Dune
* Tree nature of dune files
* Defining libraries with `library`
* Defining executables with `executable`
* Using libraries via `libraries` (uses `ocamlfind` in the background)
* etc for other options in `dune` files
* Test executables with `Ounit2`
* Poking your code in the top loop: `dune utop`, `dune top`, and `#use_output "dune top";;`
* Merlin with dune - basics on configuring to parse libraries used properly, etc.  Cornell 3.1.3.4
* Command line: `dune build`, `dune runtest`, `dune exec`
* Backtracing on error in dune: use `Base`, backtraces turned on by default then.

### Basic Documentation and Testing 
* Principles of testing
    - black box and glass box testing.  Cornell Ch7
* `ocamldoc`comments, Cornell 2.3.7
* `OUnit` unit testing library Cornell 3.1.3

## Idiomatic Functional Programming
* A major theme of the course
* design patterns (OO) = idioms (FP)
* Contrasting OO with functional - state machine vs pipeline of data (data-oriented design). Look into doing this earlier in the class.
* Refactoring also applies to FP.
    - pull out duplicate code as its own function parameter, or inline if gratuitous
    - Divide one function into two if it is doing two different things
    - Make code more parametric (or less if not needed)
    - Rename
    - Lift or hide (demote) functions/variables
    - Inline definition or converse - inline let definitions if simple, make more if too complex
    - Move around reponsibilties, make more modular by putting fewer things in public interface
    - Type refactoring - remove unneeded things, generalize (make polymorphic or GADT)
    - Module refactoring - pull out code into a new module, move a function from one module to another.
    - Combinize: replace recursion with maps and folds
    - Use more pattern matching
    - [A list of smells and principles also would be good, many of the above are DRY or "compression-driven development" issues.]
* Type-aided extension: add a type to a variant, then clean up on the type error messages.
    - Applies to many other contexts as well: make a change, chase type errors.  Type errors gone => code works.
* Go through some imperative to functional code refactorings
* The expression problem and functional vs OO trade-off.


## Specification

* Specifying properties of programs
    - Type-directed programming: start out by writing types & module signatures as a skeleton
    - `assert` for more fine-grained properties not expressible with types
    - Referential transparency
    - Abstract interfaces: white box vs gray box vs black box (&lt;abst&gt;).  
        - Black box can be bad - like closed-source code.  Really need a read-only notion, you can see the structure if needed.  Too hard now to figure out what is under the hood.

* Invariants
    - Types as (basic) invariants, with an automatic always-running static checker
    - Data structure Invariants - Cornell Representation Invariants, Ch6
    - recursive function invariants
    - representation invariants

## Orphan Topics
* Streams and laziness - Cornell 12.1
* Memoization - RWOC Imperative chapter, Cornell 12.4
 

## Advanced modules
(May need to do some of this earlier)

* `include` - Cornell 5.3.1; 5.3.1.2; subtlety of abstr with it
* Nested modules - in RWOC 4.
* First-class modules - RWOC 10.
* `let open List in ..` and `List.(...map....)` syntax
* Anonymous functors:  `module F = functor (M : S) -> ... -> functor (M : S) -> struct  ... end`
* more examples of functors being useful. libraries, etc. Cornell 5.3.2.2, .3
* passing anonymous structs to functors Cornell 5.3.2.3
* `comparator_witness` and comparison in Jane Street modules
* Type sharing constraints and destructive substitution to deal with too-hidden types.  RWOC Functors chapter.

## Advanced Types

* Weak polymorphism
* Covariant types `+'a t = ...` - declares contents are not mutable so can be fully polymorphic not weakly.  RWOC weak polymorphism section.
* GADTS - see PLII lecture notes.    Make sure to discuss with type-driven development
* New Jane street extensions: [higher-kinded types](https://github.com/janestreet/higher_kinded/) and [accessors](https://github.com/janestreet/accessor) which are like Haskell lenses.


## Advanced Testing
See [draft RWOC chapter](https://github.com/realworldocaml/book/tree/master/book/testing)

* Along with `OUnit` may also want to do `ppx_inline_tests` or whatever it is called.  RWOC using it.. Only problem is it is not working with 4.10 and utop.
* `Bisect` for code coverage. Cornell 7.4
* Property-based testing aka randomized testing aka fuzz testing, `QCheck`.  Cornell 7.7-7.9

 
## Monads and monad-likes

### Monad Warm-up
* `Option.bind` in base, also let%bind for that.. RWOC Error Handling chapter
* State passing and exception encoding - PLII notes
* CPS
* Async library and promises - Cornell 12.2 or RWOC 14.  Leaning to Async.

### Monads proper.

* Monads.  PLII notes for all the monad topics.
* Monad laws.
* Monad transormers (or, skip?)
* Monad programming.  Need to decide what libraries/bindings to use.  Jane Street has `Base.Monad` and `ppx_let`, or use `let*` now. unclear.  I don't think Jane street library has transformers?
* Comprehension.. need to research this.  See `map` in `Base.Monad` stuff.

## Metaprogramming: ppx extensions
* See RWOC ch23 (not written yet unfortunately).
* Tutorial at http://rgrinberg.com/posts/extension-points-3-years-later/
* [`ppx_jane`](https://github.com/janestreet/ppx_jane) (comparison, hash, conversion between S-Expr), 
* [`ppx_let`](https://ocaml.janestreet.com/ocaml-core/latest/doc/ppx_let/index.html).

## Under the hood of functional language runtimes
* Substitution notion of running functions and `let` - informal PLI stuff.
* Tail recursion Cornell 3.1.1.5.  
* Garbage collection
* Efficiency of functional vs mutable data structures.  Some in Ch9 Cornell.
* RWOC has a chapter on this, also on GC, maybe do a peek at that (not much though)

## FP in other languages

-   JavaScript, [React hooks](https://reactjs.org/docs/hooks-intro.html), and [ReasonReact](https://reasonml.github.io/reason-react/)
-   Python
-   Java lambdas
- Elm
  

## Top level directives (not sure where to put this, just my own reference for now)
* `#directory adir` - adds `adir` to the list of directories to search for files.
* `#pwd` - shows current working directory.
* `#trace afun` - calls and returns to `afun` will now be dumped to top level - a simple debugging tool.
* `#use "afile.ml"` - loads code file as if it was copied and pasted into the top loop.
* `#mod_use` - like `#use` but loads the file like it was a module (name of file as a module name)
* `#load "blah.cmo"`,`#load "blahlib.cma"` - load a compiled binary or library file.
* `#show` - shows the type for an entity (variable or module).
* `#show_type` - expands a type definition (if it has an expansion)
* `#require` - loads a library (does not `open` it, just loads the module)
* `#use_output "dune top"` - like the shell `xargs` command - run a command and assume output is top loop input commands.  The particular command `dune top` generates top loop commands to set up libraries and load the current project.
