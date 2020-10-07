# Lecture Outline

## Advanced modules

* more examples of functors being useful. libraries, etc. Cornell 5.3.2.2, .3

#### More Modules
- high-level discussion of witness stuff.
* `include` - Cornell 5.3.1; 5.3.1.2; subtlety of abstr with it
* General first-class modules - RWOC 10.
* `Comparable` and witnesses
* Type sharing constraints and destructive substitution to deal with too-hidden types.  RWOC Functors chapter.


#### Tangent-ish: The Concept of "First Class Modules" 
[ wrote these notes but decided to save til later ]
* "First class X" in a programming language generally means X is usually not a directly-manipulable data object but it becomes one by making it a first class element.
* Example: in JavaScript message names are first-class, they are just strings.  In Java on the other hand they can't be dynamically created at run-time
* OCaml modules are generally "above" the expressions, they can contain expressions 
    but expressions normally don't contain modules, don't pass them to or return from functions, etc.
* The first-class modules extension lets modules to some degree be treated as regular data.
* Note that you could then use a function in place of a functor sometimes
    - But, first-class modules have some restrictions so use them only when needed
* We are going to make some elementary use of libraries using first-class modules now (e.g. `Map`, `Hashtbl`, etc in `Core`)




### Topics left to hit from early part of outline
* Operators as functions and making your own infix syntax - `let (^^) x y = x * y` kind of thing.  see RWOC prefix and infix operators.
* `begin`/`end` to replace parens
* Advanced patterns - `p when e`, `'a' .. 'z'`, `as x`, or `|` patterns in let...  Cornell 3.1.7


* Command line parsing - RWOC ch14
* JSON data - RWOC ch15


### I/O and Stdio
* Basic printing
* `Stdio`
    - Channels, etc

## Build/Package/Test in Ocaml

### Dune
* Tree nature of dune files
* Defining libraries with `library`
* Defining executables with `executable`
* Using libraries via `libraries` (uses `ocamlfind` in the background)
* etc for other options in `dune` files
* Test executables with `Ounit2`
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
        - Types are a high-level spec on behavior; getting out type errors is progress!
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
 



## Advanced Types

* Weak polymorphism (covered)
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
  
