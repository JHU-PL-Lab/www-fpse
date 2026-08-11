type ff_num = Fixed of int | Floating of float;; (* read "|" as "or" *)

Fixed 5;; (* tag 5 as a Fixed *)

Floating 4.0;; (* tag 4.0 as a Floating *)

let ff_as_int x =
  match x with
  | Fixed n -> n (* pattern match like with option/list/result - those types are also variants *)
  | Floating z -> int_of_float z
;;

ff_as_int (Fixed 5);;

let ff_add n1 n2 =
  match n1, n2 with (* note use of pair here to parallel-match on two variables  *)
  | Fixed i1, Fixed i2 -> Fixed (i1 + i2)
  | Fixed i1, Floating f2 ->  Floating (float i1 +. f2) (* need to coerce *)
  | Floating f1, Fixed i2 -> Floating (f1 +. float i2) (* ditto *)
  | Floating f1, Floating f2 -> Floating (f1 +. f2)
;;

ff_add (Fixed 123) (Floating 3.14159);;

type complex = CZero | Nonzero of float * float;;

let com = Nonzero (3.2, 11.2);;

let zer = CZero;;

let parsing = Fun.id Nonzero (3.2, 11.2);; (* this is a typing error, it views as (Fun.id Nonzero) (3.2, 11.2) *)

let parsing = Fun.id @@ Nonzero (3.2, 11.2);; (* so use @@ instead of " " *)

(* Example derived from
   https://exercism.io/tracks/ocaml/exercises/hamming/solutions/afce117bfacb41cebe5c6ebb5e07e7ca
*)

type nucleotide = A | C | G | T

let combine_opt l r =
  try Some (List.combine l r) with
  | _ -> None

let count f l =
  List.fold_left (fun acc x ->
    if f x then 1 + acc else acc
  ) 0 l

let hamming_distance (left : nucleotide list) (right : nucleotide list) : int option =
  match combine_opt left right with (* this returns Some list or None *)
  | None -> None
  | Some l -> Some (count (fun (a, b) -> a <> b) l)

let hamm_example = hamming_distance [A;A;C;A;T;T] [A;A;G;A;C;T]

let hamming_distance' (left : nucleotide list) (right : nucleotide list) : int option =
  Option.bind (combine_opt left right) (fun l -> Some(count (fun (a, b) -> a <> b) l))

let (let*) = Option.bind

let hamming_distance'' (left : nucleotide list) (right : nucleotide list) : int option =
  let* l = combine_opt left right in Some(count (fun (a, b) -> a <> b) l)

# #show_type option;;
type 'a option = None | Some of 'a

# #show_type result;;
type ('a, 'b) result = ('a, 'b) result = Ok of 'a | Error of 'b

type 'a lizt = Mt | Cons of 'a * 'a lizt;; (* the recursive "'a lizt" on the rhs is a lizt of 'a *)

let lizt_eg = Cons (3, Cons (5, Cons (7, Mt)));; (* analogous to 3 :: 5 :: 7 :: [] = [3;5;7] *)

