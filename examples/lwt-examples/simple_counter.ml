(* Very Simple I/O example

 Derived from https://www.baturin.org/code/files/counter-server.ml
 
    Increment a shared counter or read its current value from stdin/stdout
*)

open Lwt
let (let*) = bind

[@@@ocaml.warning "-6"]

(* mutable counter *)
let counter = ref 0

let handle_message msg =
  match msg with
  | "read" -> string_of_int !counter
  | "inc" ->
      counter := !counter + 1;
      "Counter has been incremented"
  | _ -> "Unknown command"

let rec handle_connection () =
  let* msg = Lwt_io.read_line_opt Lwt_io.stdin in
  match msg with
  | Some msg ->
      let reply = handle_message msg in
      Lwt_io.write_line Lwt_io.stdout reply >>= handle_connection
  | None -> Lwt_io.write_line Lwt_io.stdout "Connection closed"

let () =
  Lwt_main.run @@ handle_connection ()
