(* Quickcheck Examples
   Requires:
   (libraries core)
   (preprocess (pps ppx_jane))
   in dune file
   And #require "ppx_jane" in top-loop
*)

open Core
(* Step 1 is you need a generator to make random data in a given type. *)
(* For all the built-in types, My_builtin.quickcheck_generator is a nice default generator *)

let rand_int =  
  let int_gen = (Int.quickcheck_generator) in
  (Quickcheck.random_value ~seed:`Nondeterministic int_gen)

let rand_int' =  (Quickcheck.random_value ~seed:`Nondeterministic (Int.gen_incl (-100) 100))

(* A little function to test out various generators *)
let rand_from (g : 'a Base_quickcheck.Generator.t) = 
  (Quickcheck.random_value ~seed:`Nondeterministic g)

(* Parameterizerd type generators need a generator for the parameter 
   Similar to how `List.equal` needs an `equal` on list contents *)
let int_list_gen = List.quickcheck_generator Int.quickcheck_generator

let rand_list = rand_from int_list_gen

(* Shorthand ppx notation *)
let int_list_gen' = [%quickcheck.generator: int list]

(* Similarly can compose two generators to generate a pair via Quickcheck.Generator.both *)
let rand_list_pair = rand_from (Quickcheck.Generator.both int_list_gen int_list_gen)

(* **************************************** *)
(* Using generators to repeatedly test code *)
(* **************************************** *)

(* Simple failure example based on https://github.com/realworldocaml/book/tree/master/book/testing) *)
(* Replace `assert` with `OUnit2.assert_bool` and this code can be an OUnit test function. *)
let () =
  Quickcheck.test ~sexp_of:[%sexp_of: int]
    (Int.gen_incl Int.min_value Int.max_value)
    ~f:(fun x -> assert(Sign.equal (Int.sign (Int.neg x)) (Sign.flip (Int.sign x))))

let check_a_list_rev revver = 
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

(* The following parametric type gen should also work but is currently broken in the opam dist *)

(* type 'a bin_tree = Leaf | Node of 'a * 'a bin_tree * 'a bin_tree [@@deriving quickcheck] *)

type int_tree = Leaf | Node of int * int_tree * int_tree [@@deriving quickcheck]

type int_tree = 
  | Leaf
  | Node of int * int_tree * int_tree [@@deriving quickcheck]

let atree = rand_from quickcheck_generator_int_tree

