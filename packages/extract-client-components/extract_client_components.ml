module List = ListLabels

let read_file path = try Some (In_channel.with_open_bin path In_channel.input_all) with _ -> None

type manifest_item =
  | ClientComponent of { original_path : string; compiled_js_path : string; module_name : string option }
  | ServerFunction of { compiled_js_path : string; module_name : string option; function_name : string; id : string }

let parse_client_component_line line =
  try
    Scanf.sscanf line "// extract-client %s %s" (fun filename module_name ->
        Ok (filename, if module_name = "" then None else Some module_name))
  with End_of_file | Scanf.Scan_failure _ -> Error "Invalid `extract-client` command format"

let parse_server_function_line line =
  try
    Scanf.sscanf line "// extract-server-function %s %s %s" (fun id function_name module_name ->
        Ok ((if module_name = "" then None else Some module_name), function_name, id))
  with End_of_file | Scanf.Scan_failure _ -> Error "Invalid `extract-server-function` command format"

let parse_manifest_item ~path line =
  match (parse_client_component_line (String.trim line), parse_server_function_line (String.trim line)) with
  | Ok (original_path, module_name), _ -> Some (ClientComponent { compiled_js_path = path; original_path; module_name })
  | _, Ok (module_name, function_name, id) ->
      Some (ServerFunction { compiled_js_path = path; module_name; function_name; id })
  | Error _, Error _ -> None

let parse_manifest_data ~path content : manifest_item list =
  content |> String.split_on_char '\n' |> List.filter_map ~f:(parse_manifest_item ~path)

let render_manifest manifest =
  let register_client_modules =
    List.map manifest ~f:(function
      | ClientComponent { original_path; compiled_js_path; module_name } ->
          let export =
            match module_name with Some name -> Printf.sprintf "%s.make_client" name | None -> "make_client"
          in
          Printf.sprintf
            "window.__client_manifest_map[\"%s\"] = React.lazy(() => import(\"%s\").then(module => {\n\
            \  return { default: module.%s }\n\
             }).catch(err => { console.error(err); return { default: null }; }))"
            original_path compiled_js_path export
      | ServerFunction { compiled_js_path; module_name; function_name; id } ->
          let export =
            match module_name with Some name -> Printf.sprintf "%s.%s" name function_name | None -> function_name
          in
          Printf.sprintf "window.__server_functions_manifest_map[\"%s\"] = require(\"%s\").%s" id compiled_js_path
            export)
  in
  Printf.sprintf
    {|import React from "react";
window.__client_manifest_map = window.__client_manifest_map || {};
window.__server_functions_manifest_map = window.__server_functions_manifest_map || {};
%s|}
    (String.concat "\n" register_client_modules)

(* TODO: Add parameter to allow users to configure the extension of the files *)
let is_js_file path =
  let ext = Filename.extension path in
  ext = ".js" || ext = ".bs.js" || ext = ".jsx"

(* TODO: refactor path to be a Filepath, not a string *)
let capture_all_client_modules_files_in_target path =
  let rec traverse_fs path =
    try
      match Sys.is_directory path with
      | true ->
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

let melange_target =
  let doc = "Path to the melange target directory (melange.emit (target xxx))" in
  Cmdliner.Arg.(required & pos 0 (some string) None & info [] ~docv:"MELANGE_TARGET" ~doc)

let extract_modules target =
  let current_dir = Sys.getcwd () in
  let melange_target = Filename.concat current_dir target in
  match capture_all_client_modules_files_in_target melange_target with
  | Ok manifest ->
      print_endline (render_manifest manifest);
      Ok ()
  | Error msg -> Error (`Msg msg)

let extract_cmd =
  let open Cmdliner in
  let doc = "Extract all client modules from a Melange target folder" in
  let sdocs = Manpage.s_common_options in
  let info = Cmd.info "extract-client-components" ~version:"1.0.0" ~doc ~sdocs in
  let term = Term.(term_result (const extract_modules $ melange_target)) in
  Cmd.v info term

let () = exit (Cmdliner.Cmd.eval extract_cmd)
