
# Outline of Lecture Units

## Intro to OCaml

Installing: see [the Coding page](https://pl.cs.jhu.edu/fpse/coding.html) for install instructions and lots of other information

### The Ecosystem via Hello World in OCaml

In a file `helloworld.ml` type

```ocaml
let hw = "hello"^" world"
```
* Paste into `ocaml` then in `utop`
* Save file in new directory, `ocamlc helloworld.ml`
* `./a.out` to run
* Nothing happens?  Because executables only interact by I/O (think Java, C, etc)
* Re-write to add 
```ocaml
print_string hw
```
* recompile and run: we get some output!

#### Building and running with Dune

* In same directory, add a file `dune`:
```scheme
(executable
  (name helloworld)
  (modules helloworld)
)
```
* This is the build file, like a `Makefile`.
* Now, type `dune build` to compile a standalone program like we did above.
* Then, run with `dune exec ./helloworld`

#### Adding a Library

* Lets make printing less primitive: use a `Core` library function, `printf`
* Replace printing with line `Core.printf "the string is %s\n" hw`
* Try building - gives an error
* Add line `(libraries core)` to dune file to fix
* Compile and run

#### Exploring Basic Data in the top loop

* We will use the `utop` top loop; the classic version is `ocaml` which has fewer bells and whistles
* See [the Coding page](https://pl.cs.jhu.edu/fpse/coding.html) to install `utop`.  Note you need to also set up an `.ocamlinit` file as per that page
* All the following are typed as input into `utop` with `;;` ending input.

 
* Integers
```ocaml
3 + 4;;
let x = 3 + 4;; (* give the value a name via let keyword. *)
let y = x + 5;; (* can use x now *)
let z = x + 5 in z - 1;;
```

#### Boolean operations

```ocaml
let b = true;;
b && false;;
true || false;;
1 = 2;; (* = not == for equality comparison *)
1 <> 2;;  (* <> not != for not equal *)
```

#### Other basic data -- see documentation for details
```ocaml
4.5;; (* floats *)
4.5 +. 4.3 (* operations are +. etc not just + which is for ints only *)
30980314323422L;; (* 64-bit integers *)
'c';; (* characters *)
"and of course strings";;

```
#### Simple functions on integers

To declare a function `squared` with `x` its one parameter.  `return` is  implicit.
```ocaml
let squared x = x * x;; 
squared 4;; (* to call a function -- separate arguments with S P A C E S *)
```
 *  OCaml has no `return` statement; value of the whole body-expression is what gets returned
 *  Type is automatically **inferred** and printed as domain `->` range
 *  OCaml functions in fact take only one argument - !  multiple arguments can be encoded by a trick (later)

#### Fibonacci series example - `0 1 1 2 3 5 8 13 ...` 

Let's write a well-known function with recursion

```ocaml
let rec fib n =     (* the "rec" keyword needs to be added to allow recursion *)
  if n <= 0 then 0
  else if n = 1 then 1
  else fib (n - 1) + fib (n - 2);; (* notice again everything is an expression, no "return" *)

fib 10;; (* get the 10th Fibonacci number *)
```

#### Anonymous functions

* Key to FP: functions are just expressions; put them in variables, pass and return from other functions, etc.
* Similar to lambdas in Python, Java, C++, etc - all are based on the lambda calculus *)

```ocaml
let add1 x = x + 1;; (* normal add1 definition *)
let funny_add1 = (function x -> x + 1);; (* "x" is argument here *)
funny_add1 3;;
(funny_add1 4) + 7;; 
((function x -> x + 1) 4) + 7;; (*  a "->" function is an expression and can be used anywhere *)
((fun x -> x + 1) 4) + 7;; (*  shorthand notation -- cut off the "ction" *)
```

* Multiple arguments - just leave spaces between multiple arguments

```ocaml
let add x y = x + y;;
add 3 4;;
(add 3) 4;; (* same meaning as previous application -- two applications, " " associates LEFT *)
let add3 = add 3;; (* No need to give all arguments at once!  Type of add is int -> (int -> int) - "CURRIED" *)
add3 4;;
add3 20;;
```

Conclusion: add is a function taking an integer, and returning a **function** which takes ints to ints.
So, add is a **higher-order function**: it either takes a function as an argument, or returns a function as result.

Observe `int -> int -> int` is parenthesized as `int -> (int -> int)` -- unusual **right** associativity

Be careful on operator precedence with this goofy way that function application doesn't need parens!
```ocaml
add3 (3 * 2);;
add3 3 * 2;; (* NOT the previous - this is the same as (add3 3) * 2 - application binds tighter than * *)
add3 @@ 3 * 2;; (* LIKE the original - @@ is like the " " for application but binds LOOSER than other ops *)
```

### Simple Structured Data Types: Option and Result

* Before getting into "bigger" data types and how to declare our own, let's use one of the simplest structured data types, the built-in `option` type.

```ocaml
Some 5;;
- : int option = Some 5
```

* all this does is "wrap" the 5 in the `Some` tag

```ocaml
None;;
- : 'a option = None
```

 * Notice these are both in the `option` type .. either you have `Some` data or you have `None`.
 * This type is very useful; here is a simple example.

 ```ocaml
# let nice_div m n = if n = 0 then None else Some (m / n);;
val nice_div : int -> int -> int option = <fun>
# nice_div 10 0;;
- : int option = None
# nice_div 10 2;;
- : int option = Some 5
```

There is a downside with this though, you can't just use `nice_div` like `/`:

```ocaml
# (nice_div 5 2) + 7;;
Line 1, characters 0-14:
Error: This expression has type int option
       but an expression was expected of type int
```

This type error means the `+` lhs should be type `int` but is a `Some` value so is not an `int`.

Here is a non-solution to that:
 ```ocaml
# let not_nice_div m n = if n = 0 then None else m / n;;
Line 1, characters 47-52:
Error: This expression has type int but an expression was expected of type
         'a option
```
- The `then` and `else` branches must return the same type, here they do not.

#### Pattern matching first example

Here is a real solution to the above issue:
```ocaml
# match (nice_div 5 2) with 
   | Some i -> i + 7 (* i is bound to the result, 2 here *)
   | None -> failwith "This should never happen, we divided by 2";;
- : int = 9
```
* This shows how OCaml lets us *destruct* option types, via the `match` syntax.
* `match` is similar to `switch` in C/Java/.. but is much more flexible in OCaml
* LHS in OCaml can be a general pattern
* Note that we turned `None` into an exception via `failwith`.

#### Result

An "even nicer" version of the above would be to use the `result` type, which is very similar to option.
```ocaml
# let nicer_div m n = if n = 0 then Error "Divide by zero" else Ok (m / n);;
val nicer_div : int -> int -> (int, string) result = <fun>
```
* The `result` type is explicitly intended for this case of failure-result
    - `Ok` means the normal result
    - `Error` is the error case, which unlike none can include failure data.
* Again we can do the same kind of pattern match on `Ok/Error` as above.
* This is a "more well-typed" version of the C approach of returning `-1` or `NULL` to indicate failure.

```ocaml
# match (nicer_div 5 2) with 
   | Ok i -> i + 7
   | Error s -> failwith s;;
- : int = 9
```

Lastly, the function could itself raise an exception

```ocaml
let div_exn m n = if n = 0 then failwith "divide by zero is bad!" else m / n;;
div_exn 3 4;;
```

Which has the property of not needing a match on the result.

### Lists

Lists are pervasive in OCaml; easy to create and manipulate

```ocaml
let l1 = [1; 2; 3];;
let l2 = [1; 1+1; 1+1+1];;
let l3 = ["a"; "b"; "c"];;
let l4 = [1; "a"];; (* errors - All elements must have same type - HOMOGENEOUS *)
let l5 = [];; (* empty list *)
```

#### Building lists 

Lists are represented internally as BINARY TREES with left child a leaf.
```ocaml
0 :: l1;; (* "::" is 'consing' an element to the front - fast *)
0 :: (1 :: (2 :: (3 :: [])));; (* equivalent to the above *)
[1; 2; 3] @ [4; 5];; (* appending lists - slower *)
let z = [2; 4; 6];;
let y = 0 :: z;;
z;; (* Observe z itself did not change -- lists are immutable in OCaml *)
```

#### Destructing Lists with pattern matching

```ocaml
let rec rev l =
  match l with
  |  [] -> []
  |  x :: xs -> rev xs @ [x]
;;
rev [1;2;3];; (* = 1 :: ( 2 :: ( 3 :: [])) *)
```

* Correctness of a recursive function by induction: assume recursive call does what you expect in arguing it is overall correct.
* For this example, can assume `rev xs` always reverses the tail of the list.
* Given that fact, `rev xs @ [x]` should clearly reverse the whole list.
* QED, the function is proved correct! (actually partially correct, it could also loop forever)

#### Immutable Data Structures in Functional Programming

* By default, data structures are immutable
* A change is instead implemented as rebuilding the whole list from scratch
* This style of programming: "Data structure corresponds to control flow"

Example: zero out all the negative elements in a list of numbers.


#### Introduction to OCaml notes
High-level outline of how PLI version needs to evolve
* utop and `Core`/`Base` from the get-go: = on ints only but pop into `Poly` when convenient.
* Lots of List.blah early on, including folds, pipes, etc.
* add in all of the syntax stuff below that I skipped in PLI
* Many more real examples of programs, get further away from the toy stuff.
* Type-directed programming basics early
* Need to decide on modality, either feeding into top loop or dune.  Problem is VSCode needs a dune build to get merlin file set up properly, it is hard to have files loaded that give errors.

#### Basic Functional Programming in OCaml
* Basic OCaml
    - elementary `ocaml`, `utop`, `.ocamlinit` file
    - expressions, let, functions, lists, pattern matching, higher-order functions
    - Lists lists lists, folds, pipes etc.

#### Foundational Libraries I
* Lists in Base - RWOC 1 a bit (tour) and RWOC 3.  Lots of important functions available.
* Fn, Option, Result, etc etc etc Base versions

#### NOTES: New stuff not in PLI for Basic OCaml now.
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

## Data structures (variants and records)
This is mostly covered in RWOC chapters on variants and records.

* Basic records and variants stuff obviously
* `result` type - `Ok` or `Error`.
* Advanced patterns - `p when e`, `'a' .. 'z'`, `as x`, or `|` patterns in let, `{x;y}` is same as `{x=x;y=y}`...  Cornell 3.1.7
* Polymorphic variants aka anonymous variants - Cornell 3.2.4.4, RWOC variants chapter
* See RWOC chapters on variants and records for lots of new conventions and examples.
* record field name punning: `let r = {x;y}` abbreviation - RWOC Ch5
* `let r' = { r with x = ..; y = }`  for changing just a few fields - RWOC 5
* Embedding record declarations in variants - like named args on variant fields:
`type gbu = | Good of { sugar : string; } | Bad of { spice: string; } | Ugly`

## Types
* Type inference
* Extensible variants - OCaml manual 8.14
* Equality on and Pretty printing declated data types with `ppx_deriving`
* Type-driven development - very important topic to touch on somewhere; fits well with GADTS.

## Modules
- Structures and functors; look at the `Core` libraries to see what we need to cover, need to at least be users of things like `include`, nested modules, first-class modules, etc (whatever Core uses in particular).  Idea is to start out as writers of basic modules and users of the fancier stuff, and learn how to write the fancier stuff later.
- type abstraction, module signatures

## Basic Development
(Could do this a bit earlier, it is making modules but could skip on that for a bit)

* Simple whole programs, basic dune building and testing -- see `code/set_example` .. might want to change to use `In_Channel` to just read in the numbers, see RWOC for some boilerplate for that at end of the tour.. includes basic dune etc.
* Merlin super basics (can pretty much ignore as dune should build a correct `.merlin` file)

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
