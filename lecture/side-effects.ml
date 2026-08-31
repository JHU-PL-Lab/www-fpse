# let x = ref 4;; (* have to declare initial value when creating *)
val x : int ref = {contents = 4}

# let x = ref 4;;
val x : int ref = {contents = 4}

# x + 1;;
Line 1, characters 0-1:
Error: This expression has type int ref but an expression was expected of type
         int

# !x + 1;; (* use !x to get out the value; similar to *x in C *)
- : int = 5

# x := 6;; (* assignment with (:=). x must be a ref cell.  Returns () - only performs side effect *)
- : unit = ()

# !x + 1;; (* Mutation happened to contents of cell x *)
- : int = 7

let x = ref 4
let !x = 5 (* syntax error. !x is a value, not a valid assignee *)

# print_endline;; (* returns unit; has the side effect of printing *)
- : string -> unit = <fun>

# (:=);; (* returns unit; has the side effect of assignment to LHS *)
- : 'a ref -> 'a -> unit = <fun>

# Hashtbl.add;; (* returns unit, so it has the side effect of assignment *)
: ('a, 'b) Hashtbl.t -> 'a -> 'b -> unit = <fun>

# Stack.create;; (* takes unit, so it is making a new mutable data structure *)
- : unit -> 'a Stack.t = <fun>

# Stack.create ();; (* Note the convention of putting a space here *)
- : '_weak1 Stack.t = <abstr> (* It is abstract, we can't see internals.. more on weak types soon *)

let x = ref 4;;
let f () = !x;;

x := 234;;
f ();;

let x = ref 6;; (* shadows previous x definition, NOT an assignment to x !! *)
f ();; (* 234 still, not 6 *)

# let x = ref None;;
val x : '_weak1 option ref = {contents = None}

# x := Some 3;;
- : unit = ()

# !x;;
- : int option = Some 3 (* now we see '_weak1 was touched and its now forevermore an int *)

let x = ref None (* Puts Schrodinger's cat in the box. It is weakly typed, not polymorphic. *)

let _ = x := Some 5 (* Observes Schrodinger's cat: fixes the weak type to be int *)

let _ = x := Some "hello" (* type error! x is not a string ref *)

let x = { contents = 4 };; (* 100.0% identical to `let x = ref 4` *)

x.contents <- 7;;  (* identical to `x := 6` *)

x.contents + 1;; (* identical to `!x + 1` *)

type mutable_point = { mutable x : float ; mutable y : float };;

let translate p dx dy =
  p.x <- (p.x +. dx); (* observe use of ";" here to sequence effects *)
  p.y <- (p.y +. dy)
;;

let mypoint = { x = 0.0; y = 0.0 };; (* new mutable record *)

translate mypoint 1.0 2.0;; (* changes fields inside mypoint *)

mypoint;;

(* version using ref: *)
type 'a mtree_ref =
  | MLeaf
  | MNode of 'a * 'a mtree ref * 'a mtree ref
;;

(* But, use this type with mutable records - no `!` needed: *)
type 'a mtree =
  | MLeaf
  | MNode of { data : 'a ; mutable left : 'a mtree ; mutable right : 'a mtree }
;;

# let mt = MNode { data = 3 ; left = MLeaf ; right = MLeaf };;
val mt : int mtree = MNode {data = 3; left = MLeaf; right = MLeaf}

# match mt with
| MLeaf -> ()
| MNode ({ data ; left ; right } as r) -> (* "as" captures it all under one name *)
  r.left <- MNode { data = 5 ; left = MLeaf ; right = MLeaf };;
- : unit = ()

(* Verify that mt mutated *)
# mt;;
- : int mtree =
MNode
 { data = 3
 ; left = MNode { data = 5 ; left = MLeaf ; right = MLeaf }
 ; right = MLeaf }

# 2 == 2;; (* memory layout of 2 is always the same *)
- : bool = true

# let x = ref 4;;
val x : int ref = {contents = 4}

# let y = x;; (* make y an alias for x *)
val y : int ref = {contents = 4}

# x == y;;
- : bool = true (* same pointer *)

# let z = ref 4;; (* new cell. totally different from x and y *)
val z : int ref = {contents = 4}

# x == z;;
- : bool = false (* different pointers *)

# let big_list = List.init 10000 Fun.id ;;

# let x = 10 :: big_list ;;

# let y = 11 :: big_list ;;

# x == y ;;
- : bool = false

# List.tl x == List.tl y ;;
- : bool = true (* the tails are physically identical, they are big_list *)

# let next =
  let count = ref 0 in
  fun () ->
    count := !count + 1;
    !count
;;
- : unit -> int = <fun>

# next () ; next ();; (* Increment twice *)
Line 1, characters 0-7:
Warning 10 [non-unit-statement]: this expression should have type unit.
- : int = 2

# ignore (next ()); next () (* or, better, let _ = next () in next () *)

let x = ref 1 in
while !x < 10 do
  Printf.printf "count is %i ...\n" !x;
  x := !x + 1
done;;

let arrhi = Array.init 10 (fun _ -> "hi");; (* length and initial value maker *)

let arr = [| 4; 3; 2 |];; (* make a literal array *)

arr.(0);; (* access *)

arr.(0) <- 55;; (* update cell, like with mutable record fields *)

arr;; (* see that arr has changed *)

Array.map (fun x -> x + 1) arr;; (* standard map - produces a new array *)

Array.map_inplace (fun x -> x + 1) arr;; (* This *changes* the array using the map function and returns unit *)

(* Here are some conversions *)
let a = Array.of_list [1;2;3];;
let l = Array.to_list a;;

failwith "Oops";; (* Generic code failure - exception is named Failure *)
invalid_arg "This function works on non-empty lists only";; (* Invalid_argument exception *)

# List.combine [1;2] [2;3;4];;
Exception: Invalid_argument "List.combine".

exception Boom of string;;

let f _ = raise @@ Boom "keyboard on fire";; (* raise is ultimately how all exceptions are raised *)

f ();; (* this raises the exception *)

let g () =
  try f () with
  | Boom s -> printf "exception Boom raised with payload string \"%s\"\n" s
;;

g ();;

# let s = Stack.create();;
val s : '_weak1 Stack.t = <abstr> (* Stack.t is the underlying implementation and is hidden *)

# Stack.push "hello" s;;
- : unit = () (* returns unit because s is mutated *)

# Stack.push "hello again" s;;
- : unit = ()

# Stack.push "hello one more time" s;;
- : unit = ()

# Stack.pop s;; (* exception Stack.Empty will be raised if empty here *)
- : string = "hello one more time"

# Stack.pop s;;
- : string = "hello again" (* s changed from the last pop, so this pop is different! *)

# Stack.pop s;;
- : string = "hello"

# Stack.pop s;;
Exception: Stdlib.Stack.Empty.

# Stack.pop_opt s;; (* altenative interface to return an option and avoid exceptions *)
- : string option = None

