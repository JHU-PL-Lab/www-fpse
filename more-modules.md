## More Modules and Libraries

### Tangent-ish: `ppx_jane` and `deriving`

* We briefly hit on `[@@deriving eq]` syntax in the [Variants lecture](variants.html)
    - append to `type` declaration to get an `equal` function for free on our type.
* Here cover the Jane Street `ppx_jane` version of `[@@deriving ...]`
* Recall our genome type declaration with added `[@@deriving eq]` which made an `equal_nucleotide` function
* For the Jane Street equivalent just say `[@@deriving equal]` instead of `[@@deriving eq]`

```ocaml
(* Needs #require "ppx_jane";; in top loop, 
   and (preprocess (pps (ppx_jane))) in as part of the library declaration *)
   (i.e. it is (library (name ..)  .. (preprocess ... )) - one of the library decl components)
# type nucleotide = A | C | G | T [@@deriving equal];;
type nucleotide = A | C | G | T
val equal_nucleotide : nucleotide -> nucleotide -> bool = fun
```
* The `[@@zibbo...]` indicates the type declaration is processed by the macro named `ppx_zibbo`
* The `equal` is a parameter to the macro, here it is which `deriving` extension is added
* The `[@@deriving equal]` in particular causes an `equal_nucleotide` function to be automatically generated
* Without this function we would have to use pattern matching to write our own equality.

#### Composing `deriving equal`

* If we have an `xyy_equal` function on component types, `deriving` can derive `equal` for a type built from those components:
```ocaml
# type n_list = nucleotide list [@@deriving equal];;
type n_list = nucleotide list
val equal_n_list : n_list -> n_list -> bool = fun
# equal_n_list [A;A;A] [A;G;A];;
- : bool = false
# type n_queue = nucleotide Queue.t [@@deriving equal];;
type n_queue = nucleotide Core_kernel.Queue.t
val equal_n_queue : n_queue -> n_queue -> bool = fun
```
* Notice that the `Core` libraries are designed to play well as they have `List.equal`, `Queue.equal` built in
* Generally for a component type that is the `t` of a module, the name looked for is `My_module.equal` instead of `t_equal`
* Similarly, if we are making our own module with its carrier type `t` it will also generate `My_module.equal` if we use `[@@deriving equal]`

### Some other useful `@@deriving` type accessor extensions in ppx_jane

* `sexp` generates S-expression printable representations of types which is handy for displaying data internals 
 - S-expressions are a general data format like JSON or XML, in fact they are the first such format
* For some reason the `Core` libraries make heavy use of S-expressions instead of JSON - a mistake really.
* It is not too hard to read S-expressions after a bit of staring
```ocaml
# type nucleotide = A | C | G | T [@@deriving equal, sexp];;
type nucleotide = A | C | G | T
val equal_nucleotide : nucleotide -> nucleotide -> bool = fun
val nucleotide_of_sexp : Sexp.t -> nucleotide = fun
val sexp_of_nucleotide : nucleotide -> Sexp.t = fun
 type n_list = nucleotide list [@@deriving equal, sexp];;
type n_list = nucleotide list
type n_list = nucleotide list
val equal_n_list : n_list -> n_list -> bool = fun
val n_list_of_sexp : Sexp.t -> n_list = fun
val sexp_of_n_list : n_list -> Sexp.t = fun
# sexp_of_n_list [A;G;G];;
- : Sexp.t = (A G G) (* this is the "S-Expression" version of a list.. parens and spaces *)
```
* `[@@deriving compare]` is analogous to `equal` except it makes a `compare` function instead of `equal`
```ocaml
# type nucleotide = A | C | G | T [@@deriving compare];;
type nucleotide = A | C | G | T
val compare_nucleotide : nucleotide -> nucleotide -> int = fun
# compare_nucleotide A C;;
- : int = -1
utop # compare_nucleotide C A;;
- : int = 1
```
* `Core` does have some libraries for dealing with JSON as well fortunately.
* For the homework there is a to/from JSON format function you can add to any type
 - this will save wear and tear on your fingers, no need to convert.

