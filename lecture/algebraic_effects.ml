(* 
  Algebraic Effects aka resumable exceptions
   aka (more precisely) *one-shot* resumable exceptions 
   aka The mother of all side effects
 -- another way to encode state, coroutines, etc but instead of with pure functions have only one side-effect
   
*)

(* First let us just play with a "resumable exception"
   
   Think of it as the "Pause" button on the movie you are watching.
     - You can go off and do anything else and that movie stays on pause
     - But, you can resume the movie any time in the future from the exact same spot!
     - Also, when you resume the old "pause point is gone", no re-resuming.
       (of course could "pause" again in the future from another point.)
*)

(* Uses the Effect system of OCaml 5 *)
open Effect
open Effect.Deep

(* Let's redefine integer division so we can keep things going if we
   divide by zero. *)

(* First we make a new effect named Divz; like an exception but resumable *)
type _ Effect.t += Divz: int t

(* Now we make an adaptor on existing "/" to perform this effect instead of default one *)
let newdiv x y = match y with 
| 0 -> perform (Divz)     (* perform is "resumable_raise" *)
| _ -> Stdlib.(x / y)

let _ = newdiv 33 0 (* See how this just changes the exception raised *)

(* Now we can make a new division to turn division by 0 into a 1 result 
   by resuming with 1 as the result when the exception is raised
   Note the syntax for this is currently horrible, they are going to improve it *)
let (/) n m =
  try_with (fun () -> newdiv n m) ()
  { effc = fun (type a) (eff: a t) -> match eff with
    | Divz ->     (* if we "continue" later the perform result will be the new value *)
         Printf.printf  "Div by 0, forcing return of 1\n"; Out_channel.flush stdout;
         Some (fun (k: (a, _) continuation) ->
         continue k 1 (* continue lets us RESUME at the perform point -- return 1 for n/0 value *)) 
    | _ -> None }

let _ = (3/0) + (8/0) + 1 (* same as 1 + 1 + 1 *)

(* Function to turn [n;m;p] to n/(m/(p/1)) etc 
   But, use above division to allow for recovery *)      
let rec div_list (l : int list) : int =
  Core.List.fold_right ~f:(fun n d -> n / d) l ~init:1 

