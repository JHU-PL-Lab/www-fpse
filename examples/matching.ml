open Core

(* Matching brackets exercise, see
   https://github.com/exercism/ocaml/tree/master/exercises/matching-brackets *)

(* Mutable stack version derived from
   https://exercism.io/tracks/ocaml/exercises/matching-brackets/solutions/df9c50d0863147a39fd2f69222aa1b56

   Used OCaml Stack library with exceptions, re-wrote to use Core
*)

let are_balanced_stack s =
  let stack_of_lefts = Stack.create () in
  let match_with s c =
    Option.value_map (Stack.pop s) ~f:(fun c' -> Char.( = ) c c') ~default:false
  in
  let parse = function
    | ('(' | '{' | '[') as c ->
        Stack.push stack_of_lefts c;
        true
    | ')' -> match_with stack_of_lefts '('
    | '}' -> match_with stack_of_lefts '{'
    | ']' -> match_with stack_of_lefts '['
    | _ -> true
  in
  let r = String.for_all ~f:(fun c -> parse c) s in
  r && Stack.is_empty stack_of_lefts

(* Here is an alternate version, mainly to show what Option.value_map does *)
let are_balanced_stack' s =
  let stack_of_lefts = Stack.create () in
  let match_with s c = (* expand meaning of Option.value_map *)
    match Stack.pop s with Some c' -> Char.(c = c') | None -> false
  in
  let parse = function
    | ('(' | '{' | '[') as c ->
        Stack.push stack_of_lefts c;
        true
    | ')' -> match_with stack_of_lefts '('
    | '}' -> match_with stack_of_lefts '{'
    | ']' -> match_with stack_of_lefts '['
    | _ -> true
  in
  (* Use fold instead of for_all here *)
  let r = String.fold ~init:true ~f:(fun b c -> b && parse c) s in
  r && Stack.is_empty stack_of_lefts

(* Another version which uses an exception for the empty stack pop case.
   The above version is arguably better since there is a good default to return for empty-pop *)

let are_balanced_exn s =
  let stack_of_lefts = Stack.create () in
  let match_with s c = Char.( = ) c (Stack.pop_exn s) in
  let parse = function
    | ('(' | '{' | '[') as c -> Fn.const true @@ Stack.push stack_of_lefts c
    | ')' -> match_with stack_of_lefts '('
    | '}' -> match_with stack_of_lefts '{'
    | ']' -> match_with stack_of_lefts '['
    | _ -> true
  in
  try
    let r = String.fold ~init:true ~f:(fun b c -> b && parse c) s in
    r && Stack.is_empty stack_of_lefts
  with _ -> false
(* return false if any exception is raised (a bit of a sledgehammer) *)

(* No, you don't really need mutation here at all, and the code is shorter to boot.
   Solution derived from
   https://exercism.io/tracks/ocaml/exercises/matching-brackets/solutions/ac5921390cb14120b44f049ef1a09186
*)

let are_balanced_functional s =
  String.fold_until s ~init:[]
    ~f:(fun acc c ->
      match (c, acc) with
      | '(', _ | '[', _ | '{', _ -> Continue (c :: acc)
      | ')', '(' :: tl | ']', '[' :: tl | '}', '{' :: tl -> Continue tl
      | ')', _ | ']', _ | '}', _ -> Stop false
      | _ -> Continue acc)
    ~finish:List.is_empty

(* Here is a simpler example of fold_until to better understand the above *)

let summate_til_zero s =
  List.fold_until s ~init:0
    ~f:(fun acc i ->
      match i with 0 -> Stop acc | _ -> Continue (i + acc))
    ~finish:Fn.id
