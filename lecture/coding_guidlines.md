
# Coding Guidelines for FPSE

**Be explicit.** Don't make the reader solve a puzzle; tell them what is happening by being explicit. Implicit behavior requires lots of hard thinking to understand, whereas explicit behavior can be read straight off the page. This guide here is all about how to be explicit in your code so that you are clear in your intent and so that others can review, understand, and extend your code easily and correctly.

## General guidelines

**Functional first.** Functional code shows you everything you need to know. Every outcome is in the return type. Imperative code, on the other hand, has side effects and state that you must know about and keep in mind; the returned value, if any, is not the only outcome of calling the function. Keep the scope small and prefer functional solutions. But remember: this is "functional first", not "functional only". Use imperative style where it is the least cumbersome style.

**Name your data.** Avoid long pipelines (`|>`) of nameless functions. Instead, give a helpful name to each result, and do not go out of your way to create such pipelines. Use pipelines if you have excellently named each step so that each function in the pipeline speaks for itself.

**Don’t be too clever.** The most elegant solution is not always the best one. Readability is about more than just concision. Write the shorter code if doing so does not drastically increase complexity. Point-free programming (function composition, partial application, etc.) is often clever but unreadable. Be explicit and simple without being overly verbose.

**Encapsulate with modules.** Your code should be grouped into meaningful, coherent modules. Modules should have a single purpose, and that purpose is often to contain a single type and several functions that work mainly on that type. Writing code in this way separates responsibilities and creates appropriate abstraction boundaries. Then, **document with interface files**. Interfaces are a great spot to comment and to think critically about the purpose of your module.

**The one true way to work with lists is pattern matching.** Using too many combinators clouds the structure of your solution and leads to indirect solutions to problems. Moreover, such code is likely to have many nested function calls without explanatory variable names. We prefer to read this:

```ocaml
let rec map f l =
  match l with
  | [] -> []
  | hd :: tl -> f hd :: map f tl
```

as opposed to this:

```ocaml
let rec map f l =
  if List.is_empty l
  then []
  else List.cons (f (List.hd l)) (map f (List.tl l))
```

That said...

**Know your standard library.** It is not too big (and that is a good thing), so you should know what it provides. It will solve many simple problems for you. Never reimplement anything that is in the standard library.

**Too much syntactic sugar is bad for your teeth.** Stick to the core language and write a few extra characters where it helps readability. Sugar should only be helpful; if it does anything too implicit, then your code cannot be read at a glance. Sugar can include custom infix operators, excessive use of `@@` and `|>`, partial function application, opened modules, and ppx-generated behavior. Use these features when they clarify and avoid them when they don't.

**Options over exceptions.** Exceptions for recoverable failures require the programmer to _remember_ to catch them. Options _force_ the programmer to handle them. Don’t leave anything up to chance, and favor options in your interfaces. Results allow you to express reasons for failure and are a good alternative to options.

**Abstract as necessary.** Use abstraction to avoid duplication and to avoid hardcoding. Abstraction should enhance readability by allowing the reader to focus on the fundamental problem the code at hand is solving. It should not hinder readability by being too implicit or clever. A piece of code lacks abstraction when the same idea is repeated in several places or buried under irrelevant detail.

**Parse, don’t validate.** Use new types to parse your data into always-valid forms where illegal states are unrepresentable. Avoid implicit invariants or frequent re-validation. Effective use of types can often uphold those invariants by themselves and will aid in readability.

**New types, not aliases.** New types force structure and separation, while aliases may accidentally cross data because they do not create distinct types. New types also document themselves in interfaces.

**Use the appropriate data structure.** Lists, ints, and strings are not the solutions to all your problems, as much as C wants you to think. Think carefully about the structure of your problem and the data structure it requires. Much of the time, a simple variant or record type is the appropriate solution. When an advanced data structure is required, there is probably a standard library module or an opam package for it, and these can be easy to drop into your code.

**Libraries, not frameworks.** Frameworks are opinionated and invite conflicts. Good luck using more than one of them at a time. Adopt these sparingly, and only when they are fundamental to your project. A good library is useful and not restrictive. It is easily pluggable and will not steer the direction of your code for you. In general, though, avoid depending on too many frameworks and libraries for single-use purposes because every dependency you have is one more that the reader of your code has to understand. Dependencies can be heavy, and they should be worth their weight.

## Specific suggestions

**Pattern match and destructure.** Pattern matching and `let`-destructuring (e.g. `let a, b = ... in ...`) are some of OCaml's clearest tools, and they express intent very explicitly. Use them liberally.

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

**Monomorphic, not polymorphic, comparison.** Performance aside, monomorphic comparison (e.g. `String.equal`) is defined specifically for the type at hand, while polymorphic comparison may not behave as intended. Polymorphic comparison is too structure-sensitive (e.g. on sets), may fail at runtime (e.g. on functions), and may be unsound in the presence of existential types (e.g. in GADTs). Further, type-specific comparison documents the type you intend to compare.

**Do not write long anonymous functions.** Anonymous functions should always be short. If one becomes long, then help your reader by naming it, thereby making it no longer anonymous. This frequently applies to function arguments to mapping and folding; if the argument is long and inlined, the behavior is mysterious.

**Label function arguments of the same type.** If any two arguments have the same type, you invite the caller to confuse them, or you require them to read a documenting comment. Instead, use labelled arguments to distinguish them, or, even better, use new types so that it is impossible to mess up.

**Prefer records over tuples.** Tuples are useful for transiently packing data together, but they should not be used for meaningful, long-lived groupings of data. When defining types, choose to make a new record instead of aliasing a tuple type.
