[@@@ocaml.warning "-8"] (* non-exhaustive pattern match *)

(* ***************************************** *)
(* Encoding effects functionally with monads *)
(* ***************************************** *)

(*
  So far we have seen many advantages of functional programming. 
  But, also how sometimes it is a handicap to not have side effects.

  A middle ground is worth considering: *encode* effects using purely
  functional code. We already do some of this when we use the option type instead
  of exceptions. Piping a functional data structure feels similar to side
  effects, too:
*)

module StringMap = Map.Make(String)

let _ : bool =
  StringMap.empty
  |> StringMap.add "hi" 3
  |> StringMap.add "ho" 17
  |> StringMap.for_all (fun _ -> fun i -> i > 10)


(*
  This piping is a concise "hand over fist passing" encoding of what would be a
  sequence of mutable assignments with a mutable map, for example with Hashtbl:
*)

module StringHash = Hashtbl.Make(String)
let h1 = StringHash.create (10)
let _ = 
    StringHash.add h1 "hi" 3
  ; StringHash.add h1 "ho" 17
  ; StringHash.find_all h1 "hi"

(*
  Idea: make an encoding which is more like the imperative code: state is implicit

  Think of it as defining a macro language inside of OCaml in which the code
  will look effectful even though it isn't: "monad-land".

  It looks effectful, BUT is not and so still will preserve the referential
  transparency. The mathematical basis for this is a structure called a *monad*.
  It is really just one very fancy functional programming idiom. It is NOT a
  language feature; just a coding pattern.
*)

(* ******************* *)
(* Encoding Exceptions *)
(* ******************* *)

(*
  Let's start with monads by using option's Some/None to encode exception
  effects. We have already seen examples of this, e.g. in the Minesweeper
  example when array accesses were out of bounds we returned `None`.

  Here we want to regularize/generalize it to make an offical monad. First
  recall how we had to "forward" a `None` if an operation failed. 
  Let's first define a few demo operations that "fail" with `None`:
*)

let combine_opt l1 l2 = try Some (List.combine l1 l2) with _ -> None
let tl_opt = function [] -> None | _ :: tl -> Some tl
let hd_opt = function [] -> None | hd :: _ -> Some hd

(*
  Here is an artificial example of belabored hand-over-fist passing of options:
  Combine two lists, sum pairwise, and return the 2nd element.
  Several operations within it can fail with a None, and in each case we need to
  match on that option in order to bubble that None to the top.
  Yes the code is U-G-L-Y !
*)
let ex l1 l2 =
  match combine_opt l1 l2 with
  | Some l ->
      let m = List.map (fun (x, y) -> x + y) l in
      begin match tl_opt m with
      | Some tail ->
          begin match hd_opt tail with
          | Some hd_tail -> Some hd_tail
          | None -> None
          end
      | None -> None
      end
  | None -> None

(* This code is much cleaner-looking with exceptions: *)
let ex_real_effects l1 l2 =
  let l = List.combine l1 l2 in
  let m = List.map (fun (x, y) -> x + y) l in
  let tail = List.tl m in
  let hd_tail = List.hd tail in
  hd_tail

(*
  So, .. let us keep the spirit of avoiding exceptions,
  but use a **monad** to hide all of the `Some` wrapping / `None` forwarding.
  * Think of a monad as a wrapper on regular computations (Some/None here).
  * "In Monad-land" here is an option-tagged computation.
  * "Out of the monad" is when we are not option-tagged.
  * In general we can make many different wrappers, option is just the start.

  The key operation of a monad is `bind` which sequences side-effecting
  computations.
  For Option it exists as Option.bind:
*)

