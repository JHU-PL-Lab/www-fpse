(* simple_set.ml with functors
   Defines the functor Make which allows us to build sets with comparison built-in
*)
open Core

module type EQ = sig
  type t
  val equal : t -> t -> bool
end

(* This is a functor which will make a simple set at type defined in EQ *)
module Make (M : EQ) = struct
  type t = M.t list

  let empty : t = []

  let add (x : M.t) (s : t) : t = x :: s

  let rec remove (x : M.t) (s : t) : t =
    match s with
    | [] -> failwith "item is not in set"
    | hd :: tl -> if M.equal hd x then tl else hd :: remove x tl

  let rec contains (x : M.t) (s : t) : bool =
    match s with
    | [] -> false
    | hd :: tl -> if M.equal x hd then true else contains x tl
end
