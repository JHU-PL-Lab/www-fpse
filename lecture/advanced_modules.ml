(* ******************************************* *)
(* More on types, modules, functors and hiding *)
(* ******************************************* *)

open Core
(* Will need #require "ppx_jane" in top loop
   and (preprocess (pps ppx_jane)) line in dune for this file to work *)

(* Review: the Big Picture of what is unique in OCaml types

  * One of the most novel/powerful/frustrating aspects of OCaml is the types
  * There are things you can do with types that likely no language you have ever seen supports.
  * In particular the way that they can be treated like data in modules, e.g. String.t etc
  * It helps a lot to understand the different uses of type variables, let us review that now.

 * Type variables can be polymorphic: 'a 'b etc -- very similar to Java generics
   - f : 'a -> 'a for example really means for ANY type 'a, f has type 'a -> 'a (universal)
   - We have not covered them yet but you can also declare such polymorphic types via (type a)
   - This is more like Java generics which requires generic types to be declared:
*)

let f (type a) (x : a) = x;;

(*
 * Type variables can be PARAMETERS on type - to - type functions *)

type 'a my_option = My_some of 'a | My_none

(*
   - my_option is a FUNCTION from an unknown type 'a to a type
   - f : 'a -> 'a my_option is not the same as the above, it means for ALL 'a again.

   - Alternate notation OCaml didn't use but which would let the above make more sense:
   type my_option('a) = Some of 'a | None -- 'a is clearly a PARAMETER here
   f : 'a -> option('a)  - 'a is a UNIVERSAL type passed to option which results in a type.

 * Type variables can be ALIASES
    - pretty straightforward hopefully - multiple names for the same type.
 *)

type float_alias = float
let f (x : float_alias) = x +. 1.
let sid (x : String.t) = x (* String.t is aliased to be `string` via "type t = string" in String *)

(*
 * Type variables can denote existential (hidden) types in module types
*)

module type Eq = sig type t val equal : t -> t -> bool end

(*

 - if a module is given this type the type `t` in that module is COMPLETELY hidden from outsiders
 - They know there EXISTS some type there (which is an actual type), they just don't know what it is.
 - So, they never, ever can directly do anything with such a t-typed object
 - An existential type is a type variable alias where you don't know what it is aliased to.
 - Recall that the notion of something existing but not directly defined is a fundamental part of math:
    "for all x there EXISTS a y such that y > x" -- many math assertions have "exists" in them.
 - if you want to see if something is an alias or an existential, ask to #show it; you will see aliased type.

# #show String.t;;
type nonrec t = string (* alias *)
# #show Map.t;;
type nonrec ('key, 'value, 'cmp) t = ('key, 'value, 'cmp) Map.t (* existential / hidden *)

 * Moral: every time you see a type variable reference t / 'a / Int.t / etc
    first sort it into one of the above four categories

*)

(* *************************************** *)
(* Module type hiding and un-hiding review *)
(* *************************************** *)

(* First we review sharing constraints ("with" in module types) 
   this is similar to what we did in the more-modules lecture but 
   we will make the code more generic with functors - like HW 3/4 *)

(* A module type for data that equal works on *)   
module type Datum_i = sig
  type t
  val equal : t -> t -> bool
end

(* a type of pairs over data t *)

module type Pair_i = sig
  type t
  type lr
  val create: t -> t -> lr
  val left : lr -> t
  val right : lr -> t
  val equal : lr -> lr -> bool
end

