# More Modules and Libraries

## Defining Modules in the top loop or nesting them in a file

* Modules can be defined in the top loop just like how we had defined nested modules in a `my_module.ml` file
* Basic idea to input a module in top-loop: write `module My_module = struct ... end` with `my_module.ml` file contents inserted into the "..." part
* `struct` stands for structure, modules used to be called that in OCaml; view a `struct` as a synonym of a module.
* Here is a string set example put in top-loop syntax:

```ocaml
# module String_set = struct
  open Core

  type t = string list

  let empty : t = []

  let add (x : string) (s : t) : t = x :: s

  let rec remove (x : string) (s : t) : t =
    match s with
    | [] -> failwith "item is not in set"
    | hd :: tl ->
      if String.equal hd x
      then tl
      else hd :: remove x tl

  let rec contains (x : string) (s : t) : bool =
    match s with
    | [] -> false
    | hd :: tl ->
      if String.equal x hd 
      then true 
      else contains x tl
end
module String_set :
  sig
    type t = string list
    val empty : t
    val add : string -> t -> t
    val remove : string -> t -> t
    val contains : string -> t -> bool
  end
```

* Notice how it infers a module type (aka signature, the old name for a module type -- `sig` at the start is for signature)
  - Everything inside of `sig ... end` is _exactly_ like what we would see in an `.mli` file.
* Modules are to `.ml` files as module types are to `.mli` files
* We can also define module types and explicitly use them to annotate the module.
* Use `module type TYPE_NAME_HERE = sig ... declarations here ... end` to define module types (`.mli` file equivalents).
  - It is common to use all capital letters when naming module types, but this is not enforced by the language.

```ocaml
module type STRING_SET = sig
  (* everything before the `end` below is what would be in an equivalent .mli file declaring this type *)
  type t (* Do some type hiding here by not saying what the type is, just that it exists *)
  val empty : t
  val add : string -> t -> t
  val remove : string -> t -> t
  val contains : string -> t -> bool
end
```

Now we can define the `String_set` module to have exactly this signature.

```ocaml
module String_set : STRING_SET = struct ... end
```

Notice the parallel to when we define types and values as we've done in the past:

```ocaml
type t = ... (* like `module type STRING_SET = sig ... end` above *)

let x : t = ... (* like `module String_set : STRING_SET = struct ... end` above *)
```

We can take this similarity even further. Just like we have functions on values, we can have functions on modules, called "functors".

## Functors

* Functors are parametric modules, i.e. functions from modules to modules
* They let us define a generic code library to which we can plug in some concrete code
    - in other words, just like what higher-order functions do except for modules
    - the main advantage is we get to include *types* as parameters since modules have types in them: very powerful!!
      * When we say "very powerful", we mean it! Don't overlook this!
* You only want to use a functor when there could be multiple modules to plug in.
  - Example A: if you just want to write code depending on our `String_set` module, use put `(libraries string_set)` in the `dune` file and use it. 
  - Example B: on the other hand if you want to be able to "plug in" which implementation of sets you use, make a functor where the set module is a parameter.

### Simple example

Above, we wrote a module that defined sets of strings.
- But the same code could be used to define sets of any type with just a small change!
- To write a set over at type, all we need is a notion of equality on that type.

We don't have to hard-code for strings. As long as we can pass in a type `t` and an `equal` function, then we can make a set over that type.
- We define a module type `EQ`, which will be the type of our module argument.

```ocaml
(* This module type is "some data type plus equality on it" *)
module type EQ = sig
  type t
  val equal : t -> t -> bool
end
```

Now we can write a module for sets, where the type of elements is passed in an as argument.

```ocaml
(* M is the argument to the Make_set functor *)
module Make_set (M : EQ) = struct
  (* In here, we can use M, both it's type t and the equal function. *)
  open Core

  (* Use M.t to grab the underlying type from module M *)
  type t = M.t list (* Sets are lists of M.t *)

  let empty : t = []

  let add (x : M.t) (s : t) : t = (x :: s)

  let rec remove (x : M.t) (s : t) : t =
    match s with
    | [] -> failwith "item is not in set"
    | hd :: tl ->
      if M.equal hd x (* M.equal is the equal function from M *)
      then tl 
      else hd :: remove x tl

  let rec contains (x : M.t) (s : t) : bool =
    match s with
    | [] -> false
    | hd :: tl ->
      if M.equal x hd 
      then true 
      else contains x tl
end
```

Here is the similarity to types and values as we've seen before, just to demonstrate syntactic similarity.

```ocaml
type eq = ... (* like `module type EQ = sig ... end` *)

let make_set (m : eq) = ... (* like `module Make_set (M : EQ) = struct ... end` *)
```

