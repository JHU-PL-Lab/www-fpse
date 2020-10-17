(* SFS mods based on
   https://exercism.io/tracks/ocaml/exercises/minesweeper/solutions/ace26e2f446a4a18a3b1bad83dd9487c  
*)

open Core

(* Use a 2D array of characters for board - supports O(1) random access *)
(* Let us pull out the generic 2D array stuff into its own module *)

module Array_2d = struct
  type 'a t = 'a array array

  let get (b: 'a t) (x: int) (y: int): 'a option = 
    try Some(b.(x).(y)) with Invalid_argument _ -> None

  let map (b: 'a t) ~(f: int -> int -> 'a -> 'a): ('a t) =
    Array.mapi b ~f:(fun y r -> Array.mapi r ~f:(f y))
    
  let adjacents (b: 'a t) (x: int) (y: int): 'a list = 
    let g xo yo = get b (x + xo) (y + yo) in
    List.filter_map ~f:Fn.id [
      g (-1) (-1);  g 0 (-1);  g 1 (-1);
      g (-1) 0   ;             g 1 0   ;
      g (-1) 1   ;  g 0 1   ;  g 1 1   ; 
    ]
end

(* Precondition: neighbor count i must be 0-8 *)
let to_char = function
  | i when (0 <= i && i <= 8) -> Option.value_exn (Char.of_int (i+48))
  | _  -> assert(false)

(* Simpler implementation of the above *)
let to_char' i = i |> Int.to_string |> Fn.flip String.get 0

let is_mine = Char.equal '*'
let is_field = Fn.non is_mine

let from_string_list (l : string list) = 
  List.to_array (List.map l ~f:(fun s -> String.to_array s))

(* Main calculation: annotate a board of mines *)

let annotate (board: char Array_2d.t) = 
  let count x y = Array_2d.adjacents board x y |> List.count ~f:(is_mine) in
  Array_2d.map board ~f:(fun y x c -> if is_field c then (count x y |> to_char) else c)  