let rec lizt_map (f : 'a -> 'b) (ml : 'a lizt) : 'b lizt =
  match ml with
  | Mt -> Mt
  | Cons (hd, tl) -> Cons (f hd, lizt_map f tl)

let map_eg = lizt_map (fun x -> x - 1) (Cons (3, Cons (5, Cons (7, Mt))))

# #show_type list;;
type 'a list = [] | (::) of 'a * 'a list

type 'a bin_tree =
  | Leaf
  | Node of 'a * 'a bin_tree * 'a bin_tree

let bt0 = Node ("whack!", Leaf, Leaf);;

let bt1 =
  Node
    ( "fiddly"
    , Node ("backer", Leaf, Node ("crack", Leaf, Leaf))
    , bt0
    )
;;

(* Type error, like list, must have uniform type: *)
Node ("fiddly", Node (0, Leaf, Leaf), Leaf);;

let rec add_gobble string_bintree =
  match string_bintree with
  | Leaf -> Leaf
  | Node (y, left, right) ->
    Node (y ^ " gobble", add_gobble left, add_gobble right)

let rec map (f : 'a -> 'b) (tree : 'a bin_tree) : 'b bin_tree =
  match tree with
  | Leaf -> Leaf
  | Node (y, left, right) ->
    Node (f y, map f left, map f right)

(* using tree map to make a non-recursive add_gobble *)
let add_gobble tree = map (fun s -> s ^ " gobble") tree

let rec reduce (f : 'a -> 'acc -> 'acc -> 'acc) (tree : 'a bin_tree) (leaf : 'acc) : 'acc =
  match tree with
  | Leaf -> leaf
  | Node (y, left, right) ->
    f y (reduce f left leaf) (reduce f right leaf)

(* using tree reduce *)
let int_summate tree = reduce (fun elt laccum raccum -> elt + laccum + raccum) tree 0;;

int_summate @@ Node (3, Node (1, Leaf, Node (2, Leaf, Leaf)), Leaf);;

(* reduce can also do map-like operations - the reduction can return a tree *)
let inc_nodes tree = reduce (fun elt la ra -> Node (elt+1, la, ra)) tree Leaf;;

let rec insert (x : 'a) (bt : 'a bin_tree) : ('a bin_tree) =
  match bt with
  | Leaf -> Node (x, Leaf, Leaf)
  | Node (y, left, right) ->
    if x <= y then
      Node (y, insert x left, right)
    else
      Node (y, left, insert x right)
;;

let bt' = insert 4 bt;;

let bt'' = insert 0 bt';; (* thread in the most recent tree into subsequent insert *)

List.sort String.compare ["Zoo";"Hey";"Abba"];; (* pass string's comparison function as argument *)

(* insight into OCaml expected behavior for compare: *)
# String.compare "Ahh" "Ahh";; (* =  returns 0 : equal *)
- : int = 0

# String.compare "Ahh" "Bee";; (* < returns -1 : less *)
- : int = -1

# String.compare "Ahh" "Ack";; (* > returns 1 : greater *)
- : int = 1

let rec insert compare x bt  =
  match bt with
  | Leaf -> Node (x, Leaf, Leaf)
  | Node (y, left, right) ->
    if compare x y <= 0 then
      Node (y, insert compare x left, right)
    else
      Node (y, left, insert compare x right)
;;

let bt' = insert (Int.compare) 4 bt ;;

module S = Set.Make(Int);; (* This is how you set up an int set; covered later *)

let s1 =  S.empty |> S.add 1 |> S.add 2;; (* the set {1, 2} *)
let s2 =  S.empty |> S.add 2 |> S.add 1;; (* the set {1, 2} again *)

let _ = s1 = s2;; (* returns false, but they represent the same set - ! *)

let _ = compare m1 m2;; (* the second one is considered "greater" due to internal rep'n *)

#require "ppx_deriving.eq";; (* loads the extension into utop *)
#require "ppx_deriving.ord";; (* ditto *)

type 'a tree = Leaf | Node of 'a * 'a tree * 'a tree [@@deriving ord, eq];;

type 'a tree = Leaf | Node of 'a * 'a tree * 'a tree
val compare_tree : ('a -> 'a -> int) -> 'a tree -> 'a tree -> int = <fun>
val equal_tree : ('a -> 'a -> bool) -> 'a tree -> 'a tree -> bool = <fun>

# `Zinger 3;; (* prefix constructors with a backtick for the inferred variants *)
- : [> `Zinger of int ] = `Zinger 3

# let f b = if b then `Zinger 3 else `Zanger "hi";;
val f : bool -> [> `Zanger of string | `Zinger of int ] = <fun>

# let zing_zang z =
  match z with
  | `Zinger n -> "zing! " ^ string_of_int n
  | `Zanger s -> "zang! " ^ s
val zing_zang : [< `Zanger of string | `Zinger of int ] -> string = <fun>

# zing_zang @@ `Zanger "wow";;
- : string = "zang! wow"

# zing_zang @@ `Zuber 1.2;;
Line 1, characters 13-23:
Error: This expression has type [> `Zuber of float ]
       but an expression was expected of type
         [< `Zanger of string | `Zinger of int ]
       The second variant type does not allow tag(s) `Zuber

