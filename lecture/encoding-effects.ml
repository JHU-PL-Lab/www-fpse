(* ***************************** *)
(* Encoding effects functionally *)
(* ***************************** *)

(* Aka "A Journey through Monad Land" *)

open Core

(*
  * We have seen so far the advantages of functional programming
  * But, sometimes it is a large handicap to not have side effects
  * A middle ground is possible: *encode* effects using purely functional code
    - we already saw a bit of this with the option type replacing exceptions
    - also the use of piping such as 
*)

let _ : bool = Map.empty(module String) 
               |> Map.set ~key: "hi" ~data: 3 
               |> Map.set ~key: "ho" ~data: 17
               |> Map.for_all ~f:(fun i -> i > 10)

(*   etc which is a concise "hand over fist passing" encoding 
     of what would normally be a mutable structure 

  * Idea: make a more structured encoding which is not informal like the above
  * Think of it as defining a macro language inside a language: "monad-land"
  * Will allow functional code to be written which "feels" close to effectful code
  * But it still will preserve the referential transparency etc
  * The mathematical basis for this is a structure called a *monad*.

*)

(* ******************* *)
(* Encoding Exceptions *)
(* ******************* *)

(* 
  * Let's start with using 'a option's Some/None to encode exception effects
  * We already saw many examples of this
  * Here we want to regularize/generalize it to make an offical monad.
  * First recall how we had to "forward" a `None` if an e.g. List operation failed
*)

