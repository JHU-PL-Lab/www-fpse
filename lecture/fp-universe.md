The Functional Programming Language Universe
============================================

* "This is the Dawn of the Age of FP", there are now many FP languages
* There are both viable functional-focused languages as well as FP extensions to existing languages
* FP is also the basis of modern automated theorem provers which are becoming very popular now
* We review the broader FP landscape here so you can take advantage of the power of FP even if not using OCaml

Along with the FP there are some other things we covered that you can re-use in other langauges:

* Quickchecking aka property-based testing aka random testing
  - Originated with the functional language Haskell but ported to many languages now
* Type-directed programming
  - You need a typed functional language subset for this (e.g. TypeScript)
  - Note that it doesn't work nearly as well with imperative code, types have less info in them
    - In functional programming, everything is in the function's type (e.g. any state is passed in/out)
    - *effect types* are a form of type which includes side effect information, helps fix this


## Functional-focused languages

* These are languages designed with FP in mind from the start
* Key features include
  - Immutable variables and data structures by default
  - Full higher-order functions (can pass and return functions to functions), currying, anonymous (`fun x -> ...`) functions, etc.
  - May include pattern matching, types, and type inference, but not always
* There are two major "schools" of FP today
    - ML school: static types, type-directed programming, type inference, polymorphism, pattern matching (OCaml, Standard ML, ReScript, Haskell, F#, Elm, Scala, etc)
    - Lisp school, dynamically typed: more flexible but no type-directed programming (Lisp, Scheme, Racket, Clojure, Elixir, etc)
* All of these languages should be very easy to learn now that you know OCaml.

## ML Dialects

* OCaml .. perhaps you have heard of that? :-)
* Standard ML is another variant of ML, but it has limited popularity these days
* F#, ReScript, Elm, Elixir, Scala, and Haskell are other ML-descended languages we cover briefly now

### F#

