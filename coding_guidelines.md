
# Coding Guidelines for FPSE

**Be explicit.** Don't make the reader solve a puzzle; tell them what is happening by being explicit. Implicit behavior requires lots of hard thinking to understand, whereas explicit behavior can be read straight off the page. This guide here is all about how to be explicit in your code so that you are clear in your intent and so that others can review, understand, and extend your code easily and correctly.

## General guidelines

### Functional first
* Functional code makes effects and data flow explicit because **meaningful outcomes are expressed in the return type** (referential transparency). Imperative code, on the other hand, has side effects and state that you must know about and keep in mind; the returned value, if any, is not the only outcome of calling the function.
* Keep the scope small and prefer functional solutions, but remember: this is "functional first", not "functional only". Use imperative style where it is the least cumbersome.

### Encapsulate with modules
* Your code should be grouped into meaningful, coherent modules. Those **modules should have a single purpose**, and that purpose is often to contain a single type and several functions that work mainly on that type.
* Writing code in this way separates responsibilities and creates appropriate abstraction boundaries.
* Then, **document with interface files**. Interfaces are a great place to comment and to think critically about the purpose of your module.

### Hide representations
* Modules should expose operations but not representations. Hide implementation details behind interfaces whenever practical so that users depend on the semantics of the module, not its implementation. This prevents misuse and enhances maintainability.
* However, hiding is not always the best choice. For example, if you are writing getters and setters for every field of a record type, you should instead just expose that type.

