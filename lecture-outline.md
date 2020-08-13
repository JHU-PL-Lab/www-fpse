# Outline of Lecture Units

## Course Outline

- Just repeat the Syllabus here.

## What is FP?

### History in brief

* Lambda calculus, 1930's - logicians (Church, Turing, Kleene, Curry, etc)
 - Logic proofs are formal constructions
 - Core ideas of functional programming already present
 - But no computers so no running, only hand-calculation
* Lisp, 1960's (McCarthy)
 - Implement the ideas of the mathematicians
 - Goal application space: artificial intelligence programming
 - Added list data to functions: **Lis**t **P**rocessing
* Typed functional languages, 70's & 80's: ML and its descendents Haskell and OCaml
 - Will see what this is in detail as we use OCaml
* Modern era: add FP as possibility in mainstream: Python, JavaScript, Java, C++, etc.
* FP now edging out OO school in some domains.

### Imperative vs OO vs FP

* Oversimplifying but these are the three modern schools
* More oversimplifying: "Imperative = C, OO = Java, FP = OCaml"
 - other languages can also be put in schools, but these are leading representatives today
 
### Imperative

* Imperative also has functions, but functions often have side effects (e.g. mutate some shared data structures)
* C has function pointers but they are not widely used and lack needed expressiveness (which we will cover).

### O-O

* Objects tend to have "their" state encpsulated within their boundary
* Still it is usually a mutable state - change over time
* A function is something like an object with one method, `call`, and with no fields
* That doesn't fully capture higher-order functions which is why `lambda` added to Jave.

### Functional

* Key aspect is lack of mutation: more like a mathematical function, the output only depends on the input and it's only output is the codomain value, not any side effects like printing, mutating, raising exceptions, etc.
* Lack of side effects is called "referential transparency" - variable values don't change out from under you (like in math textbook).
* Standard data structures not too different from imperative case: dictionaries, lists, etc, but often will themselves be non-mutable
* Key advantage is higher-order-ness: code is data, make new functions, accept functions as parameters.
* Allows for powerful new programming paradigms.  give examples like compose, map, etc.
* Less good at supporting extension, no notion of subclass in common functional paradigms (not impossible to add though).

### Who wins?
Thesis:
* Imperative wins for low-level code: underlying machine instructions are in the imperative domain, will run faster.
* O-O wins for super large apps with fairly shallow logic: UI's, many apps, etc.
* Functional wins for complex algorithms with deep inner logic
 - Gets too confusing with mutation, and better composition of functions makes code easier to understand.
* Of course this choice is never made in a vacuum: existing codebases and libraries, programmer experience, etc. 
 
 
## Introduction to OCaml
High-level outline of how PLI version needs to evolve
* utop and `Core` from the get-go: = on ints only but pop into `Poly` when convenient.
* Lots of List.blah early on, including folds, pipes, etc.
* add in all of the syntax stuff below that I skipped in PLI
* Many more real examples of programs, get further away from the toy stuff.

#### Basic Functional Programming in OCaml
* Basic OCaml
    - elementary `ocaml`, `utop`, `.ocamlinit` file
    - expressions, let, functions, lists, pattern matching, higher-order functions
    - Lists lists lists, folds, pipes etc.

##### New stuff not in PLI for Basic OCaml now.
* @@ application
* _ - all the places it works
* pipelining
* Pipelining for functional data construction - `List.([] |>  cons 1 |> cons 2 |> cons 3 |> cons 4)` (notice it makes it in reverse).  similar to message chaining of OOP.
* `let rec sum = function | [] -> ..` (needs function not fun)
* Minimal commands for dune, .ocamlinit, top loop.  Basically fixed recipes to start with.
* let is a special application - needed for monads later
* = on ints only by default with `Base`.  `String.(=)` etc explicitly for other base types.  Or cheat with `open Poly` (restores original OCaml polymorphic `=` which is dangerous)
* Named and optional and optional/w/default function arguments, punning with f ~x (x is both var at caller and name in callee), similar as pun in definition of function).  RWOC covers well.
* Operators as functions and making your own infix syntax - `let (^^) x y = x * y` kind of thing.  see RWOC prefix and infix operators.
* `begin`/`end` to replace parens
* effects done later, not in earlier HWs anyway.

### Data structures (variants and records)
This is mostly covered in RWOC chapters on variants and records.

* Basic records and variants stuff obviously
* Advanced patterns - `p when e`, `'a' .. 'z'`, `as x`, or `|` patterns in let, `{x;y}` is same as `{x=x;y=y}`...  Cornell 3.1.7
* Polymorphic variants aka anonymous variants - Cornell 3.2.4.4, RWOC variants chapter
* See RWOC chapters on variants and records for lots of new conventions and examples.
* record field name punning - RWOC Ch5
* `let r' = { r with x = ..; y = }`  for changing just a few fields - RWOC 5
* Embedding record declarations in variants - like named args on variant fields:
`type gbu = | Good of { sugar : string; } | Bad of { spice: string; } | Ugly`

### Types
* Type inference
* Extensible variants - OCaml manual 8.14
* Equality on and Pretty printing declated data types with `ppx_deriving`
* Type-driven development - very important topic to touch on somewhere; fits well with GADTS.

### Modules
- elemts of structures, functors; hit on more advanced stuff later
- type abstraction, module signatures
- Simple whole programs, basic dune building and testing -- see `code/set_example` .. might want to change to use `In_Channel` to just read in the numbers, see RWOC for some boilerplate for that at end of the tour.. includes basic dune etc.



