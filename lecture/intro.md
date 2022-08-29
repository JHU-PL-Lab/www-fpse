# Introduction and Background

## Course Outline

See the [Dateline](../dateline.html)

## What is Functional Programming (FP)?

* It is a style of programming where functions are the centerpiece
* A key dimension is functions-as-data aka higher-order functions: functions can be passed to and returned from functions
* It emphasizes *immutability*: data structures that cannot be changed after being created
* Mathematical functions are implicitly immutable so FP aligns closely with math
  - Think about creating an *algebra* for the domain you are coding over
  - It is much easier to write completely correct programs in an FP style for this reason

### History in brief

* &lambda;-calculus, 1930's - developed by logicians (Church, Turing, Kleene, Curry, etc)
  - Logic proofs are formal constructions, expressed as programs in the &lambda;-calculus
  - The 1930's &lambda;-calculus is the core of a modern functional programming language
  - But before computers existed so no running, only hand-calculation - !
* Lisp, 1960's (McCarthy)
  - &lambda;-calculus is elegant, build a PL around it
  - Goal application space: artificial intelligence programming
  - Added list data to &lambda; functions: **Lis**t **P**rocessing
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

### Object-Oriented (OO)

* Objects tend to have "their" state encapsulated within their boundary
* It is usually mutable state - changes over time
* A function is like an object with one method, `call`, and with no fields
* But, that analogy doesn't fully capture higher-order functions which is why `lambda` added to Java.

### Functional (FP)

* As mentioned above, a key aspect is lack of mutation: more like a mathematical function, the output only depends on the input and it's only output is the codomain value, not any side effects like printing, mutating, raising exceptions, etc.
* Lack of side effects is called "referential transparency" - variable values don't change out from under you (follows how math behaves).
* Standard data structures not too different from imperative case: dictionaries, lists, etc, but can be *immutable* - instead of mutating, make a fresh copy.
* Allows for powerful new programming paradigms using functions as data.
  - Simple example is function composition operation: `g o f (x) = g(f(x))`: `o` takes two functions and returns a new function, their composition
* Less good at supporting extension, no notion of subclass in common functional paradigms

### Who wins?
Thesis:
* Imperative often wins for low-level code: underlying machine instructions are in the imperative domain, will run faster.
* O-O often wins for super large apps with fairly shallow logic: UI's, etc.
* Functional often wins for complex algorithms with deep inner logic, and also for data manipulation focus
  - Gets too confusing with mutation, and better composition of functions makes code easier to understand.
* Of course this choice is never made in a vacuum: existing codebases and libraries, programmer experience, etc. 
 
### Typed Functional vs Untyped Functional

* There are typed FP languages (OCaml, Haskell, TypeScript, etc) and uptyped ones (Scheme, Clojure, Python, JavaScript)
* We are clearly in the types camp here with OCaml but there are trade offs
  - With types we have *type-directed programming*: types serve as a skeleton of the code structure, and often once all the type errors are fixed the code .. works!
  - The downside is types can get in the way both in terms of code maintenance and in terms of expressiveness.
