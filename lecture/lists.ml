let rec rev l =
  match l with
  |  [] -> []
  |  hd :: tl -> rev tl @ [hd]
;;

rev [1;2;3];; (* recall this list is 1 :: [2;3] which is the tree 1 :: ( 2 :: ( 3 :: [])) *)

# List.rev [1;2;3];;
- : int list = [3; 2; 1]

List.length ["d";"ss";"qwqw"];;

List.is_empty [];;

List.concat [[1;2]; [1;2;3]];; (* joins all elements in a list of lists into one list *)

List.append [1;2] [3;4];; (* Note you should use the more convenient infix @ syntax for listappend *)

# List.length;;
- : 'a list -> int = <fun> (* "for ANY type 'a, List.length will take a list of 'a and return an integer" *)

# List.is_empty;;
- : 'a list -> bool = <fun>

# List.concat;;
- : 'a list list -> 'a list = <fun>

# List.append;;
- : 'a list -> 'a list -> 'a list = <fun>

# List.map;;  (* Foreshadowing; we will review this function below *)
- : ('a -> 'b) -> 'a list -> 'b list = <fun> (* takes in a function! *)

let rec concat (l : 'a list list) =
  match l with
  | [] -> [] (* "joining together a list of no-lists is an empty list" *)
  | l :: ls -> l @ concat ls (* by induction assume (concat ls) will turn a list-of-lists into a single list *)

# (1,2.,"3");;
- : int * float * string = (1, 2., "3")

# [1,2,3];; (* a common error, parens not always needed so this is a singleton list of a 3-tuple, not a list of ints *)
- : (int * int * int) list = [(1, 2, 3)]

let divide_in_half (l : 'a list) : 'a list * 'a list =
  let half = List.length l / 2 in
  (List.take half l, List.drop half l)
;;

divide_in_half [2;3;4;5;99;6];;

# List.combine;;
- : 'a list -> 'b list -> ('a * 'b) list = <fun>

let combine_pair (l1, l2) = List.combine l1 l2;;

combine_pair @@ divide_in_half [1;2;3;4;5;6];; (* returns a list-of-pairs *)

[(1, 3); (2, 4)] |> List.split |> combine_pair ;;  (* no-op! *)

([1; 2; 3], [4; 5; 6]) |> combine_pair |> List.split;; (* another no-op! *)

let curry f = fun x -> fun y -> f (x, y);;

let uncurry f = fun (x, y) -> f x y;;

curry : ('a * 'b -> 'c) -> 'a -> 'b -> 'c

uncurry : ('a -> 'b -> 'c) -> 'a * 'b -> 'c

let combine_pair = Pair.fold List.combine;; (* Pair.fold is uncurry *)

let compose g f = fun x -> g (f x);;

compose (fun x -> x + 3) (fun x -> x * 2) 10;;

let compose g f x =  g (f x);;

let compose g f = (fun x -> g (f x));; (* this equivalent form reads more how you think of the "o" operation in math *)

let compose = fun g -> (fun f -> (fun x -> g (f x)));;

let compose g f x =  x |> f |> g;; (* This is the readability winner: feed x into f and f's result into g *)

# (compose combine_pair List.split) [(1, 3); (2, 4)];;
- : (int * int) list = [(1, 3); (2, 4)]

List.filter (fun x -> x >= 0) [1;-1;2;-2;0];;

let remove_negatives = List.filter (fun x -> x >= 0);;

remove_negatives [1;-1;2;-2;0];;

let gtz x = x >= 0;;

List.filter gtz [1;-1;2;-2;0];;

let has_negs l = l |> List.filter (fun x -> x < 0) |> List.is_empty |> not;;

let has_negs l = List.exists (fun x -> x < 0) l;;

# List.map (fun x -> x + 1) [1;-1;2;-2;0];;
- : int list = [2; 0; 3; -1; 1]

# List.map (fun x -> x >= 0) [1;-1;2;-2;0];;
- : bool list = [true; false; true; false; true]

List.map (fun (x, y) -> x + y) [(1,2);(3,4)];; (* turns list of number pairs into list of their sums *)

List.map (uncurry (+)) [(1,2);(3,4)];; (* equivalent: its an uncurried add function that is needed *)

let rec char_list_to_string l =
  match l with
  | [] -> "" (* initial value above is this "", plug it in as the base case *)
  | elt :: elts ->  (* as in the above we are calling the current list element `elt` *)
    let acc = char_list_to_string elts in (* this is also what `acc` is above, the result of recursing on the tail *)
    String.of_char elt ^ acc (* same as the body of f above, the calculation done on acc and elt *)

let rec fold_right f l init =
  match l with
  | [] -> init
  | elt :: elts ->
    let acc = fold_right f elts init in
    f elt acc

fold_right (fun elt acc -> String.of_char elt ^ acc) ['a';'b';'c'] "" ;;

let fold_right f l init =
  let rec folder_aux l =
    match l with
    | [] -> init
    | elt :: elts ->
      let accum = folder_aux elts in
      f elt accum
  in
  folder_aux l

List.fold_right (fun elt acc -> elt + acc) [3; 5; 7] 0;; (* this computes 3 + (5 + (7 + 0))  *)

List.fold_right (+) [3; 5; 7] 0;;

List.fold_left (fun accum elt -> accum + elt) 0 [3; 5; 7];; (* this is ((0 + 3) + 5) + 7 *)

let rec char_list_to_string l accum = (* invariant: accum is the accumulated result thus far *)
  match l with
  | [] -> accum (* we are totally done at this point, `accum` is the final result and just pop back out *)
  | elt :: elts ->
    char_list_to_string elts (accum ^ String.of_char elt) (* we are computing the `f` to accumulate result on the way *down* the recursion *)
;;

char_list_to_string ['a';'d'] "";; (* we need to prime the accum pump with "" here *)

let rec fold_left f init l =
  match l with
  | [] -> init
  | elt :: elts ->
    fold_left f (f init elt) elts (* observe f is invoked **before** the call -- accumulating left-first *)

let exists f l =
  l
  |> List.map f
  |> List.fold_left (||) false;; (* the List.map output is a list of booleans, just fold them up here *)

# exists (fun x -> x >= 0) [-1;-2];;
- : bool = false

# exists (fun x -> x >= 0) [1;-2];;
- : bool = true

let exists f l =
  List.fold_left (fun accum elt -> accum || f elt) false l;;

let map f l = List.fold_left (fun accum elt -> accum @ [f elt]) [] l

let map_right f l = List.fold_right (fun elt accum -> (f elt) :: accum) [] l;;

let rec fold_right f l init =
  match l with
  | [] -> init
  | hd :: tl -> f hd (fold_right f tl init) (* observe it is invoking f **after** the recursive call *)

let rec fold_left f init l =
  match l with
  | [] -> init
  | hd :: tl -> fold_left f (f init hd) tl (*observe f is invoked **before** the call -- accumulating left-first *)

# let f ?x y = match x with Some z -> z + y | None -> y;;
val f : ?x:int -> int -> int = <fun>

# f ~x:1 2;; (* give the named argument here *)
- : int = 3

# f 2;; (* implicitly not giving it here so x is None in the body. *)
- : int = 2

