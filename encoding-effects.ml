(* ***************************** *)
(* Encoding effects functionally *)
(* ***************************** *)

(* Aka "A Journey through Monad Land" *)

open Core

(*
  * We have seen so far the advantages of functional programming
  * But, sometimes it is a large handicap to not have side effects
  * One middle ground is possible: *encode* effects using functional code only
    - we already saw a bit of this with the option type replacing exceptions
    - also the use of piping such as 
*)

let _ : bool = Map.empty(module String) 
               |> Map.set ~key: "hi" ~data: 3 
               |> Map.set ~key: "ho" ~data: 17
               |> Map.for_all ~f:(fun i -> i > 10)

(*   etc which is an informal "hand over fist passing" encoding 
     of what would normally be a mutable structure 

  * Idea: make a more structured encoding which is not informal like the above
  * Think of it as defining a language-inside-a-language: "monad-land"
  * Will allow functional code to be written which "feels" close to effectful code
  * But it still will preserve the referential transparency etc in most places
  * The mathematical basis for this is a structure called a *monad*.

*)

(* ******************* *)
(* Encoding Exceptions *)
(* ******************* *)

(* 
  * Let's start with using 'a option's Some/None to encode exception effects
  * We already saw several examples of this
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
 * Here is its code: 
 *)

let bind (opt : 'a option) ~(f : 'a -> 'b option) : ('b option) = 
  match opt with 
  | None -> None 
  | Some v -> f v

let _ = bind (zip [1;2] [3;4]) ~f:(fun _ -> None)

(* 
  * bind *sequences* two side effects
  * Observe this is nothing but a "bubbler" to avoid all the match-es like above.
    - if the first argument None's then skip the f run.
  * besides the bubbling of None's it is a lot like a "let" expression.
    -  bind code1 ~f:code2  first runs code1, and if it is non-None runs code2 on result.
  * This suggests a macro:
  `let%bind x = e1 in e2`  macro expands to `bind e1 ~f:(fun x -> e2)`
  * Using the macro, code can look more like regular code with implicit effects
  * We have pushed monad-land into hiding a bit
*)

