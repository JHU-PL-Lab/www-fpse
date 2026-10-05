(*
  Quickcheck on a map using school example
*)

(* First, lets generate a random school as an assoc list like the School.dump produces *)
(* Q: Why use a different representation?  
   A: There is no built-in library function to generate arbitrary maps, only lists *)

open School

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

let _ = QCheck.Test.check_exn invariant1 (* this will immediately run this test *)

(* Define a better invariant: sorting an already-sorted school is a no-op *)
let invariant2 : QCheck2.Test.t = invariant1 (* replace `invariant1` with your test *)

(* Define a failing invariant: adding an entry twice is a no-op FAILS
   (there is no check for duplicates in the student name list) *)
let invariant3 : QCheck2.Test.t = invariant1 (* replace `invariant1` with your test *)

(* Now use QCheck_ounit to make a suite of these three invariants *)

let () =
  Printexc.record_backtrace true;
  let open OUnit2 in
  let qcheck_suite = "ounit suite of tests" >:::
     List.map QCheck_ounit.to_ounit2_test
       [ invariant1; invariant2; invariant2 ] in (* include all the tests we made above *)
  run_test_tt_main qcheck_suite (* recall this crashes top loop if you run this code there *)

(* Extra credit: make a test using `=` instead of school_equal which shows school_equal needed *)
