(* Version of School module using first-class modules
  Again roughly based on 
  https://github.com/exercism/ocaml/tree/master/exercises/grade-school *)

open Core


(* 
  Map.t has three type parameters: key type, value type, 
  and a nonce (witness) for the comparison function used for the key.
  Here we use key = int, value = string list.
  More on comparator_witness later; it is defined for all built-in types.
*)

type t = (int, string list, Int.comparator_witness) Map.t

let empty : t = Map.empty (module Int) (* new syntax: first-class module Int *)

(* ***************************************************** *)
(* Everything from here on down is the same as school.ml *)
(* ***************************************************** *)

(** 
  Add a student [stud] in grade [grade] to [school] database.
  [Map.add_multi] assumes values are lists and conses to key's
  associated list or, if the key is not present, it creates a
  new key and singleton list.
*)
let add (grade : int) (stud : string) (school : t) : t =
  Map.add_multi school ~key:grade ~data:stud

(** 
  Sorting using a fold over the map.
  [sort] below will alphabetically sort the students in each grade.
  Folding over a map is like folding over a list but the folding
  function uses both key and value.
*)
let sort (school : t) : t = 
  Map.fold school
    ~init:empty
    ~f:(fun ~key ~data scl ->
      Map.add_exn scl ~key ~data:(List.sort data ~compare:String.compare)
    )

(**
  Note that [Map.map] is a better way; it maps over the values only,
  keeping the key structure intact.
*)
let sort_better_with_map (school : t) : t = 
  Map.map school ~f:(fun data ->
    List.sort data ~compare:String.compare
  )

let roster (school : t) = school |> sort |> Map.data |> List.concat

(** Auxiliary function to dump data structure *)
let dump (school : t) = school |> Map.to_alist 

(*** Simple test *)
let test_school = empty |> add 2 "Ku" |> add 3 "Lu" |> add 9 "Mu" |> add 9 "Pupu"  |> add 9 "Apu"
