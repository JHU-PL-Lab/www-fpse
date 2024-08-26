# Introduction and Background

## Course Outline

See the [Dateline](../dateline.html)

## What is Functional Programming (FP)?

* It is a style of programming where functions are the centerpiece
* A key dimension is functions-as-data aka higher-order functions: functions can be passed to and returned from functions

### Lack of Side Effects
* FP emphasizes *immutability*: data structures that cannot be changed after being created
* More generally than limited mutation, most functions only return data, they have no other behaviors on the side (no "side effects") 
  - No printing, I/O, mutating, raising exceptions, etc.
* Lack of side effects is called "referential transparency" - variable values don't change out from under you (follows how math behaves).
* Functional data structures are analogues of imperative ones: dictionaries, lists, etc, but *immutable* 
  - Instead of mutating, make a fresh copy.
  - Sounds like it will be extremely inefficient but it is reasonable in "most" cases.

### History in brief

* &lambda;-calculus, 1930's - developed by logicians (Church, Turing, Kleene, Curry, etc)
  - Logic proofs are formal constructions, expressed as programs in the &lambda;-calculus
  - The 1930's &lambda;-calculus is the core of a modern functional programming language
  - Note all of this was before computers even existed - !!
* Lisp, late 1950's (McCarthy)
  - &lambda;-calculus is elegant, so build a PL around it
  - Goal application space: artificial intelligence programming
  - Added list data to &lambda; functions: **Lis**t **P**rocessing
  - Lisp is the ancestor of all modern dynamically-typed languages: Python, JavaScript, etc.
* Typed functional languages, 70's & 80's: Milner's ML and its descendents Haskell and OCaml
  - We will be using OCaml
* Modern era: add FP as possibility in mainstream PLs: Python, JavaScript, Java, C++, etc.

### Imperative vs Object-Oriented vs Higher-Order Functional

* Oversimplifying but these are the three modern schools
* More oversimplifying: "Imperative = C, OO = Java, FP = OCaml"
* Note many O-O languages now have functions, often called lambdas for the historical reference
* Goal of this course is to get deeply into the FP mode of programming, which can then be used in your favorite PL - Java, Python, C++, JavaScript, OCaml, etc.

### Imperative

* Imperative also has functions, but there functions often have side effects (e.g. mutate some shared data structures)
* C has function pointers to pass around functions as data but they are not widely used and lack needed expressiveness (a topic we will cover later).
* Need to explicitly manage memory with `malloc/free` and pointers which leads to many errors.

### Object-Oriented (OO)

* Objects tend to have "their" state encapsulated within their boundary
* It is usually mutable state - changes over time
* A function is like an object with one method, `call`, and with no fields
  - But, that analogy doesn't fully capture higher-order functions which is why `lambda` added to Java.

### Functional (FP)

* Advantages described above: declarative nature and correctness, more composable
* Sometimes less good at supporting extension: e.g. no notion of subclass in functional paradigm

### Which one wins?
Thesis:
* Imperative often wins for low-level code: underlying machine instructions are in the imperative domain, will run faster.
* O-O often wins for very large apps with shallow logic: UI's, etc.
* Functional often wins for complex algorithms with deep inner logic, and also for data manipulation focus
  - Gets too confusing with mutation, and better composition of functions makes code easier to understand.
 
### Typed Functional vs Untyped Functional

* There are typed FP languages (OCaml, Haskell, TypeScript, etc) and uptyped ones (Lisp, Scheme, Clojure, Python, JavaScript, etc)
* We are clearly in the types camp here with OCaml but there are trade offs
  - With types we have *type-directed programming*: types serve as a skeleton of the code structure, and often once all the type errors are fixed the code .. works!
  - The downside is types can get in the way both in terms of code maintenance and in terms of expressiveness.
