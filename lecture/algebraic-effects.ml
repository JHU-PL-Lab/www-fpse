(* Algebraic Effects 
   aka resumable exceptions
   aka (more precisely) *one-shot* resumable exceptions 
   aka The mother of all side effects
   aka better-than-monad-ism (no bind macro layer like monads)

   We are going to call these resumable exceptions since that is all they are.
   
   The following code uses examples based on or found in the tutorial at
   https://github.com/ocamllabs/ocaml-effects-tutorial
*)


(* Install and use 

You will need to install a whole new OCaml as resumable exceptions are only in a beta version now.  From your shell you need to use `opam switch create` to do that:

$ opam switch create 4.12.0+domains+effects

which will take a long time.  You then need to do the usual `eval $(opam env)`
to update your path. 

(to switch back to the non-beta, say `opam switch 4.12.0` and do the eval)
(Note that Core etc libraries are not installed as it is a whole new install.  For our little experiments we will not use `Core` but we will use `utop`.)

All of the code in this file will work in 4.12.0+domains+effects only.

*)

(* First let us just play with a "resumable exception"
   
   Think of it as the "Pause" button on the movie you are watching.
     - You can go off and do anything else
     - But, you can resume the movie any time in the future from same spot!
     - Also, when you resume the old "pause point is gone", no re-resuming.
       (of course could "pause" again in the future from another point.)
*)

effect Div_failure : int -> int (* read "effect" as "resumable_exception" *)

(* int -> here is what you pass up for raise
   -> int is what comes back for resumption *)

(* Let's redefine integer division so we can keep things going if we
   divide by zero. *)
let (/) n m =
  try Stdlib.(n / m) with
    (* perform is "resumable_raise" aka "pause" in the intuition above *)
    | Division_by_zero -> let r = perform (Div_failure n) in 
      (* if we "continue" later the perform result will be the new value *)
      Printf.printf  "Resuming the movie, value is now %n\n" r; r

(* Stupid function to turn [n;m;p] to n/(m/(p/1)) etc 
   But, use above division to allow for recovery *)      
let rec div_list (l : int list) : int =
  List.fold_right (fun n d -> n / d) l 1 

let _ = div_list [1000;100;2];; (* 1000/(100/2), no failures *)
let _ = div_list [100;2;4];;  (* failure, not caught *)
let recover_div l =
  try div_list l with (* try is overloaded, also is resumable_try *)
      (* effect here catches a resumable exception;
       k is the pause point name, k is for kontinuation (the rest after) *)
  | effect (Div_failure n) k ->
      Printf.fprintf stderr "Div failure on %n / 0!\n" n; flush_all ();
      continue k 1 (* Go back to the movie - resume from pause point k *)


let _ = recover_div [1000;100;2];; (* 1000/(100/2), no failures *)
let _ = recover_div [100;2;4];; (* 100/(2/4) so 100/0 so 1  *)
let _ = recover_div [1000;100;2];; (* 1000/100/2 so 100/1 so 100 *)
let _ = recover_div [20;4;2;1000;100;2;4];; (* multiple failures here *)

(* The above exception can only be resumed (continued) once;
   thus it is a **one-shot** resumable exception *)

let recover_div_bad l =
  try div_list l with
  | effect (Div_failure n) k -> 
      Printf.fprintf stderr "Div failure on %n / 0!\n" n; flush_all ();
      (continue k 1) + (continue k 1) (* trying to resume twice *)

let _ = recover_div_bad [100;2;4];;  (* No go -- throws error *)


(* How is this implemented?  It is fairly intuitive. 
  1) For each try/with which might raise an effect, run the try on its own stack
  2) If an effect is performed, *freeze* that runtime stack and program counter
  3) Run the effect handler code
  4) If there is a continue, thaw the frozen stack/pc and re-start

  Note there is also a `discontinue` syntax which is for the case you want to
  keep raising the failure as an actual exception.

*)

(* OK hopefully one-shot resumable exceptions make some sense now.

   But this is only the beginning: it turns out just about any side effect can be encoded with only resumable exceptions - !!
*)


(* Encoding state with resumable exceptions 

We will be covering a simplified version of  https://github.com/ocamllabs/ocaml-effects-tutorial/blob/master/sources/solved/state2.ml code below.

The idea of the encoding is as follows:

1) at the very top level we have a try block as with the previous example
2) for any state operation we throw a resumable exception
3) .. this gets us back to the top level try
4) where we can (functionally) make any state operations and 
5) resume possibly returning the get result if needed.

*)

open Printf

module type STATE = sig
  type t
  val put     : t -> unit
  val get     : unit -> t
  val run : (unit -> unit) -> init:t -> unit
end

module State (S : sig type t end) : STATE with type t = S.t = struct
  type t = S.t
  effect Get : t (* nothing up, only a t down *)
  let get () = perform Get
  effect Put : t -> unit
  let put v = perform (Put v)
  let run f ~init =
    let comp : t -> unit =
      match f () with
      | () -> (fun _ -> ())
      | effect Get k -> printf "Getting\n"; (fun s : t -> (continue k s) s)
      | effect (Put s) k -> printf "Setting\n"; (fun _ : t -> (continue k ()) s)
    in comp init
end

(* The above run function is quite subtle
   - the match always returns a function
      (note also that we can use match for both values & effects simult.)
   - that function will get fed the "current" state s as argument
   - comp init is the bootstrapping case for s
   - every time we "pop up for air"  with set/get effects we get a function
     - the result of that computation we will in turn need to feed
       the (possibly revised) state to, the final s in the continue's

   - With all of the above there is a cascade of state passing
   - And, the resulting code "looks like" the ref/:=/! code of OCaml, no let%bind

*)
module IS = State (struct type t = int end)

let super_simple () : unit = ()

let _ = IS.run super_simple 0

let sorta_simple () : unit =
  let open IS in
  assert (0 = get ());

let _ = IS.run sorta_simple 0


let simple () : unit =
  let open IS in
  assert (0 = get ());
  put 42;
  assert (42 = get ());


let _ = IS.run simple 0


(* Bigger example *)

module SS = State (struct type t = string end)

let foo () : unit =
  assert (0 = IS.get ());
  IS.put 42;
  assert (42 = IS.get ());
  IS.put 21;
  assert (21 = IS.get ());
  SS.put "hello";
  assert ("hello" = SS.get ());
  SS.put "world";
  assert ("world" = SS.get ());

let _ = IS.run (fun () -> SS.run foo "") 0


(* Lastly is it even possible to do coroutines in this setting 

See https://github.com/ocamllabs/ocaml-effects-tutorial/blob/master/sources/cooperative.ml for simple independent runs

 - the key insight here is to make a queue of the paused computations
   - the continuation is a first-class value, make a Q of them
 - async f puts the current computation on hold on Q, runs f
 - yield () puts current computation on hold on Q, runs top-of-Q

See https://github.com/ocamllabs/ocaml-effects-tutorial/blob/master/sources/solved/async_await.ml for full coroutines with promises etc.

*)