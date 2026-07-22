[@@@ocaml.warning "-8-32-27"]

(* ***************************** *)
(* Encoding effects functionally *)
(* ***************************** *)

(* Aka "A Journey through Monad Land" *)

(*
  * So far we have seen the advantages of functional programming
  * But, sometimes it is a handicap to not have side effects
  * A middle ground is sometimes the best: *encode* effects using purely functional code
    - we already saw a bit of this with the option type replacing exceptions
    - also the use of piping such as:
*)

module StringMap = Map.Make(String)

let _ : bool = StringMap.empty
               |> StringMap.add "hi" 3 
               |> StringMap.add "ho" 17
               |> StringMap.for_all (fun _ -> fun i -> i > 10)


(*  etc which is a concise "hand over fist passing" encoding 
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
  * We have already seen examples of this, e.g. Minesweeper functional example when array accesses were out of bounds
  * Here we want to regularize/generalize it to make an offical monad.
  * First recall how we had to "forward" a `None` if an e.g. List operation failed
*)

(* Combine in fact doesn't return Some/None, let us convert it to that format here.
   We need a uniformity that None is always the exceptional case and Some is the OK-case. *)
let option_combine l1 l2 = try Some(List.combine l1 l2) with _ -> None
let option_tl l = try Some(List.tl l) with _ -> None
let option_hd l = try Some(List.hd l) with _ -> None
(* 
  Here is an artificial example of lots of hand-over fist passing of options.
  Several operations can fail with a None, and in each case we need to match to bubble that None to the top.
  Yes the code is U-G-L-Y !
*)

(* Lets combine two lists, sum pairwise, and return the 2nd element of the resulting list. 
   This is not intended to be useful code, just an example of forwarding exceptional conditions *)
let ex l1 l2 = 
  match option_combine l1 l2 with 
  | Some(l) -> 
    begin (* recall `begin .. end` is just like `( ... )` - big parentheses *)
      let m =  List.fold_left (fun acc (x,y) -> x + y :: acc) [] l in
      match option_tl m with
      | Some(tail) -> 
        begin
          match option_tl tail with 
          | Some(hd_tail) -> Some(hd_tail)
          | None -> None 
        end
      | None -> None 
    end
  | None -> None

(* Before getting into how we can clean this code up lets compare with the effectful version *)
   let ex_real_effects l1 l2 =
    let l = List.combine l1 l2 in 
    let m = List.fold_left (fun acc (x,y) -> x + y :: acc) [] l in
    let tail = List.tl m in 
    let hd_tail = List.hd tail in
    hd_tail

(* I think everyone would agree that this version is a lot easier to read.. 
   .. Lets fix that! *)

(* 
  * Let us regularize this with a monad
  * Think of a monad as a wrapper on regular computations
  * "In Monad-land" here is an option-tagged computation
  * "Out of the monad" is when we are not option-tagged
*)