```ocaml
# #require "ppx_deriving_yojson";; (* see the ppx_deriving_yojson docs linked in HW for `dune` use *)
# type nucleotide = A | C | G | T [@@deriving yojson];;
type nucleotide = A | C | G | T
val nucleotide_to_yojson : nucleotide -> Yojson.Safe.t = fun
val nucleotide_of_yojson :
  Yojson.Safe.t -> nucleotide Ppx_deriving_yojson_runtime.error_or = fun
```

## Defining Modules in the top loop

* We will now cover how you can define modules in the top loop.
* The main reason we are covering this is it will help us understand nested modules and functors
     - generally the file-based method of defining a module we have done thus far is how modules are defined.

* Basic idea to input a module in top-loop: write `module My_module = struct ... end` with file in the `..
* `struct` stands for structure, modules used to be called that in OCaml; view a struct as = to a module.
* Modules are by default not expressions, so we normally can't define with `let`
* Simple set example put in top-loop syntax:

```ocaml
# module Simple_set = struct 
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
end;;
module Simple_set :
  sig
    type 'a t = 'a list
    val emptyset : 'a t
    val add : 'a -> 'a t -> 'a t
    val remove : 'a -> 'a t -> ('a -> 'a -> bool) -> 'a t
    val contains : 'a -> 'a t -> ('a -> 'a -> bool) -> bool
  end
