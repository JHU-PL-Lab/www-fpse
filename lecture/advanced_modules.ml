(* ******************************************* *)
(* More on types, modules, functors and hiding *)
(* ******************************************* *)

(*
  Review: the Big Picture of what is unique in OCaml types

  One of the most novel/powerful/elegant/frustrating/confusing aspects of OCaml
  is the types.

  There are things you can do with types that likely no language you have ever
  seen supports.

  In particular the way that they can be treated like data in modules, e.g.
  String.t, etc.

  It helps a lot to understand the different uses of type variables, let us
  review that now.

  Type variables can be polymorphic: 'a 'b etc -- very similar to Java generics.
    E.g. f : 'a -> 'a for example really means for ANY type 'a, f has type
      'a -> 'a (universal)

   We have not covered them yet, but you can also declare such polymorphic types
   via (type a). This is more like Java generics which requires generic types to
   be declared:
*)

(** [a] here is a locally abstract type. *)
let f (type a) (x : a) = x;;

(* There are also special *weak* type variables *)
let rl = ref [];;
(* return val rl : '_weak1 list ref = {contents = []} in top loop *)

(*
  '_weak1 etc are unknown types which are *not* polymorphic, they can be only
  *one* thing, but currently that type is not known.

  For this example, it is clear why it is not known: we only have an empty list.
  And, as discussed earlier, it can't be polymorphic because whatever we put in
  must come out.
*)

let () = rl := [1]
let _ = !rl (* we have forced '_weak1 to be int with this *)

(*
  Sometimes types are weak due to weaknesses in the underlying type system.
  E.g. abstraction and application are together a no-op, but they mess up the
  type, below.
*)

let weak_id = (fun () -> Fun.id) ()
(* val weak_id : '_weak2 -> '_weak2 = <fun> *)

(* Type variables can be PARAMETERS on type-to-type functions *)

type 'a my_option = My_some of 'a | My_none

(**
  [my_option] is a FUNCTION from an unknown type ['a] to a type.

  It might make more sense if type variables came after the type name:
    [type my_option('a) = Some of 'a | None]
  There, ['a] is more clearly a parameter to the [my_option] type function (i.e.
  type constructor--it constructs a type given another type).

  Type variables can be ALIASES. This is pretty straightforward, hopefully:
  multiple names for the same type.
 *)

type float_alias = float
let f (x : float_alias) = x +. 1.
(* String.t is aliased to be `string` via "type t = string" in String *)
let sid (x : String.t) = x

(* Type variables can denote **existential** (hidden) types in module types *)

module type EQ = sig type t val equal : t -> t -> bool end

(*
  If a module is given this type, the type `t` in that module is COMPLETELY
  hidden from outsiders. They know there EXISTS some type there (which is an
  actual type), they just don't know what it is.

  So, they never, ever can directly do anything with such a t-typed value.

  An existential type is a type variable alias where you don't know what it is
  aliased to.

  Recall that the notion of something existing but not directly defined is a
  fundamental part of math: "for all x there EXISTS a y such that y > x". Many
  math assertions have "exists" in them.

  Generic/polymorphic types are "for all", and hidden (i.e. abstract) types are
  "exists" in logic terms.

  If you want to see if something is an alias or an existential, ask to #show
  it in utop; you will see aliased type.

  # #show String.t;; (* alias *)
  type nonrec t = string
  # #show Map.t;; (* existential/hidden/abstract *)
  type ('key, 'value, 'cmp) t = ('key, 'value, 'cmp) Map.t

  Moral: every time you see a type variable reference t / 'a / Int.t / etc.,
  first sort it into one of the above categories:
  1. Locally abstract, i.e. polymorphic
  2. Weak
  3. Type constructor, i.e. type function
  4. Hidden, i.e. abstract, i.e. existential
  5. Alias
*)

(* *************************************** *)
(* Module type hiding and un-hiding review *)
(* *************************************** *)

(* We are picking up from the funtors.md lecture, start with some review.. *)

(* An abstract pairing module type: *)

module type PAIR = sig
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

(*
  Here is a functor to make a pair of two DATUM's, and the "with :=" syntax
  will substitute those types in the result module type.
*)
module Make_pair(Datum1 : DATUM)(Datum2 : DATUM)
  : (PAIR with type l := Datum1.t with type r := Datum2.t) = struct
  type l = Datum1.t
  type r = Datum2.t
  type t = l * r
  let create (l : l) (r : r) : t = (l,r)
  let left (p : t) = match p with (a,_) -> a
  let right (p : t) = match p with (_,b) -> b
  let equal (p1 : t) (p2 : t) =
    Datum1.equal (left p1) (left p2) && Datum2.equal (right p1) (right p2)
end

module Example_pair = Make_pair(Int)(String)

(* ******************* *)
(* First Class Modules *)
(* ******************* *)

(*
  First class modules let you treat modules as data values: let-define them, put
  them in lists, etc etc.

  We will see there are ways to push modules into expression-space, and also to
  take modules in expression-space and turn them into real modules.

  We often need an explicit module type annotation to get this to work. (Note
  that in general, the more advanced the types are, the weaker the inference is,
  and the more you need to annotate your code to help OCaml type check it)
*)

(*
  Here is the module type for Example_pair above This is the type inferred for
  the resulting module from the functor.
*)
module type EPS = sig
  type t
  val create : int -> string -> t
  val left : t -> int
  val right : t -> string
  val equal : t -> t -> bool
end

(*
  Also note we can just do this.
*)
module type EPS = module type of Example_pair

(**

  Here we put the module into a value, making it a module-as-data, a first class
  module.
  [(module M)] is the syntax (parentheses necessary) to make a first class
  module.
  [(module M : MODULE_TYPE)] is the syntax when the type checker needs some help
  (which is frequently the case) to know the module type into which you intend
  to pack the module.
*)

let mval = (module Example_pair : EPS)

(**
  To get the module back out, which is the only meaningful use of such a value,
  you use the [val] keyword, again with parentheses.
  This is the inverse of the [module] syntax.
*)
module SP = (val mval)

let _ : int =
  let p = SP.create 4 "ho" in SP.left p

(**
  Can also locally unpack it with the [module M] pattern. Here, we use the fact
  that [let]'s support patterns on the left-hand-side:
*)
let _ : int =
  let (module M) = mval in
  let p = M.create 4 "ho" in
  M.left p

(* ************************************************************************** *)

(*
  When should you use first class modules? Nowadays, they can be used to avoid
  single-purpose functors--functors that derive a module with just one function.

  We all love monads, no?
*)

module type MONAD = sig
  type 'a m
  val return : 'a -> 'a m
  val ( let* ) : 'a m -> ('a -> 'b m) -> 'b m
end

(**
  If we want to define a list-fold with a monad, we usually would use a functor.
*)

module Make_list_fold (M : MONAD) = struct
  let list_fold_leftM f init_m ls =
    let rec fold acc_m = function
    | [] -> acc_m
    | hd :: tl ->
      let open M in
      let* acc = acc_m in
      fold (f acc hd) tl
    in
    fold init_m ls
end

module Opt = struct
  type 'a m = 'a option
  let ( let* ) = Option.Syntax.( let* )
  let return a = Some a
end

(**
  To get a [list_fold_leftM] function that works on options, we have to call the
  functor, then name the resulting module, and then project from that module.
*)
module Opt_fold = Make_list_fold (Opt)

let sum_if_pos ls =
  Opt_fold.list_fold_leftM (fun acc a ->
    if a > 0 then
      Some (acc + a)
    else
      None
  ) (Some 0) ls

(**
  But this is a lot of heavy machinery for a single function. Module-dependent
  functions come to our rescue!

  We can define [list_fold_leftM] not inside a functor, but just as a function
  that takes a module (the would-be functor parameter) itself!
*)

let list_fold_leftM (module M : MONAD) f init_m ls =
  let rec fold acc_m = function
  | [] -> acc_m
  | hd :: tl ->
    let open M in
    let* acc = acc_m in
    fold (f acc hd) tl
  in
  fold init_m ls

(* With module-dependent functions, we just pass in the module on the fly! *)
let sum_if_pos' ls =
  list_fold_leftM (module Opt) (fun acc a ->
    if a > 0 then
      Some (acc + a)
    else
      None
  ) (Some 0) ls


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
