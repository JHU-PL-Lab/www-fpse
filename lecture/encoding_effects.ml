(* ***************************** *)
(* Encoding effects functionally *)
(* ***************************** *)

(* Aka "A Journey through Monad Land" *)

open Core

(*
  * So far we have seen the advantages of functional programming
  * But, sometimes it is a handicap to not have side effects
  * A middle ground is sometimes the best: *encode* effects using purely functional code
    - we already saw a bit of this with the option type replacing exceptions
    - also the use of piping such as:
*)

let _ : bool = Map.empty(module String) 
               |> Map.set ~key: "hi" ~data: 3 
               |> Map.set ~key: "ho" ~data: 17
               |> Map.for_all ~f:(fun i -> i > 10)


(*   etc which is a concise "hand over fist passing" encoding 
     of what would be a sequence of mutable assignments with a mutable map.

  * Idea: make a more structured encoding which is not informal like the above
  * Think of it as defining a macro language inside of OCaml in which the code will 
    look effectful even though it isn't: "monad-land"
  * It looks effectful, BUT is not and so still will preserve the referential transparency etc
  * The mathematical basis for this is a structure called a *monad*.
  * It is really just one very fancy functional programming idiom.

*)

(* ******************* *)
(* Encoding Exceptions *)
(* ******************* *)

(* 
  * Let's start with monads by using 'a option's Some/None to encode exception effects
  * We have already seen many examples of this, e.g. Minesweeper functional example
  * Here we want to regularize/generalize it to make an offical monad.
  * First recall how we had to "forward" a `None` if an e.g. List operation failed
*)

(* zip in fact doesn't return Some/None, let us convert it to that format here.
   We need a uniformity that None is always the exceptional case and Some is the OK-case. *)
let better_zip l1 l2 = match List.zip l1 l2 with Unequal_lengths -> None | Ok l -> Some l

(* 
  Here is an artificial example of lots of hand-over fist passing of options.
  Several operations can fail with a None, and in each case we need to match to bubble that None to the top.
  Yes the code is U-G-L-Y !
*)

(* Lets zip two lists, sum pairwise, and return the 2nd element of the resulting list. 
   This is not intended to be useful code, just an example of forwarding exceptional conditions *)
let ex l1 l2 = 
  match better_zip l1 l2 with 
  | Some(l) -> 
    begin (* recall `begin .. end` is just like `( ... )` - big parentheses *)
      let m =  List.fold l ~init:[] ~f:(fun acc (x,y) -> x + y :: acc) in
      match List.tl m with
      | Some(tail) -> 
        begin
          match List.hd tail with 
          | Some(hd_tail) -> Some(hd_tail)
          | None -> None 
        end
      | None -> None 
    end
  | None -> None

(* Before getting into how we can clean this code up lets compare with the effectful version *)
   let ex_real_effects l1 l2 =
    let l = List.zip_exn l1 l2 in 
    let m = List.fold l ~init:[] ~f:(fun acc (x,y) -> x + y :: acc) in
    let tail = List.tl_exn m in 
    let hd_tail = List.hd_exn tail in
    hd_tail

(* I think everyone would agree that this version is a lot easier to read.. 
   .. Lets fix that! *)

(* 
  * Now let us regularize this with a monad
  * Think of a monad as a wrapper on regular computations
  * "In Monad-land" here is an option-tagged computation
  * "Out of the monad" is when we are not option-tagged
*)