### Side effects

#### Mutation
* Standard mutation topics: ref, mutable records, arrays.  Printing earlier - ?
* sequencing; `ignore(3+4); print_string "hi"` to avoid warnings.  Cornell 8.3
* `==` vs `=` - Cornell 8.6
* Mutable stack eg - Cornell 8.8; get a Base alternative example, e.g. `Hashtbl` (see libraries)
* Weakly polymorphic types `‘_a` - Cornell 8.8 (save details on this for advanced types below?)

#### Exceptions
See RWOC Error/Exceptions chapter.
* lack of exception effects in types is old-fashioned.  Using option types or Ok/Error is often better.
* `match f x with exception _ -> blah | ...` shorthand syntax

#### I/O and Stdio
* Basic printing
* `Stdio`
    - Channels, etc

#### Libraries
Do libraries with modules as the `Core` modules need understanding of functors, abstraction, etc

* [`Core`](https://ocaml.janestreet.com/ocaml-core/latest/doc/core/index.html)
    - Lists in Base - RWOC 1 a bit (tour) and RWOC 3.  Worth covering, lots of important functions available.
    - `Map` (and `List.Assoc` a bit).  RWOC 13.
    - `Hashtbl`, good example of mutable code.  RWOC 13

* Command line parsing - RWOC ch14
* JSON data - RWOC ch15

### Build/Package/Test in Ocaml

#### Dune
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

#### Basic Documentation and Testing 
* Principles of testing
    - black box and glass box testing.  Cornell Ch7
* `ocamldoc`comments, Cornell 2.3.7
* `OUnit` unit testing library Cornell 3.1.3

### Idiomatic Functional Programming
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
* Type-aided extension: add a type to a variant, then clean up on the type error messages.
    - Applies to many other contexts as well: make a change, chase type errors.  Type errors gone => code works.
* Go through some imperative to functional code refactorings
* The expression problem and functional vs OO trade-off.


### Specification

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

### Orphan Topics
* Streams and laziness - Cornell 12.1
* Memoization - RWOC Imperative chapter, Cornell 12.4
 

### Advanced modules
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

### Advanced Types

* Weak polymorphism
* Covariant types `+'a t = ...` - declares contents are not mutable so can be fully polymorphic not weakly.  RWOC weak polymorphism section.
* GADTS - see PLII lecture notes.    Make sure to discuss with type-driven development
* New Jane street extensions: [higher-kinded types](https://github.com/janestreet/higher_kinded/) and [accessors](https://github.com/janestreet/accessor) which are like Haskell lenses.


### Advanced Testing
See [draft RWOC chapter](https://github.com/realworldocaml/book/tree/master/book/testing)

* Along with `OUnit` may also want to do `ppx_inline_tests` or whatever it is called.  RWOC using it.. Only problem is it is not working with 4.10 and utop.
* `Bisect` for code coverage. Cornell 7.4
* Automated test generation aka randomized testing aka fuzz testing, `QCheck`.  Cornell 7.7-7.9

 
### Monads and monad-likes

#### Monad Warm-up
* `Option.bind` in base, also let%bind for that.. RWOC Error Handling chapter
* State passing and exception encoding - PLII notes
* CPS
* Async library and promises - Cornell 12.2 or RWOC 14.  Leaning to Async.

#### Monads proper.

* Monads.  PLII notes for all the monad topics.
* Monad laws.
* Monad transormers (or, skip?)
* Monad programming.  Need to decide what libraries/bindings to use.  Jane Street has `Base.Monad` and `ppx_let`, or use `let*` now. unclear.  I don't think Jane street library has transformers?
* Comprehension.. need to research this.  See `map` in `Base.Monad` stuff.

### Metaprogramming: ppx extensions
* See RWOC ch23 (not written yet unfortunately).
* Tutorial at http://rgrinberg.com/posts/extension-points-3-years-later/
* [`ppx_jane`](https://github.com/janestreet/ppx_jane) (comparison, hash, conversion between S-Expr), 
* [`ppx_let`](https://ocaml.janestreet.com/ocaml-core/latest/doc/ppx_let/index.html).

### Under the hood of functional language runtimes
* Substitution notion of running functions and `let` - informal PLI stuff.
* Tail recursion Cornell 3.1.1.5.  
* Garbage collection
* Efficiency of functional vs mutable data structures.  Some in Ch9 Cornell.
* RWOC has a chapter on this, also on GC, maybe do a peek at that (not much though)

### FP in other languages

-   JavaScript, [React hooks](https://reactjs.org/docs/hooks-intro.html), and [ReasonReact](https://reasonml.github.io/reason-react/)
-   Python
-   Java lambdas
- Elm
  

#### Top level directives (not sure where to put this, just my own reference for now)
* `#directory adir` - adds `adir` to the list of directories to search for files.
* `#trace afun` - calls and returns to `afun` will now be dumped to top level - a simple debugging tool.
* `#use "afile.ml"` - loads code file as if it was copied and pasted into the top loop.
* `#mod_use` - like `#use` but loads the file like it was a module (name of file as a module name)
* `#load "blah.cmo"`,`#load "blahlib.cma"` - load a compiled binary or library file.
* `#show` - shows the type for an entity (variable or module).
* `#require` - loads a library (does not `open` it, just loads the module)
* `#use_output "dune top"` - like the shell `xargs` command - run a command and assume output is top loop input commands.
