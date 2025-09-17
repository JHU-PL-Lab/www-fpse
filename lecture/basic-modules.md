# Modules Basics

We've been using modules without thinking too much about them: `List.map`, `Float.(2 = 3)`, `Fn.id` -- these are uses of modules `List`, `Float`, and `Fn` that are in the `Core` library.

Now we will look at how to define our own modules to make our own libraries and code components.

## What is a module?

A module is a collection of OCaml definitions:
* `let`-defined entities, i.e. functions and values
* types
* other modules

* Modules are something like records, but they can also hold e.g. types which makes them much more powerful.
* But, modules are not first class values like records -- for example, they can't directly be passed as arguments to functions.

## `.ml` files are modules

OCaml has a simple rule:
* The contents of a file `foo.ml` define the module `Foo`.
* Capitalize the first letter (only) and drop the `.ml` to turn a file name into its module name.

In this lecture, we'll work with a running example. See [set-example.zip](../examples/set-example.zip) for the full code.

Here is `string_set.ml` from that example:

```ocaml
open Core

type t = string list (* This is a *type abreviation*: a string set is a list of strings *)

let empty : t = [] (* the one canonical empty set *)

let add (x : string) (s : t) : t = x :: s

let rec remove (x : string) (s : t) : t =
  match s with
  | [] -> failwith "item is not in set"
  | hd :: tl ->
    if String.equal hd x
    then tl (* we don't remove from the tail: this is actually a multiset *)
    else hd :: remove x tl

let rec contains (x : string) (s : t) : bool =
  match s with
  | [] -> false
  | hd :: tl ->
    if String.equal x hd 
    then true 
    else contains x tl
```

### Loading a module into `utop`

Use `dune utop` to fire up the OCaml toploop with the module loaded.
- Then access the module's contents in `String_set`.

```sh
$ dune utop
```

```ocaml
# String_set.add "hello" String_set.empty ;;
- : String_set.t = ["hello"]
```

Or open the module with `open String_set` to put everything from inside it into scope:

```ocaml
# open String_set ;;
# add "hello" empty ;;
- : t = ["hello"]
```

- Here, the fact that we used a `list` to implement the set is exposed to library users.
- Naming the type `t` is standard for "the" underlying type in a module (if there is one).
  - Built-in libraries also use this: for example, `Int.t` is an alias for `int`, etc.
- Then, `String_set.t` is read as "string set's underlying type`.

## Hiding details with module types

Modules have _types_, called **module types** or **signatures**.
- The latter term is used in math, e.g. "a DFA has signature D = (S, Σ, τ, s0, F)"
- In a signature all the types of entities in the module are declared
- And, types declared in a module are repeated in the signature again (a bit odd, but for a reason)
- Module types are also placed in files, just put an `i` on the end
  - So for example the module type of `String_set` is in the `string_set.mli` file.
- Here are the contents of that file:

```ocaml
type t = string list (* Type declarations are by default copied from .ml to .mli file *)
(* type t (* this alternate version of type t declaration *hides* t's internals *) *)
val empty : t
val add : string -> t -> t
val remove : string -> t -> t
val contains : string -> t -> bool
```

* See how we repeat the `type t =` alias declaration in this `.mli` file
* But, there is an alterative way to write that declaration: remove `= string list`
  - comment the first line and uncomment the second to get that version
* By doing this, the type `t` has been made *abstract*: users no longer can see `t` is a list

Now if we save that change and type `dune utop`:

```ocaml
# String_set.add "hello" String_set.empty ;;
- : String_set.t = <abstr>
```

The printed value is now `<abstr>`, not `["hello"]` like before.
- The type is hidden; so are the values.

Why do this?
- Good:
  - Program to interfaces, not implementations.
  - We can change the implementation without changing client code.
  - The abstraction prevents misuse and maintains invariants.
- Bad:
  - It's hard to see what's going on in `utop`.
  - It can be harder to test our module.

Further, anything define in the `.ml` that is not declared in the `.mli` is not accessible to users.
- It's like those types/values are `private`.
- If there is nothing to hide, then you don't need an `.mli` file at all. The type of the module will be inferred.
- All assignments come with an `.mli` file so you get used to the format
   - Also the documentation specifying what a function does should go in the `.mli` file by convention
   - We have followed that pattern for Assignment 3

## Building modules

Recall that `dune` files are like `Makefile`s for OCaml
To make a library module from the `string_set.ml` file, we include this in the `dune` file:

```scheme
; in file `src/dune`
(library
 (name string_set)
 (modules string_set) 
 (libraries core)
)
```

## Writing executables

Let's make an actual executable program to do something, not just a library.

* The file `set_main.ml` is our example, it takes a string and a file name and looks for that line in the file.
* Executables work by running all statements in the file from top to bottom. Any side effects are the "outputs" of the executable.
* Note that pure functional programs are useless as executables, input and output is a side effect and we need it to write applications.
* Typically, the main work in an executable is put under a `let () = ...` statement. The `...` evaluates to `() : unit`, and the side effects it performs are what we see.

