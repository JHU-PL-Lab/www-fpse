(* Derived from
    https://exercism.io/tracks/ocaml/exercises/minesweeper/solutions/ace26e2f446a4a18a3b1bad83dd9487c

*)

open Core

let to_char = function
  | -1 -> '*'
  | 1 -> '1'
  | 2 -> '2'
  | 3 -> '3'
  | 4 -> '4'
  | 5 -> '5'
  | 6 -> '6'
  | 7 -> '7'
  | 8 -> '8'
  | _ -> ' '

(* A less low-level version of the above: *)  

let to_char' i = i |> Int.to_string |> (Fn.flip String.get) 0 |> fun c -> if Char.(c='-') then '*' else c

module Board = struct
  type t = string list (* board data; see test/test.ml for examples. *)
     (* string list is a too-low-level representation of 2D array, dimensions are not uniform *)

  (* get the (x,y) character from board b.
     
    Should return `None` in all error cases where (x,y) is not on grid

     We will write several different equivalent versions to compare. *)

  let get (b : t) (x : int) (y : int) : char option =
    match List.nth b y with (* If y is too big or small List.nth will return None *)
    | None -> None 
    | Some(row) -> try Some(String.get row x) with Invalid_argument _ -> None  

(* Let us rewrite the above using some Option library functions;
   Hover over the functions to see their types.  *)    
  let get' (b : t) (x : int) (y : int) : char option =
    List.nth b y
    |> Option.value_map ~default:None ~f:(fun row ->
           Option.try_with (fun () -> String.get row x))

  (* Option.bind is like value_map but implicitly propagates None (bubbles it up) 
     This implicit bubbling is part of monadic programming, lots more later on that! *)
  let get'' (b : t) (x : int) (y : int) : char option =
    List.nth b y
    |> Option.bind ~f:(fun row -> Option.try_with (fun () -> String.get row x))

  (* Shorthand pipe notation >>=, it is just infix Option.bind; 
     need to open Option to enable *)

  let get''' (b : t) (x : int) (y : int) : char option =
    Option.(List.nth b y >>= fun row -> try_with (fun () -> String.get row x))

  (* Another equivalent notation for Option.bind where you don't need to make the fun row -> ... ;
     instead use let%bind to bind the `row` here.  Need #require "ppx_jane";; for let%bind
     let%bind allows the None case to be implicit in the background: it reads like regular code
     Compare with the get''' version, it is just a small bit of syntax sugar
 *)
  let get'''' (b : t) (x : int) (y : int) : char option =
    let open Option in (* let open Option in .. is like Option.(...) *)
    let open Let_syntax in (* need to open this module to get let%bind to work *)
    let%bind row = List.nth b y in
    try_with (fun () -> String.get row x)

(* Get a list of chars for all the squares adjacent to (x,y) *)    
(* Note List.filter_map ~f:Fn.id [Some 4; None; Some 7; None; Some (-1)] is [4; 7; -1]: 
     map Somes toss Nones *)

  let adjacents (b : t) (x : int) (y : int) : char list =
    let g xo yo = get b (x + xo) (y + yo) in
    List.filter_map ~f:Fn.id
      [
        g (-1) (-1); g 0 (-1); g 1 (-1); g (-1) 0; g 1 0; g (-1) 1; g 0 1; g 1 1;
      ]

  let is_mine = Char.equal '*'
  let is_field = Fn.non is_mine
  let is_field' c = not @@ is_mine c

  (* Apply a function to every element of the grid to produce a new grid 
    f gets the x y coordinate as well as args 
    its a 2D extension of idea of the List.mapi function which lets f also see list position #:
      List.mapi [1;2;3] ~f:(fun index i -> index + i) is  [1; 3; 5] *)
  let mapxy (b : t) ~(f : int -> int -> char -> char) : t =
    List.mapi b ~f:(fun y r ->
        String.mapi r ~f:(fun x c -> if is_field c then f x y c else c))
end

let annotate (board : string list) =
  let count x y = Board.adjacents board x y |> List.count ~f:Board.is_mine in
  Board.mapxy board ~f:(fun x y _ -> count x y |> to_char)

