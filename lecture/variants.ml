type ff_num = Fixed of int | Floating of float;;  (* read "|" as "or" *)

Fixed 5;; (* tag 5 as a Fixed *)
Floating 4.0;; (* tag 4.0 as a Floating *)

let ff_as_int x =
    match x with
    | Fixed n -> n    (* variants fit well into pattern matching syntax *)
    | Floating z -> int_of_float z;;

ff_as_int (Fixed 5);;

let ff_add n1 n2 =
   match n1, n2 with    (* note use of pair here to parallel-match on two variables  *)
     | Fixed i1, Fixed i2 -> Fixed (i1 + i2)
     | Fixed i1, Floating f2 ->  Floating(float i1 +. f2) (* need to coerce *)
     | Floating f1, Fixed i2 -> Floating(f1 +. float i2)  (* ditto *)
     | Floating f1, Floating f2 -> Floating(f1 +. f2)
;;

ff_add (Fixed 123) (Floating 3.14159);;

type complex = CZero | Nonzero of float * float;;

let com = Nonzero(3.2,11.2);;
let zer = CZero;;
let ocaml_annoyance = Fn.id Nonzero(3.2,11.2);; (* this is a parsing glitch; use @@ instead of " " *)

(* Example derived from 
   https://exercism.io/tracks/ocaml/exercises/hamming/solutions/afce117bfacb41cebe5c6ebb5e07e7ca
   This code needs a #require "ppx_jane";; in top loop to load ppx extension for @@deriving equal 
   Or, in a dune file it will need   (preprocess (pps ppx_deriving.eq)) added to the library decl *)

type nucleotide = A | C | G | T [@@deriving equal]

