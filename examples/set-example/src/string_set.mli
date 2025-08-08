type t (* Declare a type t, but don't define it, so the type is hidden to all users *)
val empty : t
val add : string -> t -> t
val remove : string -> t -> t
val contains : string -> t -> bool