open Core

(* Matching brackets exercise, see
   https://github.com/exercism/ocaml/tree/master/exercises/matching-brackets *)

(* Mutable stack version derived from
   https://exercism.io/tracks/ocaml/exercises/matching-brackets/solutions/df9c50d0863147a39fd2f69222aa1b56

   Used OCaml Stack library with exceptions, re-wrote to use Core
*)

let are_balanced_stack (s : string) : bool =
  let stack_of_lefts = Stack.create () in
  let match_with (c : char) : bool =
    Option.value_map (Stack.pop stack_of_lefts)
      ~f:(fun c' -> Char.(c = c'))
      ~default:false
    (* Option.value_map is a combinator you feed Some/None match cases to -- same as:
       `match Stack.pop stack_of_lefts with Some c' -> Char.(c = c') | None -> false` *)
  in
  (* parse parses one character, returns true if succuss, false if fail *)
  let parse = function
    (* can pattern match in anonymous function directly using `function` *)
    | ('(' | '{' | '[') as c ->
        Stack.push stack_of_lefts c;
        true
    | ')' -> match_with '('
    | '}' -> match_with '{'
    | ']' -> match_with '['
    | _ -> true
  in
  (* Loop over the characters in the string with `String.for_all` (avoid for/while in OCaml!) : *)
  let r = String.for_all ~f:(fun c -> parse c) s in
  (* alt to above using fold: `String.fold ~init:true ~f:(fun b c -> b && parse c) s` *)
  r && Stack.is_empty stack_of_lefts (* at the end the stack needs to be empty! *)

(* Another version which uses an exception for the empty stack pop case.
   The above version is arguably better since there is a good default to return for empty-pop *)

let are_balanced_exn (s : string) : bool =
  let stack_of_lefts = Stack.create () in
  let match_with (c : char) : bool = Char.(c = Stack.pop_exn stack_of_lefts) in
  let parse = function
    | ('(' | '{' | '[') as c -> Fn.const true @@ Stack.push stack_of_lefts c
    | ')' -> match_with '('
    | '}' -> match_with '{'
    | ']' -> match_with '['
    | _ -> true
  in
  try
    let r = String.fold ~init:true ~f:(fun b c -> b && parse c) s in
    r && Stack.is_empty stack_of_lefts
  with _ -> false
(* return false if any exception is raised (a sledgehammer which could catch the wrong raise) *)

(* Yes, you can solve this (more) concisely without any mutation.
   There is no functional stack data structure in OCaml as List is 98% there already.

   Solution derived from
   https://exercism.io/tracks/ocaml/exercises/matching-brackets/solutions/ac5921390cb14120b44f049ef1a09186
*)

let are_balanced_functional (s : string) : bool =
  String.fold_until s ~init:[]
    ~f:(fun stk ch ->
      match ch, stk with
      | '(', _ | '[', _ | '{', _ -> Continue (ch :: stk)
      | ')', '(' :: tl | ']', '[' :: tl | '}', '{' :: tl -> Continue tl
      | ')', _ | ']', _ | '}', _ -> Stop false
      | _ -> Continue stk)
    ~finish:List.is_empty

(* Here is a simple example of fold_until we covered earlier, to better understand the above *)

let summate_til_zero l =
  List.fold_until l ~init:0
    ~f:(fun acc i -> match i with 0 -> Stop acc | _ -> Continue (i + acc))
    ~finish:Fn.id
