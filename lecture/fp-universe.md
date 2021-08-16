The Functional Programming Language Universe
============================================

* "This is the Dawn of the Age of FP", there are now many choices of languages
* There are both viable functional-focused languages as well as FP extensions to existing languages.

## Functional-focused languages

* These are languages designed with FP style in mind from the start: immutable variables and data structures, full higher-order functions, currying, etc.
* There are generally two "schools"
    - ML school: static types, type inference, polymorphism, pattern matching (OCaml, Standard ML, Haskell, F#, etc)
    - Lisp school: dynamically typed (Lisp, Scheme, Clojure, etc)

### OCaml and Standard ML

* Of course we have to include OCaml!  
* Standard ML is another variant of ML which has limited popularity these days

### F#

* [F#](https://fsharp.org) is Microsoft's ML-style language, it has all the main features of OCaml
* It integrates well with the MSFT toolchain
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

### Reason

* [Reason](https://reasonml.github.io) is an interesting beast, it has **exactly** the features of OCaml
  - but with a somewhat different syntax not so loaded with historical oddities and kludges
  - You can convert `.rs` to `.ml` and vice-versa very cleanly and it also translates to JavaScript for browser code
  - The [Overview](https://reasonml.github.io/docs/en/overview) provides a glimpse of the syntax
    - it is not hard to see how it is a minor variation on OCaml
  - We will play with [this cool live demo](https://reasonml.github.io/en/try) which shows code in all three languages at once

#### ReasonReact

* The main thrust behind Reason is use of FP in web UI programming
* ReasonReact is the Reason version of Facebook's excellent React UI library
* We will take a peek at a [Simple To Do app](https://github.com/reasonml-old/reason-react-example/tree/master/src/todomvc) written in ReasonReact

### Elm

* [Elm](https://elm-lang.org) is an ML-school language 
* Designed for writing web apps, it runs in the browser via translation to JS.
   - Similar to Reason in goal

### Scala

* Scala is a hybrid of Java and ML which runs on the JVM so can link with Java libraries
* It is easier to do FP in compared to Java since it was built-in from the start: pattern matching, type inference, etc.

### Haskell

Haskell is in the ML school; Devin will present Haskell in detail.

### Lisp / Scheme / Racket

* Lisp was the very first functional programming language, from the late 50's
  - it was dynamically typed, there are no type declarations or inference and errors caught at runtime.
* Scheme was a clean-up of Lisp in the 70's-80's, there were several errors in the Lisp design
  - e.g. dynamic scoping -- closures were not computed in Lisp.
* [Racket](https://racket-lang.org) is a popular modern dialect of Scheme with many added features including types
* Additionally, Smalltalk, Ruby, Python, and JavaScript are dynamically-typed and are thus descended from Lisp.

### Clojure

Clojure is in the Lisp school; Kelvin will present Clojure in detail.


## FP Extensions to YourFavoriteLang

* It is now possible to do FP-style programming in Java, C++, Python, JavaScript, etc.
* All of these languages support higher-order functions with Currying, etc.
* But, there is not necessarily good library support or integration
* Also, to "really do" FP you need immutable data structures and variables
  - limited support for that in most of these languages currently

### FP in Java

Java 8+ has **Lambdas**

*   Lambdas are a bit clunky to use compared to OCaml due to how they were patched in.
*   Java 8 higher-order functions  "pun" as an interface with only one method in it.  
    - the function is taken to be the body of that single method, no need to write the method name when declaring the function then.
*   There is also some (limited) type inference for Lambda parameters.
*   [Here is a tutorial](http://docs.oracle.com/javase/tutorial/java/javaOO/lambdaexpressions.html)
*   Currying in Java, somewhat painfully: [Gist currying example](https://gist.github.com/timyates/7674005). For that example here is the [Function](https://docs.oracle.com/en/java/javase/14/docs/api/java.base/java/util/function/Function.html) and [BiFunction](https://docs.oracle.com/en/java/javase/14/docs/api/java.base/java/util/function/BiFunction.html) type.
* Use `final` to declare variables immutable in Java - use it!
* There are no immutable data structures in the Java standard library unfortunately

Terminology aside: _closure_

*   A _closure_ is just a higher-order function return value
*   The term "closure" comes from how they are implemented -- all variables not local to the function must be remembered
*   OCaml example:

```ocaml
# let f = (fun x -> fun y -> x + y) 4;;
val f : int -> int = <fun> (* f is at runtime the closure <fun y code, {x |-> 4}> *)
# f 3;;
- : int = 7
```

* Note how `x` is a function parameter and is remembered in spite of function returning, means `x` needs to be _copied_ into the closure.

### FP in C++

* Everyone is joining the Lambda party!
* Details [here](http://en.wikipedia.org/wiki/Anonymous_function#C.2B.2B_.28since_C.2B.2B11.29). 
* Closures are a headache in C++ due to different low-level ways data can be accessed in C++.
* Use `const` declarations to get immutable variables
* C++ also has some type inference a la OCaml  [C++ local type inference ](https://en.wikipedia.org/wiki/C%2B%2B11#Type_inference)
    - e.g. `auto mydata = 22;`. `auto` is like `var` in Java.
*   C++-14 adds [generic lambdas](http://en.wikipedia.org/wiki/C++14#Generic_lambdas) which look like the polymorphic types of OCaml/Java but are really just fancy macros.

### FP In Python

* Python "already has" FP including closures and Currying.

```python
def adder(x):
     def uni_adder(y):
         return x + y
     return uni_adder
 
print adder(4)(18)
```
* The above is a bit clunky having to name the intermediate function
* `map`, `filter`, `reduce` etc are already in the core language
* In addition, the [`functools`](https://docs.python.org/3/library/functools.html) standard library supports other convenience higher-order function operations
* Plus, if you want even more FP-ism, there are additional libraries such as [PyToolz](https://toolz.readthedocs.io/en/latest/index.html)

```python
from toolz import curry
@curry
 def add(x, y):
     return x + y

plusfour = add(4)     
```

* PyToolz is basically a port of the Clojure FP libraries to Python
* Python is weak on immutable variables, there is no `const`/`final`
    - but the tuples and `frozenset` are immutable data structures
    - and Python 3.8 finally has `final`


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
