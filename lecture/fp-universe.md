The Functional Programming Language Universe
============================================

* "This is the Dawn of the Age of FP", there are now many choices of languages
* There are both viable functional-focused languages as well as FP extensions to existing languages.

## Functional-focused languages

* These are languages designed with FP style in mind from the start
* Key features include
  - Immutable variables by default
  - Many immutable data structures in libraries
  - Full higher-order functions (can pass and return functions to functions), currying, anonymous (`fun x -> ` functions), etc.
  - (Often also includes pattern matching and type inference)
* Note that you may see the term "persistent data structure", we have been calling these "pure functional" or "immutable" data structures.
  - The term "persistent" has a longstanding meaning of surviving over multiple runs of a program so I personally view "persistent data structure" as a misleading term.
* There are generally two "schools"
    - ML school: static types, type inference, polymorphism, pattern matching (OCaml, Standard ML, ReScript, Haskell, F#, Elm, etc)
    - Lisp school: dynamically typed (Lisp, Scheme, Clojure, etc)
* All of these functional languages should be very easy to learn now that you know OCaml.

### OCaml and Standard ML

* OCaml .. perhaps you heard of that?? :-)
* Standard ML is another variant of ML
  - it has very limited popularity these days

### F#

* [F#](https://fsharp.org) is Microsoft's ML-style language, it has all the main features of OCaml
* It integrates well with the MSFT toolchain, probably the main point of interest
* Here is an example from their tutorial; looks familiar, eh?

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

### ReScript (ex-Reason)

* [ReScript](https://rescript-lang.org) is an interesting beast, it is a fork of OCaml in terms of features
  - But, with a somewhat different syntax not so loaded with historical oddities and kludges
  - Compiler takes `.res` to `.bs.js` which can in turn run in a browser
  - [Here](https://rescript-lang.org/try) is a playground where you can see how `.res` is turned into `.js.bs`.
  - [Some small code examples](https://rescript-lang.org/docs/manual/latest/newcomer-examples) to get an idea of the syntax

* ReScript is a fork of [Reason](https://reasonml.github.io) but Reason seems to be languishing now
  - Reason is "full OCaml" (every single feature) but with a more modern syntax
  - [This playground](https://reasonml.github.io/en/try) shows the close relation of Reason, OCaml, and JavaScript
     - ReScript doesn't have this perfect tie to OCaml but is close
     - You can still use this demo to paste in OCaml and see what the likely ReScript code will be, or vice-versa.


#### ReScriptReact

* The main thrust behind ReScript is use of soundly-typed FP in web UI programming
  - Compare to TypeScript which is not sound and lacks type inference
* ReScriptReact is the ReScript version of Facebook's excellent React UI library
* [Here](https://github.com/jihchi/rescript-react-realworld-example-app) is an example of a full browser app written in ReScriptReact.
  - ReScriptReact counts as "OCaml" for the course projects, an option to consider if you already know React.

### Elm

* [Elm](https://elm-lang.org) is an ML-school language 
* Designed for writing web apps, it runs in the browser via translation to JS.
   - Similar to ReScriptReact in goal

### Scala

* Scala is a hybrid of Java and ML which runs on the JVM so can link with Java libraries
* It is easier to do FP in compared to Java since it was built-in from the start: pattern matching, type inference, etc.

### Haskell

* Haskell is an ML descendant, it shares a lot of the same syntax
* It is hard-core FP: no direct side effects at all, must use monads for every side-effect (ouch!)
* It was gaining in popularity a lot but not so much recently, too hard-core for your average programmer

### Lisp / Scheme / Racket

* Lisp was the very first functional programming language, from the late 50's
  - inspired by Church's Lambda Calculus, circa 1934 - functional programming on paper
  - Lisp is dynamically typed, there are no type declarations or inference and all errors caught at runtime.
  - Allows mutation everywhere (no immutable `let` or immutable lists), but "only mutate when really needed".
* Scheme was a clean-up of Lisp in the 70's-80's, there were several errors in the Lisp design
  - e.g. dynamic scoping -- closures were not computed in Lisp. (see [closures tangent below](./fp-universe.html#closures))
* [Racket](https://racket-lang.org) is a popular modern dialect of Scheme with many added features including types
* [Clojure](https://clojure.org) is another more modern Lisp dialect
  - Has more immutablility by default than Scheme and so can more cleanly support parallelism 
     - Avoids race conditions on stateful data strutures
  - Runs on the Java JVM so lots of libraries
* Additionally, Smalltalk, Ruby, Python, and JavaScript are descended from Lisp (more below on those)

## FP in YourFavoriteLang

* It is now possible to do FP-style programming in Java, C++, Python, JavaScript, etc.
* All of these languages support higher-order functions with Currying, etc.
  - (Currying is usually not the default multi-arg approach as in OCaml, though)
* There is not necessarily good library support or integration
  - So, at this point more "checking the FP box" than actual "doing FP"
  - To "really do" FP you need immutable data structures and default-immutable variables

### FP in Java

Java 8+ has **Lambdas**

*   Lambdas are clunky to use due to how they were patched in.
*   Java 8 higher-order functions  "pun" as an interface with only one method in it, `apply`.  
    - the function is taken to be the body of that single method, no need to write the method name when declaring the function then.
*   There is also some (limited) type inference for Lambda parameters (plus type inference in general via `var`)
*   Currying in Java, somewhat painfully: [Gist currying example](https://gist.github.com/timyates/7674005). For that example here is the [Function](https://docs.oracle.com/en/java/javase/14/docs/api/java.base/java/util/function/Function.html) and [BiFunction](https://docs.oracle.com/en/java/javase/14/docs/api/java.base/java/util/function/BiFunction.html) type.
* Use `final` to declare variables immutable in Java - use it!
* There are no immutable data structures in the Java standard library unfortunately

### FP in C++11

* Everyone is joining the Lambda party!
* Details [here](http://en.wikipedia.org/wiki/Anonymous_function#C.2B.2B_.28since_C.2B.2B11.29). 
* Closures are a headache in C++ due to different low-level ways data can be accessed in C++.
* Use `const` declarations to get immutable variables
* C++ also has some type inference a la OCaml  [C++ local type inference ](https://en.wikipedia.org/wiki/C%2B%2B11#Type_inference)
    - e.g. `auto mydata = 22;`. `auto` is like `var` in Java.
*   C++14 adds [generic lambdas](http://en.wikipedia.org/wiki/C++14#Generic_lambdas) which look like the polymorphic types of OCaml/Java but are really just fancy macros.

### FP In Python

* Python "already has" FP including closures and Currying.  Here is a Curried add function.

```python
def adder(x):
     def uni_adder(y):
         return x + y
     return uni_adder
 
print adder(4)(18)
```
* The above is a bit clunky since the intermediate function must be named
* `map`, `filter`, `reduce` etc are already in the core libraries
* In addition, the [`functools`](https://docs.python.org/3/library/functools.html) standard library supports other convenience higher-order function operations
* Plus, if you want even more FP-ism, there are additional libraries such as [PyToolz](https://toolz.readthedocs.io/en/latest/index.html)

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
* Python 3.10 (finally!) has pattern matching - released Oct 2021.
  - [tutorial](https://www.python.org/dev/peps/pep-0636/)


### FP In JavaScript

* JavaScript is similar to Python, it has the basics built-in already

```javascript
function adder(a) 
{ return function uni_adder(b) 
    { return a+b;
    };
};
```

* `const` declarations bring the FP immutable variable default to JS - use it!
* JavaScript has no immutable data structures however
  - means e.g. lists won't be able to share sub-structures so "FP programming" will be less efficient in JS.


<a name="closures"></a>
### Terminology aside: _closure_

*   A _closure_ is just a higher-order function return value
*   The term "closure" comes from how they are implemented -- all variables not local to the function must be remembered
*   OCaml example:

```ocaml
# let f = (fun x -> fun y -> x + y) 4;;
val f : int -> int = <fun> (* f is at runtime the closure "<fun y code, {x |-> 4}>" *)
# f 3;;
- : int = 7
```

* Note how `x` is a function parameter and is remembered in spite of function returning, means `x` needs to be remembered, in the closure

* Closures are the key thing missing from C: C has *function pointers* you can pass around, but no closures.
  - It also doesn't allow you to write anonymous functions (`fun x -> ..`), etc, etc.
