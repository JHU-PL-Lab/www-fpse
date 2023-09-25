## More Modules and Libraries

### Tangent: `ppx_jane` and `deriving`

* Recall `[@@deriving equal]` in the nucleotide example to get an `=` on that type "for free":

```ocaml
(* Needs #require "ppx_jane";; in top loop, 
   and (preprocess (pps (ppx_jane))) in as part of the library declaration 
   (i.e. it is (library (name ..)  .. (preprocess ... )) - one of the library decl components) *)
# type nucleotide = A | C | G | T [@@deriving equal];;
type nucleotide = A | C | G | T
val equal_nucleotide : nucleotide -> nucleotide -> bool = <fun>
```

* `[@@zibbo...]` notation in code indicates the line is processed by the macro named `ppx_zibbo`
* The `equal` is a parameter to the macro, here it is which `deriving` extension is added
* The `[@@deriving equal]` in particular causes an `equal_nucleotide` function to be automatically generated
* Without this function we would have to use pattern matching to write our own equality.

#### Composing `deriving equal`

* If we have an `xyy_equal` function on component types, `deriving` can derive `equal` for a type built from those components. For example equality on *lists* of nucleotides:

```ocaml
# type n_list = nucleotide list [@@deriving equal];;
type n_list = nucleotide list
val equal_n_list : n_list -> n_list -> bool = <fun>
# equal_n_list [A;A;A] [A;G;A];;
- : bool = false
# type n_queue = nucleotide Queue.t [@@deriving equal];;
type n_queue = nucleotide Core_kernel.Queue.t
val equal_n_queue : n_queue -> n_queue -> bool = <fun>
```
* Notice that the `Core` libraries are designed to play well as they have `List.equal`, `Queue.equal` built in
  - But, `List.equal : ('a -> 'a -> bool) -> 'a list -> 'a list -> bool` -- it needs `=` on the underlying list data.
  - This is a bit annoying as you keep having to pass `=` for members to check `'` for lists
  - .. we will eventually make a solid fix to this below
* Note that in general for a component type that is the `t` of a module, the name looked for is `My_module.equal` instead of `t_equal` - you can say `Float.equal` and don't need to say `Float.t_equal`.

### Some other useful `@@deriving` type accessor extensions in ppx_jane

* `sexp` generates S-expression printable representations of types which is handy for displaying data internals 
 - S-expressions are a general data format like JSON or XML, in fact they are the first such format

```ocaml
# type nucleotide = A | C | G | T [@@deriving equal, sexp];;
type nucleotide = A | C | G | T
val equal_nucleotide : nucleotide -> nucleotide -> bool = fun
val nucleotide_of_sexp : Sexp.t -> nucleotide = fun
val sexp_of_nucleotide : nucleotide -> Sexp.t = fun
# type n_list = nucleotide list [@@deriving equal, sexp];;
type n_list = nucleotide list
type n_list = nucleotide list
val equal_n_list : n_list -> n_list -> bool = fun
val n_list_of_sexp : Sexp.t -> n_list = fun
val sexp_of_n_list : n_list -> Sexp.t = fun
# sexp_of_n_list [A;G;G];;
- : Sexp.t = (A G G) (* this is the "S-Expression" version of a list.. parens and spaces *)
```

* `[@@deriving compare]` is analogous to `equal` except it makes a `compare` function instead of `equal`
* We covered this in the variants lecture

```ocaml
# type nucleotide = A | C | G | T [@@deriving compare];;
type nucleotide = A | C | G | T
val compare_nucleotide : nucleotide -> nucleotide -> int = fun
# compare_nucleotide A C;;
- : int = -1
utop # compare_nucleotide C A;;
- : int = 1
```
* `Core` does not have libraries for dealing with JSON unfortunately.
* But, someone else has made such a macro library, `ppx_deriving_yojson` which works with the `yojson` library to do something like what `deriving sexp` above did.
* With these libraries you can trivially define a to/from JSON format function on any type
 - this will save wear and tear on your fingers, no need to convert.

