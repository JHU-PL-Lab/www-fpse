(* Use a 2D immutable array of characters for board - supports O(1) random access *)

(* Similar to minesweeper.ml otherwise *)

open Core

(* Let us pull out the immutable 2D array stuff into its own module *)

module Array_2d = struct
  type 'a t = 'a array array

(* The following functions are much more sensible with a 2D array *)
  let get (b : 'a t) (x : int) (y : int) : 'a option =
    Option.try_with (fun () -> b.(x).(y))

  let mapxy (b : 'a t) ~(f : int -> int -> 'a -> 'b) : 'b t =
    Array.mapi b ~f:(fun y r -> Array.mapi r ~f:(f y))

  let adjacents (b : 'a t) (x : int) (y : int) : 'a list =
    let g xo yo = get b (x + xo) (y + yo) in
    List.filter_map ~f:Fn.id
      [
        g (-1) (-1); g 0 (-1); g 1 (-1); g (-1) 0; g 1 0; g (-1) 1; g 0 1; g 1 1;
      ]
end

let to_char i = i |> Int.to_string |> (Fn.flip String.get) 0 |> fun c -> match c with '-' -> '*' | '0' -> ' ' | _ -> c

let is_mine = Char.equal '*'

let is_field = Fn.non is_mine

(* Need conversion functions to/from list of strings format since tests are that form *)

let from_string_list (l : string list) =
  List.to_array (List.map l ~f:(fun s -> String.to_array s))

let to_string_list (board : char Array_2d.t) : string list =
  Array.fold board ~init:[] ~f:(fun accum_l a ->
      accum_l
      @ [ Array.fold a ~init:"" ~f:(fun accum c -> accum ^ Char.to_string c) ])

(* Main calculation: annotate a board of mines; similar to minesweeper.ml *)

let array_annotate (board : char Array_2d.t) =
  let count_nearby_mines x y =
    Array_2d.adjacents board x y |> List.count ~f:is_mine
  in
  Array_2d.mapxy board ~f:(fun y x c ->
      if is_field c then count_nearby_mines x y |> to_char else c)

(* Overall function requires conversion functions in pipeline *)      
let annotate (l : string list) =
  l |> from_string_list |> array_annotate |> to_string_list
