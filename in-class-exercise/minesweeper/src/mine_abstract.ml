(* Make the grid more well-typed and not just characters *)
(* Builds on mine_array.ml *)

(* You will need to complete the port, its halfway through here.
   We made the new grid cell types and updated the types on existing
   functions to give a goal but only partly ported the code. *)

open Core


[@@@ocaml.warning "-32"]
[@@@ocaml.warning "-27"]

(* Array_2d as in mine_array.ml *)

module Array_2d = struct
  type 'a t = 'a array array

  let get (b : 'a t) (x : int) (y : int) : 'a option =
    Option.try_with (fun () -> b.(x).(y))

  let mapxy (b : 'a t) ~(f : int -> int -> 'a -> 'b) : 'b t =
    Array.mapi b ~f:(fun y r -> Array.mapi r ~f:(f y))

  let adjacents (b : 'a t) (x : int) (y : int) : 'a list =
    let g xo yo = get b (x + xo) (y + yo) in
    List.filter_opt (* same as List.filter_map ~f:Fn.id *)
      [
        g (-1) (-1); g 0 (-1); g 1 (-1); g (-1) 0; g 1 0; g (-1) 1; g 0 1; g 1 1;
      ]
end

(* Lets make types specifying exactly the cell content types 
   on input and output grids respectively
   We need different names for mines in the two types, so we use Mine_in and Mine_out *)

type input_cell = Mine_in | Empty
type output_cell = Mine_out | Count of int

let to_result n = Count(n)

(* Convert an output_cell to the corresponding string.*)
let count_to_string (c : output_cell) : string = 
 failwith "unimplemented"

(* Check for a mine on input grid. *)
let is_mine (s : input_cell) : bool = 
  failwith "unimplemented"

let is_field = Fn.non is_mine

(* Conversion is now a little bit more work.  For the input lets
   1) read it into a char Array_2d.t
   2) convert that to a input_cell Array2d.t via mapxy *)

let from_string_list (l : string list) : input_cell Array_2d.t =
  let char_array : char Array_2d.t = (List.to_array (List.map l ~f:(fun s -> String.to_array s))) in
  Array_2d.mapxy char_array ~f:(fun _ _ _ -> Empty(* fill in*))

(* Here is the output conversion which we give you *)  

  let to_string_list (board : output_cell Array_2d.t) : string list =
  Array.fold board ~init:[] ~f:(fun accum_l a ->
      accum_l
      @ [ Array.fold a ~init:"" ~f:(fun accum c -> accum ^ count_to_string c) ])

(* Main calculation: annotate a board of mines; similar to minesweeper.ml *)
(* The type of the function has been updated but not the code, try to fix
   hint: chase type errors! *)

let array_annotate (board : input_cell Array_2d.t) : output_cell Array_2d.t =
  let count_nearby_mines x y =
    Array_2d.adjacents board x y |> List.count ~f:is_mine
  in
  Array_2d.mapxy board ~f:(fun x y c ->
      if is_field c then count_nearby_mines x y |> to_char else c)

(* Overall function requires conversion functions in pipeline, no big deal. *)      
let annotate (l : string list) : string list =
  l |> from_string_list |> array_annotate |> to_string_list

let _  = annotate [
        "  *  ";
        "  *  ";
        "*****";
        "  *  ";
        "  *  ";
      ];;