let hamming_distance (left : nucleotide list) (right : nucleotide list) : ((int, string) result)=
  match List.zip left right with (* recall this returns Ok(list) or Unequal_lengths, another variant *)
  | List.Or_unequal_lengths.Unequal_lengths -> Error "left and right strands must be of equal length"
  | List.Or_unequal_lengths.Ok l ->
    l
    |> List.filter ~f:(fun (a,b) -> not (equal_nucleotide a b)) 
    |> List.length 
    |> fun x -> Ok(x) (* Unfortunately we can't just pipe to `Ok` since `Ok` is not a function in OCaml - make it one here *)

let hamm_example = hamming_distance [A;A;C;A;T;T] [A;A;G;A;C;T]

let hamming_distance (left : nucleotide list) (right : nucleotide list) : ((int, string) result)=
  match List.zip left right with
  | List.Or_unequal_lengths.Unequal_lengths -> Error "left and right strands must be of equal length"
  | List.Or_unequal_lengths.Ok (l) ->
    l
    |> List.fold ~init:0 ~f:(fun accum (a,b) -> accum + if (equal_nucleotide a b) then 0  else 1) 
    |> fun x -> Ok(x)

# #show_type option;;
type 'a option = None | Some of 'a

# #show_type result;;
type ('a, 'b) result = ('a, 'b) result = Ok of 'a | Error of 'b

# #show_type List.Or_unequal_lengths.t;;
type 'a t = 'a List.Or_unequal_lengths.t = Ok of 'a | Unequal_lengths

type 'a homebrew_list = Mt | Cons of 'a * 'a homebrew_list;;
let hb_eg = Cons(3,Cons(5,Cons(7,Mt)));; (* analogous to 3 :: 5 :: 7 :: [] = [3;5;7] *)

let rec homebrew_map (ml : 'a homebrew_list) ~(f : 'a -> 'b) : ('b homebrew_list) =
  match ml with
    | Mt -> Mt
    | Cons(hd,tl) -> Cons(f hd,homebrew_map tl ~f)

let map_eg = homebrew_map (Cons(3,Cons(5,Cons(7,Mt)))) ~f:(fun x -> x - 1)

# #show_type list;;
type 'a list = [] | (::) of 'a * 'a list

type 'a bin_tree = Leaf | Node of 'a * 'a bin_tree * 'a bin_tree

let bt0 = Node("whack!",Leaf, Leaf);;
let bt1 = Node("fiddly ",
            Node("backer ",
               Leaf,
               Node("crack ",
                  Leaf,
                  Leaf)),
            bt0);;

let bt2 = Node("fiddly ",
            Node("backer ",
               Leaf,
               Node("crack ",
                  Leaf,
                  Leaf)),
            bt0);;
(* Type error, like list, must have uniform type: *)
Node("fiddly",Node(0,Leaf,Leaf),Leaf);;

let rec add_gobble binstringtree =
   match binstringtree with
   | Leaf -> Leaf
   | Node(y, left, right) ->
       Node(y^"gobble",add_gobble left,add_gobble right)

let rec map (tree : 'a bin_tree) ~(f : 'a -> 'b) : ('b bin_tree) =
   match tree with
   | Leaf -> Leaf
   | Node(y, left, right) ->
       Node(f y,map ~f left,map ~f right)

(* using tree map to make a non-recursive add_gobble *)
let add_gobble tree = map ~f:(fun s -> s ^ "gobble") tree

let rec fold (tree : 'a bin_tree) ~(f : 'a -> 'accum -> 'accum -> 'accum) ~(leaf : 'accum) : 'accum =
   match tree with
   | Leaf -> leaf
   | Node(y, left, right) ->
       f y (fold ~f ~leaf left) (fold ~f ~leaf right)

(* using tree fold *)
let int_summate tree = fold ~f:(fun elt laccum raccum -> elt + laccum + raccum) ~leaf:0 tree;;
int_summate @@ Node(3,Node(1,Leaf,Node(2,Leaf,Leaf)),Leaf);;
(* fold can also do map-like operations - the folder can return a tree *)
let bump_nodes tree = fold ~f:(fun elt la ra -> Node(elt+1,la,ra)) ~leaf:Leaf tree;;

let rec insert_int (x : int) (bt : int bin_tree) : (int bin_tree) =
   match bt with
   | Leaf -> Node(x, Leaf, Leaf)
   | Node(y, left, right) ->
       if x <= y then Node(y, insert_int x left, right)
       else Node(y, left, insert_int x right)
;;

let bt' = insert_int 4 bt;;
let bt'' = insert_int 0 bt';; (* thread in the most recent tree into subsequent insert *)

List.sort ["Zoo";"Hey";"Abba"] (String.compare);; (* pass string's comparison function as argument *)
(* insight into OCaml expected behavior for compare: *)
# String.compare "Ahh" "Ahh";; )(* =  returns 0 *)
- : int = 0
# String.compare "Ahh" "Bee";; (* < returns -1 *)
- : int = -1
# String.compare "Ahh" "Ack";; (* > returns 1 *)
- : int = 1

let rec insert x bt compare =
   match bt with
   | Leaf -> Node(x, Leaf, Leaf)
   | Node(y, left, right) ->
       if (compare x y) <= 0 then Node(y, insert x left compare, right)
       else Node(y, left, insert x right compare)
;;
let bt' = insert 4 bt (Int.compare);;

# `Zinger(3);; (* prefix constructors with a backtick for the inferred variants *)
- : [> `Zinger of int ] = `Zinger 3

# [`Zinger 3; `Zanger "hi"];;
- : [> `Zanger of string | `Zinger of int ] list = [`Zinger 3; `Zanger "hi"]

# let zing_zang z = 
match z with
| `Zinger n -> "zing! "^(Int.to_string n)
| `Zanger s -> "zang! "^s
val zing_zang : [< `Zanger of string | `Zinger of int ] -> string = <fun>

# zing_zang @@ `Zanger "wow";;
- : string = "zang! wow"
# zing_zang @@ `Zuber 1.2;;
Line 1, characters 13-23:
Error: This expression has type [> `Zuber of float ]
       but an expression was expected of type
         [< `Zanger of string | `Zinger of int ]
       The second variant type does not allow tag(s) `Zuber