(* Version "-1" pair module maker functor is dumb and completely useless, 
   we can't see the type of the pair elements since Pair_i has existential t as the type *)

module Make_pair_dumb(Datum : Datum_i) : Pair_i = 
struct
  type t = Datum.t
  type lr = t * t
  let create (l : t) (r : t) = (l,r)
  let left (p : lr) = match p with (a,_) -> a
  let right (p : lr) = match p with (_,b) -> b
  let equal (p1 : lr) (p2 : lr) = Datum.equal (left p1) (left p2) && Datum.equal (right p1) (right p2)
end

module String_pair_dumb = Make_pair_dumb(String)

(* Better: version 1 uses sharing constraints to fix the problem 
   Observe: `with` is turning an existential t into an ALIAS t in Pair_i *)

module Make_pair_smarter(Datum : Datum_i) : (Pair_i with type t = Datum.t)= 
struct
  type t = Datum.t
  type lr = t * t
  let create (l : t) (r : t) = (l,r)
  let left (p : lr) = match p with (a,_) -> a
  let right (p : lr) = match p with (_,b) -> b
  let equal (p1 : lr) (p2 : lr) = 
    Datum.equal (left p1) (left p2) && Datum.equal (right p1) (right p2)
end

(* Observe that the above type is a **dependent type**:  
   the type of the returned module depends on `Datum.t` which is part
   of the concrete module value passed in:

  module Make_pair_smarter :
  functor (Datum : Datum_i) ->
    sig
      type t = Datum.t (* type of result depends on module fed in *)
      type lr
      val create : t -> t -> lr
      val left : lr -> t
      val right : lr -> t
      val equal : lr -> lr -> bool
    end

    -- dependent types generally allow many advanced coding patterns

    another e.g.: type t = x : int -> { y : int | x > y }
*)
module String_pair_smarter = Make_pair_smarter(String)

let pair_test = String_pair_smarter.create "hi" "ho"
let left_test = String_pair_smarter.left pair_test

(* Still the String_pair_smarter type might be less than great, 
   e.g. create : t -> t -> lr in String_pair_smarter module type 
   when it really is create : string -> string -> lr
*)

(* New syntax: destructive substitution to fix this *)

(* Best: version 2 *replaces* type t with Datum.t using := in place of = 
   Observe that := is basically inlining the type t into the module type. 
   Compare the following to see the difference *)

module type Temp_alias = Pair_i with type t = string;;
module type Temp_replace = Pair_i with type t := string;;

module Make_pair_smartest(Datum : Datum_i) : (Pair_i with type t := Datum.t)= 
struct
  type t = Datum.t
  type lr = t * t
  let create (l : t) (r : t) = (l,r)
  let left (p : lr) = match p with (a,_) -> a
  let right (p : lr) = match p with (_,b) -> b
  let equal (p1 : lr) (p2 : lr) = 
    Datum.equal (left p1) (left p2) && Datum.equal (right p1) (right p2)
end

module String_pair_smartest = Make_pair_smartest(String)

(* Observe type of create in the sig of the above has no t in it at all *)

(* ********************************************************************************* *)

(* ******************* *)
(* First Class Modules *)
(* ******************* *)


(* Treat modules as data values: let-define them, put in lists, etc etc *)
(* We often need an explicit module type to get this to work *)
(* (in general, the more advanced the types get the weaker the inference is) *)

(* The module type for String_pair_smartest above, declared module type needed explicitly *)
(* This is the type inferred for the resulting module the functor makes *)
module type Sps_i = 
sig
  type lr
  val create : string -> string -> lr
  val left : lr -> string
  val right : lr -> string
  val equal : lr -> lr -> bool
end


(* Let us put a module in a ref cell as a very stupid example of modules-as-data
    `(module M)` is the syntax for turning regular module into first-class one
    But often the type checker needs some help so you need to also give a type:  
    `(module M : M_i)`  *)

let mcell  =  ref (module String_pair_smartest : Sps_i)

(* Unpack it from the cell to make an official top-level module *)
(* "val" is the keyword to go back expression-land to module-land
   - it is in some sense the inverse of (module ..) *)

module SP = (val !mcell)

let _ : string = 
  let p = SP.create "hi" "ho" in SP.left p

(* Can also locally unpack it (can do this with any module) *)
let _ : string = 
  let (module M) = !mcell in let p = M.create "hi" "ho" in M.left p;;


(* ************************************************************************** *)

(* Doing something a bit more useful with first-class modules *)
(* Lets make some heterogenous data structures *)
(* We need modules to do this because they include existential types *)

(* Here is a simple module type holding one piece of data from some abstract aka existential type *)
module type Item_i =
sig 
  type t
  val item : t
  val to_string : unit -> string
end

(* An instance of the above type *)
module Int_item : Item_i = struct
  type t = Int.t
  let item = 33 (* Yes a bit overwrought, a module just to hold a single number *)
  let to_string () = Int.to_string item
end

(* Better: let us write a function to make the above module for any int i 
   Notice how we can "inject" a module into regular expressions via 
  `(module TheModule : TheModuleType)` 
   As above we *have* to include the type of the module as well *)
   
let make_int_item (i : int) = (module struct
  type t = Int.t
  let item = i
  let to_string () = Int.to_string item
end : Item_i)

(* And similarly for strings (or ANY other type) *)
let make_string_item (s : string) = (module struct
  type t = String.t
  let item = s
  let to_string () = item
end : Item_i)

(* Since the type t is hidden in Item_i we can make a heterogenous list! *)
let item_list = [make_string_item "hi"; make_int_item 5]

(* Inspect the type above, OCaml still sees a uniform list
   Observe that abstract types like t in module types are "exists t"'s - each t underlying in the list is different but OCaml just sees "exists a t" for each one and that is OK! Only when types are 100% hidden are they "exists" So, there is not a lot we can do with such data structures *)


let to_string_items (il : (module Item_i) list)  = 
  il |> List.map ~f:(fun it -> let (module M) = it in M.to_string())

  let _ = to_string_items item_list;;   
  
  (* This example is not practically useful, but there are many useful examples
   See e.g. https://dev.realworldocaml.org/first-class-modules.html 's query handling example *)


(* The main thing we still avoid here is ad-hoc typed structures, e.g. we still cannot do
   [1;true;2;false;55;false] kind of thing and that is GOOD! 
   If we wanted an alternating int-string list, instead do
   [(1,true);(2,false);(55,false)]
   which will be type-correct and less bug-prone
   
   In general rely on OCaml's types for *accurate* invariants on your code
   *)


(* ******************************************************** *)
(* First-class modules in the Core data structure libraries *)
(* ******************************************************** *)

(* Warm-up with review of Map.Make

   When we previously discussed Core.Map etc we suggested to use Map.Make to 
   make a Map over a particular type of key 

   Here is the module type of Map.Make:

   #show Map.Make;;
   module Make :
   functor (Key : Core.Map.Key) -> sig (* .. tons of stuff *) end

   So let us look at what the module type Core.Map.Key is, i.e. what we need to provide
   e.g. see https://ocaml.org/p/core/latest/doc/Core/Map_intf/module-type-Key/index.html 

   #show Map.Key;;
    module type Key = Core__.Map_intf.Key
    module type Key = Core.Map_intf.Key
    module type Key =
  sig
    type t
    val compare : t Base.Exported_for_specific_uses.Ppx_compare_lib.compare
    val t_of_sexp : Sexp.t -> t
    val sexp_of_t : t -> Sexp.t
  end

   - it needs `compare` and to/from s-expression stuff.  So let us use `[@@deriving]` to make those.
      (as we had done earlier, still reviewing here):
*)

module IntPair = struct
  type t = int * int [@@deriving compare, sexp]
end

module PairMap = Map.Make(IntPair)

(* Now the annoying thing about this is we need to make a new module for every different Map key type *)

(* Let us now look in details the first-class modules method for making Maps *)

(* Make an empty module with string key; type of m is funky more below on that *)
let a_map = Map.empty (module String) 

(* Now can simply use Map.add on a_map *)
let added = a_map |> Map.add_exn ~key:"hello" ~data:3 |> Map.to_alist

(* Note that above we had to put a module type on any defined module:
   "let mcell  =  ref (module String_pair_smartest : Sps_i)" required the ": Sps_i" 
   But here the type is in Map.empty's domain so we don't need to!
   What is Map.empty's type?  Informally it is taking a module as argument
   So, type of argument must be a module type (but in expression-land)

   
# #show Map.empty;;
val empty : ('a, 'cmp) Map.comparator -> ('a, 'b, 'cmp) Map.t

# #show_type Map.comparator;;
type nonrec ('k, 'cmp) comparator =
    (module Core__.Comparator.S with type comparator_witness = 'cmp and type t = 'k)

Digging one more level for type Map.comparator: 
# #show Core__.Comparator.S;;
module type S = Core.Comparator.S
module type S =
  sig
    type t
    type comparator_witness
    val comparator : (t, comparator_witness) Comparator.t
  end

One final level:
#show Comparator.t;;
type ('a, 'witness) t =
  ('a, 'witness) Comparator.t = private {
  compare : 'a -> 'a -> int;
  sexp_of_t : 'a -> Sexp.t;
}

-- First, notice how also putting "module" on a module type makes it an expression type
-- the parameters 'k and 'cmp are the key type and a special "nonce" type 'cmp
    -- 'cmp is in turn an alias for the type comparator_witness in the key module (String above)
    -- these are called "phantom types", nothing has that type and it only helps the typechecker
    -- think of it as a "token" that confirms there is a compare function which will always be from 
       Core.Comparator.S, e.g. String's compare

Example to show how Core.String has this all built-in :

# let m : ((string,String.comparator_witness) Map.comparator) = (module String);;
val m : (string, String.comparator_witness) Map.comparator = <module>

 The String.comparator_witness will help the typechecker type string compare uses 
 Yes its subtle.. here is an example to understand better: 
   https://blog.janestreet.com/howto-static-access-control-using-phantom-types/
   
*)

(* 

   Let us try the above first-class module Map creation on our own module IntPair: *)

let m = Map.empty (module IntPair)

(* Gives an error, module needs a comparator and a comparator_witness *)
(* Solution: here is the somewhat-magical way to add those to IntPair (or any other) module *)

module IntPairCompar = struct
  module T = struct 
  type t = int * int [@@deriving compare, sexp] 
  end
  include T
  include Comparator.Make(T) (* This makes a ton of stuff. Replace Comparator with Comparable and get extras like <= etc *)
end

(* The above "include" pattern is clever - call all "your" stuff T temporarily, include it, 
   and since it has a name you can now pass it to a functor which will build and
   include the comparators over type t.
*)

let m = Map.empty (module IntPairCompar) (* Works now; note no type on module is needed *)

(* Observe the type of Maps are `('a, 'b, 'cmp) Map_intf.Map.t`  
  'a is the key type, always <KeyModule>.t for <KeyModule> being the module for keys, e.g. IntPairCompar above
  'b is the value type
  'cmp is the phantom type to uniquely "name" the key module; it is always <KeyModule>.comparator_witness

  Notice the Map.Make version lacked the phantom type
  The ultimate purpose of the phantom is to allow Maps themselves to be correctly compared
    - only will make sense to compare maps if both the key and value are same type PLUS `compare` function is same
    - the phantom uniquely tags the `compare` since it had to be defined in the same module
    - without the phantom it would be possible incorrectly to compare two maps
*)

(* Here is in fact what Comparator.Make is adding more or less.  The `compare` and `comparator_witness`
   are in the same module so the latter serves as unique signature of the former 
   Note this code in fact will not run since Core doesn't want users doing this themselves *
     - thats the "private" in Comparator.t, outsiders can use but not make 
*)


module IntPairComparDirect = struct
  type t = int * int [@@deriving compare, sexp] 
  type comparator_witness (* an empty type, just a name aka nonce, also called a phantom type *)
  let comparator : ('a, 'witness) Comparator.t = { compare = T.compare; sexp_of_t = T.sexp_of_t}
end


(* **************** *)
(* **** I/O ******* *)
(* **************** *)

(* We will briefly look at the I/O libraries in Core (i.e., Stdio)
   See e.g. https://dev.realworldocaml.org/imperative-programming.html#file-io for description
   They are mostly straightforward, but print format strings are "very special". *)

let () = printf "%i is the number \n" 5;;

(* The compiler is doing special things with the argument here, it is converting it into
   a function which will do this particular output taking 5 as a parameter
   
   Why?? Printing is fully type-safe in OCaml, if you pass the wrong type of value
    you will get a type error ! *)

(* So, you can't just pass a format string just as a string to printf *)
let () = let s = "%i is the number \n" in printf s 5 (* type error *)

(* The compiler is converting the string into a format type value for you *)
open CamlinternalFormatBasics (* shorten what is printed *)

(* Lets give the string above a format type *)
let fmt : (int -> 'a, 'b, 'c) format =  "%i is the number \n"

(* observe the first parameter is a function taking an int - that is extracted from the %i 
  by the compiler.  Ignore the other parameters, they are for internal use.
  Note the function will be inferred if we leave it out. *)
let fmt2 : ('a, 'b, 'c) format =  "%i is the number \n"

let () = printf fmt 5;; (* Finally we can pass the format string as a parameter *)

let () = printf fmt "k";; (* Compile-time error: printing with `fmt` needs an int. *)

(* Note that in general you can declare too-generic types and OCaml inference will refine *)
let x : 'a = 6;; (* refines 'a to int *)

let fmt3 : ('a, 'b, 'c) format =  "%i is the number %s is the string %s too \n";;

let () = printf fmt3 4 "k" "l";; 

(* Note printf is Out_channel.printf and there is also 
  - fprintf (print to any out_channel including network file etc; printf is (fprintf stdout)) 
  - sprintf (just "print" onto a string), 
  - eprintf (print to std error), etc *)