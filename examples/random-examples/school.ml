(* An example use of Core.Map; somewhat solves 
  https://github.com/exercism/ocaml/tree/master/exercises/grade-school *)

open Core

(* The Make functor in the Map module specializes maps to Ints in this case 
   See https://ocaml.janestreet.com/ocaml-core/latest/doc/core_kernel/Core_kernel/Map/index.html for the Map module API.  *)

module IntMap = Map.Make(Int)

(* The Int here is the **keys** of the map (the grade here); we need to use a functor because 
  we need an underling compare function for maps to work.  Built-in Core.Int has such. 
   
Here is the module type of Make's argument, the Key module type:

# #show Core.Map_intf.Key;;
module type Key =
  sig
    type t
    val compare : t -> t -> int
    val t_of_sexp : Sexp.t -> t
    val sexp_of_t : t -> Sexp.t
  end
  
  So Int needs to have the underlying type t (= int here), compare, plus to-from s-expression 
  functions. Fortunately, it does.

  *)

(* We are defining the School module as this file; let us follow convention and name 
  "its" underlying data type t.  
  Note that IntMap has one type parameter which is the map's value data
   -- string list for a School 
  (The functor only needs the key type since compare is not needed on values)
*)
type t = (string list) IntMap.t

(*   Informal shape of a School.t map: 
  { 1 |-> ["Bob"; "Sue"], 3 |-> ["Yohan"; "Idris"]}
*)

(* The empty school *)
let empty : t = IntMap.empty

(* From now on we need to use Map.add etc directly and not IntMap.add etc
    - the empty map has in its type the type of map and we build all the maps from that *)

(**  Add a student stud in grade grade to school database 
     Map.add_multi assumes values are lists and conses to key's list
     or, creates a new key and singleton list if key not present. **)
let add (grade : int) (stud : string) (school : t) : t =  Map.add_multi school ~key:grade ~data:stud

(** 
  Sorting using a fold over the map.
  `sort` below will alphabetically sort the students in each grade.
  Folding over a map is like folding over a list but you get both key and value
*)
let sort (school : t) : t = 
  Map.fold school
    ~init:empty 
    ~f:(fun ~key ~data scl -> Map.add_exn scl ~key ~data:(List.sort data ~compare:String.compare))

(** Note that Map.map is a better way; it maps over the values only, keeping key structure intact *)
let sort_better_with_map (school : t) : t = 
  Map.map school
    ~f:(fun data -> (List.sort data ~compare:String.compare))

let roster (school : t) = school |> sort |> Map.data |> List.concat
(** Auxiliary function to dump data structure *)
let dump (school : t) = school |> Map.to_alist 
(*** Simple test *)
let test_school = empty |> add 2 "Ku" |> add 3 "Lu" |> add 9 "Mu" |> add 9 "Pupu"  |> add 9 "Apu"