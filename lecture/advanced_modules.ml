(* ******************************************* *)
(* More on types, modules, functors and hiding *)
(* ******************************************* *)

(* Will need #require "ppx_deriving.std" in top loop (which is in our course default .ocamlinit)
   and (preprocess (pps ppx_deriving.std) line in dune for this file to work *)

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

let weak_id = (fun () -> Fun.id) () (* abstraction and application are a no-op but messes up type *)
(* val weak_id : '_weak2 -> '_weak2 = <fun> *)

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
    - generic/polymorphic types are "for all", hidden types are "exists" in logic terms.
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
(* We often need an explicit module type added (`: MYMODULE`) to get this to work *)
(* (in general, the more advanced the types get the weaker the inference is) *)

(* The module type for Example_pair_smartest above, declared module type needed explicitly *)
(* This is the type inferred for the resulting module the functor makes *)
module type EPS = 
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
    `(module M : MOD)`  *)

let mcell  =  ref (module Example_pair_smartest : EPS)

(* To use it, first need to unpack it from the cell to make an official top-level module *)
(* "val" is the keyword to go back expression-land to module-land
   - it is an inverse of (module ..) syntax *)

module SP = (val !mcell)

let _ : int = 
  let p = SP.create 4 "ho" in SP.left p

(* Can also locally unpack it with `let (Module M)` syntax *)
let _ : int = 
  let (module M) = !mcell in let p = M.create 4 "ho" in M.left p;;


(* ************************************************************************** *)

(* ************************************************************ *)
(* First-class modules in the standard data structure libraries *)
(* ************************************************************ *)

(* Warm-up with review of Map.Make

   When we previously discussed Map etc we showed how to use Map.Make to make
   maps over a certain type of data.

   Here is the module type of Map.Make:

   #show Map.Make;;
   module Make :
   functor (Ord : Map.OrderedType) -> sig (* .. tons of stuff *) end

   So let us look at what the module type Map.OrderedType is:

   #show Map.OrderedType;;
   module type OrderedType = sig type t val compare : t -> t -> int end

   - it needs `compare`.  One easy way to get that is with @@deriving ord:
*)

module IntPair = struct
  type t = int * int [@@deriving ord]
end

module PairMap = Map.Make(IntPair)
let pair_map = PairMap.empty
let add_a_pair = pair_map |> PairMap.add (1,2) 3

(* Now the somewhat annoying thing about this is we need to make a new module for every different Map key type *)

(* **************** *)
(* **** I/O ******* *)
(* **************** *)

(* We will briefly look at the I/O libraries
   They are mostly straightforward, but print format strings are "very special". *)

(* First, printf, sprintf, fprintf tend to "just work" so you don't necessarily need to know this
   But it can help if you are getting strange error messages to know it is complex under the hood *)
   
let () = Printf.printf "%i is the number\n" 5;;
let () = Printf.printf "%i is the number and %s is the string \n" 5 "hoo";;

(* The compiler is doing special things with the argument here, it is converting it into
   a function which will do this particular output taking 5 as a parameter
   
   Why?? Printing is fully type-safe in OCaml, if you pass the wrong type of value
    you will get a type error ! *)

(* So, you can't just pass a format string as a string to printf *)
(* let () = let s = "%i is the number \n" in Printf.printf s 5 *) (* type error *)

(* The compiler is converting the string into a format type value for you *)
open CamlinternalFormatBasics (* shorten what is printed *)

(* Lets give the string above a format type *)
let fmt : (int -> 'a, 'b, 'c) format =  "%i is the number \n"

(* observe the first parameter is a function taking an int - that is extracted from the %i 
  by the compiler.  Ignore the other parameters, they are for internal use.
  Note the function will be inferred if we leave it out. *)
let fmt2 : ('a, 'b, 'c) format =  "%i is the number \n"


let () = Printf.printf fmt 5;; (* Finally we can pass the format string as a parameter *)

let print_int : int -> unit = Printf.printf fmt (* once printf has fmt it expects the parameters *)

let () = print_int 5;;

(* let () = Printf.printf fmt "k";; *) (* Compile-time error: printing with `fmt` needs an int. *)

(* One more format example with multiple arguments *)
let fmt3 : (int -> string -> string -> 'c, 'b, 'c) format =  "%i is the number %s is the string %s too \n";;

let () = Printf.printf fmt3 4 "k" "l";; 

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

(* Since the type t is hidden in ITEM_I we can make a heterogenous list! *)
let item_list = [make_string_item "hi"; make_int_item 5]

(* Inspect the type above, OCaml still sees a uniform list
   Observe that abstract types like t in module types are "exists t"'s - each t underlying in the list is different but OCaml just sees "exists a t" for each one and that is OK! Only when types are 100% hidden are they "exists" So, there is not a lot we can do with such data structures *)


let to_string_items (il : (module ITEM_I) list)  = 
  il |> List.map (fun it -> let (module M) : (module ITEM_I) = it in M.to_string())

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
