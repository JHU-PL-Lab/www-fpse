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
 * With time the annoyance turns to thanks (we promise!)
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

### Preconditions and Postconditions

* Types are fine for high-level structural information, but cannot express deeper properties.
  - "a function only takes non-negative input"
  - "a function returns a sorted list"
  - etc

Let us consider some preconditions, postconditions, and invariants on the `Simple_set`:

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
* Postcondition on `remove` for it returning set `s'`?  `not(contains x s')` - ??
  - No, this set data structure could be a multiset
  - If we had this postcondition on our spec we would know our implementation failed
* Postcondition on `add x s`: for the resulting set `s'`, `contains x s'` is true

#### Assertions

* `assert` can be placed in code to directly verify properties
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

### Specification and Abstraction

* The better a module is specified the less the users need to know about the underlying implementration
* The built-in `Core.Map` etc types are examples where the users need to know nothing about the implementation
* But they are a bit idealistic as "everyone knows" what an e.g. Map should do
* Still, on your own libraries you can often abstract details behind a rich spec
  - and it will make it a lot easier for users, they can just think about the spec view.

### Formal Verification

* We are not going to focus on this topic as it is not a part of mainstream software engineering (yet)
* But it is getting there and will become more and more common through your careers
* A simple view of what it is is the preconditions/postconditions/invariants/`asserts` above will be **verified** to always hold by a computer program.
  - like how a compiler verifies the type information but on a much grander scale.

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

### Testing and coverage

* Code coverage is a great *glass-box* (impl-based) metric of how good your test suite is
* The simple idea of coverage: are there lines of your code that never get exercised by any of your tests?
* Coverage tools let you easily check this.

### Bisect for OCaml code coverage

* The `bisect_ppx` preprocessor can decorate your code with one hit-bit per line 
  - it can then show which lines are "hit" upon running your test suite
* Add `(preprocess (pps bisect_ppx))` to library or executable declaration in `dune` to decorate
* The do a `dune test` which will generate the low-level hit-lines data in a file.
* Shell command `bisect-ppx-report html` then generates a pretty report showing which lines hit
  - open `_coverage/index.html` in your browser to see the report
* See [Bisect docs](https://github.com/aantron/bisect_ppx) for more details

We will check how well my tests of the simple set example covered the code using Bisect