```ocaml
(* Just a helper function. Does not run until it's given arguments in `let () = ...` *)
let do_search search_string filename =
  let my_set =
    filename
    |> In_channel.read_lines
    |> List.fold ~f:(fun set elt -> String_set.add elt set) ~init:String_set.empty
  in
  if String_set.contains search_string my_set
  then print_string @@ "\"" ^ search_string ^ "\" found\n"
  else print_string @@ "\"" ^ search_string ^ "\" not found\n"

(* This statement has some printing side effects that we observe when running the executable *)
let () =
  match Array.to_list (Sys.get_argv ()) with
  | _ :: search_string :: filename :: _ -> do_search search_string filename
  | _ -> failwith "Invalid arguments: requires two parameters, search string and file name"
```

### Building executables

To build our executable, the `dune` file has a stanza for an `executable`:

```scheme
; in file `src/dune`
(executable
  (name set_main)
  (modules set_main)
  (libraries string_set core) ; uses Core and the String_set module we made
)
```

This makes an executable out of the `set_main.ml` file.

### Running executables

* If you declared an executable in `dune` as above, it will make a file `set_main.exe`
* To run it, you can do `dune exec -- ./src/set_main.exe "open Core" src/string_set.ml`
* Which is really just `_build/default/src/set_main.exe "open Core" src/string_set.ml` after building

### Aside: the `Stdio.In_channel` library used in this executable

* `set_main.ml` uses the `In_channel` module to read in file contents
  - (Note that I/O is a **side effect**, I/O functions do things besides the value returned)
* It is part of the `Stdio` module (which is itself included in `Core` so `Core.In_channel` is the same as `Stdio.In_channel`)
* The Documentation is [here](https://ocaml.org/p/stdio/latest/doc/Stdio/index.html); we will go through it to observe a few points
  - First, now that we covered abstract types we can see there is an abstract type `t` here
  - As with our own set, it is "the underlying data" for the module, in this case file handles
  - It is hidden though so we don't get access to the details of how "files are handled"
  - In Visual Studio hover over a function definition to get the docs

### Aside: Optional arguments

* One topic we skipped over which is in many of these libraries is **optional arguments**
* They are named arguments but you don't need to give them, indicated by a `?` before the name.
* If you *do* give them, they are like named aguments, use `~name:` syntax
* e.g. in `In_channel.read_lines`, `?fix_win_eol` is an optional boolean argument
  - To use it just add `~fix_win_eol: true` (since its optional and we want the default false we left it off)
  - If you write a function with an optional argument it will show up to you as an `option`-typed object: `Some` (given) or `None` (not given).
* Many languages now support optional arguments

Example of writing a function with an optional argument:

```ocaml
# let f ?x y = match x with Some z -> z + y | None -> y;;
val f : ?x:int -> int -> int = <fun>
# f ~x:1 2;;
- : int = 3
# f 2;;
- : int = 2
```

* Use them when they are the right thing: will reduce clutter of passing often un-needed items.

### Aside: The `Sys` library in the `set_main.ml` code

* We are using this library to read in the command line args, via `Sys.get_argv`.
* The documentation is [here](https://ocaml.org/p/core/latest/doc/Core/Sys/index.html)
  - Notice how this particular module has no carrier type `t`, it is just a collection of utility functions.


### Aside: Modules within modules

* It is often useful to have modules inside of modules for further code "modularization"
* The way it is declared is in e.g. `foo.ml` (which itself defines the items for module `Foo` using the above convention), add
  ```ocaml
  module Sub = struct 
    let blah = ...
   ...
  end
  ```
  where the `...` are the same kinds of declarations that are in files like `foo.ml`.
* This syntax is also how we can directly define a module in `utop` without putting it in a file.
* In the remainder of the file you can access the contents of `Sub` as `Sub.blah`, and outside of the `foo.ml` file `Foo.Sub.blah` will access.

### Aside: Referencing and disambiguating types declared in modules


```ocaml
module A = struct
  type t = { x : int ; y : bool }
end

let ra = A.{ x = 0 ; y = true } (* Need to write `A.` here to make the type `A.t` visible *)

module B = struct
  type t = { x : int ; z : float }
end

let rb = B.{ x = 0 ; z = 1.1 }
```

* Recall that `open` makes the contents of a module directly available.
* Now if `A` and `B` are both opened, the most recently opened `t` will win.

```ocaml
open A
open B

let f r = r.x (* type inferred for r is B.t, just like with newratio *)

(* A type annotation will disambiguate: *)
let f (r : A.t) : int = r.x
```

### Aside: @@deriving in modules

`@@deriving` names things slightly differently when used in a module.

Suppose we made a module out of our previous nucleotide example, either by putting in a file `nucleotide.ml` or adding `module Nucleotide = struct .. end` to make a top-loop or nested module:

```ocaml
module Nucleotide = struct
  type t = A | C | G | T [@@deriving equal]

  let hamming_distance l = failwith "dummy"
end
```
* When this type was called `nucleotide` not in a module the `ppx` made a function `equal_nucleotide`
* Here the `ppx` is smarter, instead of `Nucleotide.equal_t` it just makes `Nucleotide.equal` - `t` is a special type in the module
* Note that `[@@deriving ..]` declarations in types in the `.ml` file need to be repeated in the `.mli` file if the types are not hidden