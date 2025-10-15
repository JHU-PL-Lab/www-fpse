open Core

(* 
  In this exercise, we'll replace the 'a option with ('a, string) result in
  the lecture Exception monad.

  You will change `raise` to have a string parameter, which will be put in result's Error constructor.
  You will chase all type errors to port this code over.
*)
module Exception = struct
  (* We are going to include this T below here, we just need to name this stuff. *)
  module T = struct
    (* This type has been updated to ('a, string) result for you, but other code mostly the same. *)
    type 'a t = ('a,string) result

    (* return injects a normal-land computation into monad-land. *)
    let return (x: 'a) : 'a t = Some x

    (* bind sequences two monad-land computations where the 2nd can use 1st's underlying value *)
    let bind (m: 'a t) ~(f: 'a -> 'b t): 'b t =
      match m with
      | Some x -> f x
      | None -> None 

    (* We let Core define `map` for us by using the `bind` we just defined. *)
    let map = `Define_using_bind

    (* `run` is the standard name for 
        1) enter monad-land from normal-land 
        2) run a computation in monad-land;
        3) transfer the final result back to normal-land 

      You should make a change here so that string message inside Error is used for failwith.
    *)

    type 'a monad_result = 'a (* 'a monad_result is the type transferred out of monad-land at end of run *)
    let run (m : unit -> 'a t) : 'a monad_result =
      match m () with 
      | Some x -> x 
      | None -> failwith "monad failed" (* CHANGE to fail with the string of the Error! *)
    (*
      For exception-looking syntax, we'll define a `raise` function. You should change
      this to have a string message, which gets put in the Error constructor.
    *)
    let raise () : 'a t = None (* CHANGE! raise now takes a string parameter *)

    let try_with (m : 'a t) (f : unit -> 'a t): 'a t =
      match m with 
      | Some x -> Some x
      | None -> f () 
  end
  include T (* The same naming trick used here as with Comparable *)
  include Monad.Make(T) (* Core.Monad functor to add lots of extra goodies inclduing let%bind etc*)
end

open Exception
open Exception.Let_syntax

(* Redoing the zipping example above using Exception now *)

let zip_monad l1 l2 = match List.zip l1 l2 with Unequal_lengths -> raise () | Ok l -> return l

(* List.hd/tl return Some/None but we need Exception versions of them: *)
let tl_or_error = function
  | [] -> Error "No tail of empty list"
  | _ :: tl -> Ok tl

let hd_or_error = function
  | [] -> Error "No head of empty list"
  | hd :: _ -> Ok hd

let ex_exception l1 l2 =
  let%bind l = zip_monad l1 l2 in 
  let m = List.fold l ~init:[] ~f:(fun acc (x,y) -> x + y :: acc) in
  let%bind tail = List.tl m in (* use hd_or_error etc here instead, we need Ok/Error results *)
  let%bind hd_tail = List.hd tail in
  return(hd_tail)

(* tests *)

let _ : int = run @@ fun () -> ex_exception [1;2;3] [9;8;7]

let test_exn_monad x =
  try_with 
    (if x = 0 then raise () else return(1 + 100 / x))
    (fun () -> return(101))

let _ : int = run @@ fun () -> test_exn_monad 4
let _ : int = run @@ fun () -> test_exn_monad 0
