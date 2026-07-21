
(* Matching brackets exercise, see
   https://github.com/exercism/ocaml/tree/master/exercises/matching-brackets *)

(* Mutable stack version derived from
   https://exercism.io/tracks/ocaml/exercises/matching-brackets/solutions/df9c50d0863147a39fd2f69222aa1b56

   Used OCaml Stack library with exceptions, re-wrote to use Core
*)

let are_balanced_stack (s : string) : bool =
  let stack_of_lefts = Stack.create () in
  let match_with (c : char) : bool =
    Option.fold (Stack.pop_opt stack_of_lefts)
      ~some:(fun c' -> c = c')
      ~none:false
    (* Option.fold is a combinator you feed Some/None match cases to -- same as:
       `match Stack.pop_opt stack_of_lefts with Some c' -> c = c' | None -> false` *)
  in
  (* parse parses one character, returns true if succuss, false if fail *)
  let parse = function
    (* can pattern match in anonymous function directly using `function` *)
    | ('(' | '{' | '[') as c ->
        Stack.push c stack_of_lefts;
        true
    | ')' -> match_with '('
    | '}' -> match_with '{'
    | ']' -> match_with '['
    | _ -> true
  in
  (* Loop over the characters in the string with `String.for_all` (avoid for/while in OCaml!) : *)
  let r = String.for_all (fun c -> parse c) s in
  (* alt to above using fold: `String.fold ~init:true ~f:(fun b c -> b && parse c) s` *)
  r && Stack.is_empty stack_of_lefts (* at the end the stack needs to be empty! *)

(* Another version which uses an exception for the empty stack pop case.
   The above version is arguably better since there is a good default to return for empty-pop *)

let are_balanced_exn (s : string) : bool =
  let stack_of_lefts = Stack.create () in
  let match_with (c : char) : bool = c = Stack.pop stack_of_lefts in
  let parse = function
    | ('(' | '{' | '[') as c -> Fun.const true @@ Stack.push c stack_of_lefts
    | ')' -> match_with '('
    | '}' -> match_with '{'
    | ']' -> match_with '['
    | _ -> true
  in
  try
    let r = String.fold_left (fun b c -> b && parse c) true s in
    r && Stack.is_empty stack_of_lefts
  with _ -> false
(* return false if any exception is raised (a sledgehammer which could catch the wrong raise) *)

(* Yes, you can solve this concisely without any mutation.
   There is no functional stack data structure in OCaml as List is 98% there already.
   Here we use a fold over the string, and we need an option type for the case that
   we find an error.  Once we get a `None` it bubbles to the top as the result.
*)

let are_balanced_functional (s : string) : bool =
  String.fold_left
    (fun state ch ->
      match state, ch with
      | None, _ -> None (* bubble the error up *)
      | Some stk, ('(' | '[' | '{') ->  Some (ch :: stk)
      | Some ('(' :: tl), ')' | Some ('[' :: tl), ']' | Some ('{' :: tl), '}' -> Some tl
      | Some _, (')' | ']' | '}') ->  None (* this is the error case *)
      | Some stk, _ -> Some stk)
    (Some [])
    s = Some [] (* should be Some [] at the end if everything matched *)