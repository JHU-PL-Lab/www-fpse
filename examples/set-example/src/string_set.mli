(* type t = string list *)
type t (* this type declaration *hides* t's internals *)
val empty : t
val add : string -> t -> t
val remove : string -> t -> t
val contains : string -> t -> bool