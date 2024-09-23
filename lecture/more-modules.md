## More Modules and Libraries

### Tangent: more on `ppx_jane` and `deriving`

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
type n_queue = nucleotide Core.Queue.t
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
# n_list_of_sexp (Sexp.of_string "(A G G)");; (* how to convert in the other direction *)
- : n_list = [A; G; G]
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


#### JSON format

* JSON is a common standard for data-as-text and may be useful in your project
* `Core` does not have libraries for dealing with JSON unfortunately.
  - `sexp` is the "JSON for Core"
* If you need JSON conversion, use `ppx_deriving_yojson` which works with the `yojson` library to do something like what `deriving sexp` above did.
* **Aside**: `ppx_deriving_yojson` is not compatible with `ppx_jane` so if you want to derive equality and comparisons along with `yojson` you need to use `#require "ppx_deriving.eq";; / [@@deriving eq]` and `#require "ppx_deriving.ord";; / [@@deriving ord]` in place of the `equal/compare` deriving in `ppx_jane`. `ppx_deriving show`, which prints variant type data, is also not compatible with `ppx_jane`.

## Defining Modules in the top loop or nesting them in a file

* Modules can be defined in the top loop just like how we had defined nested modules in a `my_module.ml` file
* Basic idea to input a module in top-loop: write `module My_module = struct ... end` with `my_module.ml` file contents inserted into the "..." part
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

* Notice how it infers a module type (aka signature, the old name for a module type -- `sig` at the start is for signature)
* We can also declare module types and explicitly declare along with the module
* Modules are to `.ml` files as Module types are to `.mli` files
* Use `module type Type_name_here = ... type here ...` to declare module types (`.mli` file equivalents):

```ocaml
module type Simple_set = (* module and module type namespaces are distinct, can re-use name *)
  sig 
    (* everything before the end below is what would be in an equivalent .mli file declaring this type *)
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

### Functors

* Functors are simply parametric modules, i.e. functions from modules to modules
* They let us define a generic code library to which we can plug in some concrete code
    - in other words, just like what higher-order functions do except for modules
    - the main advantage is we get to include *types* as parameters since modules have types in them: very powerful!!
* You only want to use a functor when there could be multiple modules to plug in.
  - Example A: if you just want to write code depending on our `Simple_set` module, use put `(libraries simple_et)` in the `dune` file and use it. 
  - Example B: on the other hand if you want to be able to "plug in" which implementation of sets you use, make a functor where the set module is a parameter.

#### Simple Functors Example

* Lets use a functor to fix the problem of the `equal` function needed as a parameter to `remove` and `contains` on our `Simple_set` module.
* (Note the `Core` libraries also do this for `Core.Set`, it is a functor)

```ocaml
(* This module type is "some data type plus equality on it" *)
module type Eq = sig 
type t
val equal: t -> t -> bool 
end

module Simple_set_functor (M: Eq) = (* this syntax defines a functor: a function on modules *)
struct
open Core
type t = M.t list (* Use M.t to grab the underlying type from module M *)
let emptyset : t = []
let add (x : M.t) (s : t) = (x :: s)
let rec remove (x : M.t) (s: t) =
  match s with
  | [] -> failwith "item is not in set"
  | hd :: tl ->
    if M.equal hd x then tl (* M.equal to use the equal function from M *)
    else hd :: remove x tl
let rec contains (x: M.t) (s: t) =
  match s with
  | [] -> false
  | hd :: tl ->
    if M.equal x hd then true else contains x tl
end
```

* Notice how the type that was polymorphic, `'a` in the original `Simple_set`, is a *parameter* `M.t` here -- we are taking the type from the `Eq` module, that is the type we need.
    - (In general there are many such programming patterns where types are treated more like data in OCaml -- adds to the power of OCaml.)
* With this code, the simple set can be set up to work at any type with equality, as we now show.
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
# module String2 : Eq = String;;
module String2 : Eq
# module String2 = (String : Eq);;  (* Equivalent way to write the above *)
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

* Functors also have types; OCaml inferred a type for `Simple_set_functor` above which was

```ocaml
module Simple_set_functor :
  functor (M : Eq) ->
    sig
      type t = M.t list
      val emptyset : t
      val add : M.t -> t -> M.t list
      val remove : M.t -> t -> M.t list
      val contains : M.t -> t -> bool
    end
```

 but we can also declare it:

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
 - Such a type is called a *dependent type*: the type of the result depends on the value of the argument

### Type Hiding

* In the above functor we were exposing the underlying implementation of the set used a list
* But, we can again do the same hiding trick we did in the `.mli` file etc: leave that off the type.
* Observe now that we have `type t` whereas in the original simple set we had `'a t`
   - its not a parametric type any more, the type parameter is in the module passed in
   - so after applying the functor that type is "baked in" to the resulting module.

