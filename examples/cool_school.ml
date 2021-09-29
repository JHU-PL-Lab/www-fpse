(* Version of School module using first-class modules
  Again roughly based on 
  https://github.com/exercism/ocaml/tree/master/exercises/grade-school *)

open Core


(* Map.t has three type parameters: key type, value type, 
   and a nonce (witness) for the comparison function used for the key.
   Here we use key = int, value = string list.
   More on comparator_witness later; it is defined for all built-in types *)

type t = (int, string list, Int.comparator_witness) Map.t

let (empty : t) = Map.empty(module Int) (* new syntax: first-class module Int *)

(* ***************************************************** *)
(* Everything from here on down is the same as school.ml *)
(* but using Map.add etc instead of IntMap.add etc       *)
(* ***************************************************** *)



(**  Add a student stud in grade grade to school database 
     Map.add_multi assumes values are lists and conses to key's list
     or, creates a new key and singleton list if key not present. **)
let add grade stud (school : t) =  Map.add_multi school ~key:grade ~data:stud

(** 
  Sorting using a fold over the map.
  Folding over a map is like folding over a list but you get both key and value
**)
let sort (school : t) : t = 
  Map.fold school
    ~init:empty 
    ~f:(fun ~key -> fun ~data -> fun scl -> Map.add_exn scl ~key ~data:(List.sort data ~compare:(String.compare) ))

(** Note that Map.map is a better way; it maps over the values only, keeping key structure intact **)
let sort_better_with_map (school : t) : t = 
  Map.map school
    ~f:(fun data -> (List.sort data ~compare:(String.compare) ))

let roster (school : t) = school |> sort |> Map.data |> List.concat

let dump (school : t) = school |> Map.to_alist

let test = empty |> add 2 "Ku" |> add 3 "Lu" |> add 9 "Mu" |> add 9 "Pupu"