(* 
 * The key operation of a monad is `bind` which sequences side-effecting computations. 
   For Option it exists as Option.bind
   Here is its code for reference (we call this one bind' to not overlap with built-in one)
 *)

let bind' (opt : 'a option) ~(f : 'a -> 'b option) : ('b option) = 
  match opt with 
  | None -> None 
  | Some v -> f v;;

(* bind does the match "for free" compared to above 
    - if the zip failed with `None` the function is ignored
    - if it succeeds the Some wrapper is automatically peeled off and the underlying data passed to f 
    - the net result is the Some/None is largely hidden in the code: *)

bind' (better_zip [1;2] [3;4]) ~f:(fun l -> match l with (l,_)::_ -> Some(l));;

(* Yes there is still a `Some` at the end in the above
   That is because the result needs to stay in monad-land (since the first part could have None'd)
   We will in fact hide Some below so its still there but its not explicit. 
   In general once you get into monad-land you tend to stay there a long time .. *)

(* 
  * bind more generally sequences ANY two functional side effects, more below on this
  * besides the bubbling of None's it is a lot like a "let" expression.
    -  bind code1 ~f:code2  first runs code1, and if it is non-None runs code2 on which can use underyling result of code1.
  * This suggests a macro:
  `let%bind x = e1 in e2`  which macro expands to `bind e1 ~f:(fun x -> e2)`
  * Using the macro, code can look more like regular code
  * We have pushed monad-land into hiding a bit more..
*)

(* let%bind exists in Core for Option.bind, lets use it
  Note we need to open a module to enable macro for Option.bind 
  And, need #require "ppx_jane" in top loop (or (preprocess (pps ppx_jane)) in dune) 
  for the macro to expand *)

open Option (* don't do this at home (tm) - in actual code use Option.(..) or let open Option in .. *)
open Option.Let_syntax;;

let%bind (l,_)::_ = better_zip [1;2] [3;4] in Some(l);; (* compare with above version - a bit more readable *)

(* this is very similar to the exn version which actually has a side effect: *)

let (l,_)::_ = List.zip_exn [1;2] [3;4] in l;;

(* 
 * OK now let us redo ex above using let%bind
 * This code looks more like the exn code above now..
 *)

let ex_bind_macro l1 l2 =
  let%bind l = better_zip l1 l2 in 
  let m = List.fold l ~init:[] ~f:(fun acc (x,y) -> x + y :: acc) in (* never None's so no bind needed here *)
  let%bind tail = List.tl m in 
  let%bind hd_tail = List.hd tail in
  return hd_tail (* "return to the monad" - here that means wrap in Some(..) *)
(* vs effectful: *)
let ex_real_effects l1 l2 =
  let l = List.zip_exn l1 l2 in 
  let m = List.fold l ~init:[] ~f:(fun acc (x,y) -> x + y :: acc) in
  let tail = List.tl_exn m in 
  let hd_tail = List.hd_exn tail in
  hd_tail

(* 
 * Here is how Option.return is defined - no rocket science here.
 * It is called return because it is injecting (returning) a "regular" value TO the monad 
 * The name is backwards perhaps since it sounds like it could be returning *from* monad-land
 *)
let return' (v : 'a) : 'a option = Some v

(* Let us write out the bind calls (expand the macro) to show why the macro is more readable: *)
let ex_bind l1 l2 =
  bind (better_zip l1 l2) ~f:(fun l ->
      let m = List.fold l ~init:[] ~f:(fun acc (x,y) -> x + y :: acc) in
      bind (List.tl m) ~f:(fun tail -> 
          bind (List.hd tail) ~f:(fun hd_tail -> 
              return(hd_tail))))
(* (vs version above: *) 
let ex_bind_macro' l1 l2 =
  let%bind l = better_zip l1 l2 in 
  let m = List.fold l ~init:[] ~f:(fun acc (x,y) -> x + y :: acc) in
  let%bind tail = List.tl m in 
  let%bind hd_tail = List.hd tail in
  return(hd_tail)
(* 
  * Observe in the above that we can invoke functions which are in monad-land like zip above
  * And, we can also invoke non-option-returning functions like List.fold; no need for bind on them
  * Just make sure to keep track of whats in and whats out of monad-land - !
*)

(* Note you can't cheat and leave out the last return, you will get a type error *)
(*
let ex_bind_error l1 l2 =
  let%bind l = zip l1 l2 in 
  let m = List.fold l ~init:[] ~f:(fun acc (x,y) -> x + y :: acc) in
  let%bind tail = List.tl m in
  let%bind hd_tail = List.hd tail in
  hd_tail *)
(* type error! Both of let%bind's arguments need to be in monad-land, `t` here now that we opened Option *)

(* Note that this code is wordy, we can merge return with last let%bind: *)
let ex_bind_fixed l1 l2 =
  let%bind l = better_zip l1 l2 in 
  let m = List.fold l ~init:[] ~f:(fun acc (x,y) -> x + y :: acc) in
  let%bind tail = List.tl m in
  List.hd tail (* this is in monad-land, all good! *)


(* In other words,   
  let%bind hd_tail = List.hd tail in return hd_tl  ===  List.hd tail
  - this is in fact a *Monad Law* we will discuss below, like let x = 5 in x === 5 in normal OCaml
*)

(* Now we love pipes but this is just let-like coding; how can we use pipe syntax??

Answer: there is also pipe syntax
   * a >>= b is just an infix form of bind, it is nothing but 
     bind a b
   * a >>| b is used when b is just a "normal" function which is not returning an option.
   - the precise encodings in fact are:
     --  a >>| b is      bind a (fun x -> return (b x))
     --  a >>| b is also a >>= (fun x -> return (b x))
   - the additional "return" "lifts" f's result back into monad-land
   - the types make this difference clear:
     # (>>|);;
     - : 'a option -> ('a -> 'b) -> 'b option = <fun>
     # (>>=);;
     - : 'a option -> ('a -> 'b option) -> 'b option = <fun>
   * If you are just sequencing a bunch of function calls as above it reads better with these two pipes

   * Lets redo the example above with monad-pipes:
*)

let ex_piped l1 l2 =
  better_zip l1 l2 
  >>| List.fold ~init:[] ~f:(fun acc (x,y) -> (x + y :: acc))
  >>= List.tl
  >>= List.hd

  (* The above uses >>| when the result of the step is not in monad-land
  and so the result needs to be put back there for the pipeline 
  >>= is for the result that is in monad-land already. *)

  (* Contrast the above with exception-based code and normal OCaml pipes: *)
let ex_piped_exn l1 l2 =
    List.zip_exn l1 l2 
    |> List.fold ~init:[] ~f:(fun acc (x,y) -> (x + y :: acc))
    |> List.tl_exn
    |> List.hd_exn
  

(* A very subtle point is that the pipe notation is associating the sequencing in 
a different manner.  Here are parens added to the above, the >>= operators are 
left-associative:  *)

let ex_piped' l1 l2 =
    (
      (
        better_zip l1 l2 
        >>| List.fold ~init:[] ~f:(fun acc (x,y) -> (x + y :: acc)) 
      )
      >>= List.tl
    )
    >>= List.hd


(* Even the regular pipe |> was left-associative, and it doesn't make sense any other way
   because the first thing in the sequence is not a function and everything else is.  Here is a 
   parenthesized version of the example at top of this file to show how it was working.  *)

let _ : bool = 
  (((Map.empty(module String) 
     |> Map.set ~key: "hi" ~data: 3)
  |> Map.set ~key: "ho" ~data: 17)
  |> Map.for_all ~f:(fun i -> i > 10) )


(* There is something subtle going on here with the operator ordering..
   - We all know that a;(b;c) "is the same order as" (a;b);c (e.g. in OCaml they give same results)
   - for let and let-bind, there is an analogous principle which is a touch more complex:
      let x = a in (let y = b in c)   ===   let y = (let x = a in b) in c
       (provided x is not in c - on the left the c won't know what x is)
   - Key point: the let%bind notation is doing the former and the pipes the latter - !!
   - Monads (including Option here) should have this let-bind associative property
   - More formally this is another *monad law* for the mathematical definition of monad (more later on that)
*)

(* To make this more clear let us turn the piped version into its exact let%bind equivalent.
   Look at the top-level (outermost) >>= above to understand why this is what it is meaning *)
let ex_piped_expanded l1 l2 =
  let%bind tail = 
    let%bind m = 
      let%map l = better_zip l1 l2 in List.fold l ~init:[] ~f:(fun acc (x,y) -> (x + y :: acc)) in
    List.tl m in
  List.hd tail

(* Note let%map is the let% analog of |>> which just wraps result in return  *)

(* 
  OK it is finally time for an actual monad -- Option extended to a more general Exception monad
  This example also shows how we can define our own monads with Core.Monad.Make

  Invariant: all values in monad-land for this monad are Some/None's.

*)

module Exception = struct

  module T = struct (* We are going to include this T below here, we just need to name this stuff *)
    type 'a t = 'a option (* this is the type of monad-land, 'a is the underlying value *)
    (* return injects a normal-land computation into monad-land *)
    let return (x: 'a) : 'a t = Some x
    (* bind sequences two monad-land computations where the 2nd can use 1st's value result *)
    let bind (m: 'a t) ~(f: 'a -> 'b t): 'b t =
      match m with
      | None -> None 
      | Some x -> f x
    (* Core requires that a map operation be defined 
       - map is like bind but the f is just a normal-land function 
       - it is called "map" because if you think of the option as a 0/1 length list
         the map operation here is analogous to List.map *)
    let the_map (m: 'a t) ~(f: 'a -> 'b): 'b t = 
      bind m ~f:(fun x -> return(f x))
    let map = `Custom(the_map) (* simpler version:  `Define_using_bind *)
    (* `run` is the standard name for 
        1) enter monad-land from normal-land 
        2) run a computation in monad-land;
        3) transfer the final result back to normal-land 
        Option.run doesn't exist, it is not the full monad package *)
    type 'a result = 'a (* 'a result is the type transferred out of monad-land at end of run *)
    let run (m : unit -> 'a t) : 'a result =
      match m () with 
      | Some x -> x 
      | None -> failwith "monad failed with None"
    (* Lets get more exception-looking syntax than what is in Core.Option *)
    let raise () : 'a t = None (* we can't pass any additional payload to a raise since None has no payload; Ok/Error would though *)
    let try_with (m : 'a t) (f : unit -> 'a t): 'a t =
      match m with 
      | None -> f () 
      | Some x -> Some x
  end
  include T (* The same naming trick used here as with Comparable *)
  include Monad.Make(T) (* Core.Monad functor to add lots of extra goodies inclduing let%bind etc*)
end

(* Lets open these up now, overriding the open of Option we did above for the monad functions like bind *)
open Exception
open Exception.Let_syntax

(* Redoing the zipping example above using Exception now *)

let zip l1 l2 = match List.zip l1 l2 with Unequal_lengths -> raise () | Ok l -> return l

let ex_exception l1 l2 =
  let%bind l = zip l1 l2 in 
  let m = List.fold l ~init:[] ~f:(fun acc (x,y) -> x + y :: acc) in
  let%bind tail = List.tl m in
  let%bind hd_tail = List.hd tail in
  return(hd_tail)

(* And, we can now "run" them from normal-land as well: *)
let _ : int = run @@ fun () -> ex_exception [1;2;3] [9;8;7]

(* In general all the Option examples above work in Exception *)

(* Here is yet another example, showing how some really simple computation can be
   put in monad-land.  Note you should not do this, effect-free code can remain as-is
   This example is just to illustrate how monads sequence *)

let oneplustwo = 
  bind (return 1) 
    ~f:(fun onev -> 
        bind (return 2) 
          ~f:(fun twov -> return (onev + twov)))

(* With the let%bind macro *)

let oneplustwo' = 
  let%bind onev = return 1 in 
  let%bind twov = return 2 in 
  return (onev + twov)

let _ : int = run (fun () -> oneplustwo')

(* Let us now encode some normal OCaml code raising an exception into Exception *)

(* Here is an actual OCaml exception that is handled with try-with *)
let test_normal_ocaml x =
  try (1 + (if x = 0 then failwith "error" else 100 / x))
  with Failure _ -> 101

(* Monad near-equivalent - note the + 1 moved in, 1 must be let%bound if written exactly as above 
   Remember, the key here is it "looks" like there are side effects but it is actually all functional code *)

let test_exn_monad x =
  try_with 
    (if x = 0 then raise () else return(1 + 100 / x))
    (fun () -> return(101))

let _ : int = run @@ fun () -> test_exn_monad 4
let _ : int = run @@ fun () -> test_exn_monad 0

(* While moving the 1 + in is the right thing to do for the above code, sometimes you can't.
   First, if you just copied the normal OCaml way it would not work - the first try-with argument
     needs to be a monadic value (a Some/None here)
   Lets as an exercise keep the 1 + in the original spot with bind (using let%bind syntax)
*)

let f (x : int) =
  try_with 
    (let%bind one = return 1 in 
     let%bind ifthen = if x = 0 then raise () else return(100 / x) in
     return(one + ifthen))
    (fun () -> return(101))

(* The monad encoding starts to get crufty here.. a big downside of monads in general *)


(* *********** *)
(* More Monads *)
(* *********** *)

(* Generally a monad for us is anything matching this module type *)

module type Monadic = sig
  type 'a t (* a "wrapper" on 'a-typed data *)
  val return : 'a -> 'a t
  val bind : 'a t -> f:('a -> 'b t) -> 'b t
  val map : 'a t -> f:('a -> 'b) -> 'b t
  type 'a result
  val run : (unit -> 'a t) -> 'a result
end

(* ( Core.Monad's version also requires map but does not require run) *)
(* Let us verify our version above is indeed a monad *)

module Exception_test : Monadic = Exception

(* 
  * General principle: side effects are result "plus other stuff"
  * Monad principle: make a type which wraps underlying data with arbitrary "other stuff"
  * When you are working over that type you are "in monad land"
  * Then make the appropriate bind/return/etc for that particular wrapper
  * Finally, use monad-land like a sublanguage: hop into e.g. `Exception` when effects needed

  * We now show how the underlying monad infrastructure can encode many other effects *)


(* First it is always good for a quick look at the "zero", the no-op monad. 
   We will put an explicit Wrapped around the monadic values to be clear
   where monad-land starts and stops. *)


module Ident = struct
  module T = struct
      type 'a t = Wrapped of 'a (* Nothing but the 'a under the wrap *)
      let unwrap (Wrapped a) = a
      let bind (a : 'a t) ~(f : 'a -> 'b t) : 'b t = f (unwrap a)
      let return (a : 'a) : 'a t = Wrapped a
      let map = `Custom (fun (a : 'a t)  ~(f : 'a -> 'b) -> Wrapped(f @@ unwrap a))
      let run (a : unit -> 'a t) : 'a = unwrap @@ a ()
  end

  include T
  include Monad.Make(T)
end

(* Lets replay our stupid 1+2 example in Ident *)
open Ident
open Ident.Let_syntax
let oneplustwo = 
  bind (return 1) 
    ~f:(fun onev -> 
        bind (return 2) 
          ~f:(fun twov -> return (onev + twov)))
let oneplustwo = 
  let%bind onev = return 1 in 
  let%bind twov = return 2 in 
  return (onev + twov)


(* ******************************** *)
(* Print / Output / Writer / Logger *)
(* ******************************** *)

(* 
* There is a family of monads where the effect is "return more stuff on the side"
  i.e. the `'a t` type is `'a * ... more stuff ...`
* Here is one such simple monad, a Logger which accumulates log messages
* A common name for these are "writers" since they are writing things
*)
module Logger = struct
  module T = struct
    type log = string list (* we will tack a string list on the side here *)
    type 'a t = 'a * log
    (* Beyond the type, the key to a monad is what bind/return are *)
    (* The key idea of the logger is to append the logs from the two sequenced computations *)
    let bind (m : 'a t) ~(f : 'a -> 'b t): 'b t =
      let (x,l') = m in 
      let (x',l'') = f x in (x',l'@l'')
    let map = `Define_using_bind
    let return (x : 'a) : 'a t = (x, []) (* empty log in a return *)

  end
  include T
  include Monad.Make(T)
  type 'a result = 'a * log
  let run (m: unit -> 'a t): 'a result = m ()
  let log msg : unit t = ((), [msg])
end

module Logger_test = (Logger : Monadic) (* verify it is a monad *)

open Logger
open Logger.Let_syntax

(* A simple example *)

let log_abs n = 
  if n >= 0 
  then let%bind () = log "positive" in return n
  else let%bind () = log "negative" in 
       let%bind () = log "indeed" in 
       let%bind () = log "yup" in return (-n)

(* another simple example, add log messages to 1+2 example above *)
let oneplustwo_logged = 
  let%bind () = log "Starting!" in
  let%bind onev = return 1 in 
  let%bind twov = return 2 in 
  let%bind r = return (onev + twov) in
  let%bind () = log "Ending!" in
  return(r)



(* **************** *)
(* Input aka Reader *)
(* **************** *)

(* 
 * All the monads up to now were "first order", the carrier type has no function types
 * Monads get *really* useful with higher-order monads, *functions* in the .t type
 * They also get much more subtle to decipher what is actually happening
 * The simplest example is probably "Reader"
 * Don't think of it as "input", it is more like "global constants"

 * The intuition is we are going to pass the constants down so they are always accessible
 *)


module Reader = struct
  module T = struct
    (* 
   * In Logger above we *returned* extra stuff, here we are *passing in* extra stuff 
   * Here we let the stuff be arbitrary, of type 'e for environment
  *)
    type ('a, 'e) t = ('e -> 'a) (* as usual, 'a is the underlying data *)
    (* bind needs to return a `'e -> 'a` so it starts with `fun e -> ...`
       This means it gets in the envt e from its caller
       bind's job is then to pass on the envt to its two sequenced computations *)
    let bind (m : ('a, 'e) t) ~(f : 'a -> ('b,'e) t) : ('b, 'e) t = 
      fun (e : 'e) -> ((f (m e)) e) (* Pass the envt e both to m, and to f *)
    let map = `Define_using_bind
    (* return injects non-monadic code into monad: code not using the envt *)
    let return (x : 'a) : ('a, 'e) t = fun (_: 'e) -> x
    (* The monad is only interesting if we have an accessor for the envt
       - observe from the type we will be able to let%bind sequence this so will work *)
    let get () : ('e, 'e) t = fun (e : 'e) -> e 
    (* To run we need to feed in an initial environment of type 'e *)
    let run (m : ('a, 'e) t) (e : 'e) = m e
  end
  include T
  include Monad.Make2(T) (* Make2 is where there are *2* type parameters on t *)
end

(* Examples *)
open Reader
open Reader.Let_syntax

(* Here is a simple environment type, think of it as a set of global constants *)
type globals = {
  name: string;
  age: int;
}

let is_retired = 
  let%bind {age;_} = get() in return (age > 65)

(* Note the above is a function due to `fun e` in monad bind;
   need to run it to execute the code *) 

let _ : bool = run is_retired {name = "Gobo"; age = 88}

(* lets expand the let%bind to a bind: *)   
let is_retired' = 
  bind (get()) (fun r -> return (r.age > 65))

(* Now lets inline the bind definition to help clarify: *)

let is_retired'' = 
  fun e -> (fun r -> return (r.age > 65)) ((get()) e ) e

(* Monads, mathematically *)

(* 
  * To *really* be a monad you need to satisfy some invariants:

    1) bind (return a) ~f  ===  f a 
    2) bind a ~f:(fun x -> return x)  ===  a
    3) bind a (fun x -> bind b ~f:(fun y -> c))  ===  
       bind (bind a ~f:(fun x -> b)) ~f:(fun y -> c)
       (where c doesn't use x)

    Let us focus on the equivalent let%bind versions which are easier to read:
    1) let%bind x = return(a) in f x  ===  f a
    2) let%bind x = a in return(x)  ===  a
    3) let%bind x = a in let%bind y = b in c ===
       let%bind y = (let%bind x = a in b) in c
  * (Note "===" here means we can replace one with the other and notice no difference)
  * These are called the "Monad Laws"
  * The last one is the trickiest but we hit on it earlier, it is associativity of bind
  * The first two are mostly intuitive properties of injecting normal values into a monad
  * Note the laws are more invariants, and can be concretely be tested on examples.
  * All of the monads we are doing here should "pass" any such invariant tests
*)

(* We in fact used all the monad laws on the initial Option example above.  
   We will review that now. *)
open Option
open Let_syntax

(* here is the version above we had that mostly used let%bind *)   
let ex_initial l1 l2 =
    let%bind l = zip l1 l2 in 
    let m = List.fold l ~init:[] ~f:(fun acc (x,y) -> x + y :: acc) in
    let%bind tail = List.tl m in 
    let%bind hd_tail = List.hd tail in
    return(hd_tail)

(* The "let m" (non-bind) here could be changed to a let%bind if we wrapped
  the defined value in a return -- this is using monad law 1) right-to-left. 
  (the "a" in the law is the List.fold .. which we abbreviated m with the let) *)    
let ex_first_law_applied l1 l2 =
    let%bind l = zip l1 l2 in 
    let%bind m = return(List.fold l ~init:[] ~f:(fun acc (x,y) -> x + y :: acc)) in
    let%bind tail = List.tl m in 
    let%bind hd_tail = List.hd tail in
    return(hd_tail)
  
(* We also noticed that the last let%bind followed by return was 
   just a no-op so we could have done the following which is 
   using monad law 2) right-to-left (letting a be `List.hd tail` )*)    
let ex_second_law_applied l1 l2 =
    let%bind l = zip l1 l2 in 
    let%bind m = return(List.fold l ~init:[] ~f:(fun acc (x,y) -> x + y :: acc)) in
    let%bind tail = List.tl m in 
    List.hd tail
    
(* Lastly we observed that pipes naturally associate like the rhs of the 
   third monad law, and the let%bind natural structure above is the lhs.
   So, with several applications of the third law left-to-right on the 
   previous we get this version.*)    
 let ex_third_law_applied l1 l2 =
    let%bind tail = 
      let%bind m = 
        let%bind l = zip l1 l2 in return(List.fold l ~init:[] ~f:(fun acc (x,y) -> (x + y :: acc))) in
      List.tl m in
    List.hd tail

(* which is better written as the pipe version (below is identical to
   the above when the macros are expanded) *)

let ex_piped_version_of_previous l1 l2 =
  zip l1 l2 
  >>= fun l -> return @@ List.fold l ~init:[] ~f:(fun acc (x,y) -> (x + y :: acc))
  (* .. Better equivalent syntax for above:   
  >>| List.fold ~init:[] ~f:(fun acc (x,y) -> (x + y :: acc))
  *)
  >>= List.tl
  >>= List.hd

(* Here is a smaller example of the third law to make it a bit easier to see *)
  let ex_before_third_law_simpler l1 l2 =
    let%bind l = zip l1 l2 in 
    let%bind tail = List.tl l in
     return(tail)
     
  let ex_after_third_law_simpler l1 l2 =
      let%bind tail = 
        (let%bind l = zip l1 l2 in List.tl l) in 
        return(tail)

(* the following code is identical to ex_after_third_law_simpler, just different macros used *)
  let ex_after_third_law_simpler_piped l1 l2 =
      zip l1 l2
      >>= List.tl
      >>= return

(* ***** *)
(* State *)
(* ***** *)

(* Before doind the monad lets write some explicit threading code to show how its working.
   Key idea of state monad is you always get passed current state, return new state. *)

(* previous hand-over fist map state passing functionally *)
let _ : bool = Map.empty(module String) 
               |> Map.set ~key: "hi" ~data: 3 
               |> Map.set ~key: "ho" ~data: 17
               |> Map.for_all ~f:(fun i -> i > 10)

(* Lets regularize it to be a bit more how the state monad works: each Map op 
   gets old map state, returns PAIR of value if any and new state *)
let map_set ~key ~data = fun m -> ((),Map.set m ~key ~data)
let map_for_all ~f = fun m -> ((Map.for_all m ~f),m)

let _ : bool = 
  let m = Map.empty(module String) in
  let ((),m') = (fun m -> map_set m ~key: "hi" ~data: 3) m in
  let ((),m'') = (fun m -> map_set m ~key: "hi" ~data: 3) m' in
  let (b,_) = (fun m -> map_for_all m ~f:(fun i -> i > 10)) m''
in b

(* Let us do a simple version of State, the whole state is just one value of type 's.
   This models a program with only one ref cell
*)
module State = struct
  module T = struct
    (* Here is the monad type: 
       - 's is the type of the stateful value we are keeping
       - We need to *thread* the 's through all computations just like we informally did above
       - So, pass the 's in like Reader *and* return it like Logger *)
    type ('a, 's) t = 's -> 'a * 's
    (* Let us now construct bind.
       1) Like Reader, the result is a fun s : 's -> ... since we pass in s
       2) First we pass e to the first computation x
       3) x returns a pair with a potentially **different** state, s'
       4) Then, thread that latest state on to f so it gets any state updates in s'
    *)
    (* expanding type abreviations, x : 's -> 'a * 's
                                    f : 'a -> ('s -> 'b * 's)
                                    return 's -> 'b * 's : *)
    let bind (x : ('a, 's) t) ~(f: 'a -> ('b, 's) t) : ('b, 's) t =
      fun (s : 's) -> let (x', s') = x s in (f x') s'
    let return (x : 'a) : ('a, 's) t = fun v -> (x, v) (* just pass on the state we got in *)
    let map = `Define_using_bind
    type ('a, 's) result = 'a * 's
    (* Run needs to get passed in an init state *)
    let run (e : ('a, 's) t) ~(init : 's): ('a, 's) result = e init
    let set (s : 's) =
      fun (_ : 's) -> ((),s) (* return () as value, toss old state, make it s *)
    let get () =
      fun (s : 's) -> (s,s) (* return the state s AND propagate s onward *)
  end
  include T
  include Monad.Make2(T)
end

open State
open State.Let_syntax;;


(* Here is an OCaml state example for review, side effect is in compiler *)
let r = ref 0 in
let rv = !r in
let () = r := rv + 1 
in !r;;

(* Here is the same example re-coded in the State monad *)

let simple_state () = 
  (* let r = ref 0 is in the `run` below - initial value at run launch *)
  let%bind rv = (get() : (int, int) t) in
  let%bind () = (set(rv + 1) : (unit, int) t) in 
  (get() : (int, int) t)

let _ = run (simple_state ()) ~init:0

(* turning the above let%bind into the underlying bind to be more explicit *)

let simple_state () = 
  (* let r = ref 0 is implicit - initial value at run time *)
  bind (get()) ~f:(fun rv ->
  bind (set(rv + 1)) ~f:(fun () ->get()))

  let _ = run (simple_state ()) ~init:0


(* Here is a bit larger example using statefulness of State 
   -- sum the elements of a list with a "mutable" counter *)

let rec sumlist = function
  | [] -> get ()
  | hd :: tl -> 
    let%bind n = get () in 
    let%bind () = set (n + hd) in
    sumlist tl

let _ : (int,int) State.result  = run (sumlist [1;2;3;4;5]) ~init:0

(* 
 * A more general State monad
   - The store is an arbitrary Map from strings to values
   - Think of the Map as mapping (global) variable names to the values
   - We will have one more type parameter as we let the heap be
     any (one) type
   - Note a real heap is harder, can have values of different types there.

   We will not cover this in lecture as it is nearly identical to the above
 *)

module State_map = struct
  module T = struct
    type 'v m = (string, 'v, String.comparator_witness) Map.t (* shorthand name for map w/string keys anf 'v values *)
    type ('a, 'v) t = 'v m -> 'a * 'v m
    let bind (x : ('a, 'v) t) ~(f: 'a -> ('b,'v) t) : ('b,'v) t =
      fun (m : 'v m) -> let (x', m') = x m in f x' m'
    let return (x : 'a) : ('a, 'v) t = fun m -> (x, m)
    let map = `Define_using_bind
    type 'a result = 'a 
    (* Run needs to pass in an empty state *)
    let run (c : ('a, 'v) t) : 'a result = 
      let mt_map = Map.empty(module String) in fst (c mt_map)
    let set (k : string) (v : 'a) : (unit, 'v) t =
      fun (s : 'a m) -> ((),Map.set ~key:k ~data:v s)
    let get (r : string) : ('a, 'v) t =
      fun (s : 'a m) -> (Map.find_exn s r, s)
    let dump : 'a m -> 'a m * 'a m =
      fun (s : 'a m) -> (s, s)    
  end
  include T
  include Monad.Make2(T)
end

open State_map
open State_map.Let_syntax

let sumlist l =
  let%bind () = set "r" 0 in
  let rec sum = function
    | [] -> get "r"
    | hd :: tl -> 
      let%bind n = get "r" in 
      let%bind _ = set "r" (n + hd) in
      sum tl
  in sum l

let _ : int = run (sumlist [1;2;3;4;5])

(* Let us revisit the above Map example to show how hand-over-fist is behind the scenes *)
(* Here is what we had above *)
let _ : bool = Map.empty(module String) 
               |> Map.set ~key: "hi" ~data: 3 
               |> Map.set ~key: "ho" ~data: 17
               |> Map.for_all ~f:(fun i -> i > 10)

(* Let's put this back in let form to make clear all the hand-over-fist passing we had to do *)
let _ : bool = 
  let m0 = Map.empty(module String) in
  let m1 = Map.set ~key: "hi" ~data: 3 m0 in 
  let m2 = Map.set ~key: "ho" ~data: 17 m1 in
  Map.for_all ~f:(fun i -> i > 10) m2

(* OK now lets use our State instead. Observe that there is no m1/m2 threading needed. *)

let map_eg_state =
  let%bind () = set "hi" 3 in
  let%bind () = set "ho" 17 in
  let%bind d = dump in (* dump dumps the whole state contents out, needed for the Map.forall *)
  return(Map.for_all ~f:(fun i -> i > 10) d)

let _ = run map_eg_state 

  let rec sum = function
    | [] -> get "r"
    | hd :: tl -> 
      let%bind n = get "r" in 
      let%bind _ = set "r" (n + hd) in
      sum tl


(* Type-directed monads 
 * Pretty much any OCaml type has a natural monad behind it
 * Some are more useful than others
 * Let us consider a monad where t is 'a list, what can that do?
*)

type 'a t = 'a list
(* Let us just try to write non-trivial bind/return that type check *)

let bind (m : 'a t) ~(f : 'a -> 'a t) : 'a t = 
  List.join (List.map m ~f)

let return (v : 'a) : 'a t = [v]


(* ************** *)
(* Nondeterminism *)
(* ************** *)

(* A result is a *list* of values, and subsequent computations try all of them etc *)
(* It allows some programming patterns to be much more simply coded *)

(* Note we will just touch on this in lecture *)
module Nondet = struct
  module T = struct
    type 'a t = 'a list
    let return (x : 'a) : 'a t = [x]
    let rec bind (m : 'a t) ~(f : 'a -> 'b t) : 'b t =
      List.join @@ List.map m ~f
    let map = `Define_using_bind

    type 'a result = 'a list
    let run (m : 'a t) : 'a result = m

    let zero : 'a t = []
    let either (a : 'a t) (b : 'a t): 'a t = a @ b
  end
  include T
  include Monad.Make(T)
end

open Nondet
open Nondet.Let_syntax

(* simple example *)
let _ : int t = let%bind x = [2;6] in [x;x + 1]

(* All divisors of a number *)

let divisors (n : int) : int t = 
  let rec _divisors n count = 
    if count = 1 then return(1)
    else 
      either (* nondeterminism - union up both results *)
        (if n mod count = 0 then return count else zero)
        (_divisors n (count-1))
  in _divisors n n

(* powerset of a set (representing set as a list here for simplicity) *)

let rec powerset (l : 'a list) : 'a list t =
  match l with
  | [] -> return []
  | hd :: tl -> let%bind pow_member = powerset tl in
    either (* note that each one of these recursive calls itself can return several different answers *)
      (return pow_member)
      (return @@ hd :: pow_member)

(* all permutations of a list *)

let rec insert (x : 'a)  (l : 'a list) : 'a list t =
  either
    (return (x :: l))
    (match l with
     | [] -> zero
     | hd :: tl -> let%bind l' = insert x tl in return (hd :: l'))

let rec permut (l : 'a list) : ('a list t) =
  match l with
  | [] -> return []
  | hd :: tl -> let%bind l' = permut tl in insert hd l'

let _ : int list list = run (permut [1;2;3])

(* Continuations, super briefly *)

type 'a t = ('a -> 'a result) -> 'a result
(* 
   - the ('a -> 'a result) is the continuation, the "rest of the computation"
   - Notice the type, we are one level higher in the function type now
   - Coroutines are a variation on the continuation monad where "rest" is the other routines
 *)


(* Composing monads *)

(* 
 * Suppose you need both state and exceptions, what to do?
 * Solution is to compose the types/binds/returns in a single monad
 * Monad transformers are functors that take monads to monads to do this
 * Here we are just going to manually compose

 * Note that one drawback with monads is the subtleties of composing effects 

*)

(* recall the types of Exception and State 
   (lets use State to stand for State for simplicity - just one cell holding an int)
*)

type 'a except = 'a Option.t
type 'a state = int -> 'a * int

(* There are *two* ways to compose types, depending on which type is on the "outside"
   * option 1: state on the outside *)

type 'a state_except = int -> ('a Option.t) * int

(* Option 2: option on the outside: *)
type 'a except_state = (int -> 'a * int) Option.t

(* 
 * The second one tosses the state in the event of an exception
 * The first one keeps it 
 * You are used to the first kind, state never gets tossed in usual PL's.
 * Could even combine both: two types of exceptions, one keeps one tosses state
 *)

