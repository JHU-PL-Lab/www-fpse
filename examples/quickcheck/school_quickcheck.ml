(*
  Quickcheck on a map using school example
*)
[@@@ocaml.warning "-32"]
[@@@ocaml.warning "-27"]

open Core

type t = (int, string list, Int.comparator_witness) Map.t

(*   
  Informal shape of a School.t map: 
    { 1 |-> ["Bob"; "Sue"]
    , 3 |-> ["Yohan"; "Idris"] }
*)

(* The empty school *)
let empty : t = Map.empty (module Int)

(*
  From now on we need to use Map.add etc directly and not IntMap.add etc
    - the empty map has in its type the type of keys and how to compare them,
     and we build all the maps from that.
*)

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


(* ******************************************************* *)

(* Quickchecking schools *)

(* First, lets generate a random school; need key module and key/val gens *)
let school_gen = Map.quickcheck_generator (module Int) Int.quickcheck_generator (List.quickcheck_generator String.quickcheck_generator)

(* Test its working by showing a random one *)
let rand_from (g : 'a Base_quickcheck.Generator.t) = (Quickcheck.random_value ~seed:`Nondeterministic g)

let _ = rand_from school_gen |> Map.to_alist

(* To write some tests need equality on schools (maps) *)
let school_equal s1 s2 = assert (Map.equal (List.equal String.equal) s1 s2)

(* A somewhat useless invariant: adding one entry always returns same thing *)
let invariant1 s = school_equal (add 3 "Joey" s) (add 3 "Joey" s)
let school_test1 () =
  Quickcheck.test school_gen ~f:invariant1

(* Define a better invariant: sorting an already-sorted school is a no-op *)
let invariant2 s = failwith "unimplemented"
let school_test2 () =
  Quickcheck.test school_gen ~f:invariant2

(* Define a bad invariant: adding an entry twice is a no-op FAILS
   (there is no check for duplicates in the student name list) *)
let invariant3 s = failwith "unimplemented"
let school_test3 () =
  Quickcheck.test school_gen ~f:invariant3
