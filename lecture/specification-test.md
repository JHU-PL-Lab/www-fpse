## Specification

* Terminology
   - Specification: *what* the program should do
   - Implementation: *how* it does it

* Let us step back and look at the bigger picture of specifying

### Correctness

* The high-level goal is to have software that is "correct"
* There are many levels of interpretation for "correct"
   - Informal spec.: we had some vague idea of what the code should do, wrote it, iteratively addressed feedback of users until bug reports shrunk to very low levels.
   - Semi-formal spec.: Sat down with stakeholders, wrote out a specification document in English with a few pictures/formulas, added some tests to code which affirmed aspects of this spec.
   - Rigorous spec.: Have an unambiguous mathematical notion of what correct behavior should be, write it out as the formal specification, make sure code meets it.
* In practice all of these modes can be fruitful depending on the project and how mission-critical it is.

### Forms of specification

Specifications can range from informal to completely rigorous and unambiguous

* Requirements and Design documents: high-level informal descriptions of what the app should do
  - This is the classic form of specification in software engineering; includes description/pictures/etc but far from code
* Types, e.g. writing an `.mli` file before implementing the code
  - Gives a very rigorous, compiler-checked skeleton for the code; we are doing this for you on the assignments
  - Much more precise than the previous in terms of code/spec relationship, but limited expressiveness
* Tests
  - A test suite constitutes a specification on a finite window of behavior - can't run all infinite cases
  - Can be 100% accurate on the cases tested, but could be woefully incomplete
  - *Coverage* measurements can be used to help close the incompleteness gap somewhat (never fully however)