(* 
 * Here is what Option.return is
 * It is called return because it is returning a "regular" value to the monad 
 * I have to say the name seems backwards to me but it is the traditional name
*)
let return (v : 'a) : 'a option = Some v

open Option (* don't generally open Option, we are doing it just for hacking examples here *)
open Option.Let_syntax (* This opens a macro let%bind etc to make code more readable *)

(* 
 * OK now let us redo the above example with bind (using the macro version) 
 * This code looks more readable than the original, right?? 
 *)

let ex_bind_macro l1 l2 =
  let%bind l = zip l1 l2 in 
  let m = List.fold l ~init:[] ~f:(fun acc (x,y) -> x + y :: acc) in
  let%bind tail = List.tl m in 
  let%bind hd_tail = List.hd tail in
  return(hd_tail)

(* Let us write out the bind calls (expand the macro) to show why the macro is good: *)
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

(* Equivalent pipe version syntax 
   * a >>= b is just an infix form of bind, it is nothing but bind a b
   * a >>| b is used when b is just a "normal" function which is not returning an option.
   - encoding:  a >>| b is bind a (fun x -> return (f x))
   - the additional "return" "lifts" f's result back into monad-land
   * If you are just sequencing a bunch of function calls as above it reads better with pipes
*)

let ex_piped l1 l2 =
  ((((zip l1 l2 
      >>| List.fold ~init:[] ~f:(fun acc (x,y) -> (x + y :: acc)))
     >>= List.tl)
    >>= List.hd)
   >>= return)


(* Here are some other versions that came up in lecture *)

(* First, the last return is in fact not needed in either let%bind or piped version
   as the previous 'a t typed value is all we need *)

let ex_bind' l1 l2 =
  bind (zip l1 l2) ~f:(fun l ->
      let m = List.fold l ~init:[] ~f:(fun acc (x,y) -> x + y :: acc) in
      bind (List.tl m) ~f:(fun tail -> (List.hd tail)))

let ex_piped' l1 l2 =
  zip l1 l2 
  >>| List.fold ~init:[] ~f:(fun acc (x,y) -> (x + y :: acc))
  >>= List.tl
  >>= List.hd

(* A subtle point is that the pipe notation is associating the sequencing in a different
   order.  
   - We all know that a;(b;c) "is the same order as" (a;b);c (e.g. in OCaml they give same results)
   - for let, the rule is a bit more convoluted:
       let xa = a in let xb = b in c   is   let xc = (let xb = (let xa = a in b) in c)
   - the let%bind notation is doing the former and the pipes the latter.
   - Note that not all monads in OCaml have this associative property but they *should*
   - the mathematical notion of a monad must have this, it is a *monad law* (more later)

*)

(* Here we also see how the >>| is a map *)

let ex_piped_expanded l1 l2 =
  bind(bind (map (zip l1 l2) ~f:(List.fold ~init:[] ~f:(fun acc (x,y) -> (x + y :: acc))))
         ~f: List.tl)
    ~f: List.hd

let ex_piped_expanded_percent l1 l2 =
  let%bind tail = 
    let%bind m = 
      let%map l = zip l1 l2 in List.fold l ~init:[] ~f:(fun acc (x,y) -> (x + y :: acc)) in
    List.tl m in
  List.hd tail

(* And, the >>| is like >>= but the second computation (the ~f one) is expected to return a 
   non-monadic value and >>| automatically lifts it to monad-land with a return 
   Here we turn >>| into a normal monad-pipe >>= with explicit return to illustrate. *)

let ex_piped'' l1 l2 =
  zip l1 l2 
  >>= fun l -> return(List.fold l ~init:[] ~f:(fun acc (x,y) -> (x + y :: acc)))
  >>= List.tl
  >>= List.hd

(* 
  * Option extended to a more general Exception monad
  * This example also shows how we can define our own monads with Base.Monad.Make
*)

module Exception = struct

  module T = struct type 'a t = 'a Option.t
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
      | None -> failwith "uncaught exception"
    (* Some more exception-looking syntax; also not in Core.Option *)
    let raise () : 'a t = None
    let try_with (m : 'a t) (f : unit -> 'a t): 'a t =
      match m with 
      | None -> f () 
      | Some x -> Some x
  end
  include T
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
   based on version in Base.Monad *)

module Ident = struct
  type 'a t = 'a (* the identity wrapper: 'a wrapped is 'a *)
  include Monad.Make (struct
      type nonrec 'a t = 'a t
      let bind (a : 'a t) ~(f : 'a -> 'b t) = f a
      let return (a : 'a t) = a
      let map = `Custom (fun (a : 'a t)  ~(f : 'a -> 'b) -> f a)
      type 'a result = 'a
      let run (a : 'a t) : 'a result = a
    end)
end

(* It might be more obvious how this is an indentity by having
   an actual wrapper in place -- here is an explicit identity monad *)

module Ident_explicit = struct
  type 'a t = Wrapped of 'a
  include Monad.Make (struct
      type nonrec 'a t = 'a t
      let unwrap (Wrapped a) = a
      let bind (a : 'a t) ~(f : 'a -> 'b t) = f (unwrap a)
      let return (a : 'a) = Wrapped a
      let map = `Custom (fun (a : 'a t)  ~(f : 'a -> 'b) -> Wrapped(f @@ unwrap a))
      let run (a : 'a t) = unwrap a
    end)
end

open Ident_explicit
open Ident_explicit.Let_syntax
let oneplustwo' = 
  let%bind onev = return 1 in 
  let%bind twov = return 2 in 
  return (onev + twov)


(* **************************** *)
(* Print / Output / Write / Log *)
(* **************************** *)

(* 
* There is a family of monads where the effect is "return more stuff on the side"
  i.e. the 'a t type is 'a * ... stuff ... or some such
* Here is one such simple monad; there are many
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
  let%bind _ = log "Starting!" in
  let%bind onev = return 1 in 
  let%bind twov = return 2 in 
  let%bind r = return (onev + twov) in
  let%bind _ = log "Ending!" in
  return(r)



(* **************** *)
(* Input aka Reader *)
(* **************** *)

(* 
 * All the monads up to now were "first order", the carrier type has no function types
 * Monads get *really* useful with higher-order monads, functions in the .t type
 * The simplest example is probably "Reader"
 * Don't think of it as "input", it is more like an "environment" of values you get implicitly
 *)


module Reader = struct
  module T = struct
    (* 
   * In Logger above we *returned* extra goodies, here we are *passing in* extra goodies 
   * Here we let the goodies be arbitrary, of type 'e for environment
  *)
    type ('a, 'e) t = ('e -> 'a)
    (* bind needs t return a 'e -> 'a so it starts with fun e ->
       This means it gets in the goodies e from its caller
       bind's job is then to pass on the goodies to its two sequenced computations *)
    let bind (m : ('a, 'e) t) ~(f : 'a -> ('b,'e) t) : ('b, 'e) t = 
      fun (e : 'e) -> (f (m e) e) (* Pass the goodies e to m and f! *)
    let map = `Define_using_bind
    let return (x : 'a) = fun (_: 'e) -> x (* not using the goodies here *)
    let get () = fun (e : 'e) -> e (* since every monad elt gets goodies, grab here *)
    (* Here is an extra function to change goodies mid-stream if needed 
       Note this is not like state, look at bind and you will see two sequenced
       computations still get the same goodies-state.
    *)
    let put_env (f : 'e -> 'e) (m : ('a, 'e) t) : ('a, 'e) t = 
      fun (e : 'e) -> m (f e)
    let run (m : ('a, 'e) t) (e : 'e) = m e
  end
  include T
  include Monad.Make2(T) (* Make2 is where there are *2* type parameters on t *)
end

(* A simple example *)
open Reader
open Reader.Let_syntax

(* Here is a simple environment type *)
type d = {
  name: string;
  age: int;
}

let is_retired = 
  let%bind r = get() in return (r.age > 65)

let _ : bool = run is_retired {name = "Gobo"; age = 88}

(* Bigger example 
   from https://gist.github.com/VincentCordobes/fff2356972a88756bd985e86cce03023 *)

let to_string age name = 
  "name: " ^ name ^ "\nage: " ^ string_of_int age
let name d = d.name

let a_run : (string, d) t =
    let%bind age0 = return 24 in
    let%bind age1 = return(age0 + 1) in
    let%bind r = get () in
    let record = to_string age1 r.name in
    return record

let a_run : (string, d) t =
    let%bind age0 = return 24 in
    let%bind age1 = return(age0 + 1) in
    match%bind get () with {name} -> (* another ppx_let extension, monadic match *)
    let record = to_string age1 name in
    return record

let m = put_env (fun d -> {d with name="Vincent"}) a_run

let () = printf "%s\n" (run m {name= "Jack"; age= 85})

(* Pipe alternative *)

let m' =
  return 24
  >>| (fun x -> x + 1)
  >>= (fun x -> get () 
        >>| name
        >>| (to_string x))
  |> put_env (fun d -> {d with name="Vincent"})

(* The following shows how a changed envt only propagates on that node, not
   from the let to the in.. need both reader and writer to do that! *)
let no_state : (string, d) t =
    let%bind age0 = return 24 in
    let%bind age1 = put_env (fun d -> {d with name="Vincent"}) (return(age0 + 1)) in
    match%bind get () with {name} -> (* another ppx_let extension, monadic match *)
    let record = to_string age1 name in
    return record

let () = printf "%s\n" (run no_state {name= "Jack"; age= 85})

(* But, the change will propagate locally "down" *) 

let downward_prop : (string, d) t =
    let%bind age0 = return 24 in
    let%bind age1 = return(age0 + 1) in
    match%bind put_env (fun d -> {d with name="Vincent"}) (get ())
       with {name} -> (* another ppx_let extension, monadic match *)
    let record = to_string age1 name in
    return record

let () = printf "%s\n" (run downward_prop {name= "Jack"; age= 85})


(* Alternative Reader with a Core.Map as the data structure *)
(* We will skip details of this in lecture as it is very similar to Reader *)

module Environment = struct
  module T = struct
    type 'v env = (string, 'v, String.comparator_witness) Map.t
    type ('a,'v) t = 'v env -> 'a

    let return (x : 'a) : ('a,'v) t = fun (_ : 'v env) -> x
    let bind (m : ('a,'v) t) ~(f : 'a -> ('b,'v) t) : ('b,'v) t =
      fun e -> f (m e) e
    let map = `Define_using_bind
    type 'a result = 'a
    let run (m : ('a,'v) t) : 'a result = m (Map.empty(module String))
    let get (s : string) : ('a,'v) t =
      fun (e : 'v env) -> Map.find_exn e s
    let put_env (s : string) (d : 'v) (m : ('a,'v) t) : ('a,'v) t =
      fun  (e : 'v env) -> m (Map.set ~key:s ~data:d e)
  end
  include(T)
  include(Monad.Make2(T))
end

(* True Monads, mathematically speaking *)

(* 
  * To *really* be a monad you also need to satisfy some invariants.
    - bind (return a) ~f  =  f a 
    - bind a ~f:(fun x -> return x)   =  a
    - bind a (fun x -> bind b ~f:(fun y -> c))  =  bind (bind a ~f:(fun x -> b)) ~f:(fun y -> c)
  * (Note "=" here means we can replace one with the other and notice no difference)
  * These are called the "Monad Laws"
  * The last one is the trickiest but we hit on it above, it is associativity of bind
  * The first two are mostly intuitive properties of injecting normal values into a monad
  * Note how the laws are too strong (logically) to write as assert's, but can be tested on examples.
  * We will look at the first two vis a vis Reader
*)


(* ***** *)
(* State *)
(* ***** *)

(* as a warm-up to state, let's just make a Monad with a simple counter. 
   * This monad is like State in that it 
   - gets in some side data (the integer count here)
   - possibly does something with it
   - passes it on for future potential users 
   - and, we can in fact have get/set for read/write on this int data - mini-state! *)

module Count = struct
  module T = struct
    (* Here is the monad type: we need to *thread* the count through all computations
       So, pass count in like Reader *and* return it like Logger *)
    type 'a t = int -> 'a * int
    (* Let us now construct bind.
       1) Like Reader, the result is a fun i : int -> ... since we pass in count
       2) First we pass the count i, plus one, to the first computation x
       3) x returns a pair with a new count, i'
       4) Now the key to being a stateful count is thread that latest state on to f
       -- f will then "see" the count of steps of x.
    *)
    let bind (x : 'a t) ~(f: 'a -> 'b t) : 'b t =
      fun (i : int) -> let (x', i') = x i in f x' i'
    let return (x : 'a) : 'a t = fun i -> (x, i)
    let map = `Define_using_bind
    type 'a result = 'a * int
    (* Run needs to pass in an initial count, 0 *)
    let run (c : 'a t) : 'a result = c 0
    let inc () : 'a t = 
      fun (n : int) -> (n+1,n+1) (* return +1 of count AND set state to +1 *)
    (* This is in fact a really simple state monad if we add get and set *)
    let set (n : int) =
      fun (_ : int) -> ((),n) (* return () as value, CHANGE state to n *)
    let get () =
      fun (n : int) -> (n,n) (* return the state n AND propagate n as state *)

  end
  include T
  include Monad.Make(T)
end

open Count
open Count.Let_syntax

let oneplustwo_incing = 
  let%bind _ = inc () in
  let%bind onev = return 1 in 
  let%bind twov = return 2 in 
  let%bind r = return (onev + twov) in
  let%bind _ = inc () in
  return(r);;

(* Count is also a simple one-element integer store, we added set/get for that *)

(* Here is an OCaml example of how state is implicitly threaded along *)

let r = ref 0 in
let () = r := !r + 1 in
let result = !r in result (* r implicitly has latest value *)

(* Here is the same example in the Count monad *)

let simple_state () = 
  let%bind rv = get() in
  let%bind () = set(rv + 1) in
  let%bind result = get() in return(result)

run @@ simple_state ();;

(* Here is a bit larger example using statefulness of Count *)

let rec sumlist = function
  | [] -> get ()
  | hd :: tl -> 
    let%bind n = get () in 
    let%bind _ = set (n + hd) in
    sumlist tl

let _ : int Count.result  = run (sumlist [1;2;3;4;5])


(* Let us try to write inc ourselves using the Count monad's set/get 
   It can't just be a normal-land function, it must be in monad-land to use side effect 
   Note we also can't write set (get() + 1) because get is in monad-land and + is not!
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
 * Here is a more general State monad - the store is an arbitrary Map from strings to values
 * It is Count without inc but with a Map on strings in place of single int
 *)

module State = struct
  module T = struct
    type 'v m = (string, 'v, String.comparator_witness) Map.t (* shorthand name for map w/string keys *)
    (* Here is the monad type: we need to *thread* the state through all computations
       So, pass it in like Reader *and* return it like Logger *)
    type ('a, 'v) t = 'v m -> 'a * 'v m
    (* Let us now construct bind.
       1) Like Reader, the result is a fun m -> ... since we pass in state
       2) First we pass the state we got to the first computation, x
       3) x returns a pair with a new state, m'
       4) Now the key to being stateful is pass that latest state on to f
       -- This sequence means assignments in x will be "seen" in f, the key idea of mutation
    *)
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

(* simple eg *)
bind [2;6] ~f:(fun x -> [x;x + 1]);;

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
   (lets use Count to stand for State for simplicity - just one cell holding an int)
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

