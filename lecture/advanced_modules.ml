(* ******************************************* *)
(* More on types, modules, functors and hiding *)
(* ******************************************* *)

open Core
(* Will need #require "ppx_jane" in top loop (which is in our course default .ocamlinit)
   and (preprocess (pps ppx_jane)) line in dune for this file to work *)

(* Review: the Big Picture of what is unique in OCaml types

  * One of the most novel/powerful/elegant/frustrating/confusing aspects of OCaml is the types
  * There are things you can do with types that likely no language you have ever seen supports.
  * In particular the way that they can be treated like data in modules, e.g. String.t etc
  * It helps a lot to understand the different uses of type variables, let us review that now.

 * Type variables can be polymorphic: 'a 'b etc -- very similar to Java generics
   - f : 'a -> 'a for example really means for ANY type 'a, f has type 'a -> 'a (universal)
   - We have not covered them yet but you can also declare such polymorphic types via (type a)
   - This is more like Java generics which requires generic types to be declared:
*)

let f (type a) (x : a) = x;;

(* There are also special *weak* type variables *)
let rl = ref [];;
(* return val rl : '_weak1 list ref = {contents = []} in top loop *)

(* '_weak1 etc are unknown types which are *not* polymorphic, 
   they can be only *one* thing, but currently that type is not known.
   For this example, its clear why it is not known, we only have an empty list.
   And, as discussed earlier it can't be polymorphic, whatever we put in must come out *)

let () = rl := [1]
let _ = !rl (* we have set '_weak1 to be int with this *)

(* Sometimes types are weak due to weaknesses in the underlying type system: *)

(* # let id = (fun x -> x)(fun x -> x) *) 
(* val id : '_weak2 -> '_weak2 = <fun> *)

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
 * Type variables can denote **existential** (hidden) types in module types
*)

module type EQ = sig type t val equal : t -> t -> bool end

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
type ('key, 'value, 'cmp) t = ('key, 'value, 'cmp) Map.t (* existential / hidden *)

 * Moral: every time you see a type variable reference t / 'a / Int.t / etc
    first sort it into one of the above four categories

*)

(* *************************************** *)
(* Module type hiding and un-hiding review *)
(* *************************************** *)

(* We are picking up from the more-modules.md lecture, start with some review.. *)

(* An abstract pairing module type: *)

module type PAIR = 
 sig
   type l
   type r
   type t = l * r
   val create : l -> r -> t
   val left : t -> l
   val right : t -> r
   val equal : t -> t -> bool
end

(* Arbitrary Data with equality module type *)
module type DATUM = sig
  type t
  val equal : t -> t -> bool
end

(* Functor to make a pair of two Datum's, 
  and the "with :=" syntax  will substitute those types in the result module type. *)
module Make_pair_smartest(Datum1 : DATUM)(Datum2 : DATUM) : (PAIR with type l := Datum1.t with type r := Datum2.t) = 
struct
  type l = Datum1.t
  type r = Datum2.t
  type t = l * r
  let create (l : l) (r : r) : t = (l,r)
  let left (p : t) = match p with (a,_) -> a
  let right (p : t) = match p with (_,b) -> b
  let equal (p1 : t) (p2 : t) = Datum1.equal (left p1) (left p2) && Datum2.equal (right p1) (right p2)
end
module Example_pair_smartest = Make_pair_smartest(Int)(String)

(* ******************* *)
(* First Class Modules *)
(* ******************* *)

(* Treat modules as data values: let-define them, put in lists, etc etc *)
(* We will see there are ways to push modules into expression-space, 
   and also to take modules in expression-space and turn them into real modules *)
(* We often need an explicit module type to get this to work *)
(* (in general, the more advanced the types get the weaker the inference is) *)

(* The module type for Example_pair_smartest above, declared module type needed explicitly *)
(* This is the type inferred for the resulting module the functor makes *)
module type EPS_I = 
sig
  type t
  val create : int -> string -> t
  val left : t -> int
  val right : t -> string
  val equal : t -> t -> bool
end


(* Let us put a module in a ref cell as a very stupid example of modules-as-data
    `(module M)` is the syntax for turning regular module into an expression
    But often the type checker needs some help so you need to also give a type:  
    `(module M : M_i)`  *)

let mcell  =  ref (module Example_pair_smartest : EPS_I)

(* Unpack it from the cell to make an official top-level module *)
(* "val" is the keyword to go back expression-land to module-land
   - it is in some sense the inverse of (module ..) *)

module SP = (val !mcell)

let _ : int = 
  let p = SP.create 4 "ho" in SP.left p

(* Can also locally unpack it with `let (Module M)` syntax *)
let _ : int = 
  let (module M) = !mcell in let p = M.create 4 "ho" in M.left p;;


(* ************************************************************************** *)

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

(* Notice we didn't need to make a StringMap module since Map.empty takes a String module  - !
   The Map.empty function itself encapsulates in its type that it is a string map: *)
let added = a_map |> Map.add_exn ~key:"hello" ~data:3

(* Under the hood of how this is working *)

(* There are some very subtle OCaml patterns used to make this work.  We will at least
   aim for a vague idea of it here, just to show that there is some deep stuff! *)

(* 
   What is Map.empty's type?  Informally it is taking a module as argument
   So, type of argument must be a module type (but in expression-land)

# #show Map.empty;;
val empty : ('a, 'cmp) Comparator.Module.t -> ('a, 'b, 'cmp) Map.t

# #show Comparator.Module.t;;
type ('a, 'b) t =
    (module Core.Comparator.S with type comparator_witness = 'b and type t = 'a)

- Observe here that putting "(module ..)" on a module type makes it an expression type

So this module must match the Core.Comparator.S signature.
Digging one more level:

# #show Core.Comparator.S;;
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

Here we finally see the requirements on a module to make a map: a witness, compare, and sexp_of

-- the parameters 'a and 'witness are the key type and a special "nonce" type 'witness
    -- 'witness is a "phantom type", no values have that type and it only helps the typechecker
    -- think of it as a "token" that confirms there is a compare function which will always be from 
       Core.Comparator.S, e.g. String's compare and not some other string compare.

Example to show how Core.String has this all built-in :

# let m : ((string,String.comparator_witness) Comparator.Module.t) = (module String);;
val m : (string, String.comparator_witness) Comparator.Module.t = <module>

 The String.comparator_witness will help the typechecker type string compare uses 
 Yes its subtle.. here is an example to understand better: 
   https://blog.janestreet.com/howto-static-access-control-using-phantom-types/
   
*)

(* 
   Why did we dive into all these details?  Suppose we wanted to make a custom
   key for a Map.

   Let us try the first-class module Map creation on our own module IntPair: *)

let m = Map.empty (module IntPair)

(* Gives an error, module needs a comparator and a comparator_witness type *)
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

(* **************** *)
(* **** I/O ******* *)
(* **************** *)

(* We will briefly look at the I/O libraries in Core (i.e., Stdio)
   See e.g. https://dev.realworldocaml.org/imperative-programming.html#file-io for description
   They are mostly straightforward, but print format strings are "very special". *)

(* First, printf, sprintf, fprintf tend to "just work" so you don't necessarily need to know this
   But it can help if you are getting strange error messages to know it is complex under the hood *)
   
let () = printf "%i is the number and %s is the string\n" 5 "hi";;

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

let print_int : int -> unit = printf fmt (* once printf has fmt it expects the parameters *)

let () = print_int 5;;

let () = printf fmt "k";; (* Compile-time error: printing with `fmt` needs an int. *)

(* One more format example with multiple arguments *)
let fmt3 : ('a, 'b, 'c) format =  "%i is the number %s is the string %s too \n";;

let () = printf fmt3 4 "k" "l";; 

(* Note printf is Out_channel.printf and there is also 
  - fprintf (print to any out_channel including network file etc; printf is (fprintf stdout)) 
  - sprintf (just "print" onto a string), 
  - eprintf (print to std error), etc *)

(* ************************************************************************************** *)

(* Example of the power of first-class modules (we will probably skip this in lecture) *)
(* Lets make some heterogenous data structures *)
(* We need modules to do this because they include existential types *)

(* Here is a simple module type holding one piece of data from some abstract aka existential type *)
module type ITEM_I = sig 
  type t
  val item : t
  val to_string : unit -> string
end

(* An instance of the above type *)
module Int_item : ITEM_I = struct
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
end : ITEM_I)

(* And similarly for strings (or ANY other type) *)
let make_string_item (s : string) = (module struct
  type t = String.t
  let item = s
  let to_string () = item
end : ITEM_I)

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