let _ = div_list [1000;100;2];; (* 1000/(100/(2/1)), no failures *)
let _ = div_list [1000;100;2;4];;  (* 1000/(100/(2/4)) is 1000/1 *)
let _ = div_list [20;4;2;1000;100;2;4];; (* multipl`e failures here *)

(* The above exception can only be resumed (continued) once;
   thus it is a **one-shot** resumable exception *)

let dont_do_this_div n m =
  try_with (fun () -> newdiv n m) ()
  { effc = fun (type a) (eff: a t) -> match eff with
    | Divz ->     (* if we "continue" later the perform result will be the new value *)
         Printf.printf  "Div by 0, forcing return of 1\n"; Out_channel.flush stdout;
         Some (fun (k: (a, _) continuation) ->
         (continue k 1) + (continue k 2) (* try to resume twice *)) 
    | _ -> None }

let _ = dont_do_this_div  4 0 (* No go -- throws Continuation_already_resumed *)

(* Note it is also possible to add to the top-level computation when you pop out *)

let adding_div n m =
  try_with (fun () -> newdiv n m) ()
  { effc = fun (type a) (eff: a t) -> match eff with
    | Divz ->     (* if we "continue" later the perform result will be the new value *)
         Printf.printf  "Div by 0, forcing return of 1\n"; Out_channel.flush stdout;
         Some (fun (k: (a, _) continuation) ->
         (continue k 1) + 77 (* add 77 to was-final result *)) 
    | _ -> None }

let _ = (adding_div 3 0) + (adding_div 8 0) + 1

(* How is this implemented?  It is fairly intuitive. 
  1) For each try/with which might raise an effect, run the try on its own stack
  2) If an effect is performed, *freeze* that runtime stack and program counter
  3) Run the effect handler code
  4) If there is a continue, thaw the frozen stack/pc and re-start

  Note there is also a `discontinue` which is for the case you want to
  keep raising the failure as an actual exception.

*)

(* OK hopefully one-shot resumable exceptions make some sense now.

   But this is only the beginning: it turns out just about any side effect can be encoded with only resumable exceptions - !
   Its fairly complex though so we will skip in lecture.   See below if interested.
*)


(* Encoding state with resumable exceptions

The high level idea of the encoding is as follows:

1) at the very top level we have a try block as with the previous example
2) for any state operation we throw a resumable exception
3) .. this gets us back to the top level try
4) where we can (functionally) make any state operations and 
5) resume possibly returning the get result if needed.

It ends up being more complex because the state has to get threaded along

Note for this example we will have a global state consisting of one integer only, but in
general that `int` could be any OCaml type.

*)

type _ Effect.t += Get: int t | Set: int -> unit t (* Get gets int back, Set passes int up *)

let run (type a) ~init (main : unit -> a) : int * a =
    (match_with main ()
      {
        retc = (fun res x -> (x, res)); (* processes final value *)
        exnc = raise;
        effc =
          (fun (type b) (e : b Effect.t) ->
            match e with
            | Get   -> Some (fun (k : (b, int -> int * a) continuation) 
                                 (x : int) -> (continue k x) x)
            | Set y -> Some (fun (k : (b, int -> int * a) continuation) 
                                 (_ : int) -> continue k () y)
            | _ -> None);
      })
      init

(* The above run function is quite subtle
   - `main` is the effectful code to be run, it is a thunk (frozen)
   - the `match_with` thaws main to runs it handles effects as per the record
   - the `main` code should be able to perform `Set` and `Get` operations on this integer
   - a is the type returned by `main` program
   - `run` returns an int * a, the heap final value plus the `main` computation final value.
   - The record expression argument to match_with defines all the handlers for effects in running `main`
      retc for the final value which it makes into a pair
      exnc in case an exception is thrown by main (it just re-raies it)
      effc is the perform handler as in previous examples
   - The final `init` in the `run` code seeds this chain of state-expecting functions with the initial state
   - Every time we "come up for air" in a perform handled by `effc` we will have the state value passed 
    (init initially and after that the x or y from the previous Get or Set)
     - and, we will then build a new function expecting the state value as the result
   - With all of the above there is a cascade of state passing
   - And, the resulting code "works just like" the ref/:=/! code of OCaml, no let%bind needed.
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
  while get() < 10 do
  Format.printf "count is %i ...\n" (get ());
  put(get() + 1);
  done

let test_counter = run ~init: 0 counter



(* Lastly is it even possible to do coroutines in this setting 

See https://github.com/ocamllabs/ocaml-effects-tutorial/blob/master/sources/cooperative.ml for simple independent runs

 - the key insight here is to make a queue of the paused computations
   - the continuation is a first-class value, make a Q of them
 - async f puts the current computation on hold on Q, runs f
 - yield () puts current computation on hold on Q, runs top-of-Q

See https://github.com/ocamllabs/ocaml-effects-tutorial/blob/master/sources/solved/async_await.ml for full coroutines with promises etc.

*)

(* Appendix: another version of run for state that uses try_with *)
let run' ~(init: int) (main : unit -> unit) : unit =
  let comp  : int -> unit =
    try_with (fun () -> (main (); fun (_ : int) -> ())) () 
    { effc = fun (type a)(eff: a Effect.t) -> match eff with
      | (Get) -> Some (fun (k: (a, _) continuation) -> (fun (s : int) -> (continue k s) s)) 
      | (Set s) -> Some (fun (k: (a, _) continuation) -> (fun (_ : int) -> (continue k ()) s))
      | _ -> None} 
  in ignore(comp init)
