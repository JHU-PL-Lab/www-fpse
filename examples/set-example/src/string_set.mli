type t = string list (* Type declarations are by default copied from .ml to .mli file *)
(* type t (* this alternate version of type t declaration *hides* t's internals *) *)
val empty : t
val add : string -> t -> t
val remove : string -> t -> t
val contains : string -> t -> bool