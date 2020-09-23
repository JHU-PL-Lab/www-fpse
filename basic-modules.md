
### Modules basics

* We have seen OCaml modules in action, e.g. `List.map`, `Float.(=)`, `Fn.id`, etc.
* We also covered how modules are collections of functions, values, types, and other modules
* Now we want to cover how individual `.ml` files define modules
    - and, how to hide some items in a module (think `private` of Java/C++) via `.mli` file signatures
* Also we will cover how most modules are *libraries* of auxiliary functions but how modules may also define *executables*.
* ... there are also many more fancy module features which we will cover later

* We are going to use a running example to explain these concepts; see [simple-set.zip](examples/simple-set.zip) for the full example


### `.ml` files as modules

The contents of the file `simple_set.ml` in the above is the following:
```ocaml
open Core

type 'a t = 'a list

let emptyset : 'a t = []

let add (x : 'a) (s : 'a t) = (x :: s)

let rec remove (x : 'a) (s: 'a t) (equal : 'a -> 'a -> bool) =
  match s with
  | [] -> failwith "item is not in set"
  | hd :: tl ->
    if equal hd x then tl
    else hd :: remove x tl equal

let rec contains (x: 'a) (s: 'a t) (equal : 'a -> 'a -> bool) =
  match s with
  | [] -> false
  | hd :: tl ->
    if equal x hd then true else contains x tl equal
```
* This is just a set implemented as a list; it is in fact a multiset
* The line `type 'a t = 'a list` is a *type abbreviation*, `'a t` is a synonym for `'a list`
* Naming a type just `t` is the standard for "the" underlying type of a module
    - When outsiders use this module the type will be `Simple_set.t`, read "Simple set's type"
    - `Core` extensively uses this convention in libraries
* Notice how the functions needing `=` we have to pass it in explicitly to be polymorphic
    - In `Core.Set` there is in fact a much better solution but involves fancier modules which we cover later
* Notice also that we declare types on the function parameters for readability, "`x : t`"
    - "Can let them be inferred at first but paste in the inferred ones later"

#### Building the library

This file can be built as a library module with the dune file

```scheme
(library
 (name simple_set)
 (modules simple_set) 
 (libraries core)
)
```

And if you want to play with your library module, command `dune utop` from the same directory will load it into the top loop:

```ocaml
myshell $ dune utop
...
utop # Simple_set.add 4 Simple_set.emptyset;;
- : int list = [4]
```

* Notice how the file name is `simple_set.ml` and it produces a module `Simple_set`
 - This is the standard, capitalize the first letter (only) going from file to module
* One thing potentially annoying here is the fact that we used a list gets exposed here
 - But, we can use type abstraction to hide this; next topic

#### Other ways to load a module into the top loop besides `dune utop`

* If you type `#use "simple_set.ml";;` it is just like copy/pasting the code of the file in -- you won't get a module.
* If you want to "paste a file in the top loop as a module", there is a command for that however:
  `#mod_use "simple_set.ml";;`
* And if that was not enough there is one more method: you can `#use_output "dune top"`
  - this runs the shell command `dune top` and pastes the output into the top loop; that `dune` command generates byte code files and then spits out a bunch of `#load` commands to load all the libraries as well as your code.

### Information Hiding with Module Signatures

* Modules also have types, they are called *signatures*
* When a module is defined in a file `simple_set.ml`, make a file `simple_set.mli` for its corresponding signature
    - the added "`i`" is for "interface"
* You don't need an `.mli` file if there is nothing to hide, the type will be inferred
    - But, even if nothing is hidden the `.mli` is good as a document of what is provided to users

So, here the `simple_set.mli` file from the above zip:

```ocaml
    type 'a t    (* hide the type 'a list here by not giving it in signature *)
    val emptyset : 'a t
    val add: 'a -> 'a t ->'a t
    val remove : 'a -> 'a t ->  ('a -> 'a -> bool) -> 'a t
    val contains: 'a -> 'a t ->  ('a -> 'a -> bool) -> bool 
```

Now if we `dune utop` with this added file we get

```ocaml
myshell $ dune utop
...
utop # Simple_set.add 4 Simple_set.emptyset;;
- : int Simple_set.t = <abstr>
```

* Notice how the `int list` result type from before is now `int Simple_set.t` 
  - it is the `t` type from module `Simple_set` and the parameter `'a` there is instantiated to `int`.
* Also notice that the value is `<abstr>`, not `[4]` like before; since the type is hidden so are the values
* This is both 
  - advantageous (program to interfaces, not implementations)
  - not adventageous (sometimes hard to see what is going on)
* We will come back to this topic later in the course

### Making an OCaml executable

* So far all we have made is libraries; let us now make a small OCaml executable.
* We will make a main module `Set_main` (in file `set_main.ml` of course) which takes a string and a file name and looks for that line in the file.

Here is what we need to add to the `dune` file along with the above to build the executable:

```scheme
(executable
  (name set_main)
  (libraries simple_set core)
  (modules set_main)
)
```


* We will now inspect `set_main.ml` in VSCode so we can use the tool tips to check out various types

#### The `Stdio.In_channel` library

* `set_main.ml` uses the `In_channel` module to read in file contents
* It is part of the `Stdio` module (which is itself included in `Core` so `Core.In_channel` is the same as `Stdio.In_channel`)
* The Documentation is [here](https://ocaml.janestreet.com/ocaml-core/latest/doc/stdio/Stdio/In_channel/index.html); we will go through it to observe a few points
  - First, now that we covered abstract types we can see there is an abstract type `t` here
  - As with our own set, it is "the underlinying data" for the module, in this case file handles
  - It is hidden though so we don't get access to the details of how "files are handled"
  - If you are used to object-oriented programming you are looking for a constructor/new; in functional code look for functions that only return a `t`, that is making a new `t`: `create` here.

#### Optional arguments tangent

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

#### The `Sys` library

* We are using this library to read in the command line args, via `Sys.get_argv`.
* We will also take a quick look at its documentation [here](https://ocaml.janestreet.com/ocaml-core/latest/doc/core/Core__/Core_sys/index.html)
  - Notice how this particular module has no carrier type `t`, it is just a collection of utility functions.

#### Running executables

* If you declared an executable in `dune` as above, it will make a file `my_main_module.exe` so in our case that is `set_main.exe`
* To exec it you can do `dune exec ./src/set_main.exe "open Core" src/simple_set.ml`
* Which is really just `_build/default/src/set_main.exe "open Core" src/simple_set.ml`