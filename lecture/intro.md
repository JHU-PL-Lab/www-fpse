# Introduction and Background

## Course Outline

See the [Dateline](../dateline.html)

## What is Functional Programming (FP)?

* It is a style of programming where functions are the centerpiece
* A key dimension is functions-as-data aka higher-order functions: functions can be passed to and returned from functions

### Lack of Side Effects
* FP emphasizes *immutability*: data structures that cannot be changed after being created
* More generally, functions *only* return data, they have no other behaviors on the side (no "side effects") 
  - No printing, I/O, mutating, raising exceptions, etc.
* Lack of side effects is called "referential transparency" 
  - Variable values don't change out from under you (follows how math behaves).
  - To understand what a function does, you *only* need to look at what you pass and what gets returned, a much narrower interface
* There exist functional data structures analogous to imperative ones: dictionaries, lists, etc, but *immutable* 
  - Instead of mutating, make a fresh copy.
  - Sounds like it will be inefficient but cost is reasonable in most cases.

### FP and Math
* Mathematical functions are implicitly immutable (think about it - no assignment/exception/.. in math!) so FP aligns closely with math
  - Think about functional programming as creating an *algebra* for the domain you are coding over
  - It is much easier to write completely correct programs in an FP style for this reason
* Additionally, FP allows for powerful new programming paradigms using functions as data.
  - A well-known example from math is composition: `g o f (x) = g(f(x))`: `o` takes two functions and returns a new function, their composition.

### History in brief

* &lambda;-calculus, 1930's - developed by logicians (Church, Turing, Kleene, Curry, etc)
  - Logic proofs are formal constructions, expressed as programs in the &lambda;-calculus
  - The 1930's &lambda;-calculus is the core of a modern functional programming language
  - All of these ideas arose before computers even existed - !!
* Lisp, late 1950's, McCarthy
  - The &lambda;-calculus is elegant, so build a PL around it
  - Goal application space: artificial intelligence programming (symbolic AI back then)
  - McCarthy added list data to &lambda; functions: **Lis**t **P**rocessing
  - Lisp is the ancestor of all modern dynamically-typed PLs: Python, JavaScript, etc.
* Typed functional languages, 70's & 80's: Milner's ML and its descendents Haskell and OCaml
* Modern era: FP added as an extension to mainstream PLs: Python, JavaScript, Java, C++, etc.

### Typed Functional vs Untyped Functional

* There are typed FP languages (OCaml, Haskell, TypeScript, etc) and uptyped ones (Lisp, Scheme, Clojure, Python, JavaScript, etc)
* We are clearly in the types camp here with OCaml but there are trade offs
  - With types we have *type-directed programming*
    - The type of a function serves as a skeleton of the code structure before writing any code
    - For example, a function that takes in a list of integers and returns an integer gives important information
    - Often once all the type errors are fixed the code .. works!
  - The downside is types can get in the way both in terms of code maintenance (more work) and in terms of expressiveness (programs with no runtime type errors won't pass the typechecker).
