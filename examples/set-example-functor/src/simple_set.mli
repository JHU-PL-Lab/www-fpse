(* simple_set.mli
   Interface for simple set functor
*)

module type EQ = sig
  type t
  val equal : t -> t -> bool
end

module Make (M : EQ) : sig
    type t (* = M.t list *) (* If this snippet was present the type would be visible *)  
    val empty : t
    val add : M.t -> t -> t
    val remove : M.t -> t -> t
    val contains : M.t -> t -> bool
  end
