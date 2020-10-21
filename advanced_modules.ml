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
   type option('a) = Some of 'a | None -- 'a is clearly a PARAMETER here
   f : 'a -> option('a)  - 'a is a UNIVERSAL type passed to option which results in a type.

 * Type variables can be ALIASES
    - pretty straightforward hopefully - multiple names for the same type.
 *)

type ti = int
let f (x : ti) = x + 1
let sid (x : String.t) = x (* String.t is aliased to be `string` via "type t = string" in String *)

(*
 * Type variables can denote existential (hidden) types in module types
*)

module type Eq = sig type t val equal : t -> t -> bool end

(*

 - if a module is given this type the type `t` in that module is COMPLETELY hidden from outsiders
 - They know there EXISTS some type there (which is an actual type), they just don't know what it is.
 - So, they never, ever can directly do anything with such a t-typed object
 - if you want to see if something is an alias or an existential, ask to #show it; you will see aliased type.

 # #show String.t;;
type nonrec t = string (* alias *)
# #show Map.t;;
type nonrec ('key, 'value, 'cmp) t = ('key, 'value, 'cmp) Map.t (* existential / hidden *)

 * Moral: every time you see a type variable reference t / 'a / Int.t / etc
    first sort it into one of the above four categories

*)

(* ************************ *)
(* Destructive Substitution *)
(* ************************ *)

(* First we review sharing constraints ("with" in module types) *)

module type Datum_i = sig
  type t
  val equal : t -> t -> bool
end

module type Pair_i = sig
  type t
  type lr
  val create: t -> t -> lr
  val left : lr -> t
  val right : lr -> t
  val equal : lr -> lr -> bool
end

