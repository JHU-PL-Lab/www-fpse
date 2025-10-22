open Core

module Reader_logger = struct
  module T = struct
    type log = string list (* we will tack a string list on the side which is the log messages *)
    type ('a, 'e) t = 'e -> 'a * log
    (* Beyond the type, the key to a monad is what bind/return are *)
    (* The key idea of the logger is to append the logs from the two sequenced computations *)
    let bind (m : ('a, 'e) t) ~(f : 'a -> ('b, 'e) t): ('b,'e) t =
      fun (e : 'e) -> let (x,l') = m e in let (x',l'') = f x e in (x',l'@l'')
    let map = `Define_using_bind
    let get () : ('e, 'e) t = fun (e : 'e) -> (* fill in *)

    let return (x : 'a) : ('a, 'e) t = fun _ -> (* fill in *)

  end
  include T
  include Monad.Make2(T) (* Make2 is for two type parameters *)
  type 'a monad_result = 'a * log
  let run (m: unit -> ('a, 'e) t) (e : 'e): 'a monad_result = m () e
  let log msg : (unit,'e) t = fun _ -> ((), [msg])
end

open Reader_logger
open Reader_logger.Let_syntax

type globals = {
  name: string;
  age: int;
}

let is_retired = fun () ->
  let%bind {age;_} = get() in 
  let%bind () = log "Hi there!" in
  return (age > 65)

(* Note the above is a function due to `fun e` in monad bind;
   need to run it to execute the code *) 

let _ = run is_retired {name = "Gobo"; age = 88}