# Simple_set.emptyset;;
- : 'a list = []
```

* Notice how it infers a module type (aka signature -- `sig` at the start is for signature)
* We can also declare module types and explicitly declare along with the module
* Use `module type Type_name_here = ... type here ...` to declare module types:

```ocaml
module type Simple_set = (* module and module type namespaces are distinct, can re-use name *)
  sig
    type 'a t
    val emptyset : 'a t
    val add : 'a -> 'a t -> 'a t
    val remove : 'a -> 'a t -> ('a -> 'a -> bool) -> 'a t
    val contains : 'a -> 'a t -> ('a -> 'a -> bool) -> bool
  end
  ```

Then can replace `module Simple_set = struct .. end` with
```ocaml
module Simple_set : Simple_set = struct ... end
```

and it will define the module with the above signature on it

## Nested modules

* OK generally we will use file-defined modules, why this detour into how to define them in top loop?
* Answer: the real use of the above syntax is it also lets us define *modules within modules* in files
   - which is in fact very useful
* We are using many of those already, e.g. `Core.List.map` means `List` is just a module inside `Core`.
* Modules nest exactly as you would expect, just write a `module My_module = struct .. end` declaration
 within a (file-based *or* top-loop-defined) module
* Here is an example 
    - (note we will do top-loop version here, could remove top/bottom two lines and put in file)

```ocaml
module Super_simple_core = struct

  module Simple_set = struct (* insert above code here ... *) end

  module List = Core.List (* just borrow Core's list for our Super_simple_core *)
end
```

### Basic Functors

* Functors are simply parametric modules, i.e. functions from modules to modules
* They let us define a generic code library to which we can plug in some concrete code
    - in other words, just like what higher-order functions do except for modules
* Like modules they are also "top-level-definable" only in basic OCaml
  - they are not expressions

#### Simple Functors Example

* Lets fix the problem of the `equal` function needed as a parameter to `remove` and `contains` on our `Simple_set` module.

```ocaml
module type Eq = sig 
type t
val equal: t -> t -> bool 
end

module Simple_set_functor (M: Eq) = 
struct
open Core
type t = M.t list
let emptyset : t = []
let add (x : M.t) (s : t) = (x :: s)
let rec remove (x : M.t) (s: t) =
  match s with
  | [] -> failwith "item is not in set"
  | hd :: tl ->
    if M.equal hd x then tl
    else hd :: remove x tl
let rec contains (x: M.t) (s: t) =
  match s with
  | [] -> false
  | hd :: tl ->
    if M.equal x hd then true else contains x tl
end
```

* Notice how the type that was polymorphic, `'a` in the original `Simple_set`, is `M.t` here -- we are
taking the type from the `Eq` module -- that is the type we need, the type over the `equal` operation. 
* To use the functor, just define a specific module by applying the functor to a module that has a type `t` and a function `equal : t -> t-> bool`.

* Alternate syntax for functors - anonymous form like with expression's "`function x -> ...`"

```ocaml
module Simple_set_functor = functor (M : Eq) -> struct  (stuff above ...) end
```
* (Can also make higher-order functors: pass and return functors from functors)

#### Types of functors

* Functors also have types, OCaml inferred a type for `Simple_set_functor` but we can also declare it:

```ocaml
# module type SSF = functor (M : Eq) ->
    sig
      type t = M.t list
      val emptyset : t
      val add : M.t -> t -> M.t list
      val remove : M.t -> t -> M.t list
      val contains : M.t -> t -> bool
    end;;
```
* Observe the type is generally `functor (M : Module_type) -> sig ... end`
* Notice how the argument module `M` occurs in the result type since it has types in it
 - Such a type is called a *dependent type*

### Using functors

* Pass a module to a functor to make a module specializing the parameter to what was passed
* In other words, just like a function but on modules

```ocaml
# module String_set = Simple_set_functor(String);;
module String_set :
  sig
    type t = string list
    val emptyset : t
    val add : string -> t -> string list
    val remove : string -> t -> string list
    val contains : string -> t -> bool
  end
```
* Note that we passed in a `String` module where the parameter had the `Eq` module type
* `String.t` is the underlying type of the string, and `String.equal` exists as an equality operation on strings, so `String` matches the `Eq` module type
 - (`utop` command `#show_module String` will dump the full module if you want to verify `t` and `equal` are there)
* Note `String` also has a whole **ton** of other functions, types, etc
  - but like with subclasses or Java interfaces you match if you have "at least" the stuff needed.
* Here is one way you can test if a module matches a module type:

```ocaml
# module String2 = (String : Eq);;
module String2 : Eq
# module String2 : Eq = String;; (* Equivalent way to write the above *)
module String2 : Eq
```
 - This declares a new module `String2` which is `String` matched against the `Eq` type.
 - Note that `String2` is restricted to *only* have `t`/`equal` with this declaration (`String` of course keeps everything, no mutuation!)

* Here is how we could instantiate the `Simple_set_functor` with our own data type

```ocaml
# #require "ppx_jane";;
# module Nucleotide = struct type t = A | C | G | T [@@deriving equal] end;;
module Nucleotide : sig type t = A | C | G | T val equal : t -> t -> bool end
# module Nuc_set = Simple_set_functor(Nucleotide);;
module Nuc_set :
  sig
    type t = Nucleotide.t list
    val emptyset : t
    val add : Nucleotide.t -> t -> Nucleotide.t list
    val remove : Nucleotide.t -> t -> Nucleotide.t list
    val contains : Nucleotide.t -> t -> bool
  end
  ```

* Note this requires us to make a module out of our type
* (also note that we used `[@@deriving equal]` to make the `equal` for free)
  - (and note it is given the name `Nucleotide.equal` and not `Nucleotide.equal_nucleotide`, since it is in a module and is the type `t` there)

### `Core`'s Set, Map, Hash table, etc

* The `Core` advanced data structures support something similar to what we did above
  - "plug in the comparison in an initialization phase and then forget about it"
* Here for example is how you make a map where the key is a built-in type (which has an associated module)

```ocaml
# module FloatMap = Map.Make(Float);; (* Or Char/Int/String/Bool/etc *)
module FloatMap :
  sig ... end
```

* Note it requires a bit more than just the type and comparison to be in `Float` for this to work
 - to/from S-expression conversions needed; use `[@@deriving compare, sexp]` on your own type:

```ocaml
#require "ppx_jane";;
# module IntPair = struct
type t = int * int [@@deriving compare, sexp]
end;;
module IntPair :
  sig
    type t = int * int
    val compare : t -> t -> int
    val t_of_sexp : Sexplib0.Sexp.t -> t
    val sexp_of_t : t -> Sexp.t
  end
# module IPMap = Map.Make(IntPair);;
module IPMap :
  sig ... end
# module IPSet = Set.Make(IntPair);;  (* Sets in Core also need compare (sorts internally) *)
...
# IPSet.(empty |> Fn.flip add (1,2) |> Fn.flip add (3,2) |> Fn.flip add (3,2) |> to_list);;
- : IntPair.t list = [(1, 2); (3, 2)]
```

Observe that only non-parametric types can be keys for maps:

```ocaml
# module FloatMap = Map.Make(List);;
Line 1, characters 27-31:
Error: Signature mismatch:
       ...
       Type declarations do not match:
         type 'a t = 'a list
       is not included in
         type t
       They have different arities.
       File "src/map_intf.ml", line 29, characters 2-35: Expected declaration
       File "src/list.mli", line 12, characters 0-48: Actual declaration
```

* Mildly annoying solution: explictly make a module for the list type you care about:

```ocaml
# module SList = struct type t = string list [@@deriving compare,sexp] end;;
module SList :
  sig
    type t = string list
    val compare : t -> t -> int
    val t_of_sexp : Sexp.t -> t
    val sexp_of_t : t -> Sexp.t
  end
# module SListMap = Map.Make(SList);;
module SListMap :
  sig ... end
```
* This is a map where the *keys* are lists of strings
* The above examples show how non-trivial data structures can be map keys
* Here is the opposite, how we can make e.g. a variant with maps in it.
* This assumes the keys are integer pairs, and the values can be any type (`'a`)

```ocaml
# type 'a intpairmaptree = Leaf | Node of ('a IPMap.t) * 'a intpairmaptree * 'a intpairmaptree;; 
type 'a intpairmaptree =
    Leaf
  | Node of 'a IPMap.t * 'a intpairmaptree * 'a intpairmaptree
```

### Larger Example Using Core.Map
* We will go over the code of [school.ml](examples/school.ml), simple code that uses a `Core.Map`.
* Note that there is a fancier way than `Map.Make` using advanced features we have not covered yet: *first-class modules*.
  - We will peek at [cool_school.ml](examples/cool_school.ml) which re-writes the `school.ml` example to use first-class modules
  - The advantage of this code is you don't need to make a new module for every type you use it at
  - Imagine if for every `List` type we had to make an `IntList`, `StringList` etc module - painful!
  - (`List` itself avoids this problem by not being comparison-friendly, we had to pass in `compare` to `List.sort` for example)

### Other Data Structures in `Core`

* `Core` has complete implementations of many classic data structures, many of which are built similarly with functor like `Map.Make`
* Be careful on imperative vs functional, difference is not well-documented or consistently-named
* Functional data structures in `Core`:
  - `Set`, `Map`, `Bag` (a multi-set), `Doubly_linked` (list), `Fqueue`, `Fdeque` (functional (double-ended) queue)
* Imperative data structures:
  - `Stack` and `Queue` as we previously discussed (which don't need `Make`/`compare`), plus `Hash_queue`, `Hash_set`, `Hashtbl` (mutable hashed queue/set/map),  `Linked_queue`

### Tangent:  Summary of Important Directives for `utop`
* `show_val` - shows the type of a value
* `#show_type` - expands a type definition (if it has an expansion)
* `#show_module` - shows all the elements inside a particular module *or functor*
* `#show_module_type` - as previous but for module types
* `#show` - the above four condensed into one command
* `#require` - loads a library (does not `open` it, just loads the module)
* `#use "afile.ml"` - loads code file as if it was copied and pasted into the top loop.
* `#mod_use` - like `#use` but loads the file like it was a module (name of file as a module name)
* `#load "blah.cmo"`, `#load "blahlib.cma"` - load a compiled binary or library file.
* `#use_output "dune top"` - run a command and assume output is top loop input commands.  
  - The particular argument `dune top` here generates top loop commands to load the current project.
  - If `dune utop` is not working this is very similar but less glitchy.
* `#directory adir` - adds `adir` to the list of directories to search for files.
* `#pwd` - shows current working directory.
* `#cd` - changes directory for loads etc.
* `#trace afun` - subsequent calls and returns to `afun` will now be dumped to top level - a simple debugging tool.
* `#help` - in case you forget one of the above

Also, standard edit/search keys work in `utop`:
* control-R searches for a previous input with a certin string in it
* control-P / control-N go up and down to edit, control-A is start of line, control-E is end, control-D deletes current
* up/down arrow go to previous/next inputs