(* Version 1 pair module maker is dumb and completely useless, 
   we can't see the type of the pair elements *)

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

(* Better: version 2 uses sharing constraints to fix the problem 
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

module String_pair_smarter = Make_pair_smarter(String)

let pair_test = String_pair_smarter.create "hi" "ho"

(* Still the String_pair_smarter type is less than great, 
   e.g. create : t -> t -> lr when it really is
   create : string -> string -> lr
*)

(* New syntax: destructive substitution to fix this *)

(* Best: version 3 *replaces* type t with Datum.t using := in place of = *)

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

(* Observe type of create in the above has no t in it at all *)

(* ******************* *)
(* First Class Modules *)
(* ******************* *)


(* Treat module as data (hyper-simple version) *)
(* We sometimes need an explicit module type to get this to work *)
(* (in general, the more advanced your types get the weaker the inference is) *)

module type Sps_i = 
sig
  type lr = String_pair_smartest.lr
  val create : string -> string -> lr
  val left : lr -> string
  val right : lr -> string
  val equal : lr -> lr -> bool
end
(* puts a module in a cell - treats as data 
    "(module M : M_i)" is the syntax for turning regular module into first-class one *)

let mcell  =  ref (module String_pair_smartest : Sps_i)

(* Unpack it from the cell to make an official top-level module *)
(* "val" is the keyword to go back expression-land to module-land
   - it is in some sense the inverse of (module ..) *)

module M = (val !mcell)

let _ : string = 
  let p = M.create "hi" "ho" in M.left p

(* Can also locally unpack it *)
let _ : string = 
  let p = let (module M) = !mcell in M.create "hi" "ho" in M.left p;;

(* Doing something a bit more useful with first-class modules *)
(* Lets make some heterogenous data structures *)
module type Item_i =
sig 
  type t
  val item : t
  val to_sexpr : unit -> Sexp.t
end

module Int_item : Item_i = struct
  type t = Int.t
  let item = 33
  let to_sexpr () = Int.sexp_of_t item
end

(* Let us make a function to make the above module for int i *)
let make_int_item (i : int) = (module struct
  type t = Int.t
  let item = i
  let to_sexpr () = Int.sexp_of_t item
end : Item_i)

(* And similarly for strings *)
let make_string_item (s : string) = (module struct
  type t = String.t
  let item = s
  let to_sexpr () = String.sexp_of_t item
end : Item_i)

(* Since the type t is hidden in Item_i we can make a heterogenous list! *)
let item_list = [make_string_item "hi"; make_int_item 5]

(* Inspect the type above, OCaml still sees a uniform list
   Observe that abstract types like t in module types are
   "exists t"'s - each t underlyin in the list is different but 
   OCaml just sees "exists a t" for each one and that is OK! 
   Only when types are 100% hidden are they "exists" 
   So, there is not a lot we can do with such data structures *)

let to_sexpr_items (il : (module Item_i) list)  = 
  List.map ~f:(fun it -> let (module M) = it in M.to_sexpr()) il

(* This example is not useful, but there are many useful examples
   See e.g. https://dev.realworldocaml.org/first-class-modules.html 's query handling example *)


(* ******************************************************** *)
(* First-class modules in the Core data structure libraries *)
(* ******************************************************** *)

(* Review of Map.Make
   When we previously discussed Core.Map etc we suggested to use Map.Make to 
   make a Map over a particular type of key 

   Here is the module type of Map.Make:

   #show Map.Make;;
   module Make :
   functor (Key : Core_kernel.Map.Key) -> sig (* .. tons of stuff *) end

   So let us look at what the module type of Key is, i.e. what we need to provide.

   #show Core_kernel.Map.Key;;
   module type Key = Core_kernel__.Map_intf.Key

   - it is just a type alias, so let us follow the alias chain:

   #show Core_kernel__.Map_intf.Key;;
   module type Key =
   sig
    type t
    val compare : t -> t -> int
    val t_of_sexp : Sexp.t -> t
    val sexp_of_t : t -> Sexp.t
   end

   - it needs to have a compare as well as to/from S-expression functions.  Example:
*)

module IntPair = struct
  type t = int * int [@@deriving compare, sexp]
end

module PairMap = Map.Make(IntPair)

(* Alternative method for creating Map's via first-class modules: *)

let m = Map.empty (module String) (* make an empty module with string key *)

let added = m |> Map.add_exn ~key:"hello" ~data:3 |> Map.to_alist

(* Notice how we can directly us Map.add etc not PairMap.add -- simpler 
   Key observation: ∂nNeeded to use first-class modules to get it to work

   Let us try this trick on our own module IntPair: *)

let m = Map.empty (module IntPair)

(* Gives an error, needs a comparator and a comparator_witness *)
(* Here is the magical way to add those *)

module IntPairCompar = struct
  module T = struct 
  type t = int * int [@@deriving compare, sexp] 
  end
  include T
  include Comparator.Make(T) (* Replace Comparator with Comparable and get extras like <= etc *)
end

let m = Map.empty (module IntPairCompar) (* Works now *)

(* The above "include" pattern is clever - call all "your" stuff T, include it, 
   and since it has a name you can now pass it to a functor which will build the comparators
   keyword This_module could also solve this in a more OO style but this is OCaml *)

(* Observe the type of Maps are now `('a, 'b, 'cmp) Map_intf.Map.t`  
  'a is the key type
  'b is the value type
  'cmp is the nonce to distinguish this particular modules compare function

  Notice the Map.Make version lacked the nonce
  The purpose of the nonce is to allow Maps themselves to be compared
    - only works if both the key and value are same type PLUS comparison is same
    - otherwise the results will be random
*)

(* Here is in fact what Comparator.Make is adding more or less: *)
module IntPairComparDirect = struct
  module T = struct 
  type t = int * int [@@deriving compare, sexp] 
  end
  include T
  type comparator_witness (* an empty type, just a name aka nonce *)
  let comparator : ('a, 'witness) Comparator.t = { compare = T.compare; sexp_of_t = T.sexp_of_t}
end

(* But, this does not 100% work:
  You need to use the functor as above since Comparator.t has the record declared "private"
  private types cannot be created outside of the module they are declared in 
  See e.g. https://caml.inria.fr/pub/docs/manual-ocaml/privatetypes.html 
  They can be *used* outside, just not created. So, only partial hiding. 
  
  Core uses private here to force us to use Comparator.Make *)

let r = IntPairCompar.comparator.sexp_of_t;; (* can access fields of private record *)


(* **************** *)
(* **** I/O ******* *)
(* **************** *)

(* If there is any time left we will briefly look at the I/O libraries in Core (i.e., Stdio)
   See e.g. https://dev.realworldocaml.org/imperative-programming.html#file-io for description
   They are mostly straightforward, but print format strings are somewhat odd. *)

let () = printf "%i is the number \n" 5;;

(* The compiler is doing special things with the argument here, it is converting it into
   a function which will do this particular output taking 5 as a parameter *)

(* So, you can't just pass a string to printf *)
let () = let s = "%i is the number \n" in printf s 5 (* type error *)

(* The compiler is converting the string into a format type value for you *)
open CamlinternalFormatBasics
let fmt : ('a, 'b, 'c) format =  "%i is the number \n"
let () = printf fmt 5;;
