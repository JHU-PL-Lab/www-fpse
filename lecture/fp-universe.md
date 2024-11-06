The Functional Programming Language Universe
============================================

* "This is the Dawn of the Age of FP", there are now many choices of FP languages
* There are both viable functional-focused languages as well as FP extensions to existing languages
* We review the landscape here so you can us some FP on your next Python/Java(Script)/C++/... project


Along with the FP there are some other things we covered that you can re-use in other langauges:

* Quickchecking aka property-based testing aka random testing
  - Originated with Haskell but being ported to many languages now
* Type-directed programming
  - You need a typed functional language subset for this (e.g. C++, TypeScript, etc)
  - Note that it doesn't work as well with imperative code, not as many type interfaces declared.


## Functional-focused languages

* These are languages designed with FP in mind from the start
* Key features include
  - Immutable variables by default
  - Libraries have immutable aka persistent data structures (immutable lists, trees, maps, etc)
  - Full higher-order functions (can pass and return functions to functions), currying, anonymous (`fun x -> ...` functions), etc.
  - Often also includes pattern matching and type inference, but also may be dynamically-typed
* There are two major "schools" of FP today
    - ML school: static types, type-directed programming, type inference, polymorphism, pattern matching (OCaml, Standard ML, ReScript, Haskell, F#, Elm, Scala, etc)
    - Lisp school, dynamically typed: more flexible but no type-directed programming (Lisp, Scheme, Racket, Clojure, etc)
* All of these true functional languages should be very easy to learn now that you know OCaml.

## ML Dialects

* OCaml .. perhaps you have heard of that? :-)
* Standard ML is another variant of ML, but it has limited popularity these days
* F#, ReScript, Elm, and Haskell are other ML-descended languages we cover briefly now

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

### ReScript (was called Reason until ~2021)

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
* It is hard-core FP: no direct side effects at all, must use monads for every side-effect (ouch!)
* It was gaining in popularity but interest has leveled off in the last few years
   - monads are too hard-core for your average programmer
* Has some very cool features that OCaml does not have, e.g. type classes for principled operator overloading

### Lisp / Scheme / Racket

* Lisp was the very first functional programming language, from the late 50's
  - inspired by Church's Lambda Calculus, circa 1934 - functional programming on paper
  - Lisp is dynamically typed, the ancestor of all modern dynamically-typed languages such as Python, JavaScript, etc.  No type-directed programming in any of these!!
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
# let add4 = (fun x -> fun y -> x + y) 4;;
val add4 : int -> int = <fun> (* add4 is at runtime the *closure* "< fun y code, {x |-> 4} >" *)
# add4 3;;                    (* The closure lets us remember the 4 we passed to x *)
- : int = 7
```

* Note how `x` is a function parameter and is remembered in spite of function returning, means `x` needs to be remembered, in the closure
* Closures are the key thing missing from C: C has *function pointers* you can pass in and out of other functions, but no closures

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
func add(_ x: Int) -> ((Int) -> Int) {
  return { y in x + y }

let r1 = add(5)(4)
let add5 = add(5)
let r2 = add5(4)
}
```

Or with more sugared syntax like OCaml's implicitly Curried functions:
```ocaml
func add(x: Int)(y: Int) -> Int {
  return x + y
}

let sum = add(2)(y: 3)
```

Note however that application requires a named parameter on the 2nd parameter.

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
 - has immutable data structures as well

```python
from toolz import curry
@curry
 def add(x, y):
     return x + y

plusfour = add(4)     
```

* PyToolz is a port of the Clojure FP libraries to Python
* Python is weak on immutable variables, there is no `const`/`final`
    - but the tuples and `frozenset` are immutable data structures
    - and Python 3.8 finally has `final`
* Python 3.10 (finally!) has pattern matching.
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