* Full logical assertions specifying code behavior in terms of math
  - e.g. *precondition* on a function that tree parameter is a binary tree (left values < right values)
  - e.g. *precondition* on a function that tree parameter is a *balanced* binary tree
  - e.g. *postcondition* that `List.sort` always returns a sorted list
  - e.g. *precondition*/*postcondition* on tree `add` function that if the input tree is balanced the output tree will also be.
  - e.g. *invariants* on data structures such as a `Set` implementation which uses an underlying always-sorted list.
  - e.g. *inductive invariants* on recursive algorithms, e.g. assuming that in the body of `reverse` that it works on a shorter list.
  - Logical assertions are more general than tests since they are for *all* inputs
    - but not necessarily verified (but, invariants do guide tests - write tests to verify on lots of examples)
* Verified assertions aka formal methods
  - After making the above logical assertions, *verify* the code meets the assertions using a verification tool
  - Now this is mostly research, but becoming more mainstream

### Type-directed programming

Fact: types outline the "shape" of the code you need to write and serve as a "structural" spec.

 * You have been doing type-directed programming, perhaps getting very annoyed whilst
   - With time the annoyance turns to thanks (we promise!)
 * Principle is: writing code that matches declared type will get you well on the way to an implementation
   - type errors point to code errors to be fixed
   - when the last type error drops, the code may directly work
 * Type-directed programming is 100% rigorous, but is incomplete: types only express *rough shapes* of data 
   - e.g. `int list` is a rough shape compared to "sorted `int list`" but the latter isn't a type in OCaml


#### Type-directed programming examples

Review example: not bubbling up `option` or other wrapped results properly

```ocaml
# let zadd (l1 : int list) (l2 : int list) : (int list) = let l = List.zip l1 l2 in List.map ~f:(fun (x,y) -> x+y) l;;
Line 1, characters 74-75:
Error: This expression has type (int * int) list List.Or_unequal_lengths.t
       but an expression was expected of type 'c list
```
 - To solve this type error you will need to `match` on the result, which should fix both type error and behavior

Review example: with partial parameters applied, remainder types hint at what is needed.

```ocaml
let l = [[3;3]; [4;4]; [22;17]] in
List.map l;;
- : f:(int list -> '_weak1) -> '_weak1 list = <fun>
```
 - The type shows that `f` needs to be a function taking an `int list` as argument.

Review example: the type in an `.mli` file can direct your implementation, e.g. `map` on `dict` example from HW2
```ocaml
val map : ('a -> 'b) -> 'a dict -> 'b dict
```
 - Q: "how can I get a dict of `'b`'s built from a dict of `'a`'s here
 - A: "Use the function from `'a` to `'b` on elements of `'a dict`.


Extension example: add a new field to a record or a new variant case, chase the type errors to patch

```ocaml
type party = Dem | Rep
type voter = { name : string; party: party }
let count_parties (l : voter list) =
  List.fold l ~init: (0,0) 
    ~f:(fun (cd,cr) -> fun {party; _} -> 
     match party with 
     | Dem -> (cd+1, cr)
     | Rep -> (cd, cr+1) );;
```

Adding a `Gre` for green party: first just change the type, and chase errors

```ocaml
type party = Dem | Rep | Gre
type voter = { name : string; party: party }
let count_parties (l : voter list) =
  List.fold l ~init: (0,0) 
    ~f:(fun (cd,cr) -> fun {party; _} -> 
     match party with 
     | Dem -> (cd+1, cr)
     | Rep -> (cd, cr+1) );;
Lines 6-8, characters 5-24:
Warning 8: this pattern-matching is not exhaustive.
Here is an example of a case that is not matched:
Gre
type party = Dem | Rep | Gre
type voter = { name : string; party : party; }
val count_parties : voter list -> int * int = <fun>
```     

- Shows a new `match` case is needed; in process of adding new case it will become clear a triple is also needed
- This example also shows why non-exhaustive pattern matches are bad: errors often lurk

Conclusion: Don't **wrestle** with OCaml's types, *dance* with them

### Preconditions and Postconditions

* Types are fine for high-level structural information, but cannot express deeper properties.
  - "a function only takes non-negative input"
  - "a function returns a sorted list"
  - etc
* Preconditions, postconditions, and invariants allow properties beyond types to be expressed

Let us consider some preconditions and postconditions on the `Simple_set.Make` functor example [(click for zipfile)](../examples/set-example-functor.zip):

```ocaml
module Make (M: Eq) = 
struct
open Core
type t = M.t list
let emptyset : t = []
let add (x : M.t) (s : t) = (x :: s)
let rec remove (x : M.t) (s: t) =
  match s with
  | [] -> failwith "item is not in set"
  | hd :: tl ->
    if M.equal hd x then tl
    else hd :: remove x tl
let rec contains (x: M.t) (s: t) =
  match s with
  | [] -> false
  | hd :: tl ->
    if M.equal x hd then true else contains x tl
end
```

* Precondition on `remove`: `s` is not empty (it would always fail otherwise)
* Stronger precondition on `remove`: `contains x s` must hold
  - could be too strong if caller wants to handle this exception (generally better to avoid exceptions though)
* Postcondition on `remove` for it returning set `s'`:  `not(contains x s')` - ??
  - No, this simple "set" data structure is in fact a multiset and this will not always hold
  - If we had this postcondition on a "real set" spec we would have seen that our implementation failed to meet it
* Postcondition on `add x s`: for the resulting set `s'`, `contains x s'` holds

#### Assertions in code

* OCaml `assert` can be placed in code to directly verify properties
  - program dies if the assertion fails, it should always hold
  - silently returns `()` if it succeeds
* Example new version of `add` above:
```ocaml
let add (x : M.t) (s : t) = 
  let s' = (x :: s) in assert (contains x s'); s'
```
* Good for development mode, but not after deployment (slows things down)
* Generally it is better to make tests to spot-check assertions instead of using `assert`
  - [`ppx_inline_tests`](https://github.com/janestreet/ppx_inline_test) is a library where you can write tests in-line with your code
  - example: `let s_test = .. in let%test_unit "add adds" = assert (contains (add s_test x) x)`
  - inline tests both document invariants and serve as tests: two-for-one!
  - They also allow functions and data structures hidden in a module to be tested
    - one issue with OCaml's modules is the tester module needs to see the local functions in the library module so they need to be made non-local for that - oops!
    - For Assignment 2 we didn't hide the underlying tree type of the dictionary so you could use it in tests

### Data structure invariants

* It is often the case that there are additional restrictions on values allowed in a data structure type
  - for example the "ordered tree" and "balanced tree" examples mentioned above
* Example from `dict` on homework: `is_ordered` must hold for the binary tree.
* Such data structure invariants should be made clear in the code documentation

### Recursion Invariants

* Recursion and other loops (e.g. in `fold`) is a prime place to assert invariants
* (Even if you don't write them out, *thinking* of the invariants are critical to coding recursive programs)
* A standard invariant for recursive functions is that the recursive calls return what the outer function expected

```ocaml
let rec rev l = 
  match l with 
  | [] -> []
  | x::xs -> let rxs = rev xs in assert(Poly.(List.rev xs = rxs)); rxs @ [x]
```
 * Note that we have to use the built-in `List.rev` to test our version - somewhat circular (note `Poly` quick-open lets `=` work on any type)
 * In general a big issue with specification is it is often hard to give a code-based definition of the full spec.
 * So, our main focus is on *partial* specs, give sanity conditions and not complete property

### Invariants over folds as examples

* In re-implementing some of the common `List` functions with `fold`s it helps to think of the invariant
* Folding left (`List.fold`):
   - Suppose we are at some arbitrary point processing the fold;
   - assume accumulation `accum` has "the result of the task" for all elements to the left in the list
   - require `~f` to then "do the task" to incorporate the current element `elt`
   - also assume `accum` is initially `init`
* Folding right: just flip the order the list is walked over in the above

```ocaml
(* invariant for length: accum is length of list up to here *)
let length l = List.fold ~init:0 ~f:(fun accum _ -> accum + 1) l 
(* invariant for rev: accum is reverse of list up to here *)
let rev l = List.fold ~init:[]  ~f:(fun accum elt -> elt::accum) l 
(* invariant for map: accum is f applied to each element of list up to here *)
let map ~f l = List.fold_right ~init:[]  ~f:(fun elt accum -> (f elt)::accum) l
(* etc *)
let filter ~f l = List.fold_right ~init:[] ~f:(fun elt accum -> if f elt then elt::accum else accum) l
```

### Formal Verification

* Formal verification is *proving* the invariants hold (e.g. that `rev` really reverses the list)
* It is of only limited applicability in mainstream SE but will become more common through your careers
* A simple view of what it is is the preconditions/postconditions/invariants/`asserts` above will be **verified** to always hold by a computer program.
  - Like how a compiler verifies type declarations but on a much grander scale.
  - End goal is to do this over a full spec. but verification of partial spec is also good (e.g. dict being a binary tree)

### Specification and Abstraction

* The more completely a module is specified the less the users need to know about the underlying implementration
* The built-in `Core.Map` etc modules are examples where the users need to know almost nothing about the implementation
* Note that *documentation* of the specification in the interface is important; sometimes `Core` is weak there
* On your own libraries you can do the same
  - it will make it a lot easier for your users, they can just think about the spec. view.

## Testing

* Testing wears two very different but very useful hats:
  1. Specification-based: use tests to define and refine what the code should do
  2. Implementation-based: find bugs in code, for example when you change code make sure you didn't break it.
* Moral: when testing, wear both hats
  - Writing tests before fully coding the answer makes the tests serve as your "coding spec"
  - Adding tests for corner cases will flesh out the spec
  - Adding tests covering past bugs will make sure they are caught quickly next time
 * Equivalent terminology you may see: black-box (spec) and glass-box (code-based) testing
  - Black-box tests are those written against the spec
  - Glass-box tests are in the context of bugs in the code and other code properties

### Standard categories of tests
* **Unit testing**: what you have mainly done -- test the small pieces of the app; no I/O testing
* **Acceptance testing**: test the bigger pieces including I/O
  - For example testing your `keywordcount.exe` on a certain fixed directory tree.
* **Random testing** of which there are many types: fuzz testing / monkey testing / property-based testing / quickcheck: 
  - the tests are run on data generated **randomly** from some distribution
  - "quickcheck"ing aka property-based testing is running **unit** tests on randomly generated data (random lists of ints, etc)
  - "fuzz testing" is running **acceptance** tests with random input strings supplied.

### Testing and coverage

* Code coverage is a great *glass-box* (impl-based) metric of how good your test suite is
* The simple idea of coverage: are there lines of your code that never get exercised by any of your tests?
* Coverage tools let you easily check this.
* We will show how the Bisect coverage tool can be used below

## OUnit2

* We have been using the `OUnit2` library mostly as a black box up to now
* Now we will go through the details, which are in fact very simple
  - There is not much in `OUnit2` per se, if you want something extra just write some higher-order functions to do it
* Here is your standard simple `tests.ml` file, from the simple-set example:

```ocaml
open OUnit2
open Simple_set

let tests = "test suite for set" >::: [
  "empty"  >:: (fun _ -> assert_equal (emptyset) (emptyset));
  "3-elt"    >:: (fun _ -> assert_equal true (contains 5 (add 5 emptyset) (=)));
  "1-elt nested" >:: (fun _ -> assert_equal false (contains 5 (remove 5 (add 5 emptyset) (=))(=)));
]

let () = run_test_tt_main tests
```

* The infix `>::` operator takes a string (test name) and a piece of test code under `fun _ ->` (to keep it from running right away) and builds a single test of type `test`:
  ```ocaml
  # let test1 = "simple test" >:: fun _ -> assert_equal (2 :: []) [2];;
    val test1 : test =
    TestLabel ("simple test",
    TestCase (Short, <fun>))
   ```

* The `>:::` operator simply takes a `test list` and builds a test suite (which in fact is just of type `test`)
  ```ocaml
  # let test_suite = "suite now" >::: [test1];;
  val test_suite : test =
  TestLabel ("suite now",
   TestList
    [TestLabel ("simple test",
      TestCase (Short, <fun>))])
  ```
* Then, `OUnit2.run_test_tt_main tests` will run the suite `tests`

#### How the tests run
* The above `tests.ml` file is just defining an executable, like `keywordcount.exe` on HW2
* Build and run the executable to run the tests
* Here a dune build file which would work for the simple set tests for example:

```scheme
(executable
  (name tests)
  (libraries
    ounit2
    simple_set
  ))

; dune rule so command line "dune runtest" (and "dune test") will run tests.
(rule
 (alias runtest)
 (action (chdir %{project_root}
  (run ./test/tests.exe))))
```

- The alias rule also runs the tests after building them
* We in fact use dune shorthand for the above: replace `executable` with `test` and it makes an executable with the above alias to run tests:

```scheme
(test
  (name tests)
  (libraries
    ounit2
    simple_set
  ))
  ```


### Higher-order testing

* If you did unit testing in other languages it looks pretty much like the above
* But in OCaml we can make tests programatically which makes for less code duplication
* Example: lets make a bunch of different tests on the same invariant, that reversing a list twice is a no-op:

```ocaml
# let make_rev_test l = ("test test" >:: (fun _ -> assert_equal(List.rev @@ List.rev l) l));; 
val make_rev_test : 'a list -> test = <fun>
```

```ocaml
let make_rev_suite ll = 
  "suite of rev rev tests" >::: List.map ll ~f:(fun l -> make_rev_test l);;
val make_rev_suite : 'a list list -> test = <fun>
```

```ocaml
let s = make_rev_suite [[];[1;2;3];[2;44;2];[32;2;3;2;1]];;
let () = run_test_tt_main s;; (* DON'T actually do this line in utop, runs but crashes utop! *)
```

* In general you can build an arbitrarily big tree of tests with suites of suites etc
   - As can be seen above, a suite of tests just has type `test`

```ocaml
let s' = "id tests" >::: 
  ["one" >:: (fun _ -> assert_equal (Fn.id 4) 4) ;
   "two" >:: (fun _ -> assert_equal (Fn.id "hello") "hello")];;
let suites = test_list [s;s'];; (* make suite of suites *)
let named_suites = "revrev and Fn.id" >: suites (* any tree of tests can be named *)
```

Here is the type of `test` under the hood (from the docs) which should make clear why the above works:

```ocaml
type test =
| TestCase of test_fun
| TestList of test list
| TestLabel of string * test
```

### Tangent: defining infix operators

* The OUnit infix operators `>::`/`>:::` are just like `+`, `^` etc

```ocaml
# #require "ounit2";;
# open OUnit2;;
# (>::) ;;
- : string -> test_fun -> test = <fun>
# (>:::);;
- : string -> test list -> test = <fun>
```

* There is no magic to this, you can also do it:

```ocaml
utop # let (^^) x y = x + y;;
val ( ^^ ) : int -> int -> int = <fun>
utop # 3 ^^ 5;;
- : int = 8
```
* Note unlike in C++ we are not overloading operators, `^^` only works on two ints now.
* The old version of `^^` for printing just got nuked.
* So, new infix ops are always defined within a module to avoid overlap
* OCaml will eventually have overloading but it is still in the development pipe

### Making actual tests

* We used `assert_equal` above which is the OUnit function to check things being equal
* `assert_bool` which is like the `assert` OCaml command: `assert_bool "name that test" (0=0)` for example
* If you want to verify some code raises an exception, use `assert_raises`
* To perform acceptance testing (I/O), use `assert_command` to run a shell command and compare against output
* If you need fixed setup/teardown code bracketing a group of tests to setup e.g. files: `bracket_tmpfile`

As always, see the documentation for more details: 
OUnit [API docs](https://ocaml.org/p/ounit2/latest/doc/index.html)

### Bisect for OCaml code coverage

* The `bisect_ppx` preprocessor can decorate your code with one hit-bit per line 
  - it can then show which lines are "hit" upon running your test suite
* Add `(preprocess (pps bisect_ppx))` to library or executable declaration in `dune` to decorate
* Then do a `dune test` which will generate the low-level hit-lines data in a file.
* Shell command `bisect-ppx-report html` generates a pretty report showing which lines hit
  - open `_coverage/index.html` in your browser to see the report
* See [Bisect docs](https://github.com/aantron/bisect_ppx) for more details
* Note that if you have lines of code that you know should not be run (e.g. invariants that should not fail) you can put `[@@@coverage off]` on them.

We will check how well my tests of the simple set example covered the code using Bisect

## Testing executables
* `OUnit` can be used to test executables: `OUnit2.assert_command` can run a shell command (e.g. your OCaml executable)
* `dune` also contains an extension called `cram` which allows for output to be compared against expected output for a given input
* It is very general, you just specify the shell command to run (can test non-OCaml just as easily)
* We will super-briefly skim the [`cram` docs](https://dune.readthedocs.io/en/stable/tests.html#cram-tests)


<a name = "quickcheck"></a>
## Base_quickcheck and Random Testing
### The big picture of random testing

  0. Suppose we have one function `f` that we want to test.
  1. We need to be able to generate random data which is the parameters of `f`
  2. We run `f` on different random data many times (say 100 or 10000 times)
  3. We need to know if the test worked or not on the random data
     - So, tests usually verify that invariants hold or some bad exception not raised etc.
     - This is another reason invariants are good, they are properties that can be quickchecked
### Using `Base_quickcheck`

* `Base_quickcheck` contains three key algorithms:
  1. Generators, `Quickcheck.Generator` - make random data of desired distribution in given type
  2. Shrinkers, `Quickcheck.Shrinker` - if a failing case is discovered, try to make it smaller (we will not cover these in detail)
  3. Runner, `Quickcheck.test` etc, which runs some fixed number (10,000 by default) of random tests and shrinks failures.

* We will look at several examples of the `Base_quickcheck` library in action in [quickcheck_examples.ml](../examples/quickcheck_examples.ml)

* [Base_quickcheck docs](https://ocaml.org/p/base_quickcheck/v0.15.0/doc/Base_quickcheck/index.html)
* The [Real World OCaml](https://dev.realworldocaml.org/testing.html#property-testing-with-quickcheck) book has a short tutorial (note it uses `ppx_inline_tests` and not `OUnit2`)


### Fuzz testing vs Quickcheck

* We are focusing on quickchecking (aka property-based testing) now but fuzz testing also important
* Fuzz testing is to acceptance tests as quickcheck is to unit tests
  - fuzzers feed in inputs on `stdio` and other input channels to whole app
  - quickcheckers are internally generating random data
* Industry fuzz testers do a lot more more than generate totally random data
  - They may be aware that the string input should fit a particular grammar, e.g. html
  - They may be combined with a coverage tool and work to find random data "covering" all the code
