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

### Imperative vs Object-Oriented vs Higher-Order Functional

* Lets oversimplify: "Imperative = C, OO = Java, FP = OCaml"
* Goal of this course is to get deeply into the FP mode of programming, which can then be used in your favorite PL - Java, Python, C++, JavaScript, OCaml, etc.

### Imperative (e.g. C)

* Imperative also has functions, but there functions often have side effects (e.g. mutating some shared data structures, raising exceptions)
* C has function pointers to pass around functions as data but they lack critical expressiveness (a topic we will cover later).
* Need to explicitly manage memory with `malloc/free` and pointers which leads to many errors.

### Object-Oriented (e.g. Java)

* Objects tend to have "their" state encapsulated within their boundary
* It is usually *mutable* state - calling a method does more than what it returns, field values could change
* A function is like an object with one method, `apply`, and with no fields
  - But, that analogy doesn't fully capture higher-order functions which is why `lambda` added to Java.

### Functional (e.g. OCaml)

* Advantages described above: declarative nature and correctness, more composable
* Can be less good at supporting extension: e.g. no notion of subclass in functional paradigm

### Which one wins?
Thesis:
* Imperative often wins for low-level code: underlying machine instructions are in the imperative domain, will run faster.
* O-O often wins for very large apps with shallow logic: UI's, etc.
* Functional often wins for complex algorithms with deep inner logic, and also for data manipulation focus
  - Gets too confusing with mutation, and better composition of functions makes code easier to understand.
 
### Typed Functional vs Untyped Functional

* There are typed FP languages (OCaml, Haskell, TypeScript, etc) and uptyped ones (Lisp, Scheme, Clojure, Python, JavaScript, etc)
* We are clearly in the types camp here with OCaml but there are trade offs
  - With types we have *type-directed programming*
    - The type of a function serves as a skeleton of the code structure before writing any code
    - For example, a function that takes in a list of integers and returns an integer gives important information
    - Often once all the type errors are fixed the code .. works!
  - The downside is types can get in the way both in terms of code maintenance (more work) and in terms of expressiveness (programs with no runtime type errors won't pass the typechecker).
