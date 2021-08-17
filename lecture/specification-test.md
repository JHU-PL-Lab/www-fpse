## Specification

* Let us step back from syntax and look at the bigger picture

* Specification: *what* the program should do
* Implementation: *how* it does it

### Why specify?

* You have to have at least some idea what your goal is before you start coding
* The more clear that goal is, the better chance you will make it

### Degrees of specification

* Requirements and Design documents: high-level informal descriptions of what the app should do
  - This is the classic form of specification in software engineering; far from code
* Types, e.g. writing an `.mli` file before implementing the code
  - Much more precise than the previous in terms of code/spec relationship, but limited expressiveness
* Tests
  - a test suite constitutes a specification on a finite window of behavior
  - Can be very accurate on the cases listed, but could be woefully incomplete
* Full logical assertions
  - e.g. *precondition* on a function that tree parameter is a binary tree (left values < right values)
  - e.g. *postcondition* that `List.sort` always returns a sorted list
  - e.g. *invariants* on data structures such as a `Set` implementation which uses an underlying always-sorted list.
  - More general than tests, but not necessarily verified
* Verified assertions aka formal methods
  - after making the above logical assertions, *verify* the code meets the assertions
  - now this is mostly research, but becoming more mainstream

### Type-directed programming

Fact: types outline the "shape" of the code you need to write and so serve as a "structural" spec.

 * You have been doing type-directed programming, perhaps getting very annoyed whilst
   - With time the annoyance turns to thanks (we promise!)
 * Principle is: just to write code matching declared (or even inferred) type will get you well on the way to an implementation
   - type errors point to code errors to be fixed
   - when the last type error drops, the code will often directly work

Review example: not bubbling up `option` or other wrapped results properly

```ocaml
# let zadd l1 l2 = let l = List.zip l1 l2 in List.map ~f:(fun (x,y) -> x+y) l;;
Line 1, characters 74-75:
Error: This expression has type ('a * 'b) list List.Or_unequal_lengths.t
       but an expression was expected of type 'c list
```
 - To solve this type error you will need to `match` on the result

Review example: with partial parameters applied, remainder types hint at what is needed.

```ocaml
let l = [[3;3]; [4;4]; 22;17] in
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

Adding a `Gre` for green party:

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

Let us consider some preconditions and postconditions on the `Simple_set`:

```ocaml
module Simple_set_functor (M: Eq) = 
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
* Stronger precondition: `contains x s` must hold
* Postcondition on `remove` for it returning set `s'`:  `not(contains x s')` - ??
  - No, this set data structure could be a multiset and this will not always hold!
  - If we had this postcondition on our spec we would know our implementation failed
* Postcondition on `add x s`: for the resulting set `s'`, `contains x s'` is true

#### Assertions

* OCaml `assert` can be placed in code to directly verify properties
  - program dies if the assertion fails, it should always hold
* Example new version of `add` above:
```ocaml
let add (x : M.t) (s : t) = 
  let s' = (x :: s) in assert (contains x s')
```
* Good for development mode, but not after deployment (slows things down)

### Data structure invariants

* It is often the case that there are additional restrictions on values allowed in a data structure type
* Example from `dict` on homework: `is_ordered` must hold for the binary tree.
* Such data structure invariants should be made clear in the code documentation

### Recursion Invariants

