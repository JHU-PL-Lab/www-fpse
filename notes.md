

## Extended Syllabus Notes

### Basic OCaml - moved to lecture outline

### Advanced OCaml data structures/types
This is mostly covered in RWOC chapters on variants and records.

* Advanced patterns - `p when e`, `'a' .. 'z'`, `as x`, or `|` patterns in let, `{x;y}` is same as `{x=x;y=y}`...  Cornell 3.1.7
* Polymorphic variants aka anonymous variants - Cornell 3.2.4.4, RWOC variants chapter
* See RWOC chapters on variants and records for lots of new conventions and examples.
* Extensible variants - OCaml manual 8.14
* Pretty printing data with `ppx_deriving`
* GADTS - see PLII lecture notes.  
* Type-driven development - very important topic to touch on somewhere; fits well with GADTS.

* record field name punning - RWOC Ch5
* `let r' = { r with x = ..; y = }`  for changing just a few fields - RWOC 5
* Embedding record declarations in variants - like named args on variant fields:
`type gbu = | Good of { sugar : string; } | Bad of { spice: string; } | Ugly`
* Covariant types `+'a t = ...` - declares contents are not mutable so can be fully polymorphic not weakly.  RWOC weak polymorphism section.
* New Jane street extensions: [higher-kinded types](https://github.com/janestreet/higher_kinded/) and [accessors](https://github.com/janestreet/accessor) which are like Haskell lenses.

* Streams and laziness - Cornell 12.1
* Memoization - RWOC Imperative chapter, Cornell 12.4

### Side effects

#### Mutation
* Standard mutation topics: ref, mutable records, arrays.  Printing earlier - ?
* sequencing; `ignore(3+4); print_string "hi"` to avoid warnings.  Cornell 8.3
* `==` vs `=` - Cornell 8.6
* Mutable stack eg - Cornell 8.8; get a Base alternative example, e.g. `Hashtbl` (see libraries)
* Weakly polymorphic types `‘_a` - Cornell 8.8

#### Exceptions
See RWOC Error/Exceptions chapter.
* lack of exception effects in types is old-fashioned.  Using option types or Ok/Error is often better.
* `match f x with exception _ -> blah | ...` shorthand syntax

#### I/O and Stdio
* Basic printing
* `Stdio`
    - Channels, etc

### Libraries and More Modules

#### Libraries
Do libraries with modules as the `Base` modules need understanding of functors, abstraction, etc

* [`Base`](https://ocaml.janestreet.com/ocaml-core/latest/doc/base/index.html)
    - Lists in Base - RWOC 1 a bit (tour) and RWOC 3.  Worth covering, lots of important functions available.
    - `Map` (and `List.Assoc` a bit).  RWOC 13.
    - `Hashtbl`, good example of mutable code.  RWOC 13

* Command line parsing - RWOC ch14
* JSON data - RWOC ch15

##### Advanced modules
* `include` - Cornell 5.3.1; 5.3.1.2; subtlety of abstr with it
* Nested modules - in RWOC 4.
* First-class modules - RWOC 10.
* `let open List in ..` and `List.(...map....)` syntax
* Anonymous functors:  `module F = functor (M : S) -> ... -> functor (M : S) -> struct  ... end`
* more examples of functors being useful. libraries, etc. Cornell 5.3.2.2, .3
* passing anonymous structs to functors Cornell 5.3.2.3
* `comparator_witness` and comparison in Jane Street modules
* Type sharing constraints and destructive substitution to deal with too-hidden types.  RWOC Functors chapter.

### The Modern OCaml Ecosystem

* `opam`
* `.ocamlinit` - initial loads.  We will include `#use "topfind";; #require "base";; open Base;;`
 - idea is will always assume we did this.
* `topfind`, `ocamlfind`

#### Dune
* Tree nature of dune files
* Defining libraries
* Defining executables
* Test executables with `Ounit2`
* Poking your code in the top loop: `dune utop`, `dune top`, and `#use_output "dune top";;`
* Merlin with dune - basics on configuring to parse libraries used properly, etc.  Cornell 3.1.3.4
* Command line: `dune build`, `dune runtest`, `dune exec`
* Backtracing on error in dune: use `Base`, backtraces turned on by default then.

#### Top level directives (this is just notes)
* `#directory adir` - adds `adir` to the list of directories to search for files.
* `#trace afun` - calls and returns to `afun` will now be dumped to top level - a simple debugging tool.
* `#use "afile.ml"` - loads code file as if it was copied and pasted into the top loop.
* `#mod_use` - like `#use` but loads the file like it was a module (name of file as a module name)
* `#load "blah.cmo"`,`#load "blahlib.cma"` - load a compiled binary or library file.
* `#show` - shows the type for an entity (variable or module).
* `#require` - loads a library (does not `open` it, just loads the module)
* `#use_output "dune top"` - like the shell `xargs` command - run a command and assume output is top loop input commands.

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

### Testing
See [draft RWOC chapter](https://github.com/realworldocaml/book/tree/master/book/testing)

* Principles of testing
    - black box and glass box testing.  Cornell Ch7
* `ocamldoc`comments, Cornell 2.3.7
* `OUnit` unit testing library Cornell 3.1.3\
* May also want to do `ppx_inline_tests` or whatever it is called.  RWOC using it.. Only problem is it is not working with 4.10 and utop.
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
      
## Primary Resources

* [Real World OCaml 2nd Edition](https://dev.realworldocaml.org/toc.html)
* [Cornell book](https://www.cs.cornell.edu/courses/cs3110/2020sp/textbook/)
* [Awesome OCaml](https://github.com/ocaml-community/awesome-ocaml)

Smaller things
* [OCaml Best practices](https://engineering.issuu.com/2018/11/20/our-current-ocaml-best-practices-part-1)
* [Imperative to functional refactoring JavaScript example](https://medium.com/software-craftsman/functional-refactoring-in-javascript-c0fe718f4efb); [another](https://jordaneldredge.com/blog/functional-javascript-learn-by-refactoring/)
* [Try OCaml](https://try.ocamlpro.com) - for early on before people get opam installed.

#### Example programs to study

* [99 problems](https://github.com/MassD/99) - a bunch of short OCaml coding examples.
* [Exercism](https://github.com/exercism/ocaml/tree/master/exercises) - more examples, more broad than the 99 problems ones. [All answers here](https://exercism.io/tracks/ocaml/exercises)

## Course Planning Ideas

* Code critique: get several dozen excellent examples and base feature discussions around them.  Code mentoring in general is a key to learning good programming principles.  Cornell course not so good on this point..
   - Use exercism for shoreter examples of this.  Pick 3-4 of their problems and find several solutions some good some bad.  Can do this early in course.
   
* Project focus ideas: porting existing tools to OCaml.  JSON, whatever.. think of libraries popular for OOSE projects for example.

* Opam jam - we all get together to install it.

### Assignments ideas: see pl-grading repo for all assignment planning 

#### Additional ideas in 8-3-20 discussion 

The expression problem and functional vs OO. (under idiomatic functional programming)

### On-line plans

* give exam but ask them to sign a pledge.
* Make it open book but in a window reasonably large.
* Use break-out rooms for code reviews.

## To Do

### Books etc to absorb

* PLII - go through that again.
* Many Jane Street libraries.

