let rec rev l =
  match l with
  |  [] -> []
  |  hd :: tl -> rev tl @ [hd]
;;
rev [1;2;3];; (* recall input list is the tree 1 :: ( 2 :: ( 3 :: [])) *)

# List.rev [1;2;3];;
- : int list = [3; 2; 1]

let rec zero_negs l =
  match l with
  |  [] -> []
  |  hd :: tl -> (if hd < 0 then 0 else hd) :: zero_negs tl
in
zero_negs [1;-2;3];;

List.length ["d";"ss";"qwqw"];;
List.is_empty [];;
List.last_exn [1;2;3];; (* get last element; raises an exception if list is empty *)
List.join [[1;2];[22;33];[444;5555]];;
List.append [1;2] [3;4];; (* Usually the infix @ syntax is used for append *)

# List.length;;
- : 'a list -> int = <fun>
# List.is_empty;;
- : 'a list -> bool = <fun>
# List.last_exn;;
- : 'a list -> 'a = <fun>
# List.join;;
- : 'a list list -> 'a list = <fun>
# List.append;;
- : 'a list -> 'a list -> 'a list = <fun>
# List.map;;  (* We will do this one below *)
- : 'a list -> f:('a -> 'b) -> 'b list = <fun>

let rec join (l: 'a list list) = match l with
  | [] -> [] (* "joining together a list of no-lists is an empty list" *)
  | l :: ls -> l @ join ls (* "by induction assume (join ls) will turn list-of-lists to single list" *)

# (1,2.,"3");;
- : int * float * string = (1, 2., "3")
# [1,2,3];; (* a common error, parens not always needed so this is a singleton list of a 3-tuple, not a list of ints *)
- : (int * int * int) list = [(1, 2, 3)]

let split_in_half l = List.split_n l (List.length l / 2);;
split_in_half [2;3;4;5;99];;

let all_front_back_pairs l = 
  let front, back = split_in_half l in 
    List.cartesian_product front back;; (* observe how let can itself pattern match pairs *)
val all_front_back_pairs : 'a list -> ('a * 'a) list = <fun>
# all_front_back_pairs [1;2;3;4;5;6];;
- : (int * int) list =
[(1, 4); (1, 5); (1, 6); (2, 4); (2, 5); (2, 6); (3, 4); (3, 5); (3, 6)]

List.unzip @@ all_front_back_pairs [1;2;3;4;5;6];;

[1;2;3;4;5;6] |> all_front_back_pairs |> List.unzip;;

List.zip [1;2;3] [4;5;6];;
- : (int * int) list List.Or_unequal_lengths.t =
Core.List.Or_unequal_lengths.Ok [(1, 4); (2, 5); (3, 6)]

# #show_type List.Or_unequal_lengths.t;;
type 'a t = 'a List.Or_unequal_lengths.t = Ok of 'a | Unequal_lengths

List.zip [1;2;3] [4;5];;
- : (int * int) list List.Or_unequal_lengths.t =
Core.List.Or_unequal_lengths.Unequal_lengths

List.unzip @@ List.zip_exn [1;2] [3;4];;

List.zip_exn @@ List.unzip [(1, 3); (2, 4)];;
Line 1, characters 16-43:
Error: This expression has type int list * int list
       but an expression was expected of type 'a list

let zip_pair (l,r) = List.zip_exn l r in 
zip_pair @@ List.unzip [(1, 3); (2, 4)];;
[(1, 3); (2, 4)] |> List.unzip|> zip_pair ;; (* Pipe equivalent form *)

let curry f = fun x -> fun y -> f (x, y);;
let uncurry f = fun (x, y) -> f x y;;

curry : ('a * 'b -> 'c) -> 'a -> 'b -> 'c
uncurry : ('a -> 'b -> 'c) -> 'a * 'b -> 'c

let zip_pair  = uncurry @@ List.zip_exn;;

let compose g f = (fun x -> g (f x));;
compose (fun x -> x+3) (fun x -> x*2) 10;;

let compose g f x =  g (f x);;
let compose g f = (fun x -> g(f x));; (* this equivalent form reads more how you think of the "o" operation in math *)
let compose = (fun g -> (fun f -> (fun x -> g(f x))));;
let compose g f x =  x |> f |> g;; (* This is the readability winner: feed x into f and f's result into g *)

# (compose zip_pair List.unzip) [(1, 3); (2, 4)];;
- : (int * int) list = [(1, 3); (2, 4)]

List.filter [1;-1;2;-2;0] (fun x -> x >= 0);;

List.filter ~f:(fun x -> x >= 0) [1;-1;2;-2;0];;

let remove_negatives = List.filter ~f:(fun x -> x >= 0);;
remove_negatives  [1;-1;2;-2;0];;

let gtz x = x >= 0;;
List.filter ~f:gtz [1;-1;2;-2;0];;

let has_negs l = l |> List.filter ~f:(fun x -> x < 0) |> List.is_empty |> not;;

let has_negs l = List.exists ~f:(fun x -> x < 0) l;;

# List.map ~f:(fun x -> x + 1) [1;-1;2;-2;0];;
- : int list = [2; 0; 3; -1; 1]
# List.map ~f:(fun x -> x >= 0) [1;-1;2;-2;0];;
- : bool list = [true; false; true; false; true]
List.map ~f:(fun (x,y) -> x + y) [(1,2);(3,4)];; (* turns list of number pairs into list of their sums *)

List.fold_right ['a';'b';'c'] ~init:"" ~f:(fun elt -> fun accum -> (Char.to_string elt)^accum);; (* computes "a"^("b"^("c"^"")) *)

let rec char_list_to_string l =
  match l with 
  | [] -> "" (* ~init above is "", plug it in as the base case *)
  | elt :: elts ->  (* as in the above we are calling the current list element `elt` *)
    let accum = char_list_to_string elts in (* this is what `accum` is, the result of recursing on a shorter list *)
      (Char.to_string elt)^accum (* now plug in the body of ~f as the calculation done on accum and elt *)

let rec fold_right l ~f ~init =
  match l with
  | [] -> init
  | elt :: elts -> 
    let accum = fold_right elts ~f ~init in 
      f elt accum

List.fold_right ~f:(fun elt accum -> elt + accum) ~init:0 [3; 5; 7];;  (* this computes 3 + (5 + (7 + 0))  *)

List.fold_right ~f:(+) ~init:0 [3; 5; 7];;

List.fold ~f:(fun accum elt -> accum + elt) ~init:0 [3; 5; 7];; (* this is ((0 + 3) + 5) + 7 *)

let rec char_list_to_string l accum =
  match l with 
  | [] -> accum (* we are totally done at this point, `accum`` is the final result and just pop pop pop *)
  | elt :: elts -> 
    char_list_to_string elts (accum^(Char.to_string elt));;  (* we are computing the `~f` to accumulate result on the way *down* the recursion now *)
char_list_to_string ['a';'d'] "";; (* we need to prime the accum pump with "" here *)

let exists l ~f =  (* Note: ~f is **declaring** a named argument f; ~f is shorthand for ~f:f *)
  l
  |> List.map ~f    (* ~f alone as an argument is again shorthand for ~f:f *)
  |> List.fold ~f:(||) ~init:false;; (* the List.map output is a list of booleans, just fold them up here *)
# exists ~f:(fun x -> x >= 0) [-1;-2];;
- : bool = false
# exists ~f:(fun x -> x >= 0) [1;-2];;
- : bool = true

let exists l ~f = 
  List.fold l ~f:(fun accum elt -> accum || f elt) ~init:false;;

let map l ~f = List.fold ~f:(fun accum elt -> accum @ [f elt]) ~init:[] l

let map_right l ~f = List.fold_right ~f:(fun elt accum -> (f elt) :: accum) ~init:[] l;;

let rec fold_right ~f l ~init =
  match l with
  | [] -> init
  | hd::tl -> f hd (fold_right ~f tl ~init) (* observe it is invoking f **after** the recursive call *)

let summate_til_zero l =
  List.fold_until l ~init:0
    ~f:(fun acc i -> match i, acc with
        | 0, sum -> Stop sum
        | _, sum -> Continue (i + sum))
    ~finish:Fn.id
let stz_example = summate_til_zero [1;2;3;4;0;5;6;7;8;9;10]