* [F#](https://fsharp.org) is Microsoft's ML-style language, it has all the main features of OCaml
* It integrates well with the MSFT toolchain, probably the main point of interest
* Here is an example from their tutorial to show how similar it is to OCaml:

```fsharp
let square x = x * x
let isOdd x = x % 2 <> 0

let sumOfOddSquares nums =
    nums
    |> List.filter isOdd
    |> List.sumBy square

let numbers = [1; 2; 3; 4; 5]
let sum = sumOfOddSquares numbers
printfn "The sum of the odd squares in %A is %d" numbers sum

type Shape =
    | Square of side: double
    | Rectangle of width: double * length: double

let getArea shape =
    match shape with
    | Square side -> side * side
    | Rectangle (width, length) -> width * length

let square = Square 2.0
printfn "The area of the square is %f" (getArea square)
```

### ReScript (previously called Reason)

* [ReScript](https://rescript-lang.org) is an interesting beast, it is a fork of OCaml in terms of features
  - It has different (improved!) syntax fixing the historical oddities and kludges of OCaml
  - Target to web browsers: compiler ("bucklescript") takes `.res` to `.bs.js` which can in turn run in a browser
  - [Here](https://rescript-lang.org/try) is a playground where you can see how `.res` is turned into `.js.bs`.
  - [This playground](https://reasonml.github.io/en/try) shows the close relation of ReScript and OCaml (and JavaScript) (it is in fact a Reason playground, the predecessor of ReScript)
  - [Some small code examples](https://rescript-lang.org/docs/manual/latest/newcomer-examples) to get an idea of the syntax

#### ReScriptReact

* The main thrust behind ReScript is use of soundly-typed FP in web UI programming
  - Compare to TypeScript which is not sound and lacks type inference
* [ReScriptReact](https://rescript-lang.org/docs/react/latest/introduction) is the ReScript version of Facebook's excellent React UI library for web browsers
* [Here](https://github.com/jihchi/rescript-react-realworld-example-app) is an example of a full browser app written in ReScriptReact.
  - ReScript and ReScriptReact count as OCaml for the course projects, an option to consider if you already know React.

### Elm

* [Elm](https://elm-lang.org) is an ML-school language 
* Designed for writing web apps, it runs in the browser via translation to JS.
   - Similar to ReScriptReact in goal

### Elixir

* [Elixir](https://elixir-lang.org) runs on the Erlang VM; Erlang is another older FP not so popular now.

### Scala

* Scala is a hybrid of Java and ML which runs on the JVM so can link with Java libraries
* It is much easier to do FP in compared to Java since FP was built-in from the start: pattern matching, type inference, etc.

### Haskell

* Haskell is an ML descendant, it shares a lot of the same syntax
* It is hard-core FP: no direct side effects _at all_, must use monads for _every_ side-effect (ouch!)
* It was gaining in popularity but interest has leveled off in the last few years
   - 100% monads is too hard-core for your average programmer; even I/O requires a monad.
* Has some very cool features that OCaml does not have, e.g. type classes for principled operator overloading

### Lisp / Scheme / Racket

* Lisp was the very first functional programming language, from the late 50's
  - inspired by Church's Lambda Calculus, circa 1934 - functional programming on paper
  - Lisp is dynamically typed, the ancestor of all modern dynamically-typed languages such as Python, JavaScript, etc.  No type-directed programming possible in any of these languages
  - Allows mutation everywhere (no immutable `let` or immutable lists), but "only mutate when really needed".
* Scheme was a clean-up of Lisp in the 70's-80's, there were several errors in the Lisp design
  - e.g. dynamic scoping -- closures were not computed in Lisp. (see [closures tangent below](./fp-universe.html#closures))
* [Racket](https://racket-lang.org) is a popular modern dialect of Scheme with many added features including types
* [Clojure](https://clojure.org) is another more modern Lisp dialect
  - Has more immutablility by default than Scheme and so can more cleanly support parallelism 
     - Avoids race conditions on stateful data strutures
  - Runs on the Java JVM so lots of libraries
* Additionally, Smalltalk, Ruby, Python, and JavaScript are descended from Lisp (more below on those)
* The Lisp school is generally in decline these days, `(the syntax (sucks) (since everything is just an s-expression (like this)))`


## The Functional language inside Theorem Provers: Lean

* You may have heard the recent news about how LLMs have solved many open problems in math
  - Not only proving them but _verifying the proofs are correct_ in an automated theorem prover.
  - This means a computer has verified every single line of every proof is correct.
  - It is right now [turning the research field of mathematics upside-down](https://www.quantamagazine.org/is-ai-the-end-of-math-as-we-know-it-20261005/).
* The main prover being used is a tool called [Lean](https://lean-lang.org) which we will cover briefly now.  [Rocq](https://rocq-prover.org) is another popular one.

Here is some Lean code from their homepage:

```ocaml
/-- A binary search funtion in Lean -/
def bsearch (a : Array UInt64) (x : UInt64) (lo hi : Nat)(h : hi ≤ a.size) : Option Nat :=
  if _ : lo < hi then
    let m := lo + (hi - lo) / 2
    if a[m] < x then bsearch a x (m + 1) hi h
    else if x < a[m] then bsearch a x lo m (by lia)
    else some m
  else none
termination_by hi - lo
```

* Looks spookily familiar, no? 
  - `Array/UInt64/Option` are exactly OCaml's `iarray/uint64/option` types
  - `def` is `let rec`, `let m := ...` is `let m = ...`, `a[m]` is `a.(m)`, etc
  - Lean is really just a fancy (pure) functional programming language!

* Lean is in several ways more powerful than OCaml
  - It has much much richer types (believe it or not), so rich that typechecking is not even decidible!
  - So, you need to _prove_ your programs typecheck
  - Additionally functions are all _total_, they must terminate on all inputs
  - The `termination_by hi - lo` in the above allows Lean to automatically prove this function terminates: `(hi - lo)` is strictly decreasing in each recursive call

#### Logical Propositions are Expressed as Types

* Lean's types are so rich that they are also a _logic_ (which is why it is a theorem prover and not just a PL)
  - Notice the odd looking `if _ : lo < hi then ...` - whats the `_ :` doing there??
  - Answer: Lean lets types represent truth values (!)
    - An empty type (i.e. it has no members) represents "false"
    - A type with _any_ member at all represents "true"
    - (Since there are no diverging functions some types will really be empty - not so in OCaml)
    - In this example, `lo < hi` is a _type_, not an expression
    - The `_ : ..` means the type has _some_ member that we don't care about, `_`
    - In general to "prove" a proposition means to find _any_ member of the corresponding type.
  - The parameter `(h : hi ≤ a.size)` is another example of this, it is a type expressing `hi` is in-bounds
    - it would be a _type error_ to invoke this function with `hi` being out of bounds
  - In general, all of mathematical logic can be expressed as types using this interpretation

#### Dependent Types and `Type`

* Lets do some smaller examples now to better understand this stuff
* Here is list `cons` in Lean (its in fact built-in but this shows the types):

```ocaml
def cons (α : Type) (a : α) (as : List α) : List α :=
  List.cons a as
```

* The `(α : Type)` is similar to `(type a)` in OCaml, its a parametric type
* But, here `Type` is _itself_ a type, the type of types - !  So, `α` is just another function parameter; types can be _values_ as well - !
* Next observe how `α` is then used later, in e.g. `(a : α)` - the _value_ of the first parameter to this function is used in the _type_ of the second (and third) parameters
  - This is called a _dependent type_

Here is another example of dependent types in action:
```ocaml
(n : Int) → (0 < n ∨ n < 0 ∨ n = 0)
```
* This looks like like a function type at first glance, but its _dependent_ - the argument `n` is used in the _type_ of the result, which is a type being used as a logic assertion like the `lo < hi` above.
* Now lets think about what "programs" are in this type: it needs to be a function which takes an integer `n` and produces a member of one of those three types (`∨` is logical-or which is like a variant type) -- Thats easy to do intuitively
* Notice that any function with this type constitutes a _proof_ that any integer is either positive, negative, or zero!
 - This is the core of how Lean can do verified math.

Here is a Lean function in that type:

```ocaml
example : (n : Int) → (0 < n ∨ n < 0 ∨ n = 0) :=
  fun n =>
    match Int.lt_trichotomy n 0 with
    | Or.inl h          => Or.inr (Or.inl h)
    | Or.inr (Or.inl h) => Or.inr (Or.inr h)
    | Or.inr (Or.inr h) => Or.inl h
```
- The trichotomy property is built in as `Int.lt_trichotomy`, but in a different order so it "shuffles" the proofs.
- The fact that this function typechecks consitutes a machine-verified _proof_ of this property.

* Logically, `(n : Int) →` is hypothesizing "for all integers `n`"
* Lean has syntactic sugar for this so it looks more like logic not types (`∀` is the standard symbol for "for all")

```ocaml
∀ n : Int, 0 < n ∨ n < 0 ∨ n = 0
```

#### Implications

* Proving a logical implication `A → B` is just finding a function in type `A → B`
  - given a member of `A` (i.e. showing `A` is true), the function will construct a member of `B` (i.e. show `B` is true).
* Here is an example in Lean, of the fact that subtracting one from a negative number also is negative.
```ocaml
(n : Int) → (0 > n) → (0 > n - 1)
```
* The `(0 > n) → (0 > n - 1)` type needs to have as a member a _function_ taking a proof of the former to the latter
* Here is a member of the above type which thus consititutes a proof of this fact:
```ocaml
example : (n : Int) → (0 > n) → (0 > n - 1) :=
  fun n => fun h => by omega
```
* Here `n` is the arbitrary integer and `h` is the hypothesized proof that `(0 > n)`.
* The `by omega` is something new, it's a _tactic_ - think of it as a macro which builds a proof that `(0 > n - 1)` using `h`
* Tactics are important because they can automatically build proofs (i.e. programs) having certain types.
* Note that proving a proposition in Lean is in some sense the _opposite_ of type inference in OCaml:
  - OCaml type inference: from an expression get me a type for that expression
  - Lean proving: from a type, get me an expression in the type.

#### Larger Proofs

Getting back to the example at the start, we can prove properties of that function:

```ocaml
theorem bsearch_none (a : Array UInt64) (x lo hi)
    (h : hi ≤ a.size)
    (sorted : a.toList.Pairwise (· ≤ ·))
    (hn : bsearch a x lo hi h = none) :
    ∀ i (_ : lo ≤ i) (_ : i < hi), a[i] ≠ x := by
  fun_induction bsearch <;>
    grind [List.pairwise_iff_getElem]
```
* `theorem` here is just sugar for `def` where the type is a proposition and the function is a member of that type
* The assertion is: for all immutable arrays `a`, and integers `x lo hi` (types inferred there), if
  - `hi ≤ a.size` holds (`h` is the witness for that)
  - `a` is sorted using `≤` as the comparison operator (`sorted` is the witness)
  - `bsearch` for `x` returned `none` as its result (i.e. `x` was not found)
  - then, forall indexes `i` into the array, `a[i] ≠ x` (mathematically it is not in the array)
* the body of the function here can all be constructed by tactics (macros)
  - Note that tactics are themselves just functional programs that someone wrote; the LLMs don't write tactics they just put them together (like in the above).

The above covers much of what is needed to do any math but Lean includes other important things:
* "exists" (∃), e.g. `∀ n, 1 < n → ∃ k, IsPrime k ∧ (k ∣ n)` ("every number has a prime factor")
  - Exists is also a type under the hood, `∃ k, k > 0` for example is approximately (`(k : Int) * (k > 0)`)
  - This is a _dependent product_, notice the type on the right of the pair depends on the value on the left
  - the `sig type t ... val add : t -> int -> t ... end` in OCaml is also a dependent product, `t` on left used on right.
* Inductive definitions, e.g. to define a grammar.
* We may glimpse at a few other Lean definitions/proofs of mathematical properties

## What is needed to have FP in YourLang
You need the following elements:
 * Higher-order functions: functions can be put in variables, passed to other functions, and returned as results of functions
 * Currying: the ability to partially apply function arguments because the type is `a1 -> (a2 -> r)`
 * Anonymous (un-named) functions: e.g. in the OCaml `(fun x -> x) 4`
 * Closures: to implement the above FP features, the compiler/interpreter needs *closures*.
 * (Also, FP languages often have pattern matching and immutable data structures)
 
 Lets cover closures briefly now.

<a name="closures"></a>
### Closures

*   A _closure_ is just how one function can return another function as a result
*   The term "closure" comes from how they are implemented -- all variable values not local to the function must be remembered
*   OCaml example:

```ocaml
# let bangit = (fun x -> fun y -> y ^ x) "!";;
val bangit : string -> string = <fun> (* bangit is at runtime the *closure* "< fun y code, {x |-> "!"} >" *)
# bangit "YES";;                    (* The closure lets us remember the "!" we passed to x *)
- : string = "YES!"                 (* This output shows the "!" was remembered by bangit *)
```

* Note how `x` is a function parameter and is remembered in spite of function returning, means `x` needs to be remembered, in the closure
* Closures are the key thing missing from C and other similar lanuages: C has *function pointers* you can pass in and out of other functions, but no closures

## FP in YourFavoriteLang

* It is now possible to do somewhat-FP-style programming in Java, C++, Python, JavaScript, etc.
* All of these languages have the core elements outlined above (higher-order, currying, anon. functions, closures)
* There is however often not good library support or integration
  - So, at this point it is more a "slice of FP" and not the whole pizza
  - With good FP libraries added and enough discipline, many FP coding idioms will still work.
* [Here](https://en.wikipedia.org/wiki/Anonymous_function) is a list of languages that do and don't support basic FP.

### FP in Java

Java 8+ has **Lambdas**

*   Lambdas are higher-order functions but are clunky to use due to how they were patched in.
*   Java 8 higher-order functions  "pun" as an interface with only one method in it, `apply`.  
    - the function is taken to be the body of that single method, no need to write the method name when declaring the function then.
*   There is also some (limited) type inference for Lambda parameters (plus type inference in general via `var`)
*   Currying in Java, somewhat painfully: [Gist currying example](https://gist.github.com/timyates/7674005). For that example here is the [Function](https://docs.oracle.com/en/java/javase/14/docs/api/java.base/java/util/function/Function.html) and [BiFunction](https://docs.oracle.com/en/java/javase/14/docs/api/java.base/java/util/function/BiFunction.html) type.
* Use `final` to declare variables immutable in Java - use it!
* There are no immutable data structures in the Java standard library unfortunately
 - significantly limits the advantages of FP
* Java 14 has records and pattern matching on them, but no "or" types so you can't make nice list/tree types (and they also won't be able to be shared as they are mutable).

### FP in C++11/14

* Closures are more difficult in C++ due to different low-level ways data can be accessed in C++.
  - you need to explicitly mark how each variable is stored in the closure: by value, reference, etc
* Can use `const` declarations to get immutable variables
* [Here](https://www.programiz.com/cpp-programming/lambda-expression) is a tutorial with some details. 
* C++ also has some type inference a la OCaml  [C++ local type inference ](https://en.wikipedia.org/wiki/C%2B%2B11#Type_inference)
    - e.g. `auto mydata = 22;`. `auto` is like `var` in Java.
*   C++14 adds [generic lambdas](http://en.wikipedia.org/wiki/C++14#Generic_lambdas) which look like the polymorphic types of OCaml/Java but are really just fancy macros.

### FP in Swift

* Swift also has support for anonymous function definitions, closures, Currying, etc.
* `let` is also built-in for defining immutable values (use `var` to mutate)
* `map` and other standard functions are supported in the system libraries, and lists can be immutable and so can be shared.
* The generic types of Swift also allow polymorphic functions to be defined like in OCaml
* Here is a Curried add function

```swift
func add(x: Int)(y: Int) -> Int {
  return x + y
}

let sum = add(2)(y: 3)
```

Note that application requires a named parameter on the 2nd parameter due to some quirks of the representation used.

### FP In Python

* Python as a descendant of Lisp "already has" FP including lambda, closures and Currying.  Here is a Curried add function.

```python
adder =  lambda x: lambda y: x + y
  
adder(4)(18)

r = adder(4)
r(18)
```
* `map`, `filter`, `reduce` etc are already in the core libraries
 - Note that lists are mutable unfortunately (no sharing) but you can make a list out of tuples which are immutable
* In addition, the [`functools`](https://docs.python.org/3/library/functools.html) standard library supports other convenience higher-order function operations
* Plus, if you want even more FP-ism, there are additional libraries such as [PyToolz](https://toolz.readthedocs.io/en/latest/index.html)

```python
from toolz import curry
@curry
 def add(x, y):
     return x + y

plusfour = add(4)     
```

* PyToolz is a port of the Clojure FP libraries to Python; still the data structures are not immutable
* Use [Pyrsistant](https://github.com/tobgu/pyrsistent?utm_source=chatgpt.com) to have immutable maps, lists, etc
* Python is weak on immutable variables, there is no `const`/`final`
    - but Python tuples and `frozenset` are immutable data structures
    - and Python 3.8 finally has `final`
* Python 3.10 has pattern matching.
  - [tutorial 1](https://www.python.org/dev/peps/pep-0636/) [tutorial 2](https://www.infoworld.com/article/3609208/how-to-use-structural-pattern-matching-in-python.html)


### FP In JavaScript or TypeScript

* JavaScript is similar to Python, it has the basics built-in already

```javascript
function adder(a) 
{ return function uni_adder(b) 
    { return a + b;
    };
};
```

* `const` declarations bring the FP immutable variable default to JS - use it!
* JavaScript has no immutable data structures however
  - means e.g. lists won't be able to share sub-structures so "FP programming" will be less efficient in JavaScript.
