(* 
  Algebraic Effects aka resumable exceptions
   aka (more precisely) *one-shot* resumable exceptions 
   aka The mother of all side effects
 -- another way to encode state, coroutines, etc but instead of with pure functions have only one side-effect
   
*)


(* Install and use 

You will need to install a whole new OCaml as resumable exceptions are only in a beta version now.  From your shell you need to use `opam switch create` to do that:

opam update
opam switch create 5.0.0~beta1

which will take a long time.  You then need to do the usual `eval $(opam env)`
to update your path. 

(to switch back to the non-beta, type `opam switch 4.14.0` and do the eval it tells you to do)
(Note that Core etc libraries are not installed as it is a whole new install.  For our little experiments we will not use `Core` but we will use `utop`.)

All of the code in this file will work in 5.0 (only).

*)

(* First let us just play with a "resumable exception"
   
   Think of it as the "Pause" button on the movie you are watching.
     - You can go off and do anything else and that movie stays on pause
     - But, you can resume the movie any time in the future from same spot!
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

(* Now we can make a new division to turn division by 0 into a 1 result *)
let (/) n m =
  try_with (fun () -> newdiv n m) ()
  { effc = fun (type a) (eff: a t) -> match eff with
    | Divz ->     (* if we "continue" later the perform result will be the new value *)
         Printf.printf  "Div by 0, forcing return of 1\n"; Out_channel.flush stdout;
         Some (fun (k: (a, _) continuation) ->
         continue k 1 (* continue lets us RESUME as perform point -- return 1 for n/0 value *)) 
    | _ -> None }

let _ = (3/0) + (8/0) + 1 (* same as 1 + 1 + 1 *)

(* Function to turn [n;m;p] to n/(m/(p/1)) etc 
   But, use above division to allow for recovery *)      
let rec div_list (l : int list) : int =
  List.fold_right ~f:(fun n d -> n / d) l ~init:1 

let _ = div_list [1000;100;2];; (* 1000/(100/(2/1)), no failures *)
let _ = div_list [1000;100;2;4];;  (* 1000/(100/(2/4)) is 1000/1 *)
let _ = div_list [20;4;2;1000;100;2;4];; (* multiple failures here *)

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

   But this is only the beginning: it turns out just about any side effect can be encoded with only resumable exceptions - !!
*)


(* Encoding state with resumable exceptions

The high level idea of the encoding is as follows:

1) at the very top level we have a try block as with the previous example
2) for any state operation we throw a resumable exception
3) .. this gets us back to the top level try
4) where we can (functionally) make any state operations and 
5) resume possibly returning the get result if needed.

It ends up being more complex because the state had to get threaded along

*)

type _ Effect.t += Get: int t | Put: int -> unit t
let get () = perform Get
let put v = perform (Put v)
let run (f : unit -> int) (init: int) : int =
  let comp  : int -> int =
    try_with (fun () -> (let _ = f () in fun (x : int) -> x)) () 
    { effc = fun  (type a)(eff: a Effect.t) -> match eff with
      | (Get) -> Some (fun (k: (a, _) continuation) -> (fun s : int -> (continue k (s : int)) s)) 
      | (Put s) -> Some (fun (k: (a, _) continuation) -> (fun _ : int -> (continue k ()) s))
      | _ -> None} 
  in comp init    

let simple () : int =
  assert (0 = get ()); 
  put 42;
  assert (42 = get ()); 0

let test = run simple 0

(* Now some more general imperative code like this in OCaml:

let x = ref 0 in
while !x < 10 do
  printf "count is %i ...\n" !x;
  x := !x + 1;
done;;

but without any actual state - !

*)
let counter () = 
  while get() < 10 do
  printf "count is %i ...\n" (get ());
  put(get() + 1);
  done; 0
let test2 = run counter 0



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

let simple () : int =
  assert (0 = get ()); 
  let _ = put 42 in 
  assert (42 = get ()); 0

let test = run simple 0


(* Lastly is it even possible to do coroutines in this setting 

See https://github.com/ocamllabs/ocaml-effects-tutorial/blob/master/sources/cooperative.ml for simple independent runs

 - the key insight here is to make a queue of the paused computations
   - the continuation is a first-class value, make a Q of them
 - async f puts the current computation on hold on Q, runs f
 - yield () puts current computation on hold on Q, runs top-of-Q

See https://github.com/ocamllabs/ocaml-effects-tutorial/blob/master/sources/solved/async_await.ml for full coroutines with promises etc.

*)