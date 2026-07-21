(* QCheck Examples
   Requires:
   (libraries qcheck) 
   (preprocess (pps ppx_deriving_qcheck))
   in dune file
*)

[@@@ocaml.warning "-32"]

(* Step 1 is you need a generator to make random data in a given type. *)
(* For all the built-in types, QCheck provides QCheck.Gen.<Builtin_type>, a default generator *)
(* Here we will generate random integers *)

let int_gen : int QCheck.Gen.t = QCheck.Gen.int

(* to do the raw generation of say a list of 10 values you can then do *)

let _ = QCheck.Gen.generate ~n:10 int_gen

(* This generator makes mostly hugely positive and negative numbers since its
   just making random bits.  In practice we usually want integers in a range. 
   Here is non-negative integers up to a fixed bound. *)

let _ = QCheck.Gen.generate ~n:10 (QCheck.Gen.int_bound 1000) 

(* Notice that each time we run this it makes new random numbers.  One
   downside of this is if you make the same random data each time you can
   repeat the running of the tests on the same data.  To fix the data 
   use the ~rand: optional paramater: *)

let _ = QCheck.Gen.generate ~n:10 ~rand:(Random.State.make [| 0 |]) (QCheck.Gen.int_bound 1000)

(* the `Random.State.make [| 0 |]` is an array of integers which is the initial seed *)    

(* to make a generator that we can plug into their test harness we take int_gen and wrap it
   up as a *builder*. Builders also can do things besides raw data generation *)

let int_builder : int QCheck.arbitrary = QCheck.make int_gen
let int_builder : int QCheck.arbitrary = QCheck.int (* convenient shorthand for previous *)

(* Observe 
   * Generators for values of some type <type> have types <type> QCheck.Gen.t 
   * Builders for values of some type <type> have types <type> QCheck.arbitrary *)

(* Here is how to make a test harness to generate a whole bunch of random values and run a test on it *)
let range_test = 
   QCheck.Test.make 
      ~count:10 (* number of tests to make *)
      ~name:"every integer is less than max_int - 100000000000000000" (* optional name *)
      QCheck.int (* the builder for the data, lets use the shorthand *)
      (fun n -> (Printf.printf "DEBUG: test data received, %i\n" n);
       n < (Int.max_int -100000000000000000)) (* the actual test: will feed 10 random integers in for n *)
   ;;

let _ = QCheck.Test.check_exn range_test

(* The generator here is rather stupid, it should test max/min and small values
   more frequently. *)

(* Parameterized type generators need a generator for the parameter 
   Similar to how `List.equal` needs an `equal` on list contents *)

let int_list_gen : (int list) QCheck.Gen.t = QCheck.Gen.list QCheck.Gen.int_pos_small

(* Lets check out a few generated lists *)

let _ = QCheck.Gen.generate ~n:10 int_list_gen

(* For the builder its the same deal as above, and parallel shorthand taking int builder: *)
let int_list_builder : int list QCheck.arbitrary = QCheck.make (int_list_gen)
let int_list_builder : int list QCheck.arbitrary = QCheck.(list int_pos_small)

let list_test =
  QCheck.Test.make ~count:100 ~name:"rev rev is a no-op"
   QCheck.(list int_pos_small) (* usually just inline the builder for simple tests *)
   (fun l -> List.rev @@ List.rev l = l);;   

(* Run the test *)
let _ = QCheck.Test.check_exn ~long:true list_test

(* Equivalent shorthand ppx notation for making a generator for a declared type *)

type int_list = int list [@@deriving qcheck]

(* Handy for variant types, and it even works for recursive types .. *)

type tree = Leaf | Node of int * tree * tree [@@deriving qcheck]

(* This macro makes the following gens/arbs:

val gen_tree_sized : int -> tree QCheck.Gen.t = <fun>
val gen_tree : tree QCheck.Gen.t = <fun>
val arb_tree_sized : int -> tree QCheck.arbitrary = <fun>
val arb_tree : tree QCheck.arbitrary 
*)

(* OK lets make a few random trees now. *)
let _ = QCheck.Gen.generate ~n:5 gen_tree

(* Note that @@deriving qcheck doesn't work on polymorphic types *)

type 'a btree = Leaf | Node of 'a * 'a btree * 'a btree [@@deriving qcheck]

(* The above code is accepted but it is unusable. *)

(* To generate more complex types such as Maps or Sets its possible to hand-code
   a generator, but in practice the easiest solution is to use a list-based encoding
   
   * To make a Set just make a list, then add the list elements to a Set
   * To make a Map make a list of pairs of (key * value) type and add to a Map
   * Here is a set example, maps are similar.

*)
module IntSet = Set.Make(Int)
let list_to_set l = IntSet.add_seq (List.to_seq l) IntSet.empty
let set_add_test = 
   QCheck.Test.make 
      ~count:10
      ~name:"adding an element to a set will make it a member"
      QCheck.(list int_pos_small) (* the builder for the list of integers *)
      (fun l -> (* the test gets a list l which we want to make a set from *)
         let s = list_to_set l (* now we have an arbitrary int set s, yay! *) in
         (* Make a random integer - note we need to pass a seed here *) 
         let rand_int = int_gen (Random.State.make_self_init ()) in
         let s' = IntSet.add rand_int s in
         IntSet.mem rand_int s')

let _ = QCheck.Test.check_exn set_add_test


(* *********************************************************** *)
(* Using generators to repeatedly test code in your test suite *)
(* *********************************************************** *)

(* All that remains is to install tests like these as OUnit tests.
   QCheck includes a library function QCheck_ounit.to_ounit2_test to do just that  *)

let () =
  Printexc.record_backtrace true;
  let open OUnit2 in
  let qcheck_suite = "ounit suite of tests" >:::
     List.map QCheck_ounit.to_ounit2_test
       [ range_test; list_test; set_add_test ] in (* include all the tests we made above *)
  run_test_tt_main qcheck_suite (* note this crashes top loop *)

(* Shrinking *)

(* In order to have a useful quickchecker you also need to find a smaller failure case
   The failure that is produced randomly could be huge for example
   Shrinking is the process of shortening lists or making smaller integers or trees etc
   but still preserve the error.
   Shrinking is built-in to the default generators.  For advanced applications 
   you can build your own shrinkers, something we will not cover.
*)