let bind' (opt : 'a option) (f : 'a -> 'b option) : ('b option) =
  match opt with
  | None -> None
  | Some v -> f v

(**
  * If opt fails with [None] the function is ignored.
  * If it succeeds, the [Some] wrapper is automatically peeled off and the
    underlying data passed to [f].
  * The net result is the [Some]/[None] is largely hidden in the code.

  Here is a use of bind showing how we could combine and get the LHS of the first pair:
*)

let _ =
  bind' (combine_opt [1;2] [3;4;5]) (fun l -> match l with (n,_)::_ -> Some n)

(**
  * Yes, there is still a [Some] at the end in the above.
  * That is because the bind result needs to stay in monad-land (since the first
  part could have been [None]).
  * (We will in fact hide [Some] below so it is still there but is not explicit.)
  * In general once you get into monad-land you tend to stay there a long time ..

  [bind], generally, sequences ANY two function side effects. Besides just
  bubbling [None], it is a lot like a [let]-expression. E.g. for options:

    [bind e1 (fun x -> e2)] first runs [e1], and if it is non-[None], then it
      runs [e2], which can use the underlying result of [e1] since its in [x].

  This suggests a macro:

    [let* x = e1 in e2], which macro-expands to [bind e1 (fun x -> e2)]

  Using this macro can make your code look more like effectful code, and it
  pushes the monad into hiding even more.
*)

let ( let* ) = Option.bind (* let* is built in to OCaml, its a definable let-extension *)

let _ =
  let* l = combine_opt [1;2] [3;4;5] in
  let (n, _) :: _ = l in 
  Some n

(* vs previous version with bind' *)
let _ =
  bind' (combine_opt [1;2] [3;4]) (fun l -> match l with (n,_)::_ -> Some n)

(* This is very similar-looking to the side-effecting version: *)
let _ =
  let l = List.combine [1;2] [3;4;5] in
  let (n, _) :: _ = l in
  n

(**
  One of the differences is that we must finish off the monadic one by writing
  [Some n]. We want to return [n] to the monad land. 
  In general, all monads have a need to return-back-to-monad and we call this operation [return]:
*)
let return x = Some x

(* And now we can redo the above example with this nicer notation. *)

let ex_bind_macro l1 l2 =
  let* l = combine_opt l1 l2 in
  let m = List.map (fun (x, y) -> x + y) l in (* never None, so no let* *)
  let* tail = tl_opt m in
  let* hd_tail = hd_opt tail in
  return hd_tail (* "return TO the monad" *)

(* vs effectful (repeating effectful version above): *)
let ex_real_effects l1 l2 =
  let l = List.combine l1 l2 in
  let m = List.map (fun (x, y) -> x + y) l in
  let tail = List.tl m in
  let hd_tail = hd_opt tail in
  hd_tail

(* Let us write out the bind calls (expand the let* macro) to show why the macro is more readable: *)
let ex_bind l1 l2 =
  Option.bind (combine_opt l1 l2) (fun l ->
    let m = List.map (fun (x, y) -> x + y) l in
    Option.bind (tl_opt m) (fun tail ->
      Option.bind (hd_opt tail) (fun hd_tail ->
        return hd_tail
      )
    )
  )

(* Let's also remind ourselves that this is all just sugar for the original match version above, 
   lets in-line the first `bind` call: *)
let ex_bind l1 l2 =
  match combine_opt l1 l2 with
  | Some l ->
    let m = List.map (fun (x, y) -> x + y) l in
    Option.bind (tl_opt m) (fun tail ->
      Option.bind (hd_opt tail) (fun hd_tail ->
        return hd_tail
      )
    )
  | None -> None

(**
  Observe in the above that we can invoke functions which return values monad-land like
  [combine_opt]. We can also invoke non-option-returning functions like
  [List.map], and we simply do not bind on them.

  Just make sure to keep track of what is in and what is out of monad land
*)

(*
let ex_bind_error l1 l2 =
  let* l = combine_opt l1 l2 in
  let m = List.map (fun (x, y) -> x + y) l in
  let* tail = tl_opt m in
  let* hd_tail = hd_opt tail in
  hd_tail
*)
(* type error! *)

(**
  Note that our example so far is overly wordy. We can and should merge the
  last [let*]/[return] combo:
*)
let ex_bind_fixed l1 l2 =
  let* l = combine_opt l1 l2 in
  let m = List.map (fun (x, y) -> x + y) l in
  let* tail = tl_opt m in
  hd_opt tail (* this is already in monad-land, all good! *)


(**
  In other words, the following two code fragments are equivalent:
    [let* hd_tail = hd_opt tail in return hd_tail]
      ===
    [hd_opt tail]

  -- the let* unwraps the monad to put the underlying value in [hd_tail], 
  then it re-wraps it with [return], so its a no-op overall.

  This is in fact a *Monad Law*, which we will discuss below.
  It is very similar to the equivalence
    [let x = 5 in x]
      ===
    [5]
  in normal OCaml.
*)

(* Now, this is all well and good but pipes are sometimes cleaner than let's;
   how can we use pipe syntax with a monad?

Answer: there is also standard pipe syntax for bind
   * a >>= b is just an infix form of bind, it is nothing but
     bind a b
   * a >>| b is used when b is just a "normal" function which is not returning an option (like the map in our example).
   - the precise encodings are:
     --  a >>| b is      bind a (fun x -> return (b x))
     --  a >>| b is also a >>= (fun x -> return (b x))
   - the additional "return" "lifts" non-monadic f's result back into monad-land
   - the types make this difference clear:
     # (>>|);;
     - : 'a option -> ('a -> 'b) -> 'b option = <fun>
     # (>>=);;
     - : 'a option -> ('a -> 'b option) -> 'b option = <fun>
   * If you are just sequencing a bunch of function calls as above it reads better with these two pipes
*)

(* Here are those definitions, recall we can (re)define operators in OCaml *)
let ( >>= ) = Option.bind
let ( >>| ) m f = Option.map f m

(* Lets now redo the example above with monad-pipes: *)

let ex_piped l1 l2 =
  combine_opt l1 l2
  >>| List.map (fun (x, y) -> x + y)
  >>= tl_opt
  >>= hd_opt

(*
  The above uses >>| when the result of the step is not in monad-land
  and so the result needs to be put back there for the pipeline
  >>= is for the result that is in monad-land already.
*)

(* Contrast the above with exception-based code and normal OCaml pipes: *)
let ex_piped_exn l1 l2 =
  List.combine l1 l2
  |> List.map (fun (x, y) -> x + y)
  |> List.tl
  |> List.hd


(* A very subtle point is that the pipe notation is associating the sequencing in
a different manner.  Here are parens added to the above, the >>= operators are
left-associative:  *)

let ex_piped' l1 l2 =
  (
    (
      combine_opt l1 l2
      >>| List.map (fun (x, y) -> x + y)
    )
    >>= tl_opt
  )
  >>= hd_opt


(*
  Even the regular pipe |> was left-associative, and it doesn't make sense any
  other way because the first thing in the sequence is not a function and
  everything else is. Here is a parenthesized version of the example at top of
  this file to show how it was working.
*)

let _ : bool =
  (
    (
      StringMap.empty
      |> StringMap.add "hi" 3
    )
    |> StringMap.add "ho" 17
  )
  |> StringMap.for_all (fun _ -> fun i -> i > 10)


(* There is something subtle going on here in let notation vs pipe notation..
   - We all know that a;(b;c) "is the same order as" (a;b);c (e.g. in OCaml they give same results)
   - for let and let*, there is an analogous principle:
      let x = a in (let y = b in c)   ===   let y = (let x = a in b) in c
       (provided x is not in c - on the left the c won't know what x is)
   - Key point: the let* notation is by default doing the former and the pipes the latter - !!
   - Monads (including Option here) should also have this let-bind associative property
   - More formally this is another *monad law* for the mathematical definition of monad (more later on that)
*)

(* To make this more clear let us turn the piped version into its exact let* equivalent.
   Look at the top-level (outermost) >>= above to understand why this is what it is meaning *)
let ( let+ ) f m = Option.map m f (* let+ is the >>| analogue, its also called "map" *)

let ex_piped_expanded l1 l2 =
  let* tail =
    let* m =
      let+ l = combine_opt l1 l2 in
      List.map (fun (x, y) -> x + y) l
    in
    tl_opt m
  in
  hd_opt tail

(*
  (Summarizing the above let*/>>= etc sugar, in practice we want to define it with a functor.
  - This will allow us to load it all by just a functor application)
*)
module Make_syntax (M : sig
  type 'a t
  val return : 'a -> 'a t
  val bind : 'a t -> ('a -> 'b t) -> 'b t
end) = struct
  let ( let* ) = M.bind
  let ( let+ ) x f = M.bind x (fun a -> M.return (f a))
  let ( >>= ) = ( let* )
  let ( >>| ) = ( let+ )
end

(* Note that Option does not have `return` so we can't pass Option as M.  Here is one solution *)
module Optional = struct
  include Option
  let return (x : 'a) : 'a option = Some x
end

(* Now we can make and open the syntax to make it available at the top level *)

module Syntax = Make_syntax(Optional)
open Syntax

(* Shorthand of the above .. no need to name a module before opening it *)
open Make_syntax(Optional)

(*
  In general there are a few other things we also want in a monad
  So, lets start from the beginning and define a "real" monad, Exception.

  Its going to be like `Optional` but with a few other additions

  Invariant: all values in monad-land for Exception are Some/None's.
  (other monads will have other types of wrappers on their data)
*)

module Exception = struct
  (* this is the type of exceptional monad-land, 'a is the underlying value. *)
  type 'a t = 'a option

  (** [return] injects a normal-land computation into monad-land *)
  let return (x : 'a) : 'a t = Some x

  (**
    [bind] sequences two monad-land computations where the 2nd can use 1st's
    value result.
  *)
  let bind (m : 'a t) (f : 'a -> 'b t) : 'b t =
    match m with
    | None -> None
    | Some x -> f x

  (**
    [map m f] is a standard monad operation which is easily defined with [bind].
    - [map] is like [bind] but the [f] is just a normal-land function.
    - It is called "map" because if you think of the option as a 0/1 length list
      then the [map] operation here is analogous to [List.map].
  *)
  let map (m : 'a t) (f : 'a -> 'b) : 'b t =
    bind m (fun x -> return (f x))

  (**
    ['a monad_result] is the type transferred out of monad-land when we finally
    want to exit.
  *)
  type 'a monad_result = 'a

  (**
    [run] is the standard name for
    1) enter monad-land from normal-land;
    2) run a computation in monad-land;
    3) transfer the final result back to normal-land.

    [Option.get] is the name for [run] in the [Option] module.

    Note that it just raises a real OCaml exception to remove the [Some].

  *)
  let run (m : unit -> 'a t) : 'a monad_result =
    match m () with
    | Some x -> x
    | None -> failwith "uncaught None-exception in monad Exception"

  (* Let's also add more exception-looking syntactic sugar  *)
  let raise () : 'a t = None

  let try_with (try_block : 'a t) (with_block : unit -> 'a t): 'a t =
    match try_block with
    | None -> with_block () (* this is a function otherwise it would always run when `try_with` called *)
    | Some x -> Some x
end

(*
  Open these up now for easy use
*)

open Exception
open Make_syntax(Exception) (* `Make_syntax` works since Exception has `t`, `bind`, and `return` *)

(* Now redo the combine example above using Exception. *)

let ex_exception l1 l2 =
  let* l = combine_opt l1 l2 in
  let m = List.map (fun (x, y) -> x + y) l in
  let* tail = tl_opt m in
  let* hd_tail = hd_opt tail in
  return hd_tail

(* And, we can now "run" them from normal-land as well: *)
let _ : int = Exception.run @@ fun () -> ex_exception [1;2;3] [9;8;7]

(*
  Here is yet another example, showing how some really simple computation can be
  put in monad-land. Note you should **not** do this, effect-free code can
  remain as-is. This example is just to illustrate how monads sequence.
*)

let oneplustwo =
  bind (return 1) (fun onev ->
    bind (return 2) (fun twov ->
      return (onev + twov)
    )
  )

(* With the let* macro *)

let oneplustwo' =
  let* onev = return 1 in
  let* twov = return 2 in
  return (onev + twov)

(** Note that 
  [let* x = e in return e']
  ===
  [let+ x = e in e'] 
 -- thats all let+ is doing, its implicitly putting in that return 
 So we could also write *)
  
let oneplustwo'' =
  let* onev = return 1 in
  let+ twov = return 2 in
  onev + twov 

let _ : int = run (fun () -> oneplustwo'')

(*
  Let us now encode some normal OCaml code raising an exception into Exception.

  Here is an actual OCaml exception that is handled with try-with.
*)

let test_normal_ocaml x =
  try
    (if x = 0 then failwith "error" else 100 / x) + 1
  with
  | Failure _ -> 101

(*
  Now here is a near-equivalent in a monad.

  Remember, the key here is that it looks like there are side effects, but it is
  actually all functional code. No side effects here!
*)

let test_exn_monad x =
  try_with
    (if x = 0 then raise () else return (100 / x + 1))
    (fun () -> return 101)

(* Note that this is not exactly the same spirit, the `+ 1` moved inside the if-then-else
   This is how you would code it, but if you wanted to exactly follow the OCaml do this *)
let test_exn_monad' x =
  try_with
    (let* ite = if x = 0 then raise () else return (100 / x) in return (ite + 1))
    (fun () -> return 101)
(* -- the if-then-else as a whole is in monad-land so a let* binding is needed 
   (well a let+ would be better here since its a `let* .... return`) *)

let _ : int = run @@ fun () -> test_exn_monad' 4
let _ : int = run @@ fun () -> test_exn_monad' 0


(* *********** *)
(* More Monads *)
(* *********** *)

(* Generally a monad is anything matching this module type *)

module type MONADIC = sig
  (* a "wrapper" on 'a-typed data *)
  type 'a t

  val return : 'a -> 'a t

  val bind : 'a t -> ('a -> 'b t) -> 'b t

  (* this is what we want to return to the outside, often just 'a *)
  type 'a monad_result

  val run : (unit -> 'a t) -> 'a monad_result
end

(* Let us verify our Exception module above is a monad by this definition: *)
module Exception_test : MONADIC = Exception

(*
  General principle: side effects are result "plus other stuff".

  General monad principle: make a type which wraps underlying data with that arbitrary
  "other stuff".

  When you are working over that type, you are "in monad land". Then make the
  appropriate bind/return/etc for that particular wrapper. Finally, use
  monad-land like a sublanguage: hop into e.g. `Exception` when effects are
  needed.

  We next show how the underlying monad infrastructure can encode many other
  effects: state, I/O, coroutines, etc, just by changing the wrapper type and bind/return
*)

(**
  First, it is good to look at the no-op monad, which does basicall nothing. It is the
  effective identity, and we put an explicit [Wrapped] constructor around
  monadic values to be clear where monad-land starts and stops.
*)

module Identity = struct
  type 'a t = Wrapped of 'a (* Nothing but the 'a under the wrap *)
  let unwrap (Wrapped a) = a
  let bind (a : 'a t) (f : 'a -> 'b t) : 'b t = f (unwrap a)
  let return (a : 'a) : 'a t = Wrapped a
  type 'a monad_result = 'a
  let run (a : unit -> 'a t) : 'a monad_result = unwrap @@ a ()
end

module Identity_test : MONADIC = Identity (* check! *)


(* ******************************** *)
(* Print / Output / Writer / Logger *)
(* ******************************** *)

(*
  There is a family of monads where the effect is "return more stuff on the side"
  i.e. the `'a t` type is `'a * ... more stuff ...`
  Here is one such simple monad, a Logger which accumulates log messages.
  A common name for these are "writers" since they are writing things.
  Note that logging is a side-effect; it is a write-only state.
*)

module Logger = struct
  (* We will tack a string list on the side which is the sequence of log messages *)
  type log = string list

  type 'a t = 'a * log

  (* Beyond the type, the key to a monad is how bind and return are defined *)
  let bind (m : 'a t) (f : 'a -> 'b t): 'b t =
    let a, l = m in (* the underlying value and its log *)
    let b, l' = f a in  (* unwrap and pass underlying data a to f, producing the next value/log *)
    (b, l @ l') (* append the logs from m and f computations *)

  (* Return logs nothing so the log is empty *)
  let return (a : 'a) : 'a t = (a, [])

  (* For the final result we want to return the log so it can be seen *)
  type 'a monad_result = 'a * log

  let run (m : unit -> 'a t): 'a monad_result = m ()
  (* Now the all-important operation to actually add something to the log! *)
  let log msg : unit t = ((), [msg])
end

module Logger_test = (Logger : MONADIC) (* yes, it is a monad *)

open Logger
open Make_syntax(Logger)

(*
  Here is the 1+2 example above but with some logging messages added using
  Logger:
*)

let oneplustwo_logged =
  let* () = log "Starting!" in
  let* onev = return 1 in
  let* twov = return 2 in
  let* r = return (onev + twov) in
  let+ () = log "Ending!" in
  r

(*
  The idea of this monad (rather than Some/None wrapping like the exception
  monad) is we wrap in a list of log messages along with the result. Here is
  what the above example is doing when the definitions are inlined:
*)

let oneplustwo_logged_nomonad =
  let (), log1 = (), ["Starting!"] in (* each let* is now a let defining a pair of value,log-to-date *)
  let onev, log2 = 1, log1 @ [] in (* by the nature of bind we are always passing the previous log onward *)
  let twov, log3 = 2, log2 @ [] in (* return adds [] since there are no log side effect *)
  let r, log4 = (onev + twov), log3 @ [] in
  let (), log5 = (), log4 @ ["Ending!"] in
  (r, log5)


(* **************** *)
(* Input aka Reader *)
(* **************** *)

(*
  All the monads up to now were "first order"; the "wrapping" type has no
  function types.

  Monads get *really* useful with higher-order monads, *functions* in the `t`
  type. They also get more subtle to decipher what is actually happening.

  The simplest example is "Reader", which is a READ-only state.
  Don't think of it as "input" but more like a bunch of global constants.

  The intuition is we are going to pass the constants along so they are always
  implicitly accessible to any expression in monad land.
*)


module Reader = struct
  (*
    In Logger above we *returned* extra stuff, here we are *passing in* extra
    stuff. Here we let the stuff be arbitrary, of type 'e for environment.
    This means 'e is another type parameter -- this is an "indexed monad".
  *)
  type ('a, 'e) t = 'e -> 'a (* as usual, 'a is the underlying data *)

  (*
    bind needs to return a `'e -> 'a` so it starts with `fun e -> ...`
    This means it gets in the envt e from its caller
    bind's job is then to pass on the envt to its two sequenced computations
  *)
  let bind (m : ('a, 'e) t) (f : 'a -> ('b,'e) t) : ('b, 'e) t =
    fun (e : 'e) ->
      (f (m e)) e (* Pass the envt e down into both m and f *)

  (* return injects non-monadic code into monad: code not using the envt *)
  let return (x : 'a) : ('a, 'e) t = fun (_ : 'e) -> x

  (*
    The monad is only interesting if we have an accessor for the envt.
    Observe from the type we will be able to let* sequence this.
  *)
  let get : ('e, 'e) t = fun (e : 'e) -> e

  (* To run we need to feed in an initial environment of type 'e *)
  let run (m : ('a, 'e) t) (e : 'e) = m e
end

(* Examples *)
open Reader
let ( let* ) = bind (* We can't use our functor here since there the type is ('a, 'e) t not 'a t *)

(* Here is a simple environment `e` type, think of it as a set of global constants *)
type globals =
  { name: string
  ; age: int
  }

let is_retired =
  let* {age ;_ } = get in
  return (age > 65)

(* Note the above is a function due to `fun e` in monad bind;
   need to run it to execute the code *)

let _ : bool = run is_retired {name = "Gobo"; age = 88}

(* let's expand the let* to a bind: *)
let is_retired' =
  bind get (fun {age;_} -> return (age > 65))

(* Now let's inline the bind definition to see whats actually happening: *)

let is_retired'' =
  fun e -> (fun {age;_} -> return (age > 65)) (get e) e

(* See how the e comes in and gets pushed on down; in particular the `get` gets
  it and returns the record. *)

(* lets finally inline get and return to remove all the Reader references: *)

let is_retired''' =
  fun e -> (fun {age;_} -> (fun _ -> (age > 65))) ((fun e -> e) e) e

let _ = is_retired''' {name = "Gobo"; age = 88}

(* Monads, mathematically *)

(**
  To *really* be a monad you need to satisfy some invariants:

    1) [bind (return a) f]  ===  [f a]
    2) [bind a (fun x -> return x)]  ===  [a]
    3) [bind a (fun x -> bind b (fun y -> c))]  ===
       [bind (bind a (fun x -> b)) (fun y -> c)]
       (where [c] doesn't use [x])

    Let us focus on the equivalent let* versions which are easier to read:
    1) [let* x = return a in f x]  ===  [f a]
    2) [let* x = m in return x]  ===  [m]
    3) [let* x = m in let* y = m' in m''] ===
       [let* y = (let* x = m in m') in m'']

  * (Note "===" here means we can replace one with the other and notice no difference)
  * These are called the "Monad Laws"
  * The last one is the trickiest but we hit on it earlier, it is associativity of bind
  * The first two are mostly intuitive properties of injecting normal values into a monad
  * Note the laws are more invariants, and can be concretely be tested on examples.
  * All of the monads we are doing here should "pass" any such invariant tests
*)

(*
  We in fact used all the monad laws on the initial Option example above.
  We will review that now. Recall that our Exception module is just an
  extension of Option.
*)
open Exception
open Make_syntax(Exception)

(* here is the version above we had that mostly used let* *)
let ex_initial l1 l2 =
  let* l = combine_opt l1 l2 in
  let m = List.map (fun (x, y) -> x + y) l in
  let* tail = tl_opt m in
  let* hd_tail = hd_opt tail in
  return hd_tail

(*
  The "let m" (non-bind) here could be changed to a let* if we wrapped
  the defined value in a return -- this is using monad law 1) right-to-left.
  (the "a" in the law is the List.fold .. which we abbreviated m with the let)
*)
let ex_first_law_applied l1 l2 =
  let* l = combine_opt l1 l2 in
  let* m = return (List.map (fun (x, y) -> x + y) l) in
  let* tail = tl_opt m in
  let* hd_tail = hd_opt tail in
  return hd_tail

(*
  We also noticed that the last let* followed by return was just a no-op so we
  could have done the following which is using monad law 2) right-to-left
  (letting a be `hd_opt tail`)
*)
let ex_second_law_applied l1 l2 =
  let* l = combine_opt l1 l2 in
  let* m = return (List.map (fun (x, y) -> x + y) l) in
  let* tail = tl_opt m in
  hd_opt tail

(*
  Lastly we observed that pipes naturally associate like the rhs of the third
  monad law, and the let* natural structure above is the lhs. So, with several
  applications of the third law left-to-right on the previous we get this
  version.
*)
let ex_third_law_applied l1 l2 =
  let* tail =
    let* m =
      let* l = combine_opt l1 l2 in
      return (List.map (fun (x, y) -> x + y) l)
    in
    tl_opt m
  in
  hd_opt tail

(* which can be written in piped style, like this: *)

let ex_piped_version_of_previous l1 l2 =
  combine_opt l1 l2
  >>= (fun l -> return @@ List.map (fun acc (x,y) -> x + y) l)
  >>= tl_opt
  >>= hd_opt

(* Here is a smaller example of the third law to make it easier to see *)
let ex_before_third_law l1 l2 =
  let* l = combine_opt l1 l2 in
  let* tail = tl_opt l in
  return tail

let ex_after_third_law l1 l2 =
  let* tail =
    (let* l = combine_opt l1 l2 in tl_opt l)
  in
  return tail

(*
  The following code is IDENTICAL to ex_after_third_law, just different macros
  used.
*)
let ex_after_third_law_piped l1 l2 =
  ((combine_opt l1 l2) >>= tl_opt) >>= return

(* Moral: monad pipes work only because the third law works! *)

(* ***** *)
(* State *)
(* ***** *)

(*
  State is reader plus writer: old state comes in, new state comes out

  Before doing the monad, let's write some explicit threading code to show how
  it is working.

  The key idea of the state monad is you always get passed the current state and
  return the new state.
*)


(* previous hand-over fist map state passing functionally *)
let _ : bool =
  StringMap.empty
  |> StringMap.add "hi" 3
  |> StringMap.add "ho" 17
  |> StringMap.for_all (fun _ -> fun i -> i > 10)

(*
  Let's regularize it to be a bit more how the state monad works: each Map op
  gets old map state, AND returns PAIR of value if any and new state
*)
let map_set key data = fun m -> ((), StringMap.add key data m)
let map_for_all f = fun m -> ((StringMap.for_all m f), m)

let _ : bool =
  let m = StringMap.empty in
  let (), m' = (fun m -> map_set "hi" 3 m) m in
  let (), m'' = (fun m -> map_set "hi" 3 m) m' in
  let b, _ = (fun m -> map_for_all m (fun _ -> fun i -> i > 10)) m'' in
  b

(*
  Let us do a simple version of State, the whole state is just one value of type
  's. This models a program with only one ref cell (e.g. one int, one StringMap,
  etc.).
*)
module State = struct
  (* Here is the monad type:
    - 's is the type of the stateful value we are keeping
    - We need to *thread* the 's through all computations just like we
      informally did above
    - So, pass the 's in like Reader *and* return it like Logger
  *)
  type ('a, 's) t = 's -> 'a * 's

  (*
    Let us now construct bind.
    1) Like Reader, the result is a fun s : 's -> ... since we pass in s
    2) First we pass e to the first computation x
    3) x returns a pair with a potentially **different** state, s'
    4) Then, thread that latest state on to f so it gets any state updates in s'
  *)
  (* expanding type abreviations, x : 's -> 'a * 's
                                  f : 'a -> ('s -> 'b * 's)
                                  return 's -> 'b * 's : *)
  let bind (x : ('a, 's) t) (f : 'a -> ('b, 's) t) : ('b, 's) t =
    fun (s : 's) ->
      let (x', s') = x s in
      (f x') s'

  let return (x : 'a) : ('a, 's) t =
    fun s -> (x, s) (* just pass on the state we got in *)

  type ('a, 's) monad_result = 'a * 's

  (* Run needs to get passed in an init state *)
  let run (e : ('a, 's) t) (init : 's) : ('a, 's) monad_result =
    e init

  let set (s : 's) =
    fun (_ : 's) -> ((), s) (* return () as value, toss old state, make it s *)

  let get =
    fun (s : 's) -> (s, s) (* return the state s AND propagate s onward *)
end

open State
let ( let* ) = bind


(* Here is an OCaml state example for review, side effect is in compiler *)
let actual_state () =
  let r = ref 0 in
  let rv = !r in
  let () = r := rv + 1 in !r

(* Here is the same example re-coded in the State monad - no mutation at runtime *)

let simple_state () =
  (* let r = ref 0 is in the `run` below - initial value at run launch *)
  let* rv = (get : (int, int) t) in
  let* () = (set(rv + 1) : (unit, int) t) in
  (get : (int, int) t)

let _ = run (simple_state ()) 0

(* turning the above let* into the underlying bind to be more explicit *)

let simple_state () =
  (* let r = ref 0 is implicit - initial value at run time *)
  bind get (fun rv ->
    bind (set (rv + 1)) (fun () ->
      get
    )
  )

let _ = run (simple_state ()) 0

(* Here is a bit larger example using statefulness of State
   -- sum the elements of a list with a "mutable" counter *)

let rec sumlist = function
  | [] -> get
  | hd :: tl ->
    let* n = get in
    let* () = set (n + hd) in
    sumlist tl

let _ : (int, int) State.monad_result = run (sumlist [1;2;3;4;5]) 0

(*
  Now we will do a a more general State monad.
  - The store is an arbitrary Map from strings to values
  - Think of the Map as mapping (global) variable names to the values
  - We will have one more type parameter as we let the heap be
    any (one) type
  - Note a real heap is harder, can have values of different types there.

   We will not cover this in lecture as it is nearly identical to the above
 *)

module State_map = struct
  type 'v m = 'v StringMap.t (* shorthand name for map w/string keys anf 'v values *)
  type ('a, 'v) t = 'v m -> 'a * 'v m

  let bind (x : ('a, 'v) t) (f: 'a -> ('b,'v) t) : ('b,'v) t =
    fun (m : 'v m) -> let (x', m') = x m in f x' m'

  let return (x : 'a) : ('a, 'v) t = fun m -> (x, m)

  type 'a monad_result = 'a

  (* Run needs to pass in an empty state *)
  let run (c : ('a, 'v) t) : 'a monad_result =
    let mt_map = StringMap.empty in fst (c mt_map)

  let set (k : string) (v : 'a) : (unit, 'v) t =
    fun (s : 'a m) -> ((), StringMap.add k v s)

  let get (r : string) : ('a, 'v) t =
    fun (s : 'a m) -> (StringMap.find r s, s)

  let dump : 'a m -> 'a m * 'a m =
    fun (s : 'a m) -> (s, s)
end

open State_map
let ( let* ) = bind

let sumlist l =
  let* () = set "r" 0 in
  let rec sum = function
    | [] -> get "r"
    | hd :: tl ->
      let* n = get "r" in
      let* _ = set "r" (n + hd) in
      sum tl
  in
  sum l

let _ : int = run (sumlist [1;2;3;4;5])

(*
  Let us revisit the above Map example to show how hand-over-fist is behind the
  scenes. Here is what we had above:
*)
let _ : bool =
  StringMap.empty
  |> StringMap.add "hi" 3
  |> StringMap.add "ho" 17
  |> StringMap.for_all (fun _ -> fun i -> i > 10)

(*
  Let's put this back in let form to make clear all the hand-over-fist passing
  we had to do.
*)
let _ : bool =
  let m0 = StringMap.empty in
  let m1 = StringMap.add "hi" 3 m0 in
  let m2 = StringMap.add "ho" 17 m1 in
  StringMap.for_all (fun _ -> fun i -> i > 10) m2

(*
  OK now let's use our State instead. Observe that there is no m1/m2 threading
  needed.
*)
let map_eg_state =
  let* () = set "hi" 3 in
  let* () = set "ho" 17 in
  let* d = dump in (* dump dumps the whole state contents out, needed for the Map.forall *)
  return (StringMap.for_all (fun _ -> fun i -> i > 10) d)

let _ = run map_eg_state

let rec sum = function
  | [] -> get "r"
  | hd :: tl ->
    let* n = get "r" in
    let* _ = set "r" (n + hd) in
    sum tl

(*
  Type-directed monads:
  * Pretty much any OCaml type has a natural monad behind it.
  * Some are more useful than others.
  * Let us consider a monad where t is 'a list, what can that do?
*)

module List_monad = struct
  type 'a t = 'a list

  (* Let us just try to write non-trivial bind/return that type check *)

  let bind (m : 'a t) (f : 'a -> 'a t) : 'a t =
    List.concat (List.map f m) (* i.e. List.concat_map f m *)

  let return (v : 'a) : 'a t = [v]
end


(* ************** *)
(* Nondeterminism *)
(* ************** *)

(*
  In a nondeterministic program, the output is a list of values, and subsequent
  computations try all of them.

  This allows some programming patterns to be much more simply coded.
  (We will just barely touch on this in lecture)
*)
module Nondet = struct
  type 'a t = 'a list
  let return (x : 'a) : 'a t = [x]
  let bind (m : 'a t) (f : 'a -> 'b t) : 'b t =
    List.concat_map f m

  type 'a monad_result = 'a list
  let run (m : 'a t) : 'a monad_result = m

  let zero : 'a t = []
  let either (a : 'a t) (b : 'a t) : 'a t = a @ b
end

open Nondet
let ( let* ) = bind

(* simple example *)
let _ : int t =
  let* x = [2; 6] in
  [x; x + 1]

(* All divisors of a number: *)
let divisors (n : int) : int t =
  let rec divs n candidate =
    if candidate = 1 then
      return 1
    else
      let this = if n mod candidate = 0 then return candidate else zero
      and rest = divs n (candidate - 1) in
      either this rest (* nondeterminism - union up both results *)
  in
  divs n n

(* powerset of a set (representing set as a list here for simplicity) *)

let rec powerset (l : 'a list) : 'a list t =
  match l with
  | [] -> return []
  | hd :: tl ->
    let* pow_member = powerset tl in
    (* note that each one of these recursive calls itself can return several different answers *)
    either
      (return pow_member)
      (return @@ hd :: pow_member)

(* all permutations of a list *)

let rec insert_anywhere (x : 'a) (l : 'a list) : 'a list t =
  let at_front = return (x :: l)
  and in_tails =
    match l with
     | [] -> zero
     | hd :: tl -> let* l' = insert_anywhere x tl in return (hd :: l')
  in
  either at_front in_tails

let rec permut (l : 'a list) : ('a list t) =
  match l with
  | [] -> return []
  | hd :: tl -> let* l' = permut tl in insert_anywhere hd l'

let _ : int list list = run (permut [1;2;3])

(* Continuations, super briefly *)

type 'a cont = { run : 'r. ('a -> 'r) -> 'r }
(*
  The ('a -> 'r) is the continuation; the rest of the computation. A value whose
  type is 'a cont has a 'a value, and when it is given a way to continue (a
  function ('a -> 'r) that should be called with that 'a value), it will do so
  and return the final 'r.

  The 'a is one level higher in the function type now than in any example before.

  Coroutines are a variation on the continuation monad where "rest" is the other
  routines.
*)

(* Composing monads *)

(*
  Suppose you need both state and exceptions, what to do?

  The solution is to compose the types/binds/returns in a single monad. We can
  do this with monad transformers. However, not all monads can compose, so there
  is no such thing as a general monad transformer; we cannot just write a
  functor to combine two monads.

  Here, we just manually compose them, as an example. We will do it with State
  and Exception.
*)

type 'a except = 'a Option.t
type 'a state = int -> 'a * int (* integer state, for example *)

(*
  There are *two* ways to compose these types, depending on which type is on the
  "outside":
  1) state on the outside
*)

type 'a state_except = int -> ('a Option.t) * int

(*
  2) option on the outside
*)
type 'a except_state = (int -> 'a * int) Option.t

(*
  The second one tosses out the state in the event of an exception. The first
  one keeps it (no matter if the 'a Option.t is Some or None, there is always
  an int state!) .

  You are probably used to the first kind, state never gets tossed in usual
  programming languages.

  You could even combine both: there are two types of exceptions, one keeps
  state, and the other tosses state.
*)
