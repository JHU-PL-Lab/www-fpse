(*
  Quickcheck on a map using simplified school example
  - to make the quickchecking a bit easier to read we let the keys (grades) be just integers here
  - recall in the previous run of this example we used `{grade = 5}` for grades.
*)

[@@@ocaml.warning "-32-27"]

module Grade = struct
  type t = { grade : int }
  let compare a b = Int.compare a.grade b.grade
end

module Grade_map = Map.Make (Grade)

(*
  The Grade here is the **keys** of the map; we need to use a functor because we
  need an underling compare function for maps to work.

  Here is the module type of Map.Make's argument, the OrderedType module type:

      #show Map.OrderedType;;
      module type OrderedType = sig type t val compare : t -> t -> int end

  So Grade needs to have the underlying type t and compare. It does.
*)

(*
  We are defining the School module as this file; let us follow convention and
  name "its" underlying data type t.
  Note that Grade_map has one type parameter which is the type of the map's
  value data: string list for a School, the roster of students in that grade.
  (The functor only needs the key type since compare is not needed on values,
  so the type of values is parametric.)
*)
type t = (string list) Grade_map.t

(*
  Informal shape of a School.t map:
    { grade:1 |-> ["Bob"; "Sue"]
    , grade:3 |-> ["Yohan"; "Idris"] }
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
  Sort the school by alphabetically sorting the students within each grade.
  We map each grade to the sorted grade.
*)
let sort (school : t) : t =
  Grade_map.map (fun roster -> List.sort String.compare roster) school

(**
  Sorting using a fold over the map.
  This will alphabetically sort the students in each grade. Folding over a map
  is like folding over a list but the folding function uses both key and value.
*)
let sort_with_fold (school : t) : t =
  Grade_map.fold (fun key data scl ->
    Grade_map.add key (List.sort String.compare data) scl
  ) school empty

(** Auxiliary function to dump data structure *)
let dump (school : t) = school |> Grade_map.to_list

(* Also need the inverse for making our quickcheck tests *)
let undump (assoc: (int * string list) list) : t = 
  assoc 
  |> List.map (fun (i,sl) -> { Grade.grade = i }, sl) 
  |> List.to_seq 
  |> Grade_map.of_seq 

let all (school : t) = school |> sort |> dump

(** Simple test *)
let test_school =
  empty
  |> add { grade = 2 } "Ku"
  |> add { grade = 3 } "Lu"
  |> add { grade = 9 } "Mu"
  |> add { grade = 9 } "Pupu"
  |> add { grade = 9 } "Apu"
  |> dump

(* ******************************************************* *)

(* Quickchecking schools *)

(* First, lets generate a random school as an assoc list like the dump above produces *)
(* Q: Why use a different representation?  
   A: There is no built-in library function to generate arbitrary maps, only lists *)

let school_gen = QCheck.Gen.list_small (QCheck.Gen.pair QCheck.Gen.int (QCheck.Gen.list QCheck.Gen.string_printable))

(* Test its working by making a random one *)
let _ = QCheck.Gen.generate ~n:1 school_gen

(* To write some tests need equality on schools (maps) DON'T use =, its wrong! *)
let school_equal (s1 : t) (s2 : t) = Grade_map.equal (List.equal String.equal) s1 s2

(* A somewhat useless invariant to test: adding one entry always returns equal schools *)
let invariant1 : QCheck2.Test.t = 
   QCheck.Test.make 
      ~count:3
      ~name:"school test 1"
      (QCheck.make school_gen) (* the builder for the list of integers *)
      (fun l -> (* the test gets a list l which we want to make a school from *)
         let school = undump l (* now we have an arbitrary school *) in
         school_equal (add { grade = 3 } "Joey" school) (add { grade = 3 } "Joey" school))

let _ = QCheck.Test.check_exn invariant1

(* Define a better invariant: sorting an already-sorted school is a no-op *)
let invariant2 : QCheck2.Test.t = invariant1 (* replace `invariant1` with your test *)
let _ = QCheck.Test.check_exn invariant2

(* Define a failing invariant: adding an entry twice is a no-op FAILS
   (there is no check for duplicates in the student name list) *)
let invariant3 : QCheck2.Test.t = invariant1 (* replace `invariant1` with your test *)
let _ = QCheck.Test.check_exn invariant3

(* Extra credit: make a test using `=` instead of school_equal which shows school_equal needed *)
