(* Selected examples from the Lwt Manual 
   https://ocsigen.org/lwt/latest/api/Lwt

   Uncomment whichever single example you want to test, and then build/run
*)

(* Lwt doesn't define let*, they use let%lwt but its historical baggage.  We will use let*: *)
let ( let* ) = Lwt.bind

(* Example showing promise resolution in action *)

(* 
let () =
  Lwt_main.run
    (let three_seconds : unit Lwt.t = Lwt_unix.sleep 3. in
     let five_seconds : unit Lwt.t = Lwt_unix.sleep 5. in
     let* () = three_seconds in
     let* () = Lwt_io.printl "3 seconds passed" in
     let* () = five_seconds in
     Lwt_io.printl "Only 2 more seconds passed") *)

(* choose chooses between promises, only one needs to resolve
   join waits for multiple promises to be resolved *)

(* let () =
   let p_1 =
     let* () = Lwt_unix.sleep 3. in
     Lwt_io.printl "Three seconds elapsed"
   in

   let p_2 =
     let* () = Lwt_unix.sleep 5. in
     Lwt_io.printl "Five seconds elapsed"
   in

   let p_3 = Lwt.choose [ p_1; p_2 ] in (* Lwt.join will resolve when both finish *)
   Lwt_main.run p_3 *)

(* Example showing how to launch a new independent coroutine *)

(* let () =
   let rec show_nag () : _ Lwt.t =
     let* () = Lwt_io.printl "Please enter a line" in
     let* () = Lwt_unix.sleep 1. in
     show_nag ()
   in
   Lwt.async (fun () -> show_nag ());

   Lwt_main.run begin
     let* line = Lwt_io.(read_line stdin) in
     Lwt_io.printl line
   end *)

(* Example showing how a compute-intensive computation can insert pause
   to allow other coroutines to get a time slice  *) 

let () =
  let rec handle_io () =
    let* () = Lwt_io.printl "Handling I/O" in
    let* () = Lwt_unix.sleep 0.1 in
    handle_io ()
  in

  let rec compute n =
    if n = 0 then Lwt.return ()
    else
      let* () =
        if n mod 1_000_000 = 0 then Lwt.pause () else Lwt.return ()
      in
      compute (n - 1)
  in

  Lwt.async handle_io;
  Lwt_main.run (compute 100_000_000)
