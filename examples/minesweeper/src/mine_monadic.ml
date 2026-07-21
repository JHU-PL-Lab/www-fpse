(* Final effects encoding topic: a larger monad example
   
   Question to answer: how does this work in practice?
   Method: let's re-code the Minesweeper app we looked at earlier using a state monad.

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

(* Functions to functionally mutate lists and strings as arrays 
   These functions are no-ops if the range is out of bounds. *)
let list_set (l : 'a list) (i : int) (v : 'a) : 'a list =
  List.mapi (fun i' v' -> if i = i' then v else v') l
let string_set (s : string) (i : int) (c : char) : string =
  String.mapi (fun i' c' -> if i = i' then c else c') s
(* Get the nth char in a string.  Since it could be out of bounds need
  an option type for the result. *)
let string_get_opt (s : string) (i : int) : char option =
  try Some(s.[i]) with
    _ -> None
(* Lets make a clean list-nth function which returns None for any out of bounds access *) 
(* The List.nth_opt library function is flawed, it raises an exception if negative. *)
let list_nth_opt l n = 
  if n < 0 then None else List.nth_opt l n

(* 
  * Board is a state monad representing a mutable board 
  * The Board state is a list of strings like the functional version 
    - Not efficient, should be replaced with a map from (x,y) to chars.
*)

module Board = struct
  (* m is the underlying store/heap data structure for the board *)
  type m = string list
  (* The type t of the monad, a classic state monad here *)
  type 'a t = m -> 'a * m
  (* Bind here is a direct combination of option and state bind *)
  let bind (x : 'a t) (f: 'a -> 'b t) : 'b t =
     fun (s : 's) -> let (x', s') = x s in (f x') s'
  let return (x : 'a) : 'a t = fun (b : m) -> x, b
  (* inc increments the character at the x,y grid location 
      This code is not so pretty due to list-of-strings grid representation *)
  let inc  (x: int) (y: int) : unit t =
    let (let*) = Option.bind in (* pop into exception monad for a sec *)
    fun (b : m) ->
    let sopt = 
      let* s = list_nth_opt b y in
      let* c' = string_get_opt s x in
        Some(string_set s x (char_inc c'))
    in
    match sopt with
    | None ->  ((), b)
    | Some(s') -> ((),list_set b y s')
(* since get x y can fail return a char option *)
  let get (x: int) (y: int): (char option t) = 
    let (let*) = Option.bind in
    fun (b : m) -> 
    let vo = (let* row = List.nth_opt b y in
      string_get_opt row x)
    in (vo,b)

  let x_dim () : ('a t) = 
    fun (b : m) -> List.hd b |> String.length, b
  let y_dim () : ('a t) = 
    fun (b : m) -> List.length b, b
(* Dump the grid to iterate over it *)   
  let dump () : ('a t) = 
    fun (b : m) -> b, b
end

(* open the monad and define let* and >> syntactic sugar *)
open Board
let ( let* ) = bind
let ( >> ) m1 m2 = bind m1 (fun () -> m2) (* monad sequence (semicolon) sugar *)

(* Function in monad-land to increment nodes adjacent to x,y by one 
   Needs to be in monad-land because it "mutates" the board
*)
let inc_adjacents (x: int) (y: int) : unit t = 
  let s xo yo = inc (x + xo) (y + yo) in
  s (-1) (-1) >> s 0 (-1) >> s 1 (-1) >> s (-1) 0 >> s 1 0 >> s (-1) 1 >> s 0 1 >> s 1 1

(* Lets now do a classic "imperative" double-nested loop to increment all mine neigbors *)  
let inc_all () : 'a t =
  let* xmax = x_dim () in
  let* ymax = y_dim () in
  let rec do_inc (x : int) (y : int) : ('a t) = 
    let* c = get x y in
    match c with 
      | Some(c') -> 
        if is_mine c' then inc_adjacents x y else return ()
      | None -> return () 
    >> (* remember think ";" for ">>", it is sequencing effects *)
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

(* Auxiliary fold function which also knows the list position, like map_i *)
let list_fold_i (f:int -> 'a -> 'b -> 'a) (init:'a) (l : 'b list) : 'a =
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