```ocaml
# #require "ppx_deriving_yojson";; (* see the ppx_deriving_yojson docs linked in HW for `dune` use *)
# type nucleotide = A | C | G | T [@@deriving yojson];;
type nucleotide = A | C | G | T
val nucleotide_to_yojson : nucleotide -> Yojson.Safe.t = fun
val nucleotide_of_yojson :
  Yojson.Safe.t -> nucleotide Ppx_deriving_yojson_runtime.error_or = <fun>
# nucleotide_to_yojson A;;
- : Yojson.Safe.t = `List [`String "A"] (* This is an OCaml inferred variant type *)
# type n_list = nucleotide list [@@deriving yojson];; (* extend to lists of nuc's *)
type n_list = nucleotide list
val n_list_to_yojson : n_list -> Yojson.Safe.t = <fun>
val n_list_of_yojson :
  Yojson.Safe.t -> n_list Ppx_deriving_yojson_runtime.error_or = <fun>
# n_list_to_yojson [A;A;G];;
- : Yojson.Safe.t =
`List [`List [`String "A"]; `List [`String "A"]; `List [`String "G"]]
# [A;A;G] |> n_list_to_yojson |> Yojson.Safe.pretty_to_string |> print_endline;;
[ [ "A" ], [ "A" ], [ "G" ] ]
- : unit = ()
```
* See the docs for more examples, in particular for records which is the bread and butter of JSON data: key-value collections.
* **Aside**: `ppx_deriving_yojson` is not compatible with `ppx_jane` so if you want to derive equality and comparisons along with `yojson` you need to use `#require "ppx_deriving.eq";; / [@@deriving eq]` and `#require "ppx_deriving.ord";; / [@@deriving ord]` in place of the `equal/compare` deriving in `ppx_jane`. 
## Defining Modules in the top loop

* We will now cover how you can define modules in the top loop.
* We mostly saw this already as the syntax is the same as how you defined a nested module
* Basic idea to input a module in top-loop: write `module My_module = struct ... end` with file contents inserted into the ".." part
* `struct` stands for structure, modules used to be called that in OCaml; view a `struct` as a synonym of a module.
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
* Use `module type Type_name_here = ... type here ...` to declare module types (`.mli` file equivalents):