* Recursion and other loops (e.g. in fold) is a prime place to assert invariants
* (Even if you don't write them out, *thinking* of the invariants are critical to any recursive program)
* A standard invariant for recursive functions is that the recursive calls return what the outer function expected

```ocaml
let rec rev l = 
  match l with 
  | [] -> []
  | x::xs -> let rxs = rev xs in assert(Poly.(List.rev xs = rev xs)); rxs @ [x]
```
 * This assertion should never fail.
 * Note however that we have to use the built-in `List.rev` to test our version - circular  
 * In general a big issue with specification is it is often hard to give a code-based definition of the spec.
 * So, our main focus is on *partial* specs, give sanity conditions and not complete property

### Invariants over folds etc

* In re-implementing some of the common `List` functions with `fold`s it helps to see invariant
* Folding left (`List.fold`):
   - Suppose we are at some arbitrary point processing the fold;
   - assume accumulation `a` has "the result of the task" for all elements to the left
   - require `~f` to then "do the task" to incorporate the current element `x`
   - also assume `a` is initially `init`
* Folding right: just flip the order the list is walked over in the above

```ocaml
let length l = List.fold ~init:0 ~f:(fun a _ -> a+1) l
let rev l = List.fold ~init:[]  ~f:(fun a x -> x::a) l 
let map ~f l = List.fold_right ~init:[]  ~f:(fun x a -> (f x)::a) l
let filter ~f l = List.fold_right ~init:[] ~f:(fun x a -> if f x then x::a else a) l
```


### Formal Verification

* We are not going to focus on this topic as it is not a part of mainstream software engineering (yet)
* But it is getting there and will become more and more common through your careers
* A simple view of what it is is the preconditions/postconditions/invariants/`asserts` above will be **verified** to always hold by a computer program.
  - Like how a compiler verifies the type information but on a much grander scale.
  - Goal is to do this over a full, not partial, spec.

### Specification and Abstraction

* The better a module is specified the less the users need to know about the underlying implementration
* The built-in `Core.Map` etc types are examples where the users need to know nothing about the implementation
* But they are a bit idealistic as "everyone knows" what an e.g. Map should do
* Still, on your own libraries you can often abstract details behind a rich spec
  - and it will make it a lot easier for users, they can just think about the spec view.

## Testing

* Testing wears two very different but both very useful hats:
  1. Implementation-based: find bugs in code, for example when you change code make sure you didn't break it.
  2. Specification-based: use tests to define and refine what the code should do
* When testing, wear both hats!!
  - Writing tests before fully coding the answer makes the tests serve as your "coding spec"
  - Adding tests for corner cases will flesh out the spec
  - Adding tests covering past bugs will make sure they are caught quickly next time
 * Another way this is phrased: black-box (spec) and glass-box (code-based) testing
  - Black-box tests are those written against the spec
  - Glass-box tests are in the context of bugs in the code and other code properties

### Standard categories of tests
* **Unit testing**: what you have mainly done -- test the small pieces of the app
* **Acceptance testing**: test the bigger pieces.  
  - For example testing your `cloc.exe` on a certain fixed directory tree.
* **Random testing** aka fuzz testing aka monkey testing aka property-based testing aka quickcheck: test on randomly generated inputs in some distribution

### Testing and coverage

* Code coverage is a great *glass-box* (impl-based) metric of how good your test suite is
* The simple idea of coverage: are there lines of your code that never get exercised by any of your tests?
* Coverage tools let you easily check this.
* We will show how the Bisect coverage tool can be used below


## OUnit2

* We have been using `OUnit2` mostly as a black box up to now
* Now we will go through the details, which are in fact very simple
  - There is not much in `OUnit2` per se, if you want something extra just write some higher-order functions to do it
* Here is your standard simple `tests.ml` file, from the simple-set example:

```ocaml
open OUnit2
open Simple_set

let tests = "test suite for rev" >::: [
  "empty"  >:: (fun _ -> assert_equal (emptyset) (emptyset));
  "3-elt"    >:: (fun _ -> assert_equal true (contains 5 (add 5 emptyset) (=)));
  "1-elt nested" >:: (fun _ -> assert_equal false (contains 5 (remove 5 (add 5 emptyset) (=))(=)));
]

let () = run_test_tt_main tests
```

* The infix `>::` operator takes a string (left) and a function with `_` argument (right) and builds a single test
* The `>:::` operator simply takes an OCaml list of the above and builds a test suite
* Then, `OUnit2.run_test_tt_main tests` will run the suite `tests`

#### How the tests run
* The above `tests.ml` file is just defining an executable, like `cloc.ml/exe` on HW2
* Build and run the executable to run the tests
* Here is the dune build file for the simple set tests for example:

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
* There in fact is a shorthand for the above in dune: replace `executable` with `test` and it makes an executable with the above alias to run tests:

```scheme
(test
  (name tests)
  (libraries
    ounit2
    simple_set
  ))
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

### Building test suites with OUnit

* The OUnit philosophy is to use OCaml functions to pull out the repeated code in your suite
* Simple example of testing one function on a bunch of lists:

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
let () = run_test_tt_main s;; (* DON'T actually do this line, runs OK but crashes utop! *)
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

* We will now take a brief pass through the 
OUnit [Overview docs](https://gildor478.github.io/ounit/ounit2/index.html) and [API docs](http://ocaml.github.io/platform-dev/packages/ounit/ounit.2.0.0/doc/oUnit/OUnit2/)
  - Testing if exception that should have been raised was raised: `assert_raises`
  - If you need fixed setup/teardown code bracketing a group of tests: `bracket`
    - useful for large mutable structures or external databases, etc
  - Testing applications (aka acceptance testing): `assert_command` to run your app
    - Really not OCaml-specific, tests input/output of any executable

### Bisect for OCaml code coverage

* The `bisect_ppx` preprocessor can decorate your code with one hit-bit per line 
  - it can then show which lines are "hit" upon running your test suite
* Add `(preprocess (pps bisect_ppx))` to library or executable declaration in `dune` to decorate
* Then do a `dune test` which will generate the low-level hit-lines data in a file.
* Shell command `bisect-ppx-report html` generates a pretty report showing which lines hit
  - open `_coverage/index.html` in your browser to see the report
* See [Bisect docs](https://github.com/aantron/bisect_ppx) for more details

We will check how well my tests of the simple set example covered the code using Bisect

<a name = "quickcheck"></a>
## Base_quickcheck and Random Testing

* Recall we previously discussed random testing: generate random data in a given type to test
* We are now going to go into more details on how to do your own random testing

### Fuzz testing vs Random Testing

* We are focusing on random testing (aka property-based testing) now but fuzz testing also important
* Slogan: "fuzz testing is to acceptance tests as random testing is to unit tests"
  - fuzzers feed in inputs on `stdio` and other input channels to whole app
  - random testers are internally generating random data
* Industry fuzz testers do a lot more more than generate totally random data
  - They may be aware that the string input should fit a particular grammar, e.g. html
  - They may be combined with a coverage tool and work to find random data "covering" all the code


### Base_quickcheck

* Three key algorithms:
  1. Generators, `Quickcheck.Generator` - make random data of desired distribution in given type
  2. Shrinkers, `Quickcheck.Strinker` - if a failing case is discovered, make it smaller
  3. Runner, `Quickcheck.test` etc, which runs some fixed number (10,000 by default) of random tests and shrinks failures.

* We will look at several examples of the `Base_quickcheck` library in action in [quickcheck_examples.ml](../examples/quickcheck_examples.ml)

* [Base_quickcheck docs](https://ocaml.janestreet.com/ocaml-core/latest/doc/base_quickcheck/Base_quickcheck/index.html)
* [Quickcheck docs](https://ocaml.janestreet.com/ocaml-core/latest/doc/core_kernel/Core_kernel/Quickcheck/index.html)

### QCheck for random testing (OLD - we decided to use Jane Street's Quickcheck not QCheck)

* The `QCheck` library lets you easily write random tests

```ocaml
# #require "qcheck";;
# let test =
  QCheck.Test.make ~count:1000 ~name:"list_rev_is_involutive"
   QCheck.(list small_nat)
   (fun l -> List.equal (=) (List.rev (List.rev l)) l);;
# QCheck.Test.check_exn test;;
```
* The novel bit is the `QCheck.(list small_nat)`
* This is specifying that the parameter `l` on the tests will get passed random lists of small natural numbers (i.e. non-negative `int`s)

* OK lets make a bad reverse and repeat.

```ocaml
let bad_rev l = match l with 1::xs -> [] | _ -> List.rev l;;
... (re-enter test above using bad_rev) ...
# QCheck.Test.check_exn test;;
Exception:
test `list_rev_is_involutive` failed on ≥ 1 cases:
[1] (after 9 shrink steps)
```

- this is reporting that it found the error.

### The details

* We will take a run through the [QCheck documentation](https://github.com/c-cube/qcheck)
* It covers how to make random data in your own type, e.g. random trees
* It also covers how to package these up into your OUnit suite
* The full API is [here](https://c-cube.github.io/qcheck/0.15/qcheck-core/QCheck/index.html)

