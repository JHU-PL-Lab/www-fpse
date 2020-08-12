# Outline of Lecture Units

## Course Outline

- Just repeat the Syllabus here.

## What is FP?

### History in brief

* Lambda calculus, 1930's - logicians (Church, Turing, Kleene, Curry, etc)
 - Logic proofs are formal constructions
 - Core ideas of functional programming already present
 - But no computers so no running, only hand-calculation
* Lisp, 1960's (McCarthy)
 - Implement the ideas of the mathematicians
 - Goal application space: artificial intelligence programming
 - Added list data to functions: **Lis**t **P**rocessing
* Typed functional languages, 70's & 80's: ML and its descendents Haskell and OCaml
 - Will see what this is in detail as we use OCaml
* Modern era: add FP as possibility in mainstream: Python, JavaScript, Java, C++, etc.
* FP now edging out OO school in some domains.

### Imperative vs OO vs FP

* Oversimplifying but these are the three modern schools
* More oversimplifying: "Imperative = C, OO = Java, FP = OCaml"
 - other languages can also be put in schools, but these are leading representatives today
 
### Imperative

* Imperative also has functions, but functions often have side effects (e.g. mutate some shared data structures)
* C has function pointers but they are not widely used and lack needed expressiveness (which we will cover).

### O-O

* Objects tend to have "their" state encpsulated within their boundary
* Still it is usually a mutable state - change over time
* A function is something like an object with one method, `call`, and with no fields
* That doesn't fully capture higher-order functions which is why `lambda` added to Jave.

### Functional

* Key aspect is lack of mutation: more like a mathematical function, the output only depends on the input and it's only output is the codomain value, not any side effects like printing, mutating, raising exceptions, etc.
* Lack of side effects is called "referential transparency" - variable values don't change out from under you (like in math textbook).
* Standard data structures not too different from imperative case: dictionaries, lists, etc, but often will themselves be non-mutable
* Key advantage is higher-order-ness: code is data, make new functions, accept functions as parameters.
* Allows for powerful new programming paradigms.  give examples like compose, map, etc.
* Less good at supporting extension, no notion of subclass in common functional paradigms (not impossible to add though).

### Who wins?
Thesis:
* Imperative wins for low-level code: underlying machine instructions are in the imperative domain, will run faster.
* O-O wins for super large apps with fairly shallow logic: UI's, many apps, etc.
* Functional wins for complex algorithms with deep inner logic
 - Gets too confusing with mutation, and better composition of functions makes code easier to understand.
* Of course this choice is never made in a vacuum: existing codebases and libraries, programmer experience, etc. 
 
 
## Introduction to OCaml

 
 