* The reason we use functors is because we can pass in types _and_ functions on those types.
  * You can't pass in a type to a normal function!

### Using functors

* Pass a module to a functor to make a new module
* In other words, just like function application but on modules
  - The syntax is annoying that we need parentheses around all functor arguments, but we should still use spaces between arguments.
* Top loop example:

```ocaml
# module Int_set = Make_set (Int);;
module Int_set :
  sig
    type t = int list
    val empty : t
    val add : int -> t -> t
    val remove : int -> t -> t
    val contains : int -> t -> bool
  end
```

* Note that we passed in a `Int` module where the parameter had the `EQ` module type - why did this work?
* Answer: `Int.t` is the underlying type of the string, and `Int.equal` exists as an equality operation on strings, so `Int` matches the `EQ` module type
   - (`utop` command `#show_module Int` will dump the full module if you want to verify `t` and `equal` are there)
* Note `Int` also has a whole **ton** of other functions, types, etc
  - but like with subclasses or Java interfaces you match a `sig` if you have "at least" the stuff needed.
* Here is one way you can test if a module matches a module type:

```ocaml
# module Int2 : EQ = Int;;
module Int2 : EQ

# module Int2 = (Int : EQ);;  (* Equivalent way to write the above *)
module Int2 : EQ
```

- This declares a new module `Int2` which is `Int` matched against the `EQ` type.
- Note that `Int2` is restricted to *only* have `t`/`equal` with this declaration.
  - Everything else has been chopped off.

ALARM!
- The type `t` in `EQ` is abstract. This means the type in `Int2` is now abstract; it is not observably equivalent to `int`.
- This is a slightly complex issue. We'll address it later in detail.
- But for the curious, here is a way we could make sure the type is still observably `int`.

```ocaml
# module Int3 : (EQ with type t = int) = Int;;
module Int3 : sig type t = int val equal : t -> t -> bool end
```

### Instantiating functors with our own custom type

Here is how we could instantiate the `Make_set` functor with our own data type. We'll do it on nucleotides in the top loop.

```ocaml
# #require "ppx_jane";;

# module Nucleotide = struct type t = A | C | G | T [@@deriving equal] end;;
module Nucleotide : sig type t = A | C | G | T val equal : t -> t -> bool end

# module Nuc_set = Make_set (Nucleotide);;
module Nuc_set :
  sig
    type t = Nucleotide.t list
    val empty : t
    val add : Nucleotide.t -> t -> Nucleotide.t list
    val remove : Nucleotide.t -> t -> Nucleotide.t list
    val contains : Nucleotide.t -> t -> bool
  end
```

* Note this requires us to make a module out of our type.
* also note that we used `[@@deriving equal]` to make the `equal` for free
  - and note it is given the name `Nucleotide.equal` and not `Nucleotide.equal_nucleotide`, since it is in a module and is the type `t` there

### Types of functors

* Functors also have types; OCaml inferred a type for `Make_set` above which was

```ocaml
module Make_set :
  functor (M : EQ) ->
    sig
      type t = M.t list
      val empty : t
      val add : M.t -> t -> M.t list
      val remove : M.t -> t -> M.t list
      val contains : M.t -> t -> bool
    end
```

but we can also declare it:

```ocaml
module type MAKE_SET = functor (M : EQ) -> sig
  type t = M.t list
  val empty : t
  val add : M.t -> t -> t
  val remove : M.t -> t -> t
  val contains : M.t -> t -> bool
end
```

* Observe the type is generally `functor (M : Module_type) -> sig ... end`
* Notice how the argument module `M` occurs in the result type!
  - Such a type is called a *dependent type*: the type of the result depends on the value of the argument.
* Functor types are module types. Just like function types are regular types.
  - Writing `type f = t1 -> t2` is similar to writing `module type F = functor (X : S1) -> S2`
  - Function types are types; functor types are module types.

### Type Hiding

* In the above functor we were exposing the underlying implementation of the set, which used a list.
* But, we can again do the same hiding trick we did in the `.mli` file etc: leave that off the type.
* Observe now that we have `type t` whereas in the original simple set we had `'a t`
   - it's not a parametric type any more, the type parameter is in the module passed in
   - so after applying the functor that type is "baked in" to the resulting module.

```ocaml
module type MAKE_SET_HIDDEN = functor (M : EQ) -> sig
  type t (* Hide the type as we did in STRING_SET *)
  val empty : t
  val add : M.t -> t -> t
  val remove : M.t -> t -> t
  val contains : M.t -> t -> bool
end

(* The old implementation works. But this just hides the type in the resulting module *)
module Make_set_hidden : MAKE_SET_HIDDEN = Make_set

module Int_set_hidden = Make_set_hidden (Int)
```

