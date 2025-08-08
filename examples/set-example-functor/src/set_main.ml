(* Example of a main executable reading command line arguments.
   Uses Core libaries to parse command line arguments.
   Uses Simple_set for a set data structure (normally would use Core.Set) *)

open Core

(** [do_search search_string filename] searches for a string line in file.
  Only matches on the whole line, a very simple search. **)

module String_set = Simple_set.Make (String) (* Apply Make functor to make a String set *)

let do_search search_string filename =
  let my_set =
    filename
    |> In_channel.read_lines
    |> List.fold ~f:(fun set elt -> String_set.add elt set) ~init:String_set.empty
  in
  if String_set.contains search_string my_set
  then print_string @@ "\"" ^ search_string ^ "\" found\n"
  else print_string @@ "\"" ^ search_string ^ "\" not found\n"

(*
    The main program.
   let () = ... is a common idiom in a main module: the code will run when module loaded
   So, the code below de facto is the `main()` of our beloved C/Java/etc. world.
   You can also just directly put the code in with out the let (), but the parser
   can get confused as to whether it is part of the previous function or not.
*)

let () =
  match Array.to_list (Sys.get_argv ()) with
  | _ :: search_string :: filename :: _ -> do_search search_string filename
  | _ -> failwith "Invalid arguments: requires two parameters, search string and file name"

