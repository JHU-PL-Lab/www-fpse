# OCaml Style Guide for 601.329 Functional Programming in Software Engineering

Author: Kelvin Qian

## Preface

Clean, readable code is essential in software development, especially as code is more often read than written.  This style guide is largely (though not entirely) based off of the [OCaml Programming Guidelines](https://ocaml.org/learn/tutorials/guidelines.html#How-to-use-modules) from the official OCaml website; while there is no "official" style, that webpage reflects the consensus view of the OCaml community.  Other style guides include the [UPenn style guide](https://www.seas.upenn.edu/~cis341/current/programming_style.shtml#10) and the [Jane Street style guide](https://opensource.janestreet.com/standards/).

Many of these guidelines are more recommendations than absolute requirements; understand _why_ these guidelines are in place rather than just following them mindlessly, and if you decide to break a recommendation, you should have a good reason.  Software development, after all, is oftentimes more art than science.  That said, we do expect that you will generally follow these guidelines (in particular the ones with **bold** remarks below) to produce clean code, and we will take off points if your code is ugly or unreadable, including cases where guidelines were abused.

### Acknowledgements

This document would not have been made possible without the input of the whole FPSE team - myself, Dr. Scott, Devin Hill, and Shiwei Weng.  Special thanks is also given to Peter Frölich, whose C style guide served as the inspiration for this document.

## General Guidelines 

0. The golden rule of style: readability comes first.  Regardless of if you're an OCaml newbie or veteran, unreadable code is your worst enemy and is the source of many bugs.

1. Each line of code should be of reasonable length.  Traditionally this meant that each line had a max length of 80 columns, but this rule has [become less relevant](https://www.phoronix.com/scan.php?page=news_item&px=Linux-Kernel-Deprecates-80-Col) with modern displays.  While 80 columns does fit snugly inside a VSCode split-screen, feel free to bump the limit up to, say, 100 columns if you wish.  What is **not** acceptable are massive lines of 200+ columns or more that are either painful to side-scroll or are unreadable thanks to text wrapping.

2. Your functions should be short - a reader will either glaze over at an overly long function or be utterly confused from having to keep track of all the moving parts.  A good rule of thumb is that you should break up a function if it's longer than the height of your screen.  Functions in good functional code often outsource tasks to helper functions that each perform a single, specific, and easy to understand task.  (Note: you can get away with a longer function if it's _conceptually_ simple, such as a `match` statement with many short cases.)

3. Your functions should not have an excessive number of arguments - functions with five arguments are okay, seven arguments is a reasonable limit, and ten arguments is _really_ pushing it.  If you have a ton of function arguments, consider using a record.  (This also applies to the length of tuples being passed into functions; see the "Miscellaneous" section.)  Additionally, for functions with more than a couple arguments consider using named arguments (the `~f:...` in function definitions and uses): they make clear what the argument is at the function call site.

4. Do not duplicate code.  Functions that share functionality should have that code split off into a helper function that both can call, for example; if you wish to later fix that code, you'd only have to do it once and not twice.  That said, avoiding code duplication is sometimes either impossible or not worth it, so (like most things in this guide) use your best judgement.

5. Give descriptive names to your variables, (non-anonymous) functions, variants, etc.  We know what `add2` does, but what the heck does `foo` do?  (You might get away with it for local variables or when using `x` and `y` in mathematical functions, but even then some description can be useful, e.g. `counter` instead of `c`.)

6. Pattern matching is your friend in OCaml, and you should use it extensively to match on cases and destructure data structures.  For example, when you're destructuring lists, you should use the `::` pattern match syntax instead of `List.hd` and `List.tl`, which run the risk of throwing exceptions on empty lists.

7. Speaking of exceptions, they are used frequently in OCaml code, but they often make debugging difficult when they're thrown from deep within the code structure.  Especially for larger programs use `option` or `result` values, and handle errors locallly.

8. Use libraries like `Core` whenever possible instead of "rolling your own."  At the end of the day, it's not worth it to re-invent the wheel when there's correct, efficient code out there designed by OCaml experts and used/bugtested by thousands of people.  The only exceptions are 1) when we tell you not to use a certain library for pedagogical purposes and 2) when literally no library exists for your specific task.

9. In general, you should be writing functional code, with no mutation.  However, OCaml does have mutable data structures like refs and arrays, and sometimes there are cases where mutation and other non-functional constructs are useful.  Use them judiciously; don't shy away from mutation if it makes your code more elegant, but do not put for-loops everywhere either.  Also for some homework problems you will be required to avoid mutation.

## Naming Conventions

0. Naming conventions for variables and other identifiers provide a baseline level of consistency and cleaniness in your code.  They also allow for people familiar with these conventions to instantly identify whether something is a variable, module, and so on.  Coders often take naming conventions for granted, but they are an essential part of coding style; for these reasons, you **must** follow the following OCaml naming conventions in this course.

1. Variables, functions, and (non-module) type signtaures are written in `all_lowercase_using_underscores`, not using `camelCase` nor `using-dashes-aka-kebab-case`. 

2. Module names (both signatures and structs) are written similarly, with the exception that the first letter must be uppercase `Like_this`.  (In dune files, however, library names are `all_undercase`.)

3. Variant names are written in either `UpperCamelCase` or `Initial_upper_case_with_underscores`.  (Pick one and stick with it in your codebase.)

4. File names `use_underscores`, but directory names `use-dashes`.

## Indentation

In this course you will be **required** to use ocp-indent, which is an auto-indenter program that you should've installed via opam.  The convention dictated by ocp-indent mandates 2 spaces per indent, as opposed to the usual 4 spaces (let alone tab characters - eww).  To make ocp-indent format your code, use `option-shift-F` on Mac or `alt-shift-F` on Windows.  The following examples show how ocp-indent indents common OCaml expressions:

