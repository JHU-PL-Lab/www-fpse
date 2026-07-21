(* Calculator to determine how many mines are adjacent to each square in an nxn grid.

   '*' is a mine, ' ' is no mine.  Output 0-8 in each non-mine square indicating how many mines
   (use ' ' instead of 0 in the output if there are no mines, that is the tradition)

   We will do multiple variations on different ways to express things for this example.

   Initial code for the below was taken from
    https://exercism.io/tracks/ocaml/exercises/minesweeper/solutions/ace26e2f446a4a18a3b1bad83dd9487c

*)

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

(* A less brute-force equivalent to the above.  Above is more readable and precise *)  

let to_char' i = 
  i 
  |> Int.to_string 
  |> (Fun.flip String.get) 0 
  |> fun c -> if c = '0' then ' ' else c

module Board = struct
  type t = string list (* board data; see test/test.ml for examples. *)
     (* A string list is a too-low-level representation of a 2D array, dimensions are not uniform *)
     (* Additionally, using '*' for mines and ' ' for non-mines is too low-level. 
     
     Note that the list of strings view is too low-level but we can
     hide that by making some functions to give a higer-level interface *)

  (* get the (x,y) character from board b.
     Should return `None` in all error cases where (x,y) is not on grid
     We will write several different equivalent versions to compare. 
 *)

(* First lets make a clean list-nth function which returns None for any out of bounds access *) 
let list_nth_opt l n = 
  try List.nth_opt l n with _ -> None

let get (b : t) (x : int) (y : int) : char option =
    match list_nth_opt b y with
    | None -> None 
    | Some(row) -> (try Some(String.get row x) with _ -> None)

(* Get a list of chars for all the squares adjacent to (x,y) *)    
(* Note List.filter_map Fun.id [Some 4; None; Some 7; None; Some (-1)] is [4; 7; -1]: 
     map the Somes, toss the Nones *)

  let adjacents (b : t) (x : int) (y : int) : char list =
    let g xo yo = get b (x + xo) (y + yo) in
    List.filter_map Fun.id
      [
        g (-1) (-1); g 0 (-1); g 1 (-1); g (-1) 0; g 1 0; g (-1) 1; g 0 1; g 1 1;
      ]

  let is_mine = Char.equal '*'
  let is_field = Fun.negate is_mine
  let is_field' c = not @@ is_mine c (* this version without Fun.negate shows why it is handy *)

  (* Apply a function to every non-mine element of the grid to produce a new grid 
     Mapping function f gets the x, y coordinate as well as args 
     Its a 2D extension of idea of the List.mapi function which lets f also see list position #:
        List.mapi (fun index i -> index + i) [1;2;3] is  [1; 3; 5] *)
  let mapxy (b : t) (f : int -> int -> char -> char) : t =
    List.mapi (fun y r ->
        String.mapi (fun x c -> if is_field c then f x y c else c) r) b
end

let annotate (board : Board.t) : Board.t =
  let count x y = Board.adjacents board x y |> fun l -> List.length (List.filter Board.is_mine l) in
  Board.mapxy board (fun x y _ -> count x y |> to_char)

