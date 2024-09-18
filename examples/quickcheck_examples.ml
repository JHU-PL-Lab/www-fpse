(* Base_quickcheck Examples
   Requires:
   (libraries core)
   (preprocess (pps ppx_jane))
   in dune file
   And #require "ppx_jane" in top-loop
*)

(* `Base_quickcheck` is highly integrated with Core libraries which is why we use it *)

[@@@warning "-32"]

open Core

(* Step 1 is you need a generator to make random data in a given type. *)
(* For all the built-in types, Core provides <Builtin_type>.quickcheck_generator, a default generator *)
(* which will generate random integers based on arguments passed *)
let int_gen = Int.quickcheck_generator
let rand_int = (Quickcheck.random_value ~seed:`Nondeterministic int_gen)

(* `Int.gen_incl` generates ints in a range *)  

let int_gen' = Int.gen_incl (-100) 100
let rand_int' =  (Quickcheck.random_value ~seed:`Nondeterministic int_gen')

(* Note that the ~seed argument is optional; if you leave it out you get the same answer each time
   This is often useful to get repeatable results from test runs
   If it is used, also use Quickcheck.random_sequence to make an unbounded list of such values 
   -- otherwise you will get the same value every time. *)

(* A little function to test out various generators: given a generator returns a random value *)
let rand_from (g : 'a Base_quickcheck.Generator.t) = (Quickcheck.random_value ~seed:`Nondeterministic g)

(* Parameterized type generators need a generator for the parameter 
   Similar to how `List.equal` needs an `equal` on list contents *)
let int_list_gen = List.quickcheck_generator Int.quickcheck_generator

(* One random list *)
let rand_list = rand_from int_list_gen

(* Shorthand ppx notation *)
let int_list_gen' = [%quickcheck.generator: int list]

(* Lists with a narrower range of integers *)
let int_list_gen'' = List.quickcheck_generator int_gen'

(* Can compose two generators to generate a pair via Quickcheck.Generator.both *)
let rand_list_pair = rand_from (Quickcheck.Generator.both int_list_gen int_list_gen)

(* **************************************** *)
(* Using generators to repeatedly test code *)
(* **************************************** *)

(* We could just directly use the above code to make some number of random test cases and then run them *)
(* But, Quickcheck has some helper functions to make that easier and with lots of extra arguments possible *)

(* IMPORTANT POINT: we always need to know the "correct" answer for the test and that limits what can be tested *)
(* So, primarily used to validate invariants or to make sure no exceptions are raised *)

(* Simple failure example from Real World OCaml *)
(* Quickcheck.test will run the ~f function on 10000 different random data items by default *)
let invariant x = assert(Sign.equal (Int.sign (Int.neg x)) (Sign.flip (Int.sign x)))

let testcode () =
  Quickcheck.test ~sexp_of:[%sexp_of: int] (* optional sexp_of needed to see failure case if any *)
    (Int.gen_incl Int.min_value Int.max_value) ~f:invariant

let informal_test = testcode ()

(* To add to a suite we need to embed in OUnit. First change assert in invariant to OUnit version *)

let ounit_invariant x = OUnit2.assert_bool "" (Sign.equal (Int.sign (Int.neg x)) (Sign.flip (Int.sign x)))

(* Make a quickcheck runner for this invariant *)
let quick_test () = Quickcheck.test ~sexp_of:[%sexp_of: int]
           (Int.gen_incl Int.min_value Int.max_value) ~f:ounit_invariant

(* Here it is packaged as an OUnit.test we can run *)
let ounit_test = OUnit2.("sign test" >:: fun _ -> quick_test ())

let _ = OUnit2.run_test_tt_main ounit_test (* run our OUnit.test in the top loop *)

(* List Reverse Example *)


(* Check to see if (reverse o reverse) is identity on all lists using int_list_gen above *)    
let check_a_list_rev (revver : int list -> int list) = 
  Quickcheck.test ~sexp_of:[%sexp_of: int list]
    int_list_gen
    ~f:(fun l -> assert(List.equal Int.equal (revver (revver l)) l))

(* The following contains no failures - silence means success *)
let () = check_a_list_rev List.rev

(* Making a bad version of reverse *)

let bad_rev l = match l with 1::_ -> [] | _ -> List.rev l

let () = check_a_list_rev bad_rev

(* Generators for your own types 
   Fortunately Quickcheck has an easy ppx to do this, analogous to `@@deriving equal`.  *)

type complex = CZero | Nonzero of float * float [@@deriving quickcheck]

let compl = rand_from quickcheck_generator_complex

type int_tree = 
  | Leaf
  | Node of int * int_tree * int_tree [@@deriving quickcheck]

let atree = rand_from quickcheck_generator_int_tree

(* Parametric types work as well; as with lists above you need to supply a generator for the 'a *)

type 'a bin_tree = Leaf | Node of 'a * 'a bin_tree * 'a bin_tree [@@deriving quickcheck]

let atree = rand_from @@ quickcheck_generator_bin_tree int_gen';;

(* Also Core has Map.quickcheck_generator, etc etc *)

(* In general you can write your own generators if you want a unique distribution
   But, the happy path is to use the built-in ones as above to make things worth the effort *)