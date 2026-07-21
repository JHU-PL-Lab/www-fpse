(*
  Algebraic Effects
    aka resumable exceptions
    aka (more precisely) *one-shot* resumable exceptions
    aka The mother of all side effects
    -- they are another way to encode state, coroutines, etc. but instead of
      using pure functions, just have one side-effect
*)

(* First let us warm up with exceptions *)
type exn += FPSE of string

let except () =
  print_endline "About to raise";
  raise (FPSE "Raised an exception");
  print_endline "Unreachable"
  [@@warning "-21"] (* supress warning about unreachable line *)

(*
  This will print:
    About to raise
    Raised an exception
*)
let () =
  try except () with
  | FPSE s ->
    print_endline s

(*
  But what if we wanted to run that unreachable line? That is, we resume the
  code after the exception is raised.

  We can do this with effects, i.e. "resumable exceptions".

  Think of it as the "Pause" button on the movie you are watching.
    - You can go off and do anything else and that movie stays on pause
    - But, you can resume the movie any time in the future from the exact same spot!
    - Also, when you resume the old "pause point" is gone, no re-resuming from
    the same spot twice. (Of course you can "pause" again in the future from
    another point.)
*)

(* Uses the Effect system of OCaml 5 *)
open Effect
open Effect.Deep (* Effect has Deep and Shallow. Prefer Deep most of the time *)

(* Let's start with a simple effectful example that just demos the control flow *)

(** Extend the effect type with a new effect constructor called [Yield], like an
  exception but resumable. *)
type _ Effect.t += Yield : unit t

(** [demo] will print, then perform the [Yield] effect, and when resumed, will
  print again. *)
let demo () =
  print_endline "Here";
  (* perform is "resumable raise", i.e. "press pause". *)
  perform Yield;
  print_endline "Back again"

(* This will print:
    Here
    There
    Back again
*)
let () =
  try demo () with
  | effect Yield, k ->
    (* The effect has been caught. So do something here, and then resume from
      where the effect was performed! i.e. "press play" *)
    print_endline "There";
    continue k () (* continue comes from Effect.Deep *)

(**
  But this effect provides nothing ([Yield] has no payload) and receives nothing
  ([Yield] has type [unit t], where the [unit] is what the performer gets back
  when the continuation is resumed).

  What if when we yield, we want to give a value to the catcher?
*)

(** [Printme s] gives the string [s] to whoever catches the effect. Any value
  [Printme s] still has type [unit t], so the performer only gets the value
  [() : unit] back when the continuation is resumed. *)
type _ Effect.t += Printme : string -> unit t

let printme () =
  print_endline "Here";
  perform (Printme "There, but where?");
  print_endline "Back again"

(* This will print:
    Here
    There, but where?
    Back again
*)
let () =
  try printme () with
  | effect Printme s, k ->
    print_endline s; (* Print the string contained in the effect *)
    continue k ()

(**
  Since [Effect.t] is just a extensible variant, we can pass them around like
  first class values. The above examples can be deduplicated.
*)

let deduped eff =
  print_endline "Here";
  perform eff; (* perform the effect that was passed in *)
  print_endline "Back again"


(* This will print:
    Here
    Yielded
    Back again
    Here
    Printing me
    Back again
*)
let () =
  try deduped Yield; deduped (Printme "Printing me") with
  | effect Yield, k ->
    print_endline "Yielded";
    continue k ()
  | effect Printme s, k ->
    print_endline s;
    continue k ()

(*
  So far, when the continuation is resumed, the performer gets nothing back
  (notice the semicolon after performing the effect). What if, when the
  continuation is resumed, we want a value with which to continue?

  To demo this we will keep using our printing example, but instead of
  "Back again", we will print some provided string. *)

(** The [Printyou] effect has type [string t], so the performer will get back
  a value with type [string] when resumed. Above, it was always unit. *)
type _ Effect.t += Printyou : string t

let printyou () =
  print_endline "Here";
  (* Assign the name to_print to the value that we get back when resuming. *)
  let to_print = perform Printyou in
  print_endline to_print (* print that string *)

(* This will print:
    Here
    Caught
    Resumed
*)
let () =
  try printyou () with
  | effect Printyou, k ->
    print_endline "Caught";
    (* We pass the string "Resumed" back to where the effect was performed. *)
    continue k "Resumed"

(* Let's step it up a bit. We will redefine integer division so we can keep
  things going if we divide by zero. *)

(** [Divz n] is performed when [n] is divided by [0], and the performer gets
  back the integer to use in place of the failed division *)
type _ Effect.t += Divz : int -> int t

let newdiv x y =
  if y = 0 then
    perform (Divz x)
  else
    x / y

(** Instead of the exception [Division_by_zero] like [33 / 0] raises, this
  performs the [Divz 33] effect. We do not catch it, so this program fails. *)
let _ : int = newdiv 33 0

(*
  Now let's overwrite the division operator. To use our new division.
*)
let (/) n m =
  try newdiv n m with
  | effect Divz n, k ->
    Printf.printf  "Div %d by 0, forcing return of 1\n%!" n;
    continue k 1

let _ : int = (3 / 0) + (8 / 0) + 1 (* same as 1 + 1 + 1 *)

(* Function to turn [n;m;p] to n/m/p etc.
   but use the above division to allow for recovery *)
let rec div_list (l : int list) : int =
  match l with
  | [] -> 1
  | hd :: tl -> List.fold_left (fun acc n -> acc / n) hd tl

let _ = div_list [1000;100;2];; (* 1000/100/2, no failures *)

let _ = div_list [1000;100;2;5];;  (* 1000/100/2/5 is 1 *)

let _ = div_list [20;4;2;1000;100;2;4];; (* multiple failures here *)

(* The above exception can only be resumed (continued) once;
   thus it is a **one-shot** resumable exception *)

let dont_do_this_div n m =
  try newdiv n m with
  | effect Divz n, k ->
    Printf.printf  "Div %d by 0, trying to resume twice\n%!" n;
    (continue k 1) + (continue k 2) (* try to resume twice *)

let _ = dont_do_this_div 4 0 (* No go -- throws Continuation_already_resumed *)

(* Note it is also possible to add to the top-level computation when you pop out *)

let adding_div n m =
  try newdiv n m with
  | effect Divz n, k ->
    Printf.printf  "Div %d by 0, resuming\n%!" n;
    (continue k 1) + 77 (* add 77 to final result *)

(* This is 1 + 77 + 4 + 1 *)
let _ = (adding_div 3 0) + (adding_div 8 2) + 1

(*
  How is this implemented?  It is fairly intuitive.
  1) For each try/with which might raise an effect, run the try on its own stack
  2) If an effect is performed, *freeze* that runtime stack and program counter
  3) Run the effect handler code on a forked stack
  4) If there is a continue, thaw the frozen stack/pc and re-start

  Note there is also a `discontinue` which is for the case you want to keep
  raising the failure as an actual exception instead of resiming the
  continuation.
