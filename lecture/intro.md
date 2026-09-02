## Introduction and Background

## What is Functional Programming (FP)?

* It is a style of programming where functions are the centerpiece
* A key dimension is functions-as-data aka higher-order functions: functions can be passed to and returned from functions

### Lack of Side Effects
* FP emphasizes *immutability*: data structures that cannot be changed after being created
* More generally, functions often *only* accept and return data, they have no other behaviors on the side (no "side effects") 
  - No printing, I/O, mutating, raising exceptions, etc.
* Lack of side effects is called "referential transparency" 
  - Variable values don't change out from under you like in math
  - To understand what a function does, you *only* need to look at what you pass and what gets returned, a much narrower interface
* There exist immutable data structure analogues: immutable dictionaries, lists, etc
  - Instead of mutating, make a fresh copy.
  - Sounds like it will be very inefficient but cost is reasonable in most cases.
* `for` and `while` loops are useless since the variable being looped on needs to mutate for them to work
  - Solution: do everything with recursion.  It works much better than you might first expect.

### FP and Math
* Mathematical functions are implicitly immutable (think about it - no assignment/exception/.. in math!) so FP aligns closely with math
  - Think about functional programming as creating an *algebra* for the domain you are coding over
  - It is much easier to write completely correct programs in an FP style
* Additionally, FP allows for powerful new programming paradigms using functions as data.
  - A simple example from math is composition: `g o f (x) = g(f(x))`: `o` takes two functions and returns a new function, their composition.

### History in brief

* &lambda;-calculus, 1930's - developed by logicians (Church, Turing, Kleene, Curry, etc)
  - First, realize that no computers even existed in the 1930s - !  Ahead of its time
  - Q: Why make it then? A: Logic proofs are constructions, expressed as programs in the &lambda;-calculus
  - The &lambda;-calculus is the core of a modern functional programming language
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
  - The downside is types can get in the way both in terms of code maintenance (more work) and in terms of expressiveness (a few programs with no runtime type errors still won't pass the typechecker).


## Course Outline

See the [Dateline](../dateline.html) for our schedule, we will make a quick pass over it.
