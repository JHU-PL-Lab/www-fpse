(* 
  In this exercise, we'll replace the 'a option with ('a, string) result in
  the lecture Exception monad.

  You will change `raise` to have a string parameter, which will be put in result's Error constructor.
  You will chase all type errors to port this code over.

  When you redo `run` below have it fail with the string error message if there was an error
    i.e. make it behave more like OCaml exceptions.
*)
module Exceptional = struct
  (* This type has been updated to ('a, string) result for you, but other code mostly the same. *)

  type 'a t = ('a,string) result

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

(* Lets use our usual functor to get nice syntax *)
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

open Exceptional
open Make_syntax(Exceptional)

(* Here are some tests from the lecture notes ported to Exceptional
   Note we have to redefine the auxiliary functions to work over Exceptional *)

let combine_opt l1 l2 = try return (List.combine l1 l2) with _ -> raise ()
let tl_opt = function [] -> raise () | _ :: tl -> return tl
let hd_opt = function [] -> raise () | hd :: _ -> return hd

let ex l1 l2 =
  let* l = combine_opt l1 l2 in
  let m = List.map (fun (x, y) -> x + y) l in (* never None, so no let* *)
  let* tail = tl_opt m in
  let* hd_tail = hd_opt tail in
  return hd_tail (* "return TO the monad" *)

let _ : int = run @@ fun () -> ex [1;2;3] [9;8;7]

let test_exn x =
  try_with 
    (if x = 0 then raise () else return(1 + 100 / x))
    (fun () -> return(101))

let _ : int = run @@ fun () -> test_exn 4
let _ : int = run @@ fun () -> test_exn 0
