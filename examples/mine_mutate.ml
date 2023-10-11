
(* 
Minesweeper board display

From https://exercism.io/tracks/ocaml/exercises/minesweeper/solutions/384efbcae59540d18f3c18615dcbb956

*)
open Core

(* Better abstraction of the board cells here: *)

type cell = Mine | Empty of int

(* Far worse abstraction of the board, a 1D array not a 2D array - ! *)

type state = { board : cell Array.t; rows : int; columns : int }

let create_state ~rows ~columns =
  { board = Array.create ~len:(rows * columns) @@ Empty 0; rows; columns }

let string_of_cell = function
  | Mine -> "*"
  | Empty 0 -> " "
  | Empty n -> Int.to_string n

let serialize { board; rows; columns } =
  let converted_board = Array.map ~f:string_of_cell board in
  let rec to_list l i acc =
    if i = Array.length board then (List.rev acc |> String.concat) :: l
    else if List.length acc = columns then
      to_list
        ((List.rev acc |> String.concat) :: l)
        (i + 1) [ converted_board.(i) ]
    else to_list l (i + 1) (converted_board.(i) :: acc)
  in
  if rows = 0 then [] else to_list [] 0 [] |> List.rev

let parse = function
  | [] -> create_state ~rows:0 ~columns:0
  | hd :: _ as l ->
    let columns = String.length hd in
    let rows = List.length l in
    let state = create_state ~rows ~columns in
    l
    |> List.bind ~f:String.to_list
    |> List.iteri ~f:(fun i c ->
        state.board.(i) <- (match c with '*' -> Mine | _ -> Empty 0));
    state

let neighbors length columns i =
  let rows = length / columns in
  let row_col_to_idx (row, col) =
    Option.some_if
      (row >= 0 && row < rows && col >= 0 && col < columns)
      ((row * columns) + col)
  in
  let row = i / columns in
  let col = i % columns in
  List.init 8 ~f:(function
      | 0 -> row_col_to_idx (row - 1, col - 1)
      | 1 -> row_col_to_idx (row - 1, col)
      | 2 -> row_col_to_idx (row - 1, col + 1)
      | 3 -> row_col_to_idx (row, col - 1)
      | 4 -> row_col_to_idx (row, col + 1)
      | 5 -> row_col_to_idx (row + 1, col - 1)
      | 6 -> row_col_to_idx (row + 1, col)
      | 7 -> row_col_to_idx (row + 1, col + 1)
      | _ -> None)
  |> List.filter_map ~f:Fn.id

let handle_cell state i = function
  | Mine ->
    neighbors (Array.length state.board) state.columns i
    |> List.iter ~f:(fun idx ->
        match state.board.(idx) with
        | Mine -> ()
        | Empty n -> state.board.(idx) <- Empty (n + 1))
  | Empty _ -> ()

let annotate input =
  let st = parse input in
  Array.iteri ~f:(handle_cell st) st.board;
  serialize st