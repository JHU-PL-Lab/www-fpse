## More Modules and Libraries

### Tangent-ish: `ppx_jane` and `deriving`

* We briefly hit on `[@@deriving eq]` syntax in the [Variants lecture](variants.html)
    - append to `type` declaration to get an `equal` function for free on our type.
* Here cover the Jane Street `ppx_jane` version of `[@@deriving ...]`
* Recall our genome type declaration with added `[@@deriving eq]` which made an `equal_nucleotide` function
* For the Jane Street equivalent just say `[@@deriving equal]` instead of `[@@deriving eq]`

```ocaml
(* Needs #require "ppx_jane";; in top loop, and (preprocess (pps (ppx_jane))) in dune file  *)
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

### Basic functors

* Functors are simply parametric modules, i.e. functions from modules to modules
* They let us define a generic code library to which we can plug in some concrete code
    - in other words, just like what higher-order functions do except for modules

Simple example: fix the problem of the `equal` function needed as a parameter to `remove` and `contains` on our `Simple_set` module.

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

### The Concept of "First Class Modules" 

* "First class X" in a programming language generally means X is usually not a directly-manipulable data object but it becomes one by making it a first class element.
* Example: in JavaScript message names are first-class, they are just strings.  In Java on the other hand they can't be dynamically created at run-time
* OCaml modules are generally "above" the expressions, they can contain expressions 
    but expressions normally don't contain modules, don't pass them to or return from functions, etc.
* The first-class modules extension lets modules to some degree be treated as regular data.
* Note that you could then use a function in place of a functor sometimes
    - But, first-class modules have some restrictions so use them only when needed
* We are going to make some elementary use of libraries using first-class modules now (e.g. `Map`, `Hashtbl`, etc in `Core`)

### Example use of Core.Map

* The `Core` libraries could have used the above functor method to define specific set etc modules at certain types
* But, to make them easier to use and avoid needing functors they use first-class modules.
* We will go over the code of [school.ml](examples/school.ml), some simple code that uses a `Core.Map`.

### Other Libraries

* We will briefly look at `Hashtbl` (a mutable map), `Set` (a functional set), `Bag` (a functional multiset), etc.

### Include