```ocaml
module type Simple_set = (* module and module type namespaces are distinct, can re-use name *)
  sig (* everything up to end below is what would be in an .mli file *)
    type 'a t (* Do some type hiding here *)
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

* We previously defined nested modules in files, now lets define one in the top loop.

```ocaml
module Super_simple_core = struct
  module Simple_set = Simple_set (* previously typed in above *)
  module List = Core.List (* just borrow Core's list for our Super_simple_core *)
end
```

This would produce the same nested module as if we had a file `super_simple_core.ml` with only 
```ocaml
module Simple_set = Simple_set (* assumes we have simple_set on the library path in the dune file *)
module List = Core.List
```
in it.
### Functors

* Functors are simply parametric modules, i.e. functions from modules to modules
* They let us define a generic code library to which we can plug in some concrete code
    - in other words, just like what higher-order functions do except for modules
    - the main advantage is we get to include *types* as parameters since modules have types in them: very powerful!!
* Note that you don't want to make every dependent module a parameter as that would get too confusing.
   - `dune` automatically makes referenced libraries available so most of the time that is the way one module uses another.
* Functors are needed when the parameter module can be more than one thing.
#### Simple Functors Example

* Lets use a functor to fix the problem of the `equal` function needed as a parameter to `remove` and `contains` on our `Simple_set` module.
* (Note the `Core` libraries also do this for `Core.Set` for example)

```ocaml
(* The following module type is "some data type plus = on it" *)
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

* Notice how the type that was polymorphic, `'a` in the original `Simple_set`, is `M.t` here -- we are taking the type from the `Eq` module, that is the type we need.
    - In general there are many such programming patterns where types are treated more like data in OCaml -- adds to the power.
* This is a great example of the usefulness of functors - many different possible types and their equivalences could be supplied with different `M`'s.
### Using functors

* Pass a module to a functor to make a new module
* In other words, just like function application but on modules

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
* Note that we passed in a `String` module where the parameter had the `Eq` module type - why did this work?
* Answer: `String.t` is the underlying type of the string, and `String.equal` exists as an equality operation on strings, so `String` matches the `Eq` module type
 - (`utop` command `#show_module String` will dump the full module if you want to verify `t` and `equal` are there)
* Note `String` also has a whole **ton** of other functions, types, etc
  - but like with subclasses or Java interfaces you match a `sig` if you have "at least" the stuff needed.
* Here is one way you can test if a module matches a module type:

```ocaml
# module String2 = (String : Eq);;
module String2 : Eq
# module String2 : Eq = String;; (* Equivalent way to write the above *)
module String2 : Eq
```
 - This declares a new module `String2` which is `String` matched against the `Eq` type.
 - Note that `String2` is restricted to *only* have `t`/`equal` with this declaration

### Instantiating functors with our own custom type
Here is how we could instantiate the `Simple_set_functor` with our own data type

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

#### Types of functors

* Functors also have types; OCaml inferred a type for `Simple_set_functor` above but we can also declare it:

```ocaml
# module type SSF = functor (M : Eq) ->
    sig
      type t = M.t list
      val emptyset : t
      val add : M.t -> t -> t
      val remove : M.t -> t -> t
      val contains : M.t -> t -> bool
    end;;
```
* Observe the type is generally `functor (M : Module_type) -> sig ... end`
* Notice how the argument module `M` occurs in the result type since it has types in it
 - Such a type is called a *dependent type*

### Type Hiding

* The above implemetation of our simple set functor does not hide the fact that the underlying implementation is lists
* Recall the goal of "abstract data types (ADTS)" is for programmers to avoid exposing implementations 
* But, hiding is harder here than in the non-functor version: once we supply the `=` we have also fixed the type.  So e.g. `emptyset` is not polymorphic, it cannot be type `'a t` any more.
* One solution is to hide the type completely in the functor type:

```ocaml
module type SSF_hidden = functor (M : Eq) ->
    sig
      type t (* hide the type completely, no longer 'a t *)
      val emptyset : t
      val add : M.t -> t -> t
      val remove : M.t -> t -> t
      val contains : M.t -> t -> bool
    end;;
    module Simple_set_functor_hidden = (Simple_set_functor : SSF_hidden)
    module String_set_hidden = Simple_set_functor_hidden(String);;
```

### `Core`'s Set, Map, Hash table, etc

* The `Core` advanced data structures support something similar to what we did above
  - "plug in the comparison in an initialization phase and then forget about it"
* Here for example is how you make a map where the key is a built-in type (which has an associated module)

```ocaml
# module FloatMap = Map.Make(Float);; (* Or Char/Int/String/Bool/etc *)
module FloatMap :
  sig ... end
```

* Note it requires a bit more than just the type and comparison to be in `Float` for this to work with `Core`
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
Simpler way to do above: can inline the module definition, no need to name it
```ocaml
# module SListMap = Map.Make(struct type t = string list [@@deriving compare,sexp] end);;
module SListMap :
  sig .. end
```
* The above is a map where the *keys* are lists of strings
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
* We will go over the code of [school.ml](../examples/school.ml), simple code that uses a `Core.Map`.
* Note that there is a fancier way than `Map.Make` using advanced features we will cover in detail later: *first-class modules*.
  - We will look at [cool_school.ml](../examples/cool_school.ml) which re-writes the `school.ml` example to use first-class modules
  - The advantage of this code is you don't need to make a new module for every type you use it at
  - Imagine if for every `List` type we had to make an `IntList`, `StringList` etc module - painful!
  - (`List` itself avoids this problem by not being comparison-friendly, we had to pass in `compare` to `List.sort` for example)

### A few other module features: `include` and `with`

#### `include`

* `include` is pretty straightforward, it "copies/pastes" one module or module type's definitions inside a new definition.
* We used this in the earlier homeworks so you already saw it.
* It is a bit like inheritance in O-O languages
```ocaml
# module Sized_set = struct 
  include Simple_set 
  let size (s : 'a t) = List.length s
end
```
 * This will make a new module `Sized_set` which is the same as `Simple_set` but with an added `size` function.
 * Observe how `'a t` works to refer to a type in `Simple_set`, just like we had pasted all that stuff in.

 Similarly module types (and also functors) can use `include`

```ocaml
module type Size_set =
  sig
    include Simple_set
    val size : 'a t -> int
  end
```

#### `with`

* `with` is sometimes needed when you have a module type with an abstract `type t` (just the type name, no explicit definition)
 - Sometimes you made it just `type t` not to hide it like we did in `simple_set.mli`, but because **we didn't know it** - it is a generic type.
 - This is common in functor parameter module types in particular, e.g. our `Eq` above has a `type t` which is intended to be generic, not hidden.
 - Above everything worked fine because `t` was only a parameter, but if the functor result module type had a `type t` in it, it would be hidden and that might not be desired.
 
* Example: here is a type of modules which contain pairs (a toy example)
* We want this to be generic over any type of pair so we let `l` and `r` be undefined
```ocaml
module type Pair = 
  sig
    type l
    type r
    type t = l * r
    val left : t -> l
    val right : t -> r
  end;;
```
OK lets make a concrete example of the above on `int` and `string`
```ocaml
module Pair = struct 
 type l = int
 type r = string
 type t = l * r
 let left ((l:l), (r:r)) = l
 let right ((l:l), (r:r)) = r
end;;
```
Now the problem is if we put the above signature on the module, we hid too much!
```ocaml
# module Matched_pair = (Pair : Pair);;
module Matched_pair : Pair
# Matched_pair.left (4,"hi");;
Line 1, characters 19-20:
Error: This expression has type int but an expression was expected of type
         Matched_pair.l
# Pair.left(4,"hi");; (* problem was the module type Pair *)
- : int = 4
```

The solution is you can specialize abstract types in module types via `with`:

```ocaml
# module Matched_pair = (Pair : Pair with type l = int with type r = string);;
module Matched_pair :
  sig
    type l = int
    type r = string
    type t = l * r
    val left : l * r -> l
    val right : l * r -> r
  end
# Matched_pair.left (4,"hi");;
- : int = 4
```
Usually `with` is inlined like above, but it is just shorthand for defining a new module type:

```ocaml
# module type Pair_int_string = Pair with type l = int with type r = string;;
module type Pair_int_string =
  sig
    type l = int
    type r = string
    type t = l * r
    val left : l * r -> l
    val right : l * r -> r
  end
```

### Other Data Structures in `Core`

* `Core` has complete implementations of many classic data structures, many of which are built similarly with functor like `Map.Make`
* Be careful on imperative vs functional, look carefully to see which it is
* Functional data structures in `Core`:
  - `Set`, `Map`, `Doubly_linked` (list), `Fqueue`, `Fdeque` (functional (double-ended) queue)
* Imperative data structures:
  - `Stack` and `Queue` as we previously discussed (which don't need `Make`/`compare`), plus `Hash_queue`, `Hash_set`, `Hashtbl` (mutable hashed queue/set/map),  `Linked_queue`,  `Bag` (a multi-set)

### Tangent:  Summary of Important Directives for `utop`
* `#show_val` - shows the type of a value
* `#show_type` - expands a type definition (if it has an expansion)
* `#show_module` - shows all the elements inside a particular module *or functor*
* `#show_module_type` - as previous but for module types
* `#show` - the above four condensed into one command
* `#require` - loads a library (does not `open` it, just loads the module)
* `#use "afile.ml"` - loads code file as if it was copied and pasted into the top loop.
* `#mod_use` - like `#use` but loads the file like it was a module (i.e. like we typed `module Filename = struct ... contents of filename.ml ... end`)
* `#load "blah.cmo"`, `#load "blahlib.cma"` etc - load a compiled binary or library file (only the `.cmo/a` versions, the bytecode compiler).
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