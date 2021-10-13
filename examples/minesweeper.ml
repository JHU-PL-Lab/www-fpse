(* Directly from
   https://exercism.io/tracks/ocaml/exercises/minesweeper/solutions/ace26e2f446a4a18a3b1bad83dd9487c  

  With explanatory comments added by SFS.

   *)

open Base

let to_char = function
  | -1 -> '*'
  | 1  -> '1'
  | 2  -> '2'
  | 3  -> '3'
  | 4  -> '4'
  | 5  -> '5'
  | 6  -> '6'
  | 7  -> '7'
  | 8  -> '8' 
  | _  -> ' '

module Board = struct
  type t = string list  (* board data; see test/test.ml for examples *)

(* get the (x,y) character on board b.
   Uses several functions in Option to properly deal with exceptional cases *)  

  let get_boom (b: t) (x: int) (y: int): char  = 
    List.nth_exn b y |> (fun row -> String.get row x);;

  let get (b: t) (x: int) (y: int): char option = 
    List.nth b y |>
    Option.value_map ~default:None ~f:(fun row -> Option.try_with (fun () -> String.get row x))

  let get' (b: t) (x: int) (y: int): char option = 
    Option.bind (List.nth b y) 
    ~f:(fun row -> Option.return(String.get row x))

(* The above might raise an exception in String.get so return 
   is in fact not what is needed here
   -- use Option.try_with as above to turn exception to `None`:
 *)    
  let get'' (b: t) (x: int) (y: int): char option = 
    Option.bind (List.nth b y) 
    ~f:(fun row -> Option.try_with(fun () -> String.get row x))

(* Shorthand pipe-like notation >>= ; need to open Option to enable *)

let get''' (b: t) (x: int) (y: int): char option = 
    Option.((List.nth b y) 
    >>= (fun row -> try_with(fun () -> String.get row x)))

(* Another notation where you don't need to make the fun;
   instead use let%bind to bind the `row` here. 
   Note that VSCode is not aware of let%bind macro
   and also you need to #require and/or preprocess ppx_let *)
let get'''' (b: t) (x: int) (y: int): char option = 
let open Option in let open Option.Let_syntax in
let%bind row = List.nth b y in try_with(fun () -> String.get row x)

  let adjacents (b: t) (x: int) (y: int): char list = 
    let g xo yo = get b (x + xo) (y + yo) in
    List.filter_map ~f:Fn.id [
      g (-1) (-1);  g 0 (-1);  g 1 (-1);
      g (-1) 0   ;             g 1 0   ;
      g (-1) 1   ;  g 0 1   ;  g 1 1   ; 
    ]

  let is_mine = Char.equal '*'
  let is_field = Fn.non is_mine
  let is_field' c = not @@ is_mine c

  let map_field (b: t) ~(f: int -> int -> char -> char): t =
    List.mapi b ~f:(fun y r -> String.mapi r ~f:(fun x c -> if is_field c then f x y c else c)) 
end

let annotate (board: string list) = 
  let count x y = Board.adjacents board x y |> List.count ~f:(Board.is_mine) in
  Board.map_field board ~f:(fun x y _ -> count x y |> to_char)