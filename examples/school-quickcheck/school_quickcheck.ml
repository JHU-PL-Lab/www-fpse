(*
  Quickcheck on a map using school example
*)
[@@@ocaml.warning "-32"]
[@@@ocaml.warning "-27"]

module IntMap = Map.Make(Int)

type t = string list IntMap.t

let empty : t = IntMap.empty

let add (grade : int) (stud : string) (school : t) : t =
   IntMap.add_to_list grade stud school

let sort (school : t) : t = 
  IntMap.fold (fun key data scl ->
      IntMap.add key (List.sort compare data) scl
    ) school
    empty

(** Auxiliary function to dump data structure *)
let dump (school : t) = school |> IntMap.to_list 

(** Auxiliary function to undump - make a map from the association list *)
let undump (assoc: (int * string list) list) : t = assoc |> List.to_seq |> IntMap.of_seq

let roster (school : t) = school |> sort |> dump


(* ******************************************************* *)

(* Quickchecking schools *)

(* First, lets generate a random school as an assoc list like the dump above produces *)

let school_gen = QCheck.Gen.list_small (QCheck.Gen.pair QCheck.Gen.int (QCheck.Gen.list QCheck.Gen.string_printable))

(* Test its working by making a random one *)
let _ = QCheck.Gen.generate ~n:1 school_gen

(* To write some tests need equality on schools (maps) DON'T use =, its wrong! *)
let school_equal s1 s2 = IntMap.equal (List.equal String.equal) s1 s2

(* A somewhat useless invariant to test: adding one entry always returns equal schools *)
let school_test1 = 
   QCheck.Test.make 
      ~count:3
      ~name:"school test 1"
      (QCheck.make school_gen)(* the builder for the list of integers *)
      (fun l -> (* the test gets a list l which we want to make a set from *)
         let school = undump l (* now we have an arbitrary school *) in
         school_equal (add 3 "Joey" school) (add 3 "Joey" school))

let _ = QCheck.Test.check_exn school_test1

(* TODO: make a test which uses `=` instead of school_equal which will be a bad test *)