### File-based functors and type hiding

* The above is the top loop version of functors, but we will be using files in actual coding
* Code the `Make_set` functor above by putting it in the file, say file `simple_set.ml`
  - *and*, rename it `Make` so `Simple_set.Make (Float)`, for example, will make a `Simple_set`.
  - This reads better, we are "making a simple set"; libraries also use this naming standard.
  - An `.mli` file cannot be a functor itself, so you have to do this if you want functors with file-based modules.
* To hide information, make a `simple_set.mli` file which lists the types of everything.
  - There is a specific naming convention on how to do this which is subtle.
  - We will review [set-example-functor.zip](../examples/set-example-functor.zip) which is our old set example redone as a functor.

### `Core`'s Set, Map, Hash table, etc

* The `Core` advanced data structures support something similar to what we did above
  - "plug in the comparison in an initialization phase and then forget about it"
* Here for example is how you make a (functional) map where the key is a built-in type
* `Map.Make` is a functor just like our `Simple_set.Make` above
 - We need to supply the type of *keys* as we need to compare on them; the types of values is arbitrary so we let it be `'a` as in a list

```ocaml
module FloatMap = Map.Make (Float) (* Or Char/Int/String/Bool/etc. Anything that is comparable and serializable *)

(* Alias the empty map -- maps are functional, so there is one canonical empty map *)
let mm : 'a Floatmap.t = FloatMap.empty

(* Use the Map module to work with all maps. *)
let mm' : int Floatmap.t = Map.add_exn mm ~key:0.4 ~data:5
(* int Floatmap.t is equivalent to 

    val mm' : (float, int, FloatMap.Key.comparator_witness) Map.t

  It has three type parameters: key, value, and witness to the way the keys are compared
*)

(* evaluates to 5 *)
let data_5 = Map.find_exn mm' 0.4

(* Use FloatMap.of_X functions to convert to a float map: *)
let mm2 = FloatMap.of_alist_exn [2.3,"hi"; 3.3,"low"; 2.6,"medium"; 22.2,"wavy"]
```

* We will ignore the above `FloatMap.Key.comparator_witness` type for now. We will learn about that later.
* Note it requires a bit more than just the type and `compare` to be in `Float` for this to work with `Core`
 - `#show Map.Make;;` will show the functor type and we can look at what `Map.Make`s argument expects
 - In particular to/from S-expression conversions are also needed; use `[@@deriving compare, sexp]` on your own type in the top loop:

```ocaml
# #require "ppx_jane";; (* this is in the ~/.ocamlinit so you should not need this *)

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

# module IPMap = Map.Make (IntPair);;
module IPMap :
  sig ... end (* big long omitted type *)

# module IPSet = Set.Make (IntPair);;  (* Sets in Core also use compare (it sorts internally) *)
...

# IPSet.empty |> Fn.flip Set.add (1,2) |> Fn.flip Set.add (3,2) |> Fn.flip Set.add (3,2) |> Set.to_list;;
- : IntPair.t list = [(1, 2); (3, 2)]
```

Observe that only non-parametric types can be keys for maps:

```ocaml
# module ListMap = Map.Make (List);;
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

* The "different arities" means one has a type parameter (`list`) and the other doesn't (`t`).
* Simple solution: explictly make a module for the list type you care about.
  * Say we want to make maps where keys are string lists.

```ocaml
# module SList = struct type t = string list [@@deriving compare, sexp] end;;
module SList :
  sig
    type t = string list
    val compare : t -> t -> int
    val t_of_sexp : Sexp.t -> t
    val sexp_of_t : t -> Sexp.t
  end

# module SListMap = Map.Make (SList);;
module SListMap :
  sig ... end
```

And remember that we can inline module definitions, so the following will work, too.

```ocaml
# module SListMap = Map.Make (struct type t = string list [@@deriving compare,sexp] end);;
module SListMap :
  sig .. end
```

* The above is a map where the *keys* are lists of strings.
* The above examples show how non-trivial data structures can be map keys.
* Here is the opposite, how we can make e.g. a variant with maps in it.
* This assumes the keys are integer pairs, and the values can be any type (`'a`).

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

### A Small Example Using Core.Map
* We will go over the code of [school.ml](../examples/school.ml), simple code that uses a `Core.Map`.
* Note that there is an alternative to `Map.Make` using advanced features we will cover in detail later: *first-class modules*.
  - We will briefly look at [cool_school.ml](../examples/cool_school.ml) which re-writes the `school.ml` example to use first-class modules
  - The advantage of this code is you don't need to make a new module for every type you use it at
  - Also avoids the `Map.add` vs `IntMap.empty` issue of two different interfaces to use same map.