1. `let ... in ...` expressions.  Nested `let ... in ...` blocks should not be indented, but variable definitions should if they are placed on a new line.

```OCaml
let short_string = "s" in
let long_string = 
  "This is a very long string so it is indented and on a new line."
in
short_string ^ " " ^ long_string
```

2. `match` (and `with`) statements.  The patterns themselves align with the `match` keyword, while the inner expressions are indented if they are on a new line.

```OCaml
match x with
| Some _ -> 0
| None ->
  failwith "This is a long string, so we put it on a new line and indented it."
```

3. `if ... then ... else ...` expressions, The conditional branches should be idented, but the keyword `else` should not be.

```OCaml
if x then
  0 + 1 * 2
else
  3 + 4
```

As a side note, notice how the `if` and `then` keywords are on the same line, while the `else` keyword is on its own line.  In if-statements, predicate variables or expressions (in this case `x`) should be short, but branches can be (reasonably) long.

One thing to point out is that it's bad form to over-indent. ocp-indent should fix any cases of over-indentation, but just remember that this:

```OCaml
let rec map fn lst =
        match lst with
        | []      -> []
        | x :: xs -> (fn x) :: (match fn xs)
```

looks worse than this:

```OCaml
let rec map fn lst =
  match lst with
  | [] -> []
  | x :: xs -> (fn x) :: (match fn xs)
```

## Modules

0. Modules are a form of code encapsulation.  Creating modules and submodules is a good way to divide your code up and keep everything straight.

1. It is good practice to write `.mli` files for the `.ml` files you write.  They enforce separation between interface and implementation (a concept shared by other languages like C++ and Java) and provide a convenient place to put documentation (see "Documentation" below).  If your `.ml` file contains a lot of helper functions, `.mli` functions ensure that they are not exposed to other parts of the codebase, let alone external programs that may use your code as a library.

2. By the same token, it is good practice to write module type signatures for the submodules you write.  This goes doubly true if you have two or more modules that share tons of functionality - in that case consider having them share the same type signature as a shared interface.

3. Use the `open` keyword judiciously.  Many style guides will tell you to avoid using `open` for any module (except for standard libraries like `Core`); they have a point since opening modules without care can result in unwanted name shadowing, as well as confusion over which function belongs to which module.  However, never opening modules can result in `Long.Module_paths.Polluting.Your.codebase`.  In general, it is a good idea to use `open` in a module when:
  - The module is a standard library that you want to use throughout your entire environment (e.g. `Core`).
  - The module is closely related to the module it's being opened in (e.g. if you're opening `My_module` in `my_module_utils.ml`).
You should also take advantage of features like `let open` and the `Module.( ... )` syntax.  Both features restrict opening the module to a particular scope, allowing you to have the best of both worlds. 

4. When writing a module for a data structure, the type of the underlying data of the module is conventially written as `t` (for "type"), e.g. `String_set.t` is the type of a set of strings, not `String_set.string_set`.  This may seem to contradict the "give descriptive names" guideline we mentioned earlier, but the descriptiveness is already in the module name.  Note that `Core` uses this convention: for example `Core.Result.t` is the `Ok/Error` variant type.

## Documentation

0. Good documentation is a must in software engineering.  Imagine if you go back to some code you haven't touched in a year or more, and there are no comments.  Good luck.

1. Many people think that documentation = comments, but that is not necessarily true.  We already mentioned the "give descriptive names" guideline as one example.  Another example is using type annotations like `(x : int)` for function arguments and return types (which has the bonus benefit of helping the compiler perform type inference).  Good variable names and type annotations can be just as descriptive as comments to someone familiar with OCaml.

2. A good place to put comments is the `.mli` file, where you can describe functions and other parts of the module signature.  You can, of course, also put comments in the `.ml` file, but putting most of your documentation in the interface allows for comments to focus on _what_ something is doing or _why_ it exists, rather than _how_ it works; it also serves as API documentation if you choose to release your library to the wider world.

3. Both of the previous points hint at how _over-_documentation is a thing.  Over-documentation clutters the code and can make it unreadable.  For example, you should not spam the body of your functions with comments describing every little thing it does; instead, the bulk of the explaining should be done by the code.  That said, do put comments if the code isn't clear enough, or if there's unusual behavior, weird edge cases, interesting algorithms, etc. in your functions, but make sure to do so judiciously.

4. In `.mli` files, you should follow ocamldoc syntax when writing comments that describe functions or types - i.e. start your comments with `(**` instead of `(*`, and use square brackets to contain OCaml values (e.g. `(** [compare x y] compares two values in a certain way *)`).  For other comments, using `(*` is perfectly acceptable and ocamldoc syntax isn't required.

## Miscellaneous

1. `match ... with ...` is not the only pattern matching syntax around; you can perform destructuring using `let` bindings if there's only one case to match. `let` destructuring is often more concise than using `match ... with ...`.  For anonymous functions you can also directly pattern match in what was the argument position if you use the `function` keyword: `function [] -> [] | x::xs -> xs`.

2. Instead of parentheses, you can use `@@` or `begin ... end` syntax to make your code cleaner.  Use `|>` liberally, it makes a "pipeline" of function operations easier to understand at a glance.

3. Tuples should be short and simple.  Do not write tuples with many elements.  A ten-element tuple should instead be a record with named fields.

4. Following the above point, each record field should be defined on a new line.  (The same also applies to lists, but only if the list entries are complex and/or have long names).
