(* Exercise to replace 'a option with ('a,string) result in Exception 
   Change `raise` to have a string parameter which will be the Error string. 
   Chase all the type errors to port this code, zip_monad also needs porting. *)
module Exception = struct

  module T = struct (* We are going to include this T below here, we just need to name this stuff *)
    type 'a t = ('a,string) result (* this is the type of monad-land, 'a is the underlying value *)
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

let zip_monad l1 l2 = match List.zip l1 l2 with Unequal_lengths -> raise () | Ok l -> return l

let ex_exception l1 l2 =
  let%bind l = zip_monad l1 l2 in 
  let m = List.fold l ~init:[] ~f:(fun acc (x,y) -> x + y :: acc) in
  let%bind tail = List.tl m in
  let%bind hd_tail = List.hd tail in
  return(hd_tail)

(* And, we can now "run" them from normal-land as well: *)
let _ : int = run @@ fun () -> ex_exception [1;2;3] [9;8;7]

let test_exn_monad x =
  try_with 
    (if x = 0 then raise () else return(1 + 100 / x))
    (fun () -> return(101))

let _ : int = run @@ fun () -> test_exn_monad 4
let _ : int = run @@ fun () -> test_exn_monad 0
