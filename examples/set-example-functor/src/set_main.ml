
module String_set = Simple_set.Make (String) (* Apply Make functor to make a String set *)

let do_search search_string filename =
  let lines = In_channel.with_open_bin filename In_channel.input_lines in
  let my_set =
    List.fold_left (fun set elt -> String_set.add elt set) String_set.empty lines
  in
  if String_set.contains search_string my_set then
    print_string @@ "\"" ^ search_string ^ "\" found\n"
  else
    print_string @@ "\"" ^ search_string ^ "\" not found\n"

let () =
  match Array.to_list Sys.argv with
  | _ :: search_string :: filename :: _ -> do_search search_string filename
  | _ -> failwith "Invalid arguments: requires two parameters, search string and file name"

