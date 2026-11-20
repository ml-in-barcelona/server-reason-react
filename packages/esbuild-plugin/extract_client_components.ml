module List = ListLabels

let read_file path = try Some (In_channel.with_open_bin path In_channel.input_all) with _ -> None

type manifest_item =
  | Client_component of { original_path : string; compiled_js_path : string; module_name : string list option }
  | Server_function of {
      id : string;
      compiled_js_path : string;
      module_name : string list option;
      function_name : string;
    }

let parse_module_name str = String.split_on_char '.' str
let print_module_name str = String.concat "." str

let parse_client_component_line line =
  try
    Scanf.sscanf line "// extract-client %s %s" (fun filename module_name ->
        Ok (filename, if module_name = "" then None else Some (parse_module_name module_name)))
  with End_of_file | Scanf.Scan_failure _ -> Error "Invalid `extract-client` command format"

let parse_server_function_line line =
  try
    Scanf.sscanf line "// extract-server-function %s %s %s" (fun id function_name module_name ->
        Ok ((if module_name = "" then None else Some (parse_module_name module_name)), function_name, id))
  with End_of_file | Scanf.Scan_failure _ -> Error "Invalid `extract-server-function` command format"

let client_marker = "// extract-client"
let server_function_marker = "// extract-server-function"
let has_marker marker line = line = marker || String.starts_with ~prefix:(marker ^ " ") line

let parse_manifest_item ~path line =
  let line = String.trim line in
  let invalid message = Error (Printf.sprintf "%s: %s: %S" path message line) in
  if has_marker server_function_marker line then
    match parse_server_function_line line with
    | Ok (module_name, function_name, id) when id <> "" && function_name <> "" ->
        Ok (Some (Server_function { compiled_js_path = path; module_name; function_name; id }))
    | Ok _ | Error _ -> invalid "invalid `extract-server-function` line"
  else if has_marker client_marker line then
    match parse_client_component_line line with
    | Ok (original_path, module_name) when original_path <> "" ->
        Ok (Some (Client_component { compiled_js_path = path; original_path; module_name }))
    | Ok _ | Error _ -> invalid "invalid `extract-client` line"
  else Ok None

let parse_manifest_data ~path content =
  String.split_on_char '\n' content
  |> List.fold_left ~init:(Ok []) ~f:(fun acc line ->
      match (acc, parse_manifest_item ~path line) with
      | Error _, _ -> acc
      | Ok _, Error message -> Error message
      | Ok items, Ok None -> Ok items
      | Ok items, Ok (Some item) -> Ok (item :: items))
  |> Result.map List.rev

let extension_rank path = match Filename.extension path with ".js" -> 0 | ".mjs" -> 1 | ".cjs" -> 2 | _ -> 3

let item_key = function
  | Client_component { original_path; module_name; _ } ->
      "client " ^ original_path ^ "#" ^ Option.fold ~none:"" ~some:print_module_name module_name
  | Server_function { id; _ } -> "server " ^ id

let item_path = function
  | Client_component { compiled_js_path; _ } | Server_function { compiled_js_path; _ } -> compiled_js_path

let same_export a b =
  match (a, b) with
  | Client_component a, Client_component b -> a.module_name = b.module_name
  | Server_function a, Server_function b -> a.module_name = b.module_name && a.function_name = b.function_name
  | _ -> false

let dedupe_manifest items =
  let sorted =
    List.stable_sort items ~cmp:(fun a b ->
        compare (extension_rank (item_path a), item_path a) (extension_rank (item_path b), item_path b))
  in
  let seen = Hashtbl.create 64 in
  List.fold_left sorted ~init:(Ok []) ~f:(fun acc item ->
      match acc with
      | Error _ -> acc
      | Ok kept -> (
          let key = item_key item in
          match Hashtbl.find_opt seen key with
          | None ->
              Hashtbl.add seen key item;
              Ok (item :: kept)
          | Some first when same_export first item -> Ok kept
          | Some first -> (
              match item with
              | Server_function { id; _ } ->
                  Error
                    (Printf.sprintf "duplicate server function id %S in %s and %s" id (item_path first) (item_path item))
              | Client_component _ -> Ok (item :: kept))))
  |> Result.map List.rev

let render_manifest manifest =
  let register_client_modules =
    List.map manifest ~f:(function
      | Client_component { original_path; compiled_js_path; module_name } ->
          let original_path_with_submodule =
            match module_name with
            | Some name -> Printf.sprintf "%s#%s" original_path (print_module_name name)
            | None -> original_path
          in
          let export =
            match module_name with
            | Some name -> Printf.sprintf "%s.make_client" (print_module_name name)
            | None -> "make_client"
          in
          (* A loader record, not a React.lazy: the Flight client's $L references already provide
             laziness (preloadModule starts the import and blocks the module chunk; requireModule
             returns the component synchronously once loaded). Wrapping in React.lazy produced a
             lazy-resolving-to-lazy element type, which React rejects when the chunk isn't already
             loaded ("Lazy element type must resolve to a class or function"). *)
          Printf.sprintf
            "window.__client_manifest_map[\"%s\"] = { load: () => import(\"%s\").then(module => module.%s) }"
            original_path_with_submodule compiled_js_path export
      | Server_function { compiled_js_path; module_name; function_name; id } ->
          let export =
            match module_name with
            | Some name -> Printf.sprintf "%s.%s" (print_module_name name) function_name
            | None -> function_name
          in
          Printf.sprintf "window.__server_functions_manifest_map[\"%s\"] = require(\"%s\").%s" id compiled_js_path
            export)
  in
  Printf.sprintf
    {|window.__client_manifest_map = window.__client_manifest_map || {};
window.__server_functions_manifest_map = window.__server_functions_manifest_map || {};
%s|}
    (String.concat "\n" register_client_modules)

let is_js_file path = List.mem (Filename.extension path) ~set:[ ".js"; ".jsx"; ".mjs"; ".cjs" ]

(* TODO: refactor path to be a Filepath, not a string *)
let capture_all_client_modules_files_in_target path =
  let rec traverse_fs path =
    try
      match Sys.is_directory path with
      | true ->
          let contents = Sys.readdir path in
          Array.sort compare contents;
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
            | Some content -> parse_manifest_data ~path content
            | None -> Error (Printf.sprintf "Failed to read file: %s" path)
          else Ok []
    with
    | Sys_error msg -> Error (Printf.sprintf "System error: %s" msg)
    | e -> Error (Printf.sprintf "Unexpected error: %s" (Printexc.to_string e))
  in
  traverse_fs path

let melange_target =
  let doc = "Path to the melange target directory (melange.emit (target xxx))" in
  Cmdliner.Arg.(required & pos 0 (some string) None & info [] ~docv:"MELANGE_TARGET" ~doc)

let extract_modules target =
  let melange_target = if Filename.is_relative target then Filename.concat (Sys.getcwd ()) target else target in
  match Result.bind (capture_all_client_modules_files_in_target melange_target) dedupe_manifest with
  | Ok manifest ->
      print_endline (render_manifest manifest);
      0
  | Error msg ->
      prerr_endline ("server-reason-react.extract_client_components: " ^ msg);
      1

let extract_cmd =
  let open Cmdliner in
  let doc = "Extract all client modules from a Melange target folder" in
  let sdocs = Manpage.s_common_options in
  let info = Cmd.info "extract-client-components" ~version:"1.0.0" ~doc ~sdocs in
  let term = Term.(const extract_modules $ melange_target) in
  Cmd.v info term

let () = exit (Cmdliner.Cmd.eval' extract_cmd)
