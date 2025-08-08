(* strinG-set.ml
   Defines the module String_set which is a simple functional set data structure on strings.
*)

open Core

(* This type declaration is the data structure storing the actual sets (just a list here)
   Note how we call the type just "t", that is because the full name will be String_set.t
   -- "string set's type" is how you can read this *)

type t = string list

let empty : t = []

let add (x : string) (s : t) : t = x :: s

let rec remove (x : string) (s : t) : t =
  match s with
  | [] -> failwith "item is not in set"
  | hd :: tl ->
    if String.equal hd x
    then tl
    else hd :: remove x tl

let rec contains (x : string) (s : t) : bool =
  match s with
  | [] -> false
  | hd :: tl ->
    if String.equal x hd 
    then true 
    else contains x tl
