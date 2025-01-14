module List = ListLabels

let read_file path = try Some (In_channel.with_open_bin path In_channel.input_all) with _ -> None

let write_file (path : string) (content : string) : unit =
  Out_channel.with_open_text path (fun oc ->
      Out_channel.output_string oc content;
      Out_channel.close oc)

type manifest_item = { original_path : string; compiled_js_path : string; module_name : string option }
type manifest = manifest_item list

(* // extract-client input.re Prop_with_many_annotation *)
(* Parse a single line using Scanf *)
let parse_line line =
  try
    (* Try to parse with prop_name *)
    Scanf.sscanf line "// extract-client %s %s" (fun filename prop_name -> Ok (filename, Some prop_name))
  with End_of_file | Scanf.Scan_failure _ -> (
    try
      (* Try to parse without prop_name *)
      Scanf.sscanf line "// extract-client %s" (fun filename -> Ok (filename, None))
    with End_of_file | Scanf.Scan_failure _ -> Error "Invalid extract command format")

let parse_manifest_data ~path content : manifest_item list =
  String.split_on_char '\n' content
  |> List.filter_map ~f:(fun line ->
         match parse_line (String.trim line) with
         | Ok (original_path, module_name) -> Some { compiled_js_path = path; original_path; module_name }
         | Error _ -> None)

let render_manifest ~path (manifest : manifest) =
  let register_client_components =
    List.map manifest ~f:(fun { original_path; compiled_js_path; module_name } ->
        (* let _module_name =
          original_path |> Filename.basename (* Gets "xxx.re" from the full path *)
          |> Filename.remove_extension (* Removes ".re" extension *)
        in *)
        let export =
          match module_name with Some name -> Printf.sprintf "%s.make_client" name | None -> "make_client"
        in
        Printf.sprintf
          "window.__client_manifest_map[\"%s\"] = React.lazy(() => import(\"./%s\").then(module => {\n\
          \  return { default: module.%s }\n\
           }))"
          original_path compiled_js_path export)
  in
  let content =
    Printf.sprintf
      {|// Generated by client_components_mapper
const React = require("react");
window.__client_manifest_map = window.__client_manifest_map || {};
%s|}
      (String.concat "\n" register_client_components)
  in
  write_file path content

let is_js_file path =
  let ext = Filename.extension path in
  ext = ".js" || ext = ".bs.js"

(* TODO: refactor path to be a Filepath *)
let capture_all_client_component_files_in_target path =
  let rec traverse_fs path =
    try
      match Sys.is_directory path with
      | true ->
          (* Handle directory *)
          let contents = Sys.readdir path in
          Array.fold_left
            (fun acc entry ->
              let full_path = Filename.concat path entry in
              match acc with
              | Ok files -> (
                  match traverse_fs full_path with Ok new_files -> Ok (files @ new_files) | Error err -> Error err)
              | Error err -> Error err)
            (Ok []) contents
      | false ->
          (* Handle file *)
          if is_js_file path then
            match read_file path with
            | Some content -> Ok (parse_manifest_data ~path content)
            | None -> Error (Printf.sprintf "Failed to read file: %s" path)
          else Ok []
    with
    | Sys_error msg -> Error (Printf.sprintf "System error: %s" msg)
    | Unix.Unix_error (err, _, _) -> Error (Printf.sprintf "Unix error: %s" (Unix.error_message err))
    | e -> Error (Printf.sprintf "Unexpected error: %s" (Printexc.to_string e))
  in
  traverse_fs path
(* Process file *)
(* let process_file filepath =
  try
    let content = In_channel.with_open_text filepath In_channel.input_all in
    Ok (process_content content)
  with e ->
    Error (Printf.sprintf "Error reading file: %s" (Printexc.to_string e)) *)

let () =
  let argv = Array.to_list Sys.argv in
  (* extract-client-components --target melange_target --out path *)
  let first_argument = List.nth_opt argv 1 in
  let second_arg = List.nth_opt argv 2 in
  let path = Option.value ~default:"./bootstrap.js" second_arg in

  let melange_target =
    match first_argument with
    | Some v -> v
    | None -> failwith "Add a 'melange-target' to extract components from. It can't be empty"
  in
  match capture_all_client_component_files_in_target melange_target with
  | Ok manifest -> render_manifest ~path manifest
  | Error msg -> print_endline msg

(* match decode sexp with
  | manifest -> render_manifest ~path manifest
  | exception Invalid_sexp message ->
      Printf.printf "Invalid sexp: %s. Generated an empty bootstrap.js file" message;
      render_manifest ~path []
  | exception exn ->
      Printf.printf "Unexpected error: %s. Generated an empty bootstrap.js file" (Printexc.to_string exn);
      render_manifest ~path []
 *)