*)

(* OK hopefully one-shot resumable exceptions make some sense now.

   But this is only the beginning: it turns out just about any side effect can
   be encoded with only resumable exceptions - !  Its fairly complex though so
   we will skip in lecture.   See below if interested.
*)


(* Encoding state with resumable exceptions

The high level idea of the encoding is as follows:

1) at the very top level we have a try block as with the previous example
2) for any state operation we throw a resumable exception
3) .. this gets us back to the top level try
4) where we can (functionally) make any state operations and
5) resume by possibly returning the get result if needed.

It ends up being more complex because the state has to get threaded along

Note for this example we will have a global state consisting of one integer only, but in
general that `int` could be any OCaml type.

*)

type _ Effect.t +=
  | Get: int t (* get the int state *)
  | Set: int -> unit t (* set the int state *)

let run (type a) ~init (main : unit -> a) : int * a =
  let handle =
    match main () with
    | effect Get, k ->
      fun (state : int) -> (* propagates (and continues with) the old state *)
        continue k state state
    | effect Set new_state, k ->
      fun _ -> (* ignores the old state *)
        continue k () new_state
    | v ->
      fun state -> (* returns the final state *)
        state, v
  in
  handle init

(** The above run function is quite subtle
  - [main] is the effectful code to be run. It is a thunk (i.e. is frozen).
  - The [match with] thaws [main] and handles it effects.
  - Every time we "come up for air" in a perform handled by the effect handlers,
    we will have the state value passed in, which is initially [init], and
    after that it is [state] or [new_state] in the [Get] and [Set] handlers,
    respectively.
  - The final [handle init] "seeds" this state.
  - There is then a cascade of state passing.
  - When [main ()] finally finishes, the state is passed in one more time and is
    returned as a tuple along with the final result [v].
  - The resulting code works just like the [ref]/[:=]/[!] of imperative OCaml,
    but it threads state like a state monad, but there is no [let*]/[bind].
*)

let simple () : unit =
  assert (0 = perform Get);
  perform @@ Set 42;
  assert (42 = perform Get)

let test = run ~init:0 simple

(* Now a larger example of how to encode some imperative OCaml such as this:

let x = ref 0 in
while !x < 10 do
  printf "count is %i ...\n" !x;
  x := !x + 1;
done;;

but without any actual state - !
We use `get` and `put` functions to make it look a bit more like !/:=
*)

let get () = perform Get
let put v = perform (Set v)

let counter () =
  while get () < 10 do
    Format.printf "count is %i ...\n" (get ());
    put (get () + 1);
  done

let test_counter = run ~init:0 counter

(* Lastly is it even possible to do coroutines in this setting

See https://github.com/ocamllabs/ocaml-effects-tutorial/blob/master/sources/cooperative.ml for simple independent runs

 - the key insight here is to make a queue of the paused computations
   - the continuation is a first-class value, make a Q of them
 - async f puts the current computation on hold on Q, runs f
 - yield () puts current computation on hold on Q, runs top-of-Q

See https://github.com/ocamllabs/ocaml-effects-tutorial/blob/master/sources/solved/async_await.ml for full coroutines with promises etc.

*)

(* Appendix: another version of run for state that uses try/with *)
let run' ~(init: int) (main : unit -> unit) : unit =
  let comp : int -> unit =
    try main (); fun (_ : int) -> () with
    | effect Get, k ->
      fun (s : int) ->
        continue k s s
    | effect Set s, k ->
      fun (_ : int) ->
        continue k () s
  in
  ignore (comp init)
