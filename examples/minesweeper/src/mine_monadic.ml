(* Final effects encoding topic: a larger monad example
   
   Question to answer: how does this work in practice?
   Method: let's re-code the Minesweeper app we looked at earlier using a state monad.

*)

(* 
  Monadic state Minesweeper

  * Uses the imperative method of incrementing all mine-adjacent cells by one.
    - as opposed to the functional approach of counting mines around each cell.

*)

let is_mine = Char.equal '*'
(* "increment" a character a la Minesweeper *)
let char_inc c = 
  if Char.equal c ' ' then '1' 
  else if Char.equal c '*' then c 
  else (Char.chr @@ (Char.code c + 1)) 

let list_split_n n xs =
  if n < 0 then invalid_arg "list_split_n";
  let rec aux acc n = function
    | xs when n = 0 ->
        (List.rev acc, xs)
    | [] ->
        failwith "list_split_n: index out of bounds"
    | x :: xs ->
        aux (x :: acc) (n - 1) xs
  in
  aux [] n xs

let list_set (l : 'a list) (i : int) (v : 'a) : 'a list option =
  let (b4,after) = list_split_n i l in 
  match after with 
  | [] -> None
  | _ :: tl -> Some(b4 @ [v] @ tl)
let string_set (s : string) (i : int) (c : char) : string =
  String.mapi (fun i' c' -> if i = i' then c else c') s
let string_nget_opt (s : string) (i : int) : char option =
  try Some(s.[i]) with
    _ -> None

(* 
  * Board is a state/exceptions monad representing a mutable board 
  * The Board state is a list of strings like the functional version 
    - Not efficient, should be replaced with a map from (x,y) to chars.
*)

module Board = struct
  (* m is the underlying store/heap data structure for the board *)
  type m = string list
  (* The type t of the monad
      This is an option monad inside a state monad
      The option is needed for operations outside of the grid coordinates *)
  type 'a t = m -> ('a option) * m
  (* Bind here is a direct combination of option and state bind *)
  let bind (x : 'a t) (f: 'a -> 'b t) : 'b t =
    fun (b : m) -> 
    match x b with 
    | (Some(x'),b') -> f x' b' 
    | (None,b') -> (None,b')
  let return (x : 'a) : 'a t = fun (b : m) -> (Some(x), b)
  let map = `Define_using_bind
  (* inc increments the character at the x,y grid location 
      This code is not pretty due to list-of-strings grid representation *)
  let inc  (x: int) (y: int) : unit t =
    fun (b : m) ->
    let sopt = 
      match List.nth_opt b y with
      | None -> None
      | Some(s) -> match string_nget_opt s x with
        | None -> None
        | Some(c') -> Some(string_set s x (char_inc c'))
    in
    match sopt with
    | None ->  (Some(), b)
    | Some(s') ->
      match (list_set b y s') with 
      | None -> (Some(),b)
      | Some(b') -> (Some(),b')

  let get (x: int) (y: int): char t = 
    let (let*) = Option.bind in
    fun (b : m) -> 
    let vo = (let* row = List.nth_opt b y in
      try Some(String.get row x) with _ -> None)
    in (vo,b)
  let x_dim () : ('a t) = 
    fun (b : m) -> (Some(List.hd b |> String.length),b)
  let y_dim () : ('a t) = 
    fun (b : m) -> (Some(List.length b), b)
  (* Monad users may need the whole grid to iterate over it *)   
  let dump () : ('a t) = 
    fun (b : m) -> (Some(b), b)
end

(* open the monad and define its syntax *)
open Board
let ( let* ) = bind
let ( >>= ) = bind
let ( >>| ) m f = bind m (fun x -> return (f x))

(* Function in monad-land to increment nodes adjacent to x,y by one 
   Needs to be in monad-land because it "mutates" the board
*)
let inc_adjacents (x: int) (y: int) : unit t = 
  let s xo yo = let* () = inc (x + xo) (y + yo) in return () in
  let* () = s (-1) (-1) in 
  let* () = s 0 (-1) in
  let* () = s 1 (-1) in
  let* () = s (-1) 0 in
  let* () = s 1 0 in
  let* () = s (-1) 1 in
  let* () = s 0 1 in  s 1 1


(* Lets now do a classic "imperative" double-nested loop to increment all mine neigbors *)  
let inc_all () : 'a t =
  let* xmax = x_dim () in
  let* ymax = y_dim () in
  let rec do_inc (x : int) (y : int) : ('a t) = 
    let* c = get x y in
    let* () = if is_mine c then inc_adjacents x y else return () in
    if x + 1 = xmax then
      if y + 1 = ymax then return ()
      else do_inc 0 (y + 1)
    else do_inc (x + 1) y 
  in
  do_inc 0 0


let annotate (b : m) =
    let (_,b') = inc_all () b in b'


(* Sample test board *)
let b = [
        "  *  ";
        "  *  ";
        "*****";
        "  *  ";
        "  *  ";
      ]

let _ = annotate b
    
(* Alternative: use folding to do the iteration.
   * Need to define monadic versions of list_iter_i to iterate an effectful function over the grid which will thread along the state.
   * You can't just map the function over the list, you need to make a chain of binds to propagate effects
   * It ends up being complicated, the above traditional imperative approach arguably reads better  *)

let list_fold_i f init l =
  snd
    (List.fold_left
       (fun (i, acc) x ->
         (i + 1, f i acc x))
       (0, init)
       l)   
let list_iteri (l : string list) (f: int -> string -> unit t) : unit t =
  list_fold_i (fun i acc a -> bind acc (fun () -> f i a)) (return ()) l    
let string_iteri (s : string) (f: int -> char -> unit t) : unit t =
  list_fold_i (fun i acc a -> bind acc (fun () -> f i a)) (return ()) (List.of_seq @@ String.to_seq s) 
(* iterji iterates over the whole grid applying effectful function f *)
let iterji (f : int -> int -> char -> 'a t) =
  let* b = dump () in
  list_iteri b (fun y -> fun s -> string_iteri s (f y))

(* With the above setup the main function is easy: call inc_adjacents on all mines *)
let inc_all' () : 'a t =
  iterji (fun y x c -> if is_mine c then inc_adjacents x y else return ())

let _ = inc_all' () b

let annotate' (b : m) =
    let (_,b') = inc_all' () b in b'

let _ = annotate' b

(* Complexity analysis of this for grid of n elements (a square-root n by square-root n grid)
   
   - Each inc will take O(n) since the whole grid has to be rebuilt with one change
   - O(n) inc's are performed total so it will be O(n^2).

  Alternative monad implementation as a Core.Map from keys (i,j):
    - lookup and increment will be O(log n) since Core.Map is implemented as a balanced tree
    - one change to a Map is only log n because only one path in tree is changed, rest re-used
    - so total time is O(n log n)

  Regular imperative implementation using a 2D array: O(n)
    - O(1) for each inc operation

  (Note that for this application even n^2 is fine, but similar algorithms may have much much larger grids)
  
*)

(* Morals about encoding effects with monads

 1. It is very cool that you can create an "effectful sublanguage" within a pure functional language
 2. It has both advantages 
     - highly local use of only the effects you need (as we saw in the example above)
     - referential transparency preserved for the functional code
     - For some algorithms the functional data structures will be better
        -- e.g. in Nondeterminism plus State, can share parts of Maps between nondeterministic computations
        -- no sharing is possible with imperative maps
    And disadvantages
     - Hard conceptually to keep your head on the right "layer"
     - Tends to bloat the code due to various crufty corner cases as we saw in the above example
     - Sacrifice in efficiency due to underlying immutable data structures
*)