### The `with` type refinement operation


* `with` is sometimes needed when you have a module type with an abstract `type t` (just the type name, no explicit definition)
 - Sometimes you made it just `type t`, not to hide it like we did in `simple_set.mli`, but because **we didn't know it** - it is a generic type.
 - This is common in functor parameter module types in particular, e.g. our `EQ` above has a `type t` which is intended to be generic, not hidden.
 - Above, everything worked fine because `t` was only a parameter, but if the functor result module type had a `type t` in it, it would be hidden, and that might not be desired.
 
* Example: here is a type of modules which contain pairs (a toy example)
* We want this to be generic over any type of pair so we let `l` and `r` be undefined
```ocaml
module type PAIR = sig
  type l
  type r
  type t = l * r
  val left : t -> l
  val right : t -> r
end
```

OK lets make a concrete example of the above on `int` and `string`:

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
# module Matched_pair = (Pair : PAIR);;
module Matched_pair : PAIR

# Matched_pair.left (4,"hi");;
Line 1, characters 19-20:
Error: This expression has type int but an expression was expected of type
         Matched_pair.l

# Pair.left (4,"hi");; (* This shows problem was the module type PAIR, not the original module Pair *)
- : int = 4
```

The solution is you can specialize abstract types in module types via `with`:

```ocaml
# module Matched_pair = (Pair : PAIR with type l = int with type r = string);;
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

Usually `with` is inlined like above, but it is just shorthand for defining a new module type, and inlining that module type:

```ocaml
# module type PAIR_INT_STRING = PAIR with type l = int with type r = string;;
module type PAIR_INT_STRING =
  sig
    type l = int
    type r = string
    type t = l * r
    val left : l * r -> l
    val right : l * r -> r
  end
```

`with` is often needed in functors which need to expose a type in a parameter:

```ocaml
(* random data with equality *)
module type DATUM = sig
  type t
  val equal : t -> t -> bool
end

module Make_pair_dumb (Datum1 : DATUM) (Datum2 : DATUM) : PAIR = struct
  type l = Datum1.t (* Oops this gets hidden since PAIR type just has "type l" *)
  type r = Datum2.t (* ditto *)
  type t = l * r
  let left (p : t) = match p with (a,_) -> a
  let right (p : t) = match p with (_,b) -> b
  let equal (p1 : t) (p2 : t) = Datum1.equal (left p1) (left p2) && Datum2.equal (right p1) (right p2)
end

module Example_pair_dumb = Make_pair_dumb (Int) (String)
(* Example_pair_dumb.left (1,"e") fails, we hid the fact that l/r are int/string *)
```

Let us fix this by specializing the `Pair` module type with `with`:

```ocaml
module Make_pair_smarter (Datum1 :  DATUM) (Datum2 :  DATUM) : (PAIR with type l = Datum1.t with type r = Datum2.t) = struct
  type l = Datum1.t
  type r = Datum2.t
  type t = l * r
  let left (p : t) = match p with (a,_) -> a
  let right (p : t) = match p with (_,b) -> b
  let equal (p1 : t) (p2 : t) = Datum1.equal (left p1) (left p2) && Datum2.equal (right p1) (right p2)
end

module Example_pair_smarter = Make_pair_smarter (Int) (String)
```

Sometimes we might want to *inline* the types we are instantiating in `with`: use `:=` in place of `=` for that:

```ocaml
module Make_pair_smartest (Datum1 :  DATUM) (Datum2 :  DATUM) : (PAIR with type l := Datum1.t with type r := Datum2.t) = struct
  (* type l = Datum1.t *) (* Not needed! They were destructively substituted! *)
  (* type r = Datum2.t *)
  type t = Datum1.t * Datum2.t
  let left (p : t) = match p with (a,_) -> a
  let right (p : t) = match p with (_,b) -> b
  let equal (p1 : t) (p2 : t) = Datum1.equal (left p1) (left p2) && Datum2.equal (right p1) (right p2)
end

module Example_pair_smartest = Make_pair_smartest (Int) (String)
```

This could use an example to really spell out:

```ocaml
module type TLIST = sig
  type a 
  type t = a list
end

(* Substitutes `int` in for `a` and then deletes `a`. *)
module type INTLIST = TLIST with type a := int

(* Equivalent definition: *)
module type INTLIST = sig
  (* No type a! It's been deleted *)
  type t = int list
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