(* 
 * The key operation of a monad is `bind` which sequences side-effecting computations. 
   For Option it exists as Option.bind
   Here is its code for reference (we call this one bind' to not overlap with built-in one)
 *)

let bind' (opt : 'a option) (f : 'a -> 'b option) : ('b option) = 
  match opt with 
  | None -> None 
  | Some v -> f v;;

(* bind does the match "for free" compared to above 
    - if the combine failed with `None` the function is ignored
    - if it succeeds the Some wrapper is automatically peeled off and the underlying data passed to f 
    - the net result is the Some/None is largely hidden in the code
    - here is a stupid example to combine and get lhs of first pair: *)

bind' (option_combine [1;2] [3;4;5]) (fun l -> match l with (n,_)::_ -> Some(n));;

(* Yes there is still a `Some` at the end in the above
   That is because the bind result needs to stay in monad-land (since the first part could have None'd)
   We will in fact hide Some below so its still there but its not explicit. 
   In general once you get into monad-land you tend to stay there a long time .. *)

(* 
  * bind more generally sequences ANY two functional side effects, more below on this
  * besides the bubbling of None's it is a lot like a "let" expression.
    -  bind code1 code2  first runs code1, and if it is non-None runs code2 on which can use underyling result of code1.
  * This suggests a macro:
  `let* x = e1 in e2`  which macro expands to `bind e1 (fun x -> e2)`
  * Using the macro, code can look more like regular code
  * We have pushed monad-land into hiding a bit more..
*)

(* let* exists in Core for Option.bind, lets use it
  Note we need to open a module to enable macro for Option.bind 
  And, need #require "ppx_jane" in top loop (or (preprocess (pps ppx_jane)) in dune) 
  for the macro to expand *)

let ( let* ) = Option.bind;;

let* (n,_)::_ = option_combine [1;2] [3;4] in Some(n);; (* compare with above version - a bit more readable *)

(* compare this to the exn version which actually has a side effect, its similar: *)

let (n,_)::_ = List.combine [1;2] [3;4] in n;;

(* 
 * OK now let us redo the larger example above using let*
 * This code looks more like the exn code above now:
 *)

(* 
 * To "return to the monad" we want to wrap the value in a Some, lets make that clear.
 * It is called return because it is injecting (returning) a "regular" value TO the monad 
 * The name is unintuitive since it sounds like it could be *returning from* monad-land, but its not!
 *)
let return x = Some x

let ex_bind_macro l1 l2 =
  let* l = option_combine l1 l2 in 
  let m = List.fold_left (fun acc (x,y) -> x + y :: acc) [] l in (* never None's so no bind needed here *)
  let* tail = option_tl m in 
  let* hd_tail = option_hd tail in
  return hd_tail (* "return TO the monad" - here that means wrap in Some(..) *)
(* vs effectful (repeating effectful version above): *)
let ex_real_effects l1 l2 =
  let l = List.combine l1 l2 in 
  let m = List.fold_left (fun acc (x,y) -> x + y :: acc) [] l in
  let tail = List.tl m in 
  let hd_tail = option_hd tail in
  hd_tail

(* Let us write out the bind calls (expand the macro) to show why the macro is more readable: *)
let ex_bind l1 l2 =
  Option.bind (option_combine l1 l2) (fun l ->
      let m = List.fold_left (fun acc (x,y) -> x + y :: acc)[] l in
      Option.bind (option_tl m) (fun tail -> 
          Option.bind (option_hd tail) (fun hd_tail -> 
              return(hd_tail))))
(* (vs version with let* above, repeated for easy eyeballing: *) 
let ex_bind_macro' l1 l2 =
  let* l = option_combine l1 l2 in 
  let m = List.fold_left (fun acc (x,y) -> x + y :: acc) [] l in
  let* tail = option_tl m in 
  let* hd_tail = option_hd tail in
  return(hd_tail)
(* 
  * Observe in the above that we can invoke functions which are in monad-land like combine above
  * And, we can also invoke non-option-returning functions like List.fold; no need for bind on them
  * Just make sure to keep track of whats in and whats out of monad-land - !
*)

(* Note you can't cheat and leave out the last return, you will get a type error *)
(*
let ex_bind_error l1 l2 =
  let* l = option_combine l1 l2 in 
  let m = List.fold (fun acc (x,y) -> x + y :: acc) [] l in
  let* tail = option_tl m in
  let* hd_tail = option_hd tail in
  hd_tail *)
(* type error! Both of let*'s arguments need to be in monad-land, `t` here now that we opened Option *)

(* Note that this code is wordy, we can merge return with last let*: *)
let ex_bind_fixed l1 l2 =
  let* l = option_combine l1 l2 in 
  let m = List.fold_left (fun acc (x,y) -> x + y :: acc) [] l in
  let* tail = option_tl m in
  option_hd tail (* this is in monad-land, all good! *)


(* In other words,   
  let* hd_tail = option_hd tail in return hd_tl  ===  option_hd tail
  - this is in fact a *Monad Law* we will discuss below, like let x = 5 in x === 5 in normal OCaml
*)

(* Now, we all love pipes but this is just let-like coding; how can we use pipe syntax??

Answer: there is also stadard pipe syntax for bind
   * a >>= b is just an infix form of bind, it is nothing but 
     bind a b
   * a >>| b is used when b is just a "normal" function which is not returning an option.
   - the precise encodings in fact are:
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

(* Here are those definitions *)
let ( >>= ) = Option.bind
let ( >>| ) m f =
  Option.bind m (fun x -> return (f x))

(* Lets now redo the example above with monad-pipes: *)

let ex_piped l1 l2 =
  option_combine l1 l2 
  >>| List.fold_left (fun acc (x,y) -> (x + y :: acc)) []
  >>= option_tl
  >>= option_hd

  (* The above uses >>| when the result of the step is not in monad-land
  and so the result needs to be put back there for the pipeline 
  >>= is for the result that is in monad-land already. *)

  (* Contrast the above with exception-based code and normal OCaml pipes: *)
let ex_piped_exn l1 l2 =
    List.combine l1 l2 
    |> List.fold_left (fun acc (x,y) -> (x + y :: acc)) []
    |> List.tl
    |> List.hd
  

(* A very subtle point is that the pipe notation is associating the sequencing in 
a different manner.  Here are parens added to the above, the >>= operators are 
left-associative:  *)

let ex_piped' l1 l2 =
    (
      (
        option_combine l1 l2 
        >>| List.fold_left (fun acc (x,y) -> (x + y :: acc)) []
      )
      >>= option_tl
    )
    >>= option_hd


(* Even the regular pipe |> was left-associative, and it doesn't make sense any other way
   because the first thing in the sequence is not a function and everything else is.  Here is a 
   parenthesized version of the example at top of this file to show how it was working.  *)

let _ : bool = StringMap.empty
               |> StringMap.add "hi" 3 
               |> StringMap.add "ho" 17
               |> StringMap.for_all (fun _ -> fun i -> i > 10)


(* There is something subtle going on here with the operator ordering..
   - We all know that a;(b;c) "is the same order as" (a;b);c (e.g. in OCaml they give same results)
   - for let and let-bind, there is an analogous principle:
      let x = a in (let y = b in c)   ===   let y = (let x = a in b) in c
       (provided x is not in c - on the left the c won't know what x is)
   - Key point: the let* notation is doing the former and the pipes the latter - !!
   - Monads (including Option here) should have this let-bind associative property
   - More formally this is another *monad law* for the mathematical definition of monad (more later on that)
*)

(* To make this more clear let us turn the piped version into its exact let* equivalent.
   Look at the top-level (outermost) >>= above to understand why this is what it is meaning *)
let ( let+ ) f m = Option.map m f

let ex_piped_expanded l1 l2 =
  let* tail = 
    let* m = 
      let+ l = option_combine l1 l2 in 
        List.fold_left (fun acc (x,y) -> (x + y :: acc)) [] l in
    option_tl m in
  option_hd tail

(* Note let+ is the let analog of |>> which just wraps result in return  *)

(* 
  OK it is finally time for an actual monad -- Option extended to a more general Exception monad
  This example also shows how we can define our own monads with Core.Monad.Make

  Invariant: all values in monad-land for this monad are Some/None's.

*)

module Exception = struct
  type 'a t = 'a option (* this is the type of monad-land, 'a is the underlying value *)
  (* return injects a normal-land computation into monad-land *)
  let return (x: 'a) : 'a t = Some x
  (* bind sequences two monad-land computations where the 2nd can use 1st's value result *)
  let bind (m: 'a t) (f: 'a -> 'b t): 'b t =
    match m with
    | None -> None 
    | Some x -> f x
  (* map is a standard monad operation which is easily defined with bind
      - map is like bind but the f is just a normal-land function 
      - it is called "map" because if you think of the option as a 0/1 length list
        the map operation here is analogous to List.map *)
  let map (m: 'a t) (f: 'a -> 'b): 'b t = 
    bind m (fun x -> return(f x))
  (* `run` is the standard name for 
      1) enter monad-land from normal-land 
      2) run a computation in monad-land;
      3) transfer the final result back to normal-land 
      Option.run doesn't exist, it is not the full monad package *)
  type 'a monad_result = 'a (* 'a monad_result is the type transferred out of monad-land at end of run *)
  let run (m : unit -> 'a t) : 'a monad_result =
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

(* Lets open these up now, overriding the open of Option we did above for the monad functions like bind *)

open Exception
(* Redoing the combine example above using Exception now *)

(* Here is the suite of sugar for the Exception monad *)

let ( let* ) = bind
let ( let+ ) f m = map m f
let ( >>= ) = bind
let ( >>| ) m f = bind m (fun x -> return (f x))

let combine_monad l1 l2 = match option_combine l1 l2 with None -> raise () | Some l -> return l
let ex_exception l1 l2 =
  let* l = combine_monad l1 l2 in 
  let m = List.fold_left (fun acc (x,y) -> x + y :: acc) [] l in
  let* tail = option_tl m in
  let* hd_tail = option_hd tail in
  return(hd_tail)

(* And, we can now "run" them from normal-land as well: *)
let _ : int = Exception.run @@ fun () -> ex_exception [1;2;3] [9;8;7]

(* In general all the Option examples above work in Exception *)

(* Here is yet another example, showing how some really simple computation can be
   put in monad-land.  Note you should not do this, effect-free code can remain as-is
   This example is just to illustrate how monads sequence *)

let oneplustwo = 
  bind (return 1) 
    (fun onev -> 
        bind (return 2) 
          (fun twov -> return (onev + twov)))

(* With the let* macro *)

let oneplustwo' = 
  let* onev = return 1 in 
  let* twov = return 2 in 
  return (onev + twov)

let _ : int = run (fun () -> oneplustwo')

(* Let us now encode some normal OCaml code raising an exception into Exception *)

(* Here is an actual OCaml exception that is handled with try-with *)
let test_normal_ocaml x =
  try (1 + (if x = 0 then failwith "error" else 100 / x))
  with Failure _ -> 101

(* Monad near-equivalent - note the + 1 moved in, 1 must be let*-bound if written exactly as above 
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
   Lets as an exercise keep the 1 + in the original spot with bind (using let* syntax)
*)

let f (x : int) =
  try_with 
    (let* one = return 1 in 
     let* ifthen = if x = 0 then raise () else return(100 / x) in
     return(one + ifthen))
    (fun () -> return(101))

(* The monad encoding starts to get crufty here.. a downside of monads in general *)


(* *********** *)
(* More Monads *)
(* *********** *)

(* Generally a monad for us is anything matching this module type *)

module type MONADIC = sig
  type 'a t (* a "wrapper" on 'a-typed data *)
  val return : 'a -> 'a t
  val bind : 'a t -> ('a -> 'b t) -> 'b t
  val map : 'a t -> ('a -> 'b) -> 'b t
  type 'a monad_result (* this is what we want to return to the outside, often just 'a *)
  val run : (unit -> 'a t) -> 'a monad_result
end

(* Let us verify our Exception module above is indeed a monad by this definition *)

module Exception_test : MONADIC = Exception

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
  type 'a t = Wrapped of 'a (* Nothing but the 'a under the wrap *)
  let unwrap (Wrapped a) = a
  let bind (a : 'a t) (f : 'a -> 'b t) : 'b t = f (unwrap a)
  let return (a : 'a) : 'a t = Wrapped a
  let map (m : 'a t) (f: 'a -> 'b): 'b t = 
    bind m (fun x -> return(f x))      
  type 'a monad_result = 'a
  let run (a : unit -> 'a t) : 'a monad_result = unwrap @@ a ()
end

module Ident_test : MONADIC = Ident (* check! *)


(* ******************************** *)
(* Print / Output / Writer / Logger *)
(* ******************************** *)

(* 
* There is a family of monads where the effect is "return more stuff on the side"
  i.e. the `'a t` type is `'a * ... more stuff ...`
* Here is one such simple monad, a Logger which accumulates log messages
* A common name for these are "writers" since they are writing things
* Note that logging is a side-effect, its like state but is write-only.
*)

module Logger = struct
  type log = string list (* we will tack a string list on the side which is the log messages *)
  type 'a t = 'a * log
  (* Beyond the type, the key to a monad is what bind/return are *)
  (* The key idea of the logger is to append the logs from the two sequenced computations *)
  let bind (m : 'a t) (f : 'a -> 'b t): 'b t =
    let (x,l') = m in 
    let (x',l'') = f x in (x',l'@l'')
  let return (x : 'a) : 'a t = (x, []) (* empty log in a return *)
  let map (m: 'a t) (f: 'a -> 'b): 'b t = 
    bind m (fun x -> return(f x))
  type 'a monad_result = 'a * log
  let run (m: unit -> 'a t): 'a monad_result = m ()
  let log msg : unit t = ((), [msg])
end

module Logger_test = (Logger : MONADIC) (* yes it is a monad *)

open Logger
let ( let* ) = bind
let ( let+ ) f m = map m f
let ( >>= ) = bind
let ( >>| ) m f = bind m (fun x -> return (f x))

(* Here is the 1+2 example above but with some logging messages added using Logger: *)

let oneplustwo_logged = 
  let* () = log "Starting!" in
  let* onev = return 1 in 
  let* twov = return 2 in 
  let* r = return (onev + twov) in
  let* () = log "Ending!" in
  return(r)

(* 
  The idea of the monad is rather than Some/None wrapping, we wrap in a list of log messages along with the result.  Here is what the above example is doing when the definitions are inlined: *)

let oneplustwo_logged_nomonad = 
  let (),log1 = (), ["Starting!"] in (* each let* is now a let defining a pair of value,log-to-date *)
  let onev,log2 = 1, log1 @ [] in (* by the nature of bind we are always passing the previous log onward *)
  let twov,log3 = 2, log2 @ [] in (* return adds [] since there is no log side effect *)
  let r,log4 = (onev + twov) , log3 @ [] in
  let (), log5 = (), log4@["Ending!"] in
  (r,log5)


(* **************** *)
(* Input aka Reader *)
(* **************** *)

(* 
 * All the monads up to now were "first order", the "wrapping" type has no function types
 * Monads get *really* useful with higher-order monads, *functions* in the .t type
 * They also get more subtle to decipher what is actually happening
 * The simplest example is "Reader", like state but this time READ-only
 * Don't think of it as "input", it is more like a bunch of global constants

 * The intuition is we are going to pass the constants along so they are always accessible
 *)


module Reader = struct
  (* 
  * In Logger above we *returned* extra stuff, here we are *passing in* extra stuff 
  * Here we let the stuff be arbitrary, of type 'e for environment
*)
  type ('a, 'e) t = ('e -> 'a) (* as usual, 'a is the underlying data *)
  (* bind needs to return a `'e -> 'a` so it starts with `fun e -> ...`
      This means it gets in the envt e from its caller
      bind's job is then to pass on the envt to its two sequenced computations *)
  let bind (m : ('a, 'e) t) (f : 'a -> ('b,'e) t) : ('b, 'e) t = 
    fun (e : 'e) -> ((f (m e)) e) (* Pass the envt e down into both m and f *)
  (* return injects non-monadic code into monad: code not using the envt *)
  let return (x : 'a) : ('a, 'e) t = fun (_: 'e) -> x
  let map (m: ('a, 'e) t) (f: 'a -> 'b): ('b, 'e) t = 
    bind m (fun x -> return(f x))    
  (* The monad is only interesting if we have an accessor for the envt
      - observe from the type we will be able to let* sequence this so will work *)
  let get () : ('e, 'e) t = fun (e : 'e) -> e 
  (* To run we need to feed in an initial environment of type 'e *)
  let run (m : ('a, 'e) t) (e : 'e) = m e
end

(* Examples *)
open Reader
let ( let* ) = bind
let ( let+ ) f m = map m f
let ( >>= ) = bind
let ( >>| ) m f = bind m (fun x -> return (f x))

(* Here is a simple environment type, think of it as a set of global constants *)
type globals = {
  name: string;
  age: int;
}

let is_retired = 
  let* {age;_} = get() in return (age > 65)

(* Note the above is a function due to `fun e` in monad bind;
   need to run it to execute the code *) 

let _ : bool = run is_retired {name = "Gobo"; age = 88}

(* lets expand the let* to a bind: *)   
let is_retired' = 
  bind (get()) (fun {age;_} -> return (age > 65))

(* Now lets inline the bind definition to see whats actually happening: *)

let is_retired'' = 
  fun e -> (fun {age;_} -> return (age > 65)) ((get()) e) e

(* See how the e comes in and gets pushed on down; 
in particular the `get` gets it and returns the record *)  

(* lets finally inline get() and return to remove all the Reader references: *)

let is_retired''' = 
  fun e -> (fun {age;_} -> (fun _ -> (age > 65))) ((fun e -> e) e ) e

let _ = is_retired''' {name = "Gobo"; age = 88}

(* Monads, mathematically *)

(* 
  * To *really* be a monad you need to satisfy some invariants:

    1) bind (return a) f  ===  f a 
    2) bind a (fun x -> return x)  ===  a
    3) bind a (fun x -> bind b (fun y -> c))  ===  
       bind (bind a (fun x -> b)) (fun y -> c)
       (where c doesn't use x)

    Let us focus on the equivalent let* versions which are easier to read:
    1) let* x = return(a) in f x  ===  f a
    2) let* x = m in return(x)  ===  m
    3) let* x = m in let* y = m' in m'' ===
       let* y = (let* x = m in m') in m''
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
let return x = Some x
let ( let* ) = bind
let ( let+ ) f m = map m f
let ( >>= ) = bind
let ( >>| ) m f = bind m (fun x -> return (f x))

(* here is the version above we had that mostly used let* *)   
let ex_initial l1 l2 =
    let* l = option_combine l1 l2 in 
    let m = List.fold_left (fun acc (x,y) -> x + y :: acc) [] l in
    let* tail = option_tl m in 
    let* hd_tail = option_hd tail in
    return(hd_tail)

(* The "let m" (non-bind) here could be changed to a let* if we wrapped
  the defined value in a return -- this is using monad law 1) right-to-left. 
  (the "a" in the law is the List.fold .. which we abbreviated m with the let) *)    
let ex_first_law_applied l1 l2 =
    let* l = option_combine l1 l2 in 
    let* m = return(List.fold_left (fun acc (x,y) -> x + y :: acc) [] l) in
    let* tail = option_tl m in 
    let* hd_tail = option_hd tail in
    return(hd_tail)
  
(* We also noticed that the last let* followed by return was 
   just a no-op so we could have done the following which is 
   using monad law 2) right-to-left (letting a be `option_hd tail` )*)    
let ex_second_law_applied l1 l2 =
    let* l = option_combine l1 l2 in 
    let* m = return(List.fold_left (fun acc (x,y) -> x + y :: acc) [] l) in
    let* tail = option_tl m in 
    option_hd tail
    
(* Lastly we observed that pipes naturally associate like the rhs of the 
   third monad law, and the let* natural structure above is the lhs.
   So, with several applications of the third law left-to-right on the 
   previous we get this version.*)    
 let ex_third_law_applied l1 l2 =
    let* tail = 
      let* m = 
        let* l = option_combine l1 l2 in return(List.fold_left (fun acc (x,y) -> (x + y :: acc)) [] l) in
      option_tl m in
    option_hd tail

(* which is better written as the pipe version (below is identical to
   the above when the macros are expanded) *)

let ex_piped_version_of_previous l1 l2 =
  option_combine l1 l2 
  >>= fun l -> return @@ List.fold_left (fun acc (x,y) -> (x + y :: acc)) [] l
  (* .. Better equivalent syntax for above:   
  >>| List.fold fun acc (x,y) -> (x + y :: acc)) []  *)
  >>= option_tl
  >>= option_hd

(* Here is a smaller example of the third law to make it easier to see *)
  let ex_before_third_law l1 l2 =
    let* l = option_combine l1 l2 in 
    let* tail = option_tl l in
     return(tail)
     
  let ex_after_third_law l1 l2 =
      let* tail = 
        (let* l = option_combine l1 l2 in option_tl l) in 
        return(tail)

(* the following code is IDENTICAL to ex_after_third_law, just different macros used *)
  let ex_after_third_law_piped l1 l2 =
      ((option_combine l1 l2) >>= option_tl ) >>= return

(* Moral: monad pipes work only because the third law works! *)      

(* ***** *)
(* State *)
(* ***** *)

(* State is basically reader plus writer: old state comes in, new state comes out *)

(* Before doind the monad lets write some explicit threading code to show how its working.
   Key idea of state monad is you always get passed current state, return new state. *)

(* previous hand-over fist map state passing functionally *)
let _ : bool = StringMap.empty
               |> StringMap.add "hi" 3 
               |> StringMap.add "ho" 17
               |> StringMap.for_all (fun _ -> fun i -> i > 10)

(* Lets regularize it to be a bit more how the state monad works: each Map op 
   gets old map state, AND returns PAIR of value if any and new state *)
let map_set key data = fun m -> ((),StringMap.add key data m)
let map_for_all f = fun m -> ((StringMap.for_all m f),m)

let _ : bool = 
  let m = StringMap.empty in
  let ((),m') = (fun m -> map_set "hi" 3 m) m in
  let ((),m'') = (fun m -> map_set "hi" 3 m) m' in
  let (b,_) = (fun m -> map_for_all m (fun _ -> fun i -> i > 10)) m''
in b

(* Let us do a simple version of State, the whole state is just one value of type 's.
   This models a program with only one ref cell (e.g. one int, one StringMap, etc)
*)
module State = struct
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
  let bind (x : ('a, 's) t) (f: 'a -> ('b, 's) t) : ('b, 's) t =
    fun (s : 's) -> let (x', s') = x s in (f x') s'
  let return (x : 'a) : ('a, 's) t = fun s -> (x, s) (* just pass on the state we got in *)
  let map (m : ('a, 's) t) (f: 'a -> 'b): ('b, 's) t = 
      bind m (fun x -> return(f x))      
  type ('a, 's) monad_result = 'a * 's
  (* Run needs to get passed in an init state *)
  let run (e : ('a, 's) t) (init : 's): ('a, 's) monad_result = e init
  let set (s : 's) =
    fun (_ : 's) -> ((),s) (* return () as value, toss old state, make it s *)
  let get () =
    fun (s : 's) -> (s,s) (* return the state s AND propagate s onward *)
end

open State

let ( let* ) = bind
let ( let+ ) f m = map m f
let ( >>= ) = bind
let ( >>| ) m f = bind m (fun x -> return (f x))


(* Here is an OCaml state example for review, side effect is in compiler *)
let actual_state () = 
  let r = ref 0 in 
  let rv = !r in
  let () = r := rv + 1 in !r

(* Here is the same example re-coded in the State monad - no mutation at runtime *)

let simple_state () = 
  (* let r = ref 0 is in the `run` below - initial value at run launch *)
  let* rv = (get() : (int, int) t) in
  let* () = (set(rv + 1) : (unit, int) t) in 
  (get() : (int, int) t)

let _ = run (simple_state ()) 0

(* turning the above let* into the underlying bind to be more explicit *)

let simple_state () = 
  (* let r = ref 0 is implicit - initial value at run time *)
  bind (get()) (fun rv ->
  bind (set(rv + 1)) (fun () ->get()))

  let _ = run (simple_state ()) 0

(* Here is a bit larger example using statefulness of State 
   -- sum the elements of a list with a "mutable" counter *)

let rec sumlist = function
  | [] -> get ()
  | hd :: tl -> 
    let* n = get () in 
    let* () = set (n + hd) in
    sumlist tl

let _ : (int,int) State.monad_result  = run (sumlist [1;2;3;4;5]) 0

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
  type 'v m = 'v StringMap.t (* shorthand name for map w/string keys anf 'v values *)
  type ('a, 'v) t = 'v m -> 'a * 'v m
  let bind (x : ('a, 'v) t) (f: 'a -> ('b,'v) t) : ('b,'v) t =
    fun (m : 'v m) -> let (x', m') = x m in f x' m'
  let return (x : 'a) : ('a, 'v) t = fun m -> (x, m)
  let map (m : ('a, 's) t) (f: 'a -> 'b): ('b, 's) t = 
      bind m (fun x -> return(f x))   
  type 'a monad_result = 'a 
  (* Run needs to pass in an empty state *)
  let run (c : ('a, 'v) t) : 'a monad_result = 
    let mt_map = StringMap.empty in fst (c mt_map)
  let set (k : string) (v : 'a) : (unit, 'v) t =
    fun (s : 'a m) -> ((),StringMap.add k v s)
  let get (r : string) : ('a, 'v) t =
    fun (s : 'a m) -> (StringMap.find r s, s)
  let dump : 'a m -> 'a m * 'a m =
    fun (s : 'a m) -> (s, s)    
end

open State_map
let ( let* ) = bind
let ( let+ ) f m = map m f
let ( >>= ) = bind
let ( >>| ) m f = bind m (fun x -> return (f x))

let sumlist l =
  let* () = set "r" 0 in
  let rec sum = function
    | [] -> get "r"
    | hd :: tl -> 
      let* n = get "r" in 
      let* _ = set "r" (n + hd) in
      sum tl
  in sum l

let _ : int = run (sumlist [1;2;3;4;5])

(* Let us revisit the above Map example to show how hand-over-fist is behind the scenes *)
(* Here is what we had above *)
let _ : bool = StringMap.empty
               |> StringMap.add "hi" 3 
               |> StringMap.add "ho" 17
               |> StringMap.for_all (fun _ -> fun i -> i > 10)

(* Let's put this back in let form to make clear all the hand-over-fist passing we had to do *)
let _ : bool = 
  let m0 = StringMap.empty in
  let m1 = StringMap.add "hi" 3 m0 in 
  let m2 = StringMap.add "ho" 17 m1 in
  StringMap.for_all (fun _ -> fun i -> i > 10) m2

(* OK now lets use our State instead. Observe that there is no m1/m2 threading needed. *)

let map_eg_state =
  let* () = set "hi" 3 in
  let* () = set "ho" 17 in
  let* d = dump in (* dump dumps the whole state contents out, needed for the Map.forall *)
  return(StringMap.for_all (fun _ -> fun i -> i > 10) d)

let _ = run map_eg_state 

  let rec sum = function
    | [] -> get "r"
    | hd :: tl -> 
      let* n = get "r" in 
      let* _ = set "r" (n + hd) in
      sum tl


(* Type-directed monads 
 * Pretty much any OCaml type has a natural monad behind it
 * Some are more useful than others
 * Let us consider a monad where t is 'a list, what can that do?
*)

type 'a t = 'a list
(* Let us just try to write non-trivial bind/return that type check *)

let bind (m : 'a t) (f : 'a -> 'a t) : 'a t = 
  List.concat (List.map f m)

let return (v : 'a) : 'a t = [v]


(* ************** *)
(* Nondeterminism *)
(* ************** *)

(* A result is a *list* of values, and subsequent computations try all of them etc *)
(* It allows some programming patterns to be much more simply coded *)

(* Note we will just touch on this in lecture *)
module Nondet = struct
  type 'a t = 'a list
  let return (x : 'a) : 'a t = [x]
  let bind (m : 'a t) (f : 'a -> 'b t) : 'b t =
    List.concat @@ List.map f m
  let map (m: 'a t) (f: 'a -> 'b): 'b t = 
    bind m (fun x -> return(f x))
  type 'a monad_result = 'a list
  let run (m : 'a t) : 'a monad_result = m

  let zero : 'a t = []
  let either (a : 'a t) (b : 'a t): 'a t = a @ b
end

open Nondet
let ( let* ) = bind
let ( >>= ) = bind
let ( >>| ) m f = bind m (fun x -> return (f x))
let ( let+ ) f m = map m f

(* simple example *)
let _ : int t = let* x = [2;6] in [x;x + 1]

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
  | hd :: tl -> let* pow_member = powerset tl in
    either (* note that each one of these recursive calls itself can return several different answers *)
      (return pow_member)
      (return @@ hd :: pow_member)

(* all permutations of a list *)

let rec insert (x : 'a)  (l : 'a list) : 'a list t =
  either
    (return (x :: l))
    (match l with
     | [] -> zero
     | hd :: tl -> let* l' = insert x tl in return (hd :: l'))

let rec permut (l : 'a list) : ('a list t) =
  match l with
  | [] -> return []
  | hd :: tl -> let* l' = permut tl in insert hd l'

let _ : int list list = run (permut [1;2;3])

(* Continuations, super briefly *)

type 'a t = ('a -> 'a monad_result) -> 'a monad_result
(* 
   - the ('a -> 'a monad_result) is the continuation, the "rest of the computation"
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
