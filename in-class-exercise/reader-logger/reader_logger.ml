(* Combine reader and logger functionality together *)
[@@@ocaml.warning "-26"]
module Reader_logger = struct
  type log = string list
  type ('a, 'e) t = 'e -> 'a * log
  let bind (m : ('a, 'e) t) (f : 'a -> ('b, 'e) t): ('b,'e) t =
    fun (e : 'e) -> let (x,l') = m e in failwith "unimplemented" (* fill in the rest of bind *)
  let map = `Define_using_bind
  let get () : ('e, 'e) t = fun (e : 'e) -> failwith "unimplemented" (* fill in *)
  let return (x : 'a) : ('a, 'e) t = fun _ -> failwith "unimplemented" (* fill in *)
  type 'a monad_result = 'a * log
  let run (m: unit -> ('a, 'e) t) (e : 'e): 'a monad_result = m () e
  let log msg : (unit,'e) t = fun _ -> ((), [msg])
end

open Reader_logger
let ( let* ) = bind (* add let* sugar for our monad (can't use functor since it has two types) *)

type globals = {
  name: string;
  age: int;
}

(* A simple test, a Reader example with a log message added: *)
let is_retired = fun () ->
  let* {age;_} = get() in 
  let* () = log "Hi there!" in
  return (age > 65)

let _ = run is_retired {name = "Gobo"; age = 88}
