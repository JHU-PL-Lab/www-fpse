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
  zip l1 l2 
  >>| List.fold ~init:[] ~f:(fun acc (x,y) -> (x + y :: acc))
  >>= List.tl
  >>= List.hd
  >>= return

(* Observe the return line is not needed *)

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
       - map is like bind but the f is just a normal-land function *)
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

(* a simple example.  Note this is very artificial, don't enter monad-land unless you need to! *)
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

(* 
  * Lift the above back into normal-land from the monad 
  * Note here we in fact already "ran" the code but not so in all monads
*)
let _ : int = run oneplustwo'

(* Redoing the previous example we did on Option using Exception now *)
let ex_exception l1 l2 =
  let%bind l = zip l1 l2 in 
  let m = List.fold l ~init:[] ~f:(fun acc (x,y) -> x + y :: acc) in
  let%bind tail = List.tl m in
  let%bind hd_tail = List.hd tail in
  return(hd_tail)

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
   Taken from Base.Monad *)

module Ident = struct
  type 'a t = 'a (* the identity wrapper: 'a wrapped is 'a *)

  include Monad.Make (struct
      type nonrec 'a t = 'a t
      let bind a ~f = f a
      let return a = a
      let map = `Custom (fun a ~f -> f a)
    end)
end

(* Observe there is no run in Base's notion of a Monad *)

(* **************************** *)
(* Print / Output / Write / Log *)
(* **************************** *)

module Log = struct
  module T = struct
    type log = string list
    type 'a t = log -> 'a * log

    let return (x : 'a) : 'a t = fun l -> (x, l)
    let bind (m : 'a t) ~(f : 'a -> 'b t): 'b t =
      fun l -> let (x,l') = m l in f x l'
    let map = `Define_using_bind
  end
  include T
  include Monad.Make(T)
  type 'a result = 'a * log
  let run (m: 'a t): 'a result =
    let (x,l) =  m [] in (x,l)
  let log msg : unit t = fun l -> ((), msg :: l)
end

module Exception_test = (Log : Monadic) (* verify again it is a monad *)

open Log
open Log.Let_syntax

(* A stupid example *)

let log_abs n = run
    (if n >= 0 
     then let%bind _ = log "positive" in return n
     else let%bind _ = log "negative" in return (-n))


(* **************** *)
(* Input aka Reader *)
(* **************** *)

module Reader = struct
  module T = struct
    type ('a, 'e) t = ('e -> 'a)
    let run (m : ('a, 'e) t) (d : 'e) = m d
    let bind (m : ('a, 'e) t) ~(f : 'a -> ('b,'e) t) = 
      fun (d : 'e) -> (f (m d) d)
    let map = `Define_using_bind
    let return (x : 'a) = fun (_: 'e) -> x
    let put_env (f : 'e -> 'e) (m : ('a, 'e) t) : ('a, 'e) t = 
      fun (d : 'e) -> m (f d)
    let get () = fun (d : 'e) -> d
  end
  include T
  include Monad.Make2(T) (* Make2 is where there are *2* type parameters on t *)
end

(* Example from https://gist.github.com/VincentCordobes/fff2356972a88756bd985e86cce03023 *)

type d = {
  name: string;
  age: int;
}
let to_string age name = 
  "name: " ^ name ^ "\nage: " ^ string_of_int age
let name d = d.name
let () =
  let open Reader in
  let m =
    return 24
    >>| (fun x -> x + 1)
    >>= (fun x -> get () 
          >>| name
          >>| (to_string x))
    |> put_env (fun d -> {d with name="Vincent"})
  in
  let env = {name= "Jack"; age= 85} in
  printf "%s\n" (run m env)

(* Alternative Reader with a Core.Map as the data structure *)

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
    - bind (return a) ~f ≈ f a 
    - bind a ~f:(fun x -> return x) ≈ a
    - bind (bind a ~f:(fun x -> b)) ~f:(fun y -> c) ≈ bind a (fun x -> bind b ~f:(fun y -> c))
  * These are called the "Monad Laws"
  * Note how they are too strong (logically) to write as assert's, but can be tested on examples.
  * We will think for a bit about how the above monads fare vis a vis the laws
*)


(* ***** *)
(* State *)
(* ***** *)

(* A simple State monad - just uses a Map with String keys as the store *)

module State = struct
  module T = struct
    type 'a m = (string, 'a, String.comparator_witness) Map.t
    type ('a, 'v) t = 'v m -> 'a * 'v m

    let return (x : 'a) : ('a, 'v) t = fun v -> (x, v)
    let bind (x : ('a, 'v) t) ~(f: 'a -> ('b,'v) t) : ('b,'v) t =
      fun v -> let (x', v') = x v in f x' v'
    let map = `Define_using_bind
    type 'a result = 'a 
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

(* TODO: examples of above *)