### Know your standard library
* It is not too big (and that is a good thing), so you should know [what it provides](https://ocaml.org/manual/5.5/stdlib.html). It will solve many simple problems for you.
* Never reimplement anything that is in the standard library, and always reach for the standard library when it expresses your intent.
* If you find that your code is just a library function, then use the library function. If you find that your code is essentially a composition of two library functions, then use those two libraries functions. That said...

### Think structurally
* Using too many combinators clouds the structure of the problem and leads to indirect solutions. **You should not be asking yourself how you can assemble a solution from existing library functions but instead how you can best solve the problem with OCaml.**
* If you think primarily in terms of library functions, then you are missing out on the power that the language itself provides. Moreover, combinator-heavy code is likely to have many nested function calls without explanatory variable names.

  > For example, something like `List.map (Fun.flip List.cons ls) xs` is over-using combinators. Just write `List.map (fun x -> x :: ls) xs`.

* See [iterators](https://ocaml.org/docs/guidelines#iterators) in the official OCaml Guidelines for an extra terrible example.

### Don’t be too clever
* The most elegant solution is not always the best one. **Readability is about more than just concision.**
* Write the shorter code if doing so does not drastically increase complexity.
* Point-free programming (especially excessive function composition and partial application) is often clever but unreadable. Be explicit and simple without being overly verbose.

### Use the weakest feature
* **Use the simplest feature that expresses your intent**. More powerful features are valuable when they solve a problem that simpler features cannot, but they should not be used merely because they exist.
* Every additional capability in the feature you use imposes a cost on the reader because they must be prepared for you to use it!
* Search for the simplest type or feature that solves your problem, and then introduce mechanisms only when they buy you something.

  > For example, do not use a list where a tuple suffices, or a first class module when you only need a higher order function, or object polymorphism when records and variants get the job done clearly.

### Use the appropriate data structure
* Lists, ints, and strings are not the solutions to all your problems, as much as C wants you to think they are.
* Think carefully about the structure of your problem and the data structure it requires. Much of the time, a simple variant or record type is the appropriate solution.
* When an advanced data structure is required, there is probably a standard library module or an opam package for it, and these can be easy to drop into your code.

### Frameworks: No, Libraries: Yes.
* Frameworks are opinionated and invite conflicts. They are large dependencies that massively influence the structure of your program. Good luck using more than one of them at a time. Adopt frameworks sparingly, and only when they are fundamental to your project.
* A good library, on the other hand, is useful and not restrictive. It is easily pluggable and will not steer the direction of your code for you.
* In general, avoid depending on too many frameworks and libraries for single-use purposes because every dependency you have is one more that the reader of your code has to understand. **Dependencies can be heavy, and they should be worth their weight.**

  > An example framework is `Lwt` for concurrency. It will take over your code with monads, and you cannot nest its use, so you cannot depend on other libraries that use it themselves.

  > Some example libaries are the monotonic timing library [`Mtime`](https://erratique.ch/software/mtime), and the priority search queue data structure [`Psq`](https://github.com/pqwy/psq). These define a few types and functions that are tightly contained and are unopinionated.

* [Source](https://watch.ocaml.org/w/arLEkYE7NC4fdCcWz2LBLt) (Malcolm Matalka at FUN Ocaml 2025)

### Abstract appropriately
* Use abstraction to avoid duplication and to avoid hardcoding.
* Abstraction should enhance readability by allowing the reader to focus on the fundamental problem the code at hand is solving.
* **A piece of code lacks abstraction when the main idea is buried under irrelevant detail** or just when the same idea is repeated in several places.
* It should not hinder readability by being too implicit or clever, so choose the smallest abstraction that captures the common idea (See "Use the weakest feature").

### Parse, don’t validate
* Use new types to **parse your data into always-valid forms** where illegal states are unrepresentable.
* Avoid implicit invariants or frequent re-validation. Effective use of types can often uphold those invariants by themselves and will aid in readability.

  > For example, parse a string into an abstract `email` type exactly once instead of checking at every use that it is a valid email string.

* [Source](https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/) (Alexis King, Nov 5 2019)

## Specific suggestions

**DRY**. Don't Repeat Yourself. An oldie but goodie. Repeat yourself maybe once, but only if you did not have to copy/paste code to do so. Higher order functions (functions as arguments to other functions) make it especially easy to avoid repeating yourself.

**Pattern match and destructure.** Pattern matching and `let`-destructuring (e.g. `let a, b = ... in ...`) are some of OCaml's clearest tools, and they express intent very explicitly. Use them liberally.

**Do not write long anonymous functions.** Anonymous functions should always be short. If one becomes long, then help your reader by naming it, thereby making it no longer anonymous. This frequently applies to function arguments to mapping and folding; if the argument is long and inlined, the behavior is mysterious.

**Monomorphic, not polymorphic, comparison.** Performance aside, monomorphic comparison (e.g. `String.equal`) is defined specifically for the type at hand, while polymorphic comparison may not behave as intended. Polymorphic comparison is too structure-sensitive (e.g. on sets), may fail at runtime (e.g. on functions), and may be unsound in the presence of existential types (e.g. in GADTs). Further, type-specific comparison documents the type you actually intend to compare.

**Options over exceptions.** Exceptions for recoverable failures require the programmer to _remember_ to catch them. Options _force_ the programmer to handle them. Don’t leave anything up to chance, and favor options in your interfaces. Results allow you to express reasons for failure and can be a good alternative to options.

> For example, to normalize a vector to a unit vector, you may prefer `val normalize_opt : vector -> vector option` instead of `val normalize : vector -> vector` because normalization is not total: it is not defined on the zero vector, so the second can fail.

**New types, not abbreviations.** New types force structure and separation, while abbreviations may accidentally cross data because they do not create distinct types. New types also document themselves in interfaces.

> For example, for a 2D integer point, prefer `type t = { x : int ; y : int }`, a new record type, instead of `type t = int * int`.

**Prefer records over tuples.** Tuples are useful for transiently packing data together, but they should not be used for meaningful, long-lived groupings of data. When defining types, choose to make a new record instead of abbreviating a tuple type, like the 2D point above.

**Label function arguments of the same type.** If any two arguments have the same type, you invite the caller to confuse them, or you require them to read a documenting comment. Instead, use labeled arguments to distinguish them, or, even better, use new types so that it is impossible to mess up.

> For example, the standard library function `String.split_first : sep:string -> string -> (string * string) option` uses labels to distinguish its arguments, yet `String.concat : string -> string list -> string` does not because the types are different.

**Avoid programming with indices.** An index in a list is most often _not_ the right idea. Using indices invites off-by-one errors that are not possible in a structural approach to the problem. Lean into pattern matching and forming your solution with structure rather than numbers because structure can be better visualized and verified.

> For example, to get the element in a list before the first one satisfying `p`, this:
> ```ocaml
> List.find_mapi (fun i x ->
>   if p x then List.nth_opt xs (i - 1) else None
> ) xs
> ```
> is less clear than:
> ```ocaml
> let rec find = function
>   | [] | [_] -> None
>   | prev :: next :: _ when p next -> Some prev
>   | _ :: tl -> find tl
> in
> find xs
> ```
> to a seasoned functional programmer, especially because the first raises an exception in the singleton list case satisfying `p`!

**Align delimiters.** Matching delimiters (e.g. `begin` and `end`, or `let` and `in`) should appear on the same line or be aligned in the same column. This helps the reader find the end of an expression by scanning in only one direction (either to the right or down).

**`begin`/`end`**. Delimit program constructs with `begin` and `end`. They are especially preferable to parentheses around control flow constructs like `match`, `if`, and `try`. For example, in the following, `begin match` reads like one keyword, and it aligns better than any parentheses would.

```ocaml
match x with
| [] ->
  begin match y with
  | None -> ...
  | Some z -> ...
  end
| _ -> ...
```

## Common patterns

**Name your types `t`.** Most types should be named `t`. This naturally encourages each type to live in its own module, where the module name describes that type `t`. This keeps modules focused and small, and it separates responsibilities by type. For example, `List.t` is the type of lists, and the `List` module is limited to only operations on lists. It also helps composability with functors.

**`module T`/`include T`**. When defining a type that will be passed to a functor, it is common practice to wrap the type and its operations in a module called `T`. Suppose you intend to implement this interface:

```ocaml
(* my_module.mli *)
type t = A of int
val compare : t -> t -> int
module Set : Set.S with type elt = t
```

A good design to avoid redefinitions and aliasing is:

```ocaml
(* my_module.ml *)
module T = struct
  type t = A of int
  let compare (A x) (A y) = Int.compare x y
end
include T
module Set = Set.Make (T)
```

**`module type S`**. When a module type is implemented by a functor, it is typical to call that module type `S`. While not descriptive by itself, the enclosing module provides the context, just like types named `t`. For example, `Set.S` is the module type of sets, and `Set.Make` is a functor that produces modules with type `Set.S`. This helps to keep modules focused--the `Set` module in the standard library contains little more than `S` and `Make`.

**Contain syntax in submodules**. Sugar does indeed have its place in your code, and that place is in submodules. If you define custom operators or `let`-syntax, then put them in submodules such as `Infix` and `Syntax` respectively, rather than in the top level. This keeps the default interface uncluttered and requires users to explicitly opt into the additional syntax. The [Option](https://ocaml.org/manual/5.5/api/Option.Syntax.html) module in the standard library does this. For example, with a monad,

```ocaml
(* monad.ml *)
module type S = sig
  type 'a m
  val return : 'a -> 'a m
  val bind : 'a m -> ('a -> 'b m) -> 'b m
  module Infix : sig
    val (>>=) : 'a m -> ('a -> 'b m) -> 'b m
    val (>>|) : 'a m -> ('a -> 'b) -> 'b m
  end
  module Syntax : sig
    val ( let* ) : 'a m -> ('a -> 'b m) -> 'b m
    val ( let+ ) : 'a m -> ('a -> 'b) -> 'b m
  end
end
```

The user must make it clear they are using sugar for a monad `M : Monad.S` by writing `open M.Syntax` or `let open M.Syntax in ...`. This tells the reader both what the sugar means and where it comes from.
