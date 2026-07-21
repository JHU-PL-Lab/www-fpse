(* Let's re-code the minesweeper with a more intelligent / abstract data structure, not the list of strings *)

(* Use a 2D immutable array of characters for board - supports O(1) random access *)
(* It is also arguably a cleaner design as we have a separate data structure for the 2D array *)

(* Code below is similar to minesweeper.ml otherwise *)
(* We still are using chars ' ' / '*' for grid entries which is still too low-level.. *)

(* Let us pull out the immutable 2D array stuff into its own module, instead of Board *)
(* Why? A 2D immutable array is a very clear abstraction boundary, we know exactly what it is *)
(* This struct is a generic 2D immutable array, nothing here is for minesweeper only *)
(* Lets also use actual arrays.  Since grids don't get extended/shunk lists have no advantage *)
(* This shows we can use arrays functionally, we don't mutate it but we get O(1) access benefit *)
module Array_2d = struct
  type 'a t = 'a array array

(* The following functions are much more sensible with an OCaml array *)
  let get (b : 'a t) (x : int) (y : int) : 'a option =
    try Some(b.(x).(y)) with _ -> None

  let mapxy (b : 'a t) (f : int -> int -> 'a -> 'b) : 'b t =
    Array.mapi (fun y r -> Array.mapi (f y) r) b

  let adjacents (b : 'a t) (x : int) (y : int) : 'a list =
    let g xo yo = get b (x + xo) (y + yo) in
    List.filter_map Fun.id
      [
        g (-1) (-1); g 0 (-1); g 1 (-1); g (-1) 0; g 1 0; g (-1) 1; g 0 1; g 1 1;
      ]
end

let to_char = function
  | 0 -> ' '
  | 1 -> '1'
  | 2 -> '2'
  | 3 -> '3'
  | 4 -> '4'
  | 5 -> '5'
  | 6 -> '6'
  | 7 -> '7'
  | 8 -> '8'
  | _ -> invalid_arg "all counts must be 0-8"

let is_mine = Char.equal '*'

let is_field = Fun.negate is_mine

(* Need conversion functions to/from list of strings format since tests are that form *)

let from_string_list (l : string list) : char array array =
  Array.of_list (List.map (fun s -> Array.init (String.length s) (String.get s)) l)

let to_string_list (board : char Array_2d.t) : string list =
  Array.fold_left (fun accum_l a ->
      accum_l
      @ [ Array.fold_left (fun accum c -> accum ^ String.make 1 c) "" a]) [] board

(* Main calculation: annotate a board of mines; similar to minesweeper.ml *)

let array_annotate (board : char Array_2d.t) : char Array_2d.t =
  let count_nearby_mines x y =
    Array_2d.adjacents board x y |> fun l -> List.length (List.filter is_mine l)
  in
  Array_2d.mapxy board (fun y x c ->
      if is_field c then count_nearby_mines x y |> to_char else c)

(* Overall function requires conversion functions in pipeline, no big deal. *)      
let annotate (l : string list) : string list =
  l |> from_string_list |> array_annotate |> to_string_list

(* simple test *)  
let _  = annotate [
        "  *  ";
        "  *  ";
        "*****";
        "  *  ";
        "  *  ";
      ]