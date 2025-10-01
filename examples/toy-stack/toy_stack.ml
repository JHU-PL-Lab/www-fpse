open Core

[@@@ocaml.warning "-32"]
[@@@ocaml.warning "-27"]

(* A simple mutable stack type.
   Observe that stacks only require mutation at the top *)

type 'a stk = Empty | Node of 'a * ('a stk) (* this could as well be a List.t *)
type 'a stack = 'a stk ref

let create () : 'a stack = ref Empty;;

let push (s : 'a stack) (v : 'a) : unit = failwith "exercise"

(* If the stack is empty you can invoke `invalid_arg "empty stack!"` *)
let pop_exn (s : 'a stack) : unit = failwith "exercise"

let top_exn (s : 'a stack) : 'a = failwith "exercise"

(* make a stack to test *)

let s1 = create ()
let () = push s1 5; push s1 3; push s1 9