```ocaml
module type SSF_hidden = functor (M : Eq) ->
    sig
      type t (* hide the type as before but just `type t` now not `type 'a t` *)
      val emptyset : t
      val add : M.t -> t -> t
      val remove : M.t -> t -> t
      val contains : M.t -> t -> bool
    end;;
    module Simple_set_functor_hidden : SSF_hidden = Simple_set_functor
    module String_set_hidden = Simple_set_functor_hidden(String);;
```

### File-based functors and type hiding

* The above is the top loop version of functors, but we will be using files in actual coding
* Code the `Simple_set_functor` above by putting it in the file, say file `simple_set.ml`
  - *and*, rename it `Make` so `Simple_set.Make(Float)` for example will make a `Simple_set`
  - this reads better, we are "making a simple set"; libraries also use this naming standard
* To hide information make a `simple_set.mli` file which lists the types of everything
  - There is a specific naming convention on how to do this which is subtle
  - We will review [set-example-functor.zip](../examples/set-example-functor.zip) which is our old set example redone as a functor

### `Core`'s Set, Map, Hash table, etc

* The `Core` advanced data structures support something similar to what we did above
  - "plug in the comparison in an initialization phase and then forget about it"
* Here for example is how you make a (functional) map where the key is a built-in type
* `Map.Make` is a functor just like our `Simple_set.Make` above
 - We need to supply the type of *keys* as we need to compare on them; the types of values is arbitrary so we let it be `'a` as in a list

```ocaml
# module FloatMap = Map.Make(Float);; (* Or Char/Int/String/Bool/etc *)
module FloatMap :
  sig ... end
# let mm = FloatMap.empty;;
val mm : 'a FloatMap.t = <abstr> (* t is the key type, and 'a is the value (anything for empty map) *)
# let mm' = Map.add_exn mm ~key:0.4 ~data:5;; (* Just use Map. interface since mm defines key type *)
val mm' : (float, int, FloatMap.Key.comparator_witness) Map.t = <abstr> (* three types: (key,value,witness) *)
(* observe above how the Map. functions return a different type; it is compatible with 'a FloatMap.t *)
# Map.find_exn mm' 0.4 ;; 
(* Use FloatMap.of_X functions to convert to a float map: *)
# let mm2 = FloatMap.of_alist_exn [2.3,"hi"; 3.3,"low"; 2.6,"medium"; 22.2,"wavy"];;
```

* (Ignore the above `FloatMap.Key.comparator_witness` type for now, we will learn about that later)
* Note it requires a bit more than just the type and `compare` to be in `Float` for this to work with `Core`
 - `#show Map.Make;;` will show the functor type and we can look at what `Map.Make`s argument expects
 - In particular to/from S-expression conversions are also needed; use `[@@deriving compare, sexp]` on your own type:

```ocaml
#require "ppx_jane";; (* this is in the ~/.ocamlinit so you should not need this *)
# module IntPair = struct
type t = int * int [@@deriving compare, sexp]
end;;
module IntPair :
  sig
    type t = int * int
    val compare : t -> t -> int
    val t_of_sexp : Sexp.t -> t
    val sexp_of_t : t -> Sexp.t
  end
# module IPMap = Map.Make(IntPair);;
module IPMap :
  sig ... end
# module IPSet = Set.Make(IntPair);;  (* Sets in Core also need compare (sorts internally) *)
...
# IPSet.empty |> Fn.flip Set.add (1,2) |> Fn.flip Set.add (3,2) |> Fn.flip Set.add (3,2) |> Set.to_list;;
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

* The "different arities" means one has a type parameter (`list`) and the other doesn't (`t`)
* Simple solution: explictly make a module for the list type you care about:

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
Another way to do above: can inline the module definition, no need to name it
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
* Notice how we refer to our pair map type as `'a IPMap.t`
  - The keys are integer pairs, that is built-in to `IPMap.t`, and the values are `'a`s, the parameter here
  - Compare with `'a list` instead of a map in the nodes; `'a List.t` is just an alias for that type:
  ```ocaml
  type 'a listtree = Leaf | Node of ('a List.t) * 'a listtree * 'a listtree;; 
  ```

### Larger Example Using Core.Map
* We will go over the code of [school.ml](../examples/school.ml), simple code that uses a `Core.Map`.
* Note that there is a fancier way than `Map.Make` using advanced features we will cover in detail later: *first-class modules*.
  - We will look at [cool_school.ml](../examples/cool_school.ml) which re-writes the `school.ml` example to use first-class modules
  - The advantage of this code is you don't need to make a new module for every type you use it at
  - Imagine if for every `List` type we had to make an `IntList`, `StringList` etc module - painful!
  - (`List` itself avoids this problem by not being comparison-friendly, we had to pass in `compare` to `List.sort` for example)

### The `with` type refinement operation


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

Sometimes we also want to inline the types we are instantiating in `with`: use `:=` in place of `=` for that:

```ocaml
# module Matched_pair = (Pair : Pair with type l := int with type r := string);;
module Matched_pair :
  sig type t = int * string val left : t -> int val right : t -> string end
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