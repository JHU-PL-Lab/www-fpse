(*
  An example use of Map; somewhat solves
  https://github.com/exercism/ocaml/tree/master/exercises/grade-school
*)

(*
  The Make functor in the Map module specializes maps to Ints in this case
  See https://ocaml.org/manual/5.5/api/Map.S.html for the Map module API.
*)

module Grade = struct
  type t = { grade : int }
  let compare a b = Int.compare a.grade b.grade
end

module Grade_map = Map.Make (Grade)

(*
  The Grade here is the **keys** of the map; we need to use a functor because we
  need an underling compare function for maps to work.

  Here is the module type of Make's argument, the OrderedType module type:

      #show Map.OrderedType;;
      module type OrderedType = sig type t val compare : t -> t -> int end

  So Grade needs to have the underlying type t and compare.
*)

(*
  We are defining the School module as this file; let us follow convention and
  name "its" underlying data type t.
  Note that Grade_map has one type parameter which is the type of the map's
  value data -- string list for a School.
  (The functor only needs the key type since compare is not needed on values,
  so the type of values is parametric.)
*)
type t = (string list) Grade_map.t

(*
  Informal shape of a School.t map:
    { 1 |-> ["Bob"; "Sue"]
    , 3 |-> ["Yohan"; "Idris"] }
*)

(* The empty school *)
let empty : t = Grade_map.empty

(**
  Add a student [stud] in grade [grade] to [school] database.
  [Map.add_to_list] assumes values are lists and conses to key's associated list
  or, if the key is not present, it creates a new key and singleton list.
*)
let add (grade : Grade.t) (stud : string) (school : t) : t =
  Grade_map.add_to_list grade stud school

(**
  Sorting using a fold over the map.
  [sort] below will alphabetically sort the students in each grade. Folding
  over a map is like folding over a list but the folding function uses both key
  and value.
*)
let sort (school : t) : t =
  Grade_map.fold (fun key data scl ->
    Grade_map.add key (List.sort String.compare data) scl
  ) school empty

(**
  Note that [Grade_map.map] is a better way; it maps over the values only,
  keeping the key structure intact.
*)
let sort_better_with_map (school : t) : t =
  Grade_map.map (fun data -> List.sort String.compare data) school

(** Auxiliary function to dump data structure *)
let dump (school : t) = school |> Grade_map.to_list

let roster (school : t) = school |> sort |> dump

(** Simple test *)
let test_school =
  empty
  |> add { grade = 2 } "Ku"
  |> add { grade = 3 } "Lu"
  |> add { grade = 9 } "Mu"
  |> add { grade = 9 } "Pupu"
  |> add { grade = 9 } "Apu"
