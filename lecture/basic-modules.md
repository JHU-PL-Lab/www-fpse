# Modules Basics

We've already _used_ modules without thinking too much about them: `List.map`, `Float.(2 = 3)`, `Fn.id` -- all these come from modules in the `Core` library.

Now it's time to look under the hood:
* What are modules in OCaml?
* How do files become modules?
* How can we hide details with signatures (`.mli` files)?
* How do we work with modules in the toploop?
* How do nested modules work?

In future lectures, we'll learn more advanced features like functions on modules. But first, the basics.

## What is a module?

A module is a _collection_ of OCaml definitions:
* types
* values (including functions, which are values)
* other modules

Since we know records: records are collections of values, each with a name.

A module is a _bit_ like a record, but it can hold many different kinds of things, not just values. However, modules are not first class values like records.

## `.ml` files are modules

OCaml has a simple rule:
* The contents of a file `foo.ml` define the module `Foo`.
  - Capitalize the first letter (only) and drop the `.ml`.

In this lecture, we'll work with a running example. See [set-example.zip](../examples/set-example.zip) for the full code.

Here is `string_set.ml` from that example:

```ocaml
open Core

type t = string list (* the type of a string set is a list of strings *)

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

This creates a module `String_set` with:
* a type `t`
* four values `empty`, `add`, `remove`, and `contains`.

### Using it in `utop`

Use `dune utop` to fire up the OCaml toploop with the module loaded.
- Then access the module's contents in `String_set`.

```sh
$ dune utop
```

```ocaml
# String_set.add "hello" String_set.empty ;;
- : string list = ["hello"]
```

Or open the module with `open String_set` to put everything from inside it into scope:

```ocaml
# open String_set ;;
# add "hello" empty ;;
- : string list = ["hello"]
```

Here, the fact that we used a `list` is _exposed_ in the type and the value.
- We made the _type abbreviation_ with `type t = string list`. So `t` is a synonym for `string list`.
- Naming the type `t` is standard for "the" underlying type in a module.
- Then, `String_set.t` is read as "string set's type`.

## Hiding details with module types

Modules have _types_, called **module types** or **signatures**.
- The latter term is used in math, e.g. "a DFA has signature D = (S, Σ, τ, s0, F)"

The type of `String_set` can be written out and put in the `string_set.mli` file.
- The added "i" is for "interface".

```ocaml
type t (* Declare a type t, but don't define it, so the type is hidden to all users *)
val empty : t
val add : string -> t -> t
val remove : string -> t -> t
val contains : string -> t -> bool
```

The type `t` has been made abstract. We did not write `type t = string list`.

Now in `utop`:

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
- All assignments come with an `.mli` file so you get used to the format, and they serve as documentation, which is always good!

## Building modules

We use `dune` to build our code in this class.

To make a library module from the `string_set.ml` file, we use this `dune`.

```scheme
; in file `src/dune`
(library
 (name string_set)
 (modules string_set) 
 (libraries core)
)
```

See [set-example.zip](../examples/set-example.zip) for the full code.

## Writing executables

So far, we have only made libraries. Now, we'll write a small OCaml executable.

We will write the executable in `set_main.ml`, which takes a string and a file name and looks for that line in the file.

Executables work by running all statements in the file from top to bottom. Any side effects are the "outputs" of the executable.

Typically, the main work in an executable is put under a `let () = ...` statement. The `...` evaluates to `() : unit`, and the side effects it performs are what we see.

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

To build an executable, the `dune` file has a stanza for an `executable` instead of a `library`:

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
* To run it, you can do `dune exec -- ./src/set_main.exe "open Core" src/simple_set.ml`
* Which is really just `_build/default/src/set_main.exe "open Core" src/simple_set.ml` after building

## More examples

### The `Stdio.In_channel` library

* `set_main.ml` uses the `In_channel` module to read in file contents
  - (Note that I/O is a **side effect**, I/O functions do things besides the value returned)
* It is part of the `Stdio` module (which is itself included in `Core` so `Core.In_channel` is the same as `Stdio.In_channel`)
* The Documentation is [here](https://ocaml.org/p/stdio/latest/doc/Stdio/index.html); we will go through it to observe a few points
  - First, now that we covered abstract types we can see there is an abstract type `t` here
  - As with our own set, it is "the underlying data" for the module, in this case file handles
  - It is hidden though so we don't get access to the details of how "files are handled"
  - If you are used to object-oriented programming you are looking for a constructor/new; in functional code look for functions that only return a `t`, that is making a new `t`: `create` here.

### Optional arguments tangent

* One topic we skipped over which is in many of these libraries is **optional arguments**
* They are named arguments but you don't need to give them, indicated by a `?` before the name.
* If  you *do* give them, they are like named aguments, use `~name:` syntax
* e.g. in `In_channel.create`, `val create : ?⁠binary:Base.bool -> Base.string -> t`
  - an optional flag `~binary:true` could be passed to make a binary file handle
  - example usage: `In_channel.create ~binary:false "/tmp/wowfile"`
* Many languages now support optional arguments (not so 10 years ago - newer feature)

Writing your own functions with optional arguments is easy: the value passed in is an `option` type

```ocaml
# let f ?x y = match x with Some z -> z + y | None -> y;;
val f : ?x:int -> int -> int = <fun>
# f ~x:1 2;;
- : int = 3
# f 2;;
- : int = 2
```

* Use them when they are the right thing: will reduce clutter of passing often un-needed items.

### The `Sys` library

* We are using this library to read in the command line args, via `Sys.get_argv`.
* We will also take a quick look at its documentation [here](https://ocaml.org/p/core/latest/doc/Core/Sys/index.html)
  - Notice how this particular module has no carrier type `t`, it is just a collection of utility functions.


### Modules within modules

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
* Assignment 3 includes some nested modules, this time with more purpose; we will take a look.