(* zip in fact doesn't return Some/None, let us convert it to that format here *)
let zip l1 l2 = match List.zip l1 l2 with Unequal_lengths -> None | Ok l -> Some l

(* 
  * Here is an artificial example of lots of hand-over fist passing of options. 
  * Several operations can fail with a None, and in each case we need to bubble that None to the top.
  * Yes the code is ugly!
*)
let ex l1 l2 =
  match zip l1 l2 with 
  | Some(l) -> 
    begin
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

(* 
  * Now let us regularize this with a monad
  * Think of a monad as a wrapper on regular computations
  * "In Monad-land" here is an option-tagged computation
  * "Out of the monad" is when we are not option-tagged
*)

(* 
 * The key operation of a monad is `bind` 
 * For Option it already exists as Option.bind
 * Here is its code for reference: 
 *)

let bind' (opt : 'a option) ~(f : 'a -> 'b option) : ('b option) = 
  match opt with 
  | None -> None 
  | Some v -> f v;;

(* bind does the match "for free" compared to above 
    - if the zip failed with `None the function is ignored
    - if it succeeds the Some removed and the underlying data passed to f *)
bind' (zip [1;2] [3;4]) ~f:(function (l,r)::tl -> Some(l));;

(* 
  * bind more generally *sequences* two side effects
  * besides the bubbling of None's it is a lot like a "let" expression.
    -  bind code1 ~f:code2  first runs code1, and if it is non-None runs code2 on which can use underyling result of code1.
  * This suggests a macro:
  `let%bind x = e1 in e2`  macro expands to `bind e1 ~f:(fun x -> e2)`
  * Using the macro, code can look more like regular code with implicit effects
  * We have pushed monad-land into hiding a bit
*)

(* Note we need to open a module to enable macro for Option.bind 
   And, need #require "ppx_jane" for the macro to expand *)

open Option (* don't do this at home (tm) *)
open Option.Let_syntax

let%bind (l,r)::tl = zip [1;2] [3;4] in Some(l);;


(* 
 * OK now let us redo the above example with bind (using the macro version) 
 * This code looks more readable than the original, right?? 
 *)

let ex_bind_macro l1 l2 =
  let%bind l = zip l1 l2 in 
  let m = List.fold l ~init:[] ~f:(fun acc (x,y) -> x + y :: acc) in
  let%bind tail = List.tl m in 
  let%bind hd_tail = List.hd tail in
  return(hd_tail) (* "return to the monad" - here that means wrap in Some(..) *)

(* 
 * Here is what Option.return above is
 * It is called return because it is injecting (returning) a "regular" value into the monad 
 * I have to say the name seems backwards to me but it is the traditional name
 * (in fact it has a new name in Haskell recently)
*)
let return' (v : 'a) : 'a option = Some v


(* Let us write out the bind calls (expand the macro) to show why the macro is better: *)
let ex_bind l1 l2 =
  bind (zip l1 l2) ~f:(fun l ->
      let m = List.fold l ~init:[] ~f:(fun acc (x,y) -> x + y :: acc) in
      bind (List.tl m) ~f:(fun tail -> 
          bind (List.hd tail) ~f:(fun hd_tail -> 
              return(hd_tail))))

(* 
  * Observe in the above that we can invoke functions which are in monad-land like zip above
  * And, we can also invoke regular functions like List.fold; no need for bind on them
  * Just make sure to keep track of whats in and whats out of monad-land - !
*)

(* Note you can't cheat and leave out the last return, you will get a type error *)

let ex_bind_error l1 l2 =
  let%bind l = zip l1 l2 in 
  let m = List.fold l ~init:[] ~f:(fun acc (x,y) -> x + y :: acc) in
  let%bind tail = List.tl m in
  let%bind hd_tail = List.hd tail in
  hd_tail
(* type error! Both of let%bind's arguments need to be in monad-land, Option.t here *)

(* Note that you *could* leave out the return though merge it with last let%bind: *)
let ex_bind_fixed l1 l2 =
  let%bind l = zip l1 l2 in 
  let m = List.fold l ~init:[] ~f:(fun acc (x,y) -> x + y :: acc) in
  let%bind tail = List.tl m in
  List.hd tail (* this is in monad-land, all good! *)

(* Equivalent pipe version syntax 
   * a >>= b is just an infix form of bind, it is nothing but bind a b
   * a >>| b is used when b is just a "normal" function which is not returning an option.
   - encodings:
     --  a >>| b is      bind a (fun x -> return (b x))
     --  a >>| b is also a >>= (fun x -> return(b x))
   - the additional "return" "lifts" f's result back into monad-land
   - the types make this difference clear:
     # (>>|);;
     - : 'a option -> ('a -> 'b) -> 'b option = <fun>
     # (>>=);;
     - : 'a option -> ('a -> 'b option) -> 'b option = <fun>
   * If you are just sequencing a bunch of function calls as above it reads better with these two pipes
*)

let ex_piped l1 l2 =
  zip l1 l2 
  >>| List.fold ~init:[] ~f:(fun acc (x,y) -> (x + y :: acc))
  >>= List.tl
  >>= List.hd

  (* The above uses >>| when the result of the step is not in monad-land
  and so the result needs to be put back there for the pipeline 
  >>= is for the result that is in monad-land already. *)

(* A subtle point is that the pipe notation is associating the sequencing in 
a different order.  Here is parens added to the above *)

let ex_piped' l1 l2 =
  ((
    (zip l1 l2 
  >>| List.fold ~init:[] ~f:(fun acc (x,y) -> (x + y :: acc))
    )
  >>= List.tl)
  >>= List.hd)

(*
   - We all know that a;(b;c) "is the same order as" (a;b);c (e.g. in OCaml they give same results)
   - for let, the rule is a bit more convoluted:
      let x = a in let y = b in c   =   let y = (let x = a in b) in c
       (provided x is not in c)
   - the let%bind notation is doing the former and the pipes the latter.
   - Note that not all monads in OCaml have this associative property but they *should*
   - the mathematical notion of a monad must have this, it is a *monad law* (more later)

*)

(* To show this let us turn the piped version into let%bind version: *)
let ex_piped_expanded l1 l2 =
  let%bind tail = 
    let%bind m = 
      let%map l = zip l1 l2 in List.fold l ~init:[] ~f:(fun acc (x,y) -> (x + y :: acc)) in
    List.tl m in
  List.hd tail

(* Note let%map is the let% analogue of |>> which just wraps resuult in return  *)


(* 
  * OK it is finally time for a "real" monad
  * Option extended to a more general Exception monad
  * This example also shows how we can define our own monads with Base.Monad.Make
*)

module Exception = struct

  module T = struct 
    type 'a t = 'a Option.t
    (* return injects a normal-land computation into monad-land *)
    let return (x: 'a) : 'a t = Some x
    (* bind sequences two monad-land computations where the 2nd can use 1st's result *)
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
    type 'a result = 'a 
    (* `run` is the standard name for "enter monad-land from normal-land" function 
        and process the result back into normal-land 
        Option.run doesn't exist, it is not the full monad package *)
    let run (m : 'a t) : 'a result =
      match m with 
      | Some x -> x 
      | None -> failwith "monad failed with None"
    (* Some more exception-looking syntax; also not in Core.Option *)
    let raise () : 'a t = None
    let try_with (m : 'a t) (f : unit -> 'a t): 'a t =
      match m with 
      | None -> f () 
      | Some x -> Some x
  end
  include T (* The same naming trick used here as with Comparable *)
  include Monad.Make(T) (* Base.Monad functor to add lots of extra goodies *)
end

open Exception
open Exception.Let_syntax

(* Redoing the previous example we did on Option using Exception now *)
let ex_exception l1 l2 =
  let%bind l = zip l1 l2 in 
  let m = List.fold l ~init:[] ~f:(fun acc (x,y) -> x + y :: acc) in
  let%bind tail = List.tl m in
  let%bind hd_tail = List.hd tail in
  return(hd_tail)

(* And, we can "run" them from normal-land as well: *)
let _ : int = run @@ ex_exception [1;2;3] [9;8;7]

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

let _ : int = run oneplustwo'

(* Let us encode some normal OCaml code raising an exception *)

let test_normal_ocaml x =
  try (1 + (if x = 0 then failwith "error" else 100 / x))
  with Failure _ -> 101

(* Monad near-equivalent - note the + 1 moved in, 1 must be bound if written exactly as above *)

let test_monad x =
  try_with 
    (if x = 0 then raise () else return(1 + 100 / x))
    (fun () -> return(101))

let _ : int = run @@ test_monad 4
let _ : int = run @@ test_monad 0

(* While moving the 1 + in is the right thing to do for the above code, sometimes you can't..
   Lets as an exercise keep the 1 + in the original spot with bind (using let%bind syntax)
*)

let f (x : int) =
  try_with 
    (let%bind one = return 1 in 
     let%bind ifthen = if x = 0 then raise () else return(100 / x) in
     return(one + ifthen))
    (fun () -> return(101))

(* The monad encoding starts to get a little crufty here.. a downside of monads *)


(* *********** *)
(* More Monads *)
(* *********** *)

(* Generally a monad is anything matching this module type signature *)

module type Monadic = sig
  type 'a t (* a "wrapper" on 'a-typed data *)
  val return : 'a -> 'a t
  val bind : 'a t -> f:('a -> 'b t) -> 'b t
  type 'a result
  val run : 'a t -> 'a result
end

(* (Base.Monad's version also requires map but does not require run) *)
(* Let us verify our version above is indeed a monad *)

module Exception_test = (Exception : Monadic)

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
      let run (a : 'a t) : 'a = unwrap a
  end

  include T
  include Monad.Make(T)
end

open Ident
open Ident.Let_syntax
let oneplustwo = 
  let%bind onev = return 1 in 
  let%bind twov = return 2 in 
  return (onev + twov)


(* ******************************** *)
(* Print / Output / Writer / Logger *)
(* ******************************** *)

(* 
* There is a family of monads where the effect is "return more stuff on the side"
  i.e. the `'a t` type is `'a * ... stuff ...`
* Here is one such simple monad, a Logger which accumulates log messages
* A common name for these is "writer" as that is the Haskell library name.  
*)
module Logger = struct
  module T = struct
    type log = string list (* we will tack a string list on the side here *)
    type 'a t = 'a * log
    (* Beyond the type, the key to a monad is what bind/return are *)
    (* The key for a logger is to append the logs from the two sequenced computations *)
    let bind (m : 'a t) ~(f : 'a -> 'b t): 'b t =
      let (x,l') = m in 
      let (x',l'') = f x in (x',l'@l'')
    let map = `Define_using_bind
    let return (x : 'a) : 'a t = (x, [])

  end
  include T
  include Monad.Make(T)
  type 'a result = 'a * log
  let run (m: 'a t): 'a result = m 
  let log msg : unit t = ((), [msg])
end

module Logger_test = (Logger : Monadic) (* verify again it is a monad *)

open Logger
open Logger.Let_syntax

(* A simple example *)

let log_abs n = 
  if n >= 0 
  then let%bind _ = log "positive" in return n
  else let%bind _ = log "negative" in return (-n)

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
 * The simplest example is probably "Reader"
 * Don't think of it as "input", it is more like a "global "environment of values you get implicitly
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
      fun (e : 'e) -> (f (m e) e) (* Pass the envt e to m, and to f! *)
    let map = `Define_using_bind
    let return (x : 'a) = fun (_: 'e) -> x (* not using the envt here *)
    let get () : ('e, 'e) t = fun (e : 'e) -> e (* grab the envt here *)
    let run (m : ('a, 'e) t) (e : 'e) = m e
  end
  include T
  include Monad.Make2(T) (* Make2 is where there are *2* type parameters on t *)
end

(* Examples *)
open Reader
open Reader.Let_syntax

(* First let us replay the above 1+2 example
   Observe how the let-defined value below is a function
   -- it is waiting for the envt to get passed in. *)

let oneplustwo_again = 
  let%bind onev = return 1 in 
  let%bind twov = return 2 in 
  return (onev + twov)

(* Now let us actually use the monad *)
(* Here is a simple environment type, think of it as global constants *)
type d = {
  name: string;
  age: int;
}

let is_retired = 
  let%bind r = get() in return (r.age > 65)

(* again the above is just a function; need to run it to execute the code *)  

let _ : bool = run is_retired {name = "Gobo"; age = 88}

(* Monads, mathematically *)

(* 
  * To *really* be a monad you need to satisfy some invariants:

    1) bind (return a) ~f  =  f a 
    2) bind a ~f:(fun x -> return x)  =  a
    3) bind a (fun x -> bind b ~f:(fun y -> c))  =  
       bind (bind a ~f:(fun x -> b)) ~f:(fun y -> c)

    equivalent let%bind versions:
    1) let%bind x = return(a) in f a  =  f a
    2) let%bind x = a in return(x)  =  a
    3) let%bind x = a in let%bind y = b in c =
       let%bind y = (let%bind x = a in b) in c
  * (Note "=" here means we can replace one with the other and notice no difference)
  * These are called the "Monad Laws"
  * The last one is the trickiest but we hit on it earlier, it is associativity of bind
  * The first two are mostly intuitive properties of injecting normal values into a monad
  * Note the laws are more invariants, and can be concretely be tested on examples.
  * All of the monads we are doing here should "pass" any such invariant tests
*)

(* We in fact used all the monad laws on the initial Option example above.  
   We will review that now. *)

(* here is the version above we had that mostly used let%bind *)   
let ex_initial l1 l2 =
    let%bind l = zip l1 l2 in 
    let m = List.fold l ~init:[] ~f:(fun acc (x,y) -> x + y :: acc) in
    let%bind tail = List.tl m in 
    let%bind hd_tail = List.hd tail in
    return(hd_tail)

(* The "let m" (non-bind) here could be changed to a let%bind if we wrapped
  the defined value in a return -- this is using monad law 1) right-to-left. *)    
let ex_first_law_applied l1 l2 =
    let%bind l = zip l1 l2 in 
    let%bind m = return(List.fold l ~init:[] ~f:(fun acc (x,y) -> x + y :: acc)) in
    let%bind tail = List.tl m in 
    let%bind hd_tail = List.hd tail in
    return(hd_tail)
  
(* We also noticed that the last let%bind followed by return was 
   just a no-op so we could have done the following which is 
   using monad law 2) right-to-left *)    
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
  >>= return(List.fold ~init:[] ~f:(fun acc (x,y) -> (x + y :: acc)))
  >>= List.tl
  >>= List.hd

(* Since it is a handful to sort out how that is the third law 
   lets hack this down into a smaller example.  *)
  let ex_before_third_law_simpler l1 l2 =
    let%bind l = zip l1 l2 in 
    let%bind tail = List.tl l in
     return(tail)
     
  let ex_after_third_law_simpler l1 l2 =
      let%bind tail = 
        (let%bind l = zip l1 l2 in List.tl l) in 
        return(tail)

  let ex_after_third_law_simpler_piped l1 l2 =
      zip l1 l2
      >>= List.tl
      >>= return

(* ***** *)
(* State *)
(* ***** *)

(* Let us start with a simple version, the whole state is just one integer.
   Just imagine that int was a `Map` for a more general State (which we do below)
*)

module State_int = struct
  module T = struct
    (* Here is the monad type: we need to *thread* the int through all computations
       So, pass the int in like Reader *and* return it like Logger *)
    type 'a t = int -> 'a * int
    (* Let us now construct bind.
       1) Like Reader, the result is a fun i : int -> ... since we pass in i
       2) First we pass i to the first computation x
       3) x returns a pair with a potentially **different** state, i'
       4) Now the key to being truly stateful is to thread that latest state on to f
    *)
    let bind (x : 'a t) ~(f: 'a -> 'b t) : 'b t =
      fun (i : int) -> let (x', i') = x i in (f x') i'
    let return (x : 'a) : 'a t = fun i -> (x, i)
    let map = `Define_using_bind
    type 'a result = 'a * int
    (* Run needs to pass in an initial i, 0 *)
    let run (i : 'a t) : 'a result = i 0
    let set (n : int) =
      fun (_ : int) -> ((),n) (* return () as value, CHANGE state to n *)
    let get () =
      fun (n : int) -> (n,n) (* return the state n AND propagate n as state *)
(* Lets also build in ++ for fun *)
      let inc () : 'a t = 
        fun (n : int) -> (n+1,n+1) 
  
  end
  include T
  include Monad.Make(T)
end

open State_int
open State_int.Let_syntax

(* Here is an OCaml example of how state is implicitly threaded along *)

let r = ref 0 in
let () = r := !r + 1 in
let result = !r in result (* r implicitly has latest value *)

(* Here is the same example in the State_int monad *)

let simple_state () = 
  (* let r = ref 0 is implicit - initial value at run time *)
  let%bind rv = (get() : int t) in
  let%bind () = (set(rv + 1) : int t) in
  let%bind result = (get() : int t) in return(result)

run @@ simple_state ();;

(* inlining the above let%bind *)

let simple_state () = 
  (* let r = ref 0 is implicit - initial value at run time *)
  bind (get()) ~f:(fun rv ->
  bind (set(rv + 1)) ~f:(fun () ->
  bind (get()) ~f:(fun result -> return(result))))

run @@ simple_state ();;


(* Here is a bit larger example using statefulness of State_int *)

let rec sumlist = function
  | [] -> get ()
  | hd :: tl -> 
    let%bind n = get () in 
    let%bind _ = set (n + hd) in
    sumlist tl

let _ : int State_int.result  = run (sumlist [1;2;3;4;5])


(* Let us try to write inc ourselves using the State_int monad's set/get 
   It can't just be a normal-land function, it must be in monad-land to use side effect 
   Note we also can't write `set (get() + 1)` because get is in monad-land and + is not!
*)

let bad_inc = set ( get() + 1) (* type error ! *)

let our_inc () =
  let%bind cur = get () in
  let%bind () = set (cur + 1) in
  get ()

(* Show it works *)
let oneplustwo_our_incing = 
  let%bind _ = our_inc () in
  let%bind onev = return 1 in 
  let%bind twov = return 2 in 
  let%bind r = return (onev + twov) in
  let%bind _ = our_inc () in
  return(r)

(* 
 * A more general State monad
   - The store is an arbitrary Map from strings to values
   - Think of the Map as mapping (global) variable names to the values
   - We will have one more type parameter as we let the heap be
     any (one) type
   - Note a real heap is harder, can have values of different types there.

   We will not look this over in detail as the ideas are all above
 *)

module State = struct
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
  end
  include T
  include Monad.Make2(T)
end

open State
open State.Let_syntax

let sumlist l =
  let%bind r = set "r" 0 in
  let rec sum = function
    | [] -> get "r"
    | hd :: tl -> 
      let%bind n = get "r" in 
      let%bind _ = set "r" (n + hd) in
      sum tl
  in sum l

let _ : int = run (sumlist [1;2;3;4;5])


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
let _ : int t = bind [2;6] ~f:(fun x -> [x;x + 1])

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

(* Other monads we are skipping for now
 * Continuations *)
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
*)

(* recall the types of Exception and State 
   (lets use State_int to stand for State for simplicity - just one cell holding an int)
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

