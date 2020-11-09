open Core

(* Recall a standard binary tree type *)

type 'a bin_tree = Leaf | Node of 'a * 'a bin_tree * 'a bin_tree

(* Standard tree fold function *)
let rec fold tree ~f ~leaf =
  match tree with
  | Leaf -> leaf
  | Node(y, left, right) ->
    f y (fold ~f ~leaf left) (fold ~f ~leaf right)

(* Using standard tree fold *)
let int_summate tree = fold ~f:(fun y -> fun ls -> fun rs-> y + ls + rs) ~leaf:0 tree;;
let bt = Node(3,Node(1,Leaf,Node(2,Leaf,Leaf)),Leaf);;
int_summate bt;;

(* CPS tree fold function *)
let rec fold_cps (tree:'b bin_tree) ~(f:'b -> 'a -> 'a -> 'a) ~(leaf:'a) ~(c : 'a -> 'b) =
  match tree with
  | Leaf -> c(leaf)
  | Node(x, left, right) ->
    fold_cps  (* Tail recursive now - ! *)
      left ~f ~leaf
      ~c:(fun y -> 
          fold_cps (* also a tail-call here so again no stack needed *)
            right ~f ~leaf 
            ~c:(fun z -> c(f x y z)) 
        )

(* Usage requires giving a top-level continuation, in this case id *)
let int_summate_cps tree = 
  fold_cps ~f:(fun y -> fun ls -> fun rs -> y + ls + rs) ~leaf:0 ~c:(Fn.id) tree;;

int_summate_cps bt;;


