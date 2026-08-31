type t = string list (* This is a *type abbreviation*: a string set is a list of strings *)

let empty : t = [] (* the one canonical empty set *)

let add (x : string) (s : t) : t = x :: s

let rec remove (x : string) (s : t) : t =
  match s with
  | [] -> failwith "item is not in set"
  | hd :: tl ->
    if hd = x then
      tl (* we don't remove from the tail: this is actually a multiset *)
    else
      hd :: remove x tl

let rec contains (x : string) (s : t) : bool =
  match s with
  | [] -> false
  | hd :: tl ->
    if hd = x then
      true
    else
      contains x tl

# String_set.add "hello" String_set.empty ;;
- : String_set.t = ["hello"]

# open String_set ;;
# add "hello" empty ;;
- : t = ["hello"]

type t = string list
(* type t (* this alternate version of type t declaration *hides* t's internals *) *)
val empty : t
val add : string -> t -> t
val remove : string -> t -> t
val contains : string -> t -> bool

# String_set.add "hello" String_set.empty ;;
- : String_set.t = <abstr>

(* Just a helper function. Does not run until it's given arguments in `let () = ...` *)
let do_search search_string filename =
  let lines = In_channel.with_open_bin filename In_channel.input_lines in
  let my_set =
    List.fold_left (fun set elt -> String_set.add elt set) String_set.empty lines
  in
  if String_set.contains search_string my_set then
    print_string @@ "\"" ^ search_string ^ "\" found\n"
  else
    print_string @@ "\"" ^ search_string ^ "\" not found\n"

(* This statement has some printing side effects that we observe when running the executable *)
let () =
  match Array.to_list Sys.argv with
  | _ :: search_string :: filename :: _ -> do_search search_string filename
  | _ -> failwith "Invalid arguments: requires two parameters, search string and file name"

module A = struct
  type t = { x : int ; y : bool }
end

let ra = A.{ x = 0 ; y = true } (* Need to write `A.` here to make the type `A.t` visible *)

module B = struct
  type t = { x : int ; z : float }
end

let rb = B.{ x = 0 ; z = 1.1 }

open A
open B

let f r = r.x (* type inferred for r is B.t, just like with newratio from the records lecture *)

(* A type annotation will disambiguate: *)
let f (r : A.t) : int = r.x

let f' r = r.A.x (* this works too )

