[@@@warning "-27-32"]

open Sexplib
open Sexplib.Sexp

type rule = { deps : string list; targets : string list; action : string }

let contains str sub =
  let str_len = String.length str in
  let sub_len = String.length sub in

  if sub_len = 0 then true
  else if sub_len > str_len then false
  else
    let rec check_from pos =
      if pos > str_len - sub_len then false
      else
        let rec match_sub i =
          if i = sub_len then true else if str.[pos + i] = sub.[i] then match_sub (i + 1) else false
        in
        if match_sub 0 then true else check_from (pos + 1)
    in
    check_from 0

let clean_path path =
  (* Remove _build/default/ prefix if present *)
  let prefix = "_build/default/" in
  if String.starts_with ~prefix path then
    String.sub path (String.length prefix) (String.length path - String.length prefix)
  else path

let parse_file = function
  | List [ Atom "File"; List [ Atom "In_build_dir"; Atom path ] ]
  | List [ Atom "File"; List [ Atom "In_source_tree"; Atom path ] ] ->
      Some (clean_path path)
  | List [ Atom "File"; List [ Atom "External"; Atom _ ] ] -> None
  | sexp ->
      Printf.eprintf "Skipping unknown file sexp: %s\n" (Sexp.to_string sexp);
      None

let parse_files = function
  | List [ Atom "files"; List files; _ ] ->
      List.filter_map
        (function
          | Atom path -> Some (clean_path path)
          | sexp ->
              Printf.eprintf "Skipping unknown target sexp: %s\n" (Sexp.to_string sexp);
              None)
        files
  | sexp ->
      Printf.eprintf "Skipping unknown targets sexp: %s\n" (Sexp.to_string sexp);
      []

let rec find_file_paths = function
  | List [ Atom "File"; List [ Atom "In_build_dir"; Atom path ] ]
  | List [ Atom "File"; List [ Atom "In_source_tree"; Atom path ] ] ->
      [ clean_path path ]
  | List [ Atom "File"; List [ Atom "External"; _ ] ] -> [] (* Skip external files *)
  | List items -> List.concat_map find_file_paths items
  | _ -> []

let rec find_target_files = function
  | List (Atom "files" :: List files :: _) ->
      List.filter_map (function Atom path -> Some (clean_path path) | _ -> None) files
  | List xs -> List.concat_map find_target_files xs
  | _ -> []

let find_flag flag parts =
  List.find_map
    (fun part ->
      if String.starts_with ~prefix:flag part then
        Some (String.trim (String.sub part (String.length flag) (String.length part - String.length flag)))
      else None)
    parts

let scan str fmt mapper =
  match Scanf.sscanf str fmt mapper with
  | exception Scanf.Scan_failure fail ->
      Printf.eprintf "--\n";
      Printf.eprintf "%s\n\n" str;
      Printf.eprintf "%s\n--" fail;
      None
  | exception End_of_file -> None
  | nice -> Some nice

let parse_rule = function
  | List
      [
        List [ Atom "deps"; (List [ List _ ] as deps) ];
        List [ Atom "targets"; (List [ List _; List _ ] as targets) ];
        List [ Atom "context"; Atom "default" ];
        List [ Atom "action"; List (Atom "chdir" :: Atom "_build/default" :: rest) ];
      ] ->
      let deps = find_file_paths deps in
      let targets = find_target_files targets in
      (* Take just the action after chdir _build/default *)
      let action = Sexp.to_string (List rest) in
      Some { deps; targets; action }
  | List
      [
        List [ Atom "deps"; deps ];
        List [ Atom "targets"; targets ];
        List [ Atom "context"; Atom "default" ];
        List [ Atom "action"; action ];
      ] ->
      let deps = find_file_paths deps in
      let targets = find_target_files targets in
      let action = Sexp.to_string action in
      Some { deps; targets; action }
  | _ -> None

let parse_rules content =
  let sexps = Sexp.of_string_many content in
  List.filter_map parse_rule sexps

let print_rule rule =
  print_endline "--- deps ---";
  List.iter (fun rule -> print_endline rule) rule.deps;
  print_endline "\n--- targets ---";
  List.iter (fun rule -> print_endline rule) rule.targets;
  print_endline "\n--- action ---";
  print_endline rule.action;
  print_endline "\n"

let print_rules rules = List.iter print_rule rules

let build_chain rules =
  let deps_map = Hashtbl.create 50 in
  List.iter
    (fun rule ->
      List.iter
        (fun dep ->
          List.iter
            (fun target ->
              if (not (String.contains dep '/')) || not (String.contains target '/') then ()
              else Hashtbl.add deps_map dep target)
            rule.targets)
        rule.deps)
    rules;

  let start_files = Hashtbl.create 50 in
  Hashtbl.iter
    (fun dep _target -> if String.ends_with ~suffix:".re" dep then Hashtbl.replace start_files dep true)
    deps_map;

  let chains = ref [] in
  Hashtbl.iter
    (fun start _ ->
      let rec build_chain_from file acc =
        let next = Hashtbl.find_all deps_map file in
        match next with [] -> file :: acc | [ target ] -> build_chain_from target (file :: acc) | _ -> file :: acc
      in
      try
        let chain = List.rev (build_chain_from start []) in
        chains := chain :: !chains
      with Not_found -> ())
    start_files;
  !chains

let () =
  try
    let content = All_dune_rules.counter in
    let rules = parse_rules content in
    Printf.eprintf "Parsed %d rules\n" (List.length rules);
    print_rules rules;
    let chains = build_chain rules in
    if chains = [] then Printf.eprintf "No chains found\n"
    else List.iter (fun chain -> print_endline (String.concat " -> " chain)) chains
  with exn -> Printf.eprintf "Unexpected error: %s\n" (Printexc.to_string exn)
