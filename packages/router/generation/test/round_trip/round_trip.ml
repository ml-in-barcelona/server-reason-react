(* round_trip href ROUTE name=value ... : typed values -> tryHref -> server -> page props
   round_trip serve PATHNAME           : pathname -> server -> page props -> tryHref
   Values use OCaml string escapes. A catch-all takes one name=value argument per segment. *)

let show_props = function
  | Pages.Scalars (i, s, b, c) -> Printf.sprintf "Scalars i=%d s=%S b=%b c=%d" i s b c
  | Optional (i, s) ->
      let opt f = function None -> "None" | Some v -> f v in
      Printf.sprintf "Optional i=%s s=%s" (opt string_of_int i) (opt (Printf.sprintf "%S") s)
  | Rest parts -> Printf.sprintf "Rest parts=[%s]" (String.concat "; " (List.map (Printf.sprintf "%S") parts))
  | OptRest (lead, rest) ->
      Printf.sprintf "OptRest lead=%d rest=[%s]" lead (String.concat "; " (List.map (Printf.sprintf "%S") rest))

let try_href = function
  | Pages.Scalars (i, s, b, c) -> (Router.Scalars.tryHref ~i ~s ~b ~c (), fun () -> Router.Scalars.href ~i ~s ~b ~c ())
  | Optional (i, s) -> (Router.Optional.tryHref ?i ?s (), fun () -> Router.Optional.href ?i ?s ())
  | Rest parts -> (Router.Rest.tryHref ~parts (), fun () -> Router.Rest.href ~parts ())
  | OptRest (lead, rest) -> (Router.OptRest.tryHref ~lead ~rest (), fun () -> Router.OptRest.href ~lead ~rest ())

let serve pathname =
  match RouterEngine.Path.stripBasePath ~basePath:"/base" pathname with
  | None -> Error "outside the base path"
  | Some pathname -> (
      let search = match RouterEngine.Search.parse "" with Ok search -> search | Error _ -> assert false in
      match RouterEngine.EndpointRegistry.find RouterRegistry.registry ~pathname with
      | Error (MalformedEscape _) -> Error "malformed escape"
      | Error (EncodedSlash _) -> Error "encoded slash"
      | Error (InvalidPath _) -> Error "invalid path"
      | Ok None -> Error "no matching route"
      | Ok (Some matched) -> (
          match RouterEngine.EndpointRegistry.decode matched ~search with
          | Error (InvalidPathParameter { name }) -> Error ("invalid path parameter " ^ name)
          | Error _ -> Error "decode error"
          | Ok prepared -> (
              Pages.rendered := None;
              match
                Lwt_main.run (RouterEngine.Execution.run (RouterEngine.Endpoint.execution prepared ~context:()))
              with
              | RouterRuntime.Loader.Data plan ->
                  let resolved =
                    Lwt_main.run
                      (RouterEngine.Plan.resolve plan ~applicationStatus:(fun _ ->
                           RouterRuntime.Status.InternalServerError))
                  in
                  ignore
                    (Lwt_main.run
                       (ReactServerDOM.render_html ~skipRoot:true (RouterEngine.Plan.resolvedElement resolved)));
                  Option.to_result ~none:"no page rendered" !Pages.rendered
              | _ -> Error "no page plan")))

let print_serve pathname =
  match serve pathname with
  | Ok props ->
      print_endline ("props: " ^ show_props props);
      Some props
  | Error message ->
      print_endline ("serve: " ^ message);
      None

let print_href props =
  let tried, href = try_href props in
  let raised = match href () with href -> Ok href | exception Invalid_argument message -> Error message in
  (match tried with
  | Ok href -> print_endline ("href: " ^ href)
  | Error message -> print_endline ("tryHref: " ^ message));
  (match (tried, raised) with
  | Ok a, Ok b when String.equal a b -> ()
  | Error _, Error _ -> ()
  | _, Ok b -> print_endline ("but href returns " ^ b)
  | _, Error message -> print_endline ("but href raises " ^ message));
  Result.to_option tried

let parse_args args =
  List.map
    (fun arg ->
      match String.index_opt arg '=' with
      | Some i -> (String.sub arg 0 i, Scanf.unescaped (String.sub arg (i + 1) (String.length arg - i - 1)))
      | None -> failwith ("expected name=value: " ^ arg))
    args

let props_of route args =
  let args = parse_args args in
  let one name = List.assoc_opt name args in
  let get name = match one name with Some v -> v | None -> failwith ("missing " ^ name) in
  let all name = List.filter_map (fun (n, v) -> if n = name then Some v else None) args in
  let int v = match int_of_string_opt v with Some i -> i | None -> failwith ("not an int: " ^ v) in
  match route with
  | "Scalars" -> Pages.Scalars (int (get "i"), get "s", bool_of_string (get "b"), int (get "c"))
  | "Optional" -> Optional (Option.map int (one "i"), one "s")
  | "Rest" -> Rest (all "parts")
  | "OptRest" -> OptRest (int (get "lead"), all "rest")
  | route -> failwith ("unknown route " ^ route)

let () =
  match List.tl (Array.to_list Sys.argv) with
  | "href" :: route :: args -> (
      match print_href (props_of route args) with Some href -> ignore (print_serve href) | None -> ())
  | [ "serve"; pathname ] -> ( match print_serve pathname with Some props -> ignore (print_href props) | None -> ())
  | _ ->
      prerr_endline "usage: round_trip href ROUTE name=value ... | round_trip serve PATHNAME";
      exit 2
