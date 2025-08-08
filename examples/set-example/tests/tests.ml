
open OUnit2
open String_set

let tests = "test suite for simple set" >::: [
  "empty"  >:: (fun _ -> assert_equal empty empty);
  "3-elt"    >:: (fun _ -> assert_equal true (contains "5" (add "5" empty)));
  "1-elt nested" >:: (fun _ -> assert_equal false (contains "5" (remove "5" (add "5" empty))));
]

let _ = run_test_tt_main tests