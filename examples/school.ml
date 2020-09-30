(* An example use of Core.Map; somewhat solves 
  https://github.com/exercism/ocaml/tree/master/exercises/grade-school *)

open Core

(* The Make functor in the Map module specializes maps to Ints in this case *)

module IntMap = Map.Make(Int)

(* The Int here is the **keys** of the map (the grade here); we need to use a functor because 
  we need an underling compare function for maps to work.  Built-in Core.Int has such. 
   
Here is the module type of Make's argument:

module type Key =
  sig
    type t
    val compare : t -> t -> int
    val t_of_sexp : Sexp.t -> t
    val sexp_of_t : t -> Sexp.t
  end
  
  So Int needs to have the underlying type t (= int here), compare, plus to-from s-expression 
  functions.

  *)

(* We are defining the School module; let us follow convention and name 
  "its" underlying data type t.  
  Note that IntMap has one type parameter which is the map's range
   -- string list for a School *)
type t = (string list) IntMap.t

(* The empty school *)

let empty = IntMap.empty

(**  Add a student stud in grade grade to school database 
     Map.add_multi assumes values are lists and conses to key's list
     or, creates a new key and singleton list if key not present. **)
let add grade stud (school : t) =  IntMap.add_multi school ~key:grade ~data:(stud)

(** 
  Sorting using a fold over the map.
  Folding over a map is like folding over a list but you get both key and value
**)
let sort (school : t) = 
  IntMap.fold school
    ~init:empty 
    ~f:(fun ~key -> fun ~data -> fun scl -> IntMap.add_exn scl ~key ~data:(List.sort data ~compare:(String.compare) ))

(** Note that Map.map is a better way; it maps over the values only, keeping key structure intact **)
let sort_better_with_map (school : t) = 
  IntMap.map school
    ~f:(fun data -> (List.sort data ~compare:(String.compare) ))

let roster school = school |> sort |> IntMap.data |> List.concat

let dump school = school |> IntMap.to_alist (* Auxiliary function to dump data structure *)

let test_school = empty |> add 2 "Ku" |> add 3 "Lu" |> add 9 "Mu" |> add 9 "Pupu"  |> add 9 "Apu"