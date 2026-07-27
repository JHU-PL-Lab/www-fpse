# OCaml Style Guide for FPSE

Here are the FPSE guidelines for writing well-formatted, good-looking OCaml code. [Here](./coding_guidelines.md) are the guidelines for writing _good_ code, not just _good-looking_ code, which we will cover later in the course.

It matters that your code is easy to read, and this means following conventions. These are not all hard rules: code style involves judgment. But consistency is important, and you should have a good reason to depart from the conventions below.

## Naming and documentation

**Casing conventions.**

| Kind                   | Convention                                       |
|------------------------|--------------------------------------------------|
| Files                  | `lowercase_with_underscores.ml(i)`               |
| Modules                | `Capitalized_with_underscores` (preferred over `CamelCase`, to match file names) |
| Variant constructors   | `Capitalized_with_underscores` or `CamelCase`    |
| Module types           | `ALL_CAPS_WITH_UNDERSCORES`                      |
| Types                  | `lowercase_with_underscores`                     |
| Values                 | `lowercase_with_underscores`                     |

Modules and variant constructors do not have a hard rule. Use what reads best, and stick with it.

**Use meaningful names for values.** A name should say what a value is or computes. Avoid single letters and unclear abbreviations, except for common conventions like `f` for an arbitrary function argument, `hd`/`tl` for list patterns, `t` for type names, etc.

For example, prefer `last_elt` over `x`, and `total_cost` over `tc`. Some common abbreviations for long words are fine, like `desc` instead of `description`.

**Write odoc comments.** Document your `.mli` files with `(** ... *)` comments below each value, type, and module. A short description of purpose and behavior is usually enough. Mention important edge cases, assumptions, exceptions, or effects. Remember that when a function is functional, it usually just returns something or _is_ something. It does not _do_, so choose your words to reflect this.

```ocaml
val normalize_opt : vector -> vector option
(** [normalize_opt v] is [Some u], where [u] is the unit vector in the
  direction of [v], if [v] is not the zero vector. It is [None] otherwise. *)
```

## Clarity

**Write short functions.** A function should do little more than what its name says. If you find yourself writing a long function, look for a natural point to split it into several functions, each with its own name and purpose. The natural breaking point is often where nesting gets deep.

**Explain with comments.** In `.ml` files, prefer clear code over comments, but add ordinary comments for non-obvious algorithms, invariants, design choices, or surprising edge cases.

**Do not overly nest.** Deeply nested `if`s, `match`es, or `let`s are hard to read because the reader must track many levels at once. This can be a sign that a function is doing too much and should be split up, or that a pattern match can be flattened (see below).

**Open judiciously.** Avoid `open`ing modules at the top of a file just to save typing; it makes it unclear where a name comes from. On the other hand, do not write out long qualified paths repeatedly. A local open is a good compromise:

```ocaml
let ten_ms =
  let open Mtime.Span in
  10 * ms
```

Long module paths can also be shortened with a module alias.

## Code shape

**Use blank lines to separate ideas.** Put blank lines between top-level definitions unless they are very closely related. Avoid large unbroken blocks of definitions.

**Keep lines short.** Most lines can and should be 80 characters or fewer, but this is not a hard rule. Sometimes code is more readable with a longer line (often because of long, descriptive names). Use 80 characters as a soft cutoff and 100 as a hard cutoff.

**Indent with meaning.** Indentation should reflect the structure of the code: a token is more indented than another exactly when it is nested more deeply. Consistent indentation lets a reader infer structure at a glance without having to match up keywords. If your code becomes _too_ indented because of this, it may be a sign that the structure is too deep, and you need to extract out some logic.

**Align delimiters.** Matching delimiters (`let`/`in`, `begin`/`end`, `(`/`)` etc.) should be on the same line or aligned in the same column, so a reader only has to scan in one direction to find the end of a block (right or down only). If a `let ... in` does not fit on one line, break it like this:

```ocaml
let good_name =
  expression
in
cont
```
so that `let` and `in` always line up, regardless of how long `expression` is.

This is easier to read than

```ocaml
let good_name =
  expression in
cont
```

The common exception is `struct`/`end` in modules, where the `end` usually aligns with the introductory `module` keyword to save a line and/or an indentation. For example:

```ocaml
module My_module = struct
  type t = Int_constr of int
end
```

**Use `begin`/`end` for structure.** Prefer `begin`/`end` over parentheses to delimit control-flow constructs like `match`, `if`, and `try`, especially when nested.

```ocaml
match x with
| A ->
  begin match y with
  | B -> 1
  | C -> 2
  end
| D -> 3
```

Use parentheses for ordinary grouping, function arguments, tuples, and operator precedence.

## Idioms

**Nest patterns, not matches.** If a `match` immediately matches again on a variable pattern, consider combining the patterns instead of nesting them.

```ocaml
match x with
| Some y ->
  begin match y with
  | A -> 1
  | B -> 2
  end
| None -> 0
```
is better written as
```ocaml
match x with
| Some A -> 1
| Some B -> 2
| None -> 0
```

**Use record punning.** When a field name and the variable it binds/matches/creates share the same name, use punning instead of writing it twice.

```ocaml
{ x = x; y = y }         (* prefer: *) { x; y }
match p with { x = x; y = y } -> ...    (* prefer: *) match p with { x; y } -> ...
{ p with x = x }          (* prefer: *) { p with x }
```

## Small details

**Two spaces instead of tabs.** Indent with two spaces. Tabs render inconsistently across editors and displays. Two spaces are just enough to visibly indent without losing much space to work with.

**No trailing whitespace.** Trailing whitespace can bloat diffs with invisible changes. Most editors can be configured to strip it automatically on save.

**Aboid many arguments.** Functions with many positional arguments of the same type are easy to call incorrectly, and they can be hard to read. Prefer fewer arguments, and use labels when a function needs several. Lots of arguments can also be a sign that conceptually related data is floating around loosely and should be put into a record or other data structure and passed as one argument.

**Use `@@` occasionally.** Use `@@` to avoid a pile of closing parentheses, especially for a final function argument.

```ocaml
print_string (String.concat ", " (List.map string_of_int (List.append xs ys)))
print_string @@ String.concat ", " (List.map string_of_int @@ List.append xs ys)
```

Beware that several uses of `@@` in the same expression can sometimes be confusing because of associativity:

```ocaml
print_string @@ String.concat ", " @@ List.map string_of_int @@ List.append xs ys
```

In this case, a pipeline with `|>`, an intermediate name, or a combination of `@@` and parentheses is often clearer.

**Do not overparenthesize.** Use only as many parentheses as necessary for function calls or when operator precedence is unclear. When in doubt about precedence, use parentheses for clarity.
