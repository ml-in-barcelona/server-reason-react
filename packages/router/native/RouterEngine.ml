include RouterEngineRuntime

module Path = struct
  type segment = RouterPattern.segment =
    | Static of string
    | Parameter of RouterPattern.parameter
    | CatchAll of { name : string }

  type error = MalformedEscape of string | EncodedSlash of string | InvalidPath of string

  let decode_segment pathname ~start ~stop =
    match RouterUrl.decodeSegmentRange pathname ~start ~stop with
    | Ok segment -> Ok segment
    | Error Malformed -> Error (MalformedEscape (RouterUrl.slice pathname start stop))
    | Error EncodedSlash -> Error (EncodedSlash (RouterUrl.slice pathname start stop))
    | Error InvalidSegment -> Error (InvalidPath (RouterUrl.slice pathname start stop))

  let rec decode_segments pathname decoded error stop =
    let slash = String.rindex_from pathname (stop - 1) '/' in
    let start = slash + 1 in
    if start = stop then
      if slash = 0 then Error (InvalidPath pathname)
      else decode_segments pathname decoded (Some (InvalidPath pathname)) slash
    else
      match decode_segment pathname ~start ~stop with
      | Ok segment ->
          if slash = 0 then match error with Some error -> Error error | None -> Ok (segment :: decoded)
          else decode_segments pathname (segment :: decoded) error slash
      | Error current -> if slash = 0 then Error current else decode_segments pathname decoded (Some current) slash

  let decodePathname pathname =
    if String.equal pathname "/" then Ok []
    else if String.equal pathname "" || pathname.[0] <> '/' then Error (InvalidPath pathname)
    else decode_segments pathname [] None (String.length pathname)

  let validBasePath pathname =
    if String.contains pathname '?' || String.contains pathname '#' then false
    else
      match decodePathname pathname with
      | Error _ -> false
      | Ok segments -> (
          let decoded = match segments with [] -> "/" | _ -> "/" ^ String.concat "/" segments in
          match RouterPattern.parse decoded with
          | Ok pattern ->
              RouterPattern.parameters pattern = []
              && String.equal pathname
                   (match segments with
                   | [] -> "/"
                   | _ -> "/" ^ String.concat "/" (List.map RouterPattern.encodeStaticSegment segments))
          | Error _ -> false)

  let stripBasePath ~basePath pathname =
    if String.equal basePath "/" then Some pathname
    else
      let length = String.length pathname in
      let rec strip start = function
        | [] -> Some (if start = length then "/" else String.sub pathname start (length - start))
        | segment :: segments -> (
            if start >= length || pathname.[start] <> '/' then None
            else
              let stop = Option.value (String.index_from_opt pathname (start + 1) '/') ~default:length in
              match decode_segment pathname ~start:(start + 1) ~stop with
              | Ok decoded when String.equal decoded segment -> strip stop segments
              | Ok _ | Error _ -> None)
      in
      match decodePathname basePath with Ok segments -> strip 0 segments | Error _ -> None

  let splitLocation location =
    match String.index_opt location '?' with
    | None -> (location, "")
    | Some index -> (String.sub location 0 index, String.sub location index (String.length location - index))

  let stripTrailingSlashes pathname =
    let length = String.length pathname in
    let rec first_trailing index =
      if index > 1 && pathname.[index - 1] = '/' then first_trailing (index - 1) else index
    in
    let stop = first_trailing length in
    if stop = length then None else Some (String.sub pathname 0 stop)
end

module TrailingSlash = struct
  type t = Redirect | Reject
end

module Route = struct
  type t = {
    id : string;
    path : string;
    pattern : RouterPattern.t;
    segments : Path.segment list;
    parameter_names : string list;
    specificity : int;
  }

  let make ~id ~path =
    match (RouterPattern.validUtf8 path, RouterPattern.parse path) with
    | false, _ -> invalid_arg ("invalid route path " ^ path)
    | true, Ok pattern ->
        let segments = RouterPattern.segments pattern in
        let parameter_names =
          List.fold_right
            (fun segment names ->
              match segment with
              | Path.Static _ -> names
              | Parameter parameter -> parameter.RouterPattern.name :: names
              | CatchAll { name } -> name :: names)
            segments []
        in
        { id; path; pattern; segments; parameter_names; specificity = RouterPattern.specificity pattern }
    | true, Error _ -> invalid_arg ("invalid route path " ^ path)

  let id route = route.id
  let path route = route.path
end

module Registry = struct
  open Path

  type node = {
    static_children : (string, node) Hashtbl.t;
    mutable parameter_child : node option;
    mutable catch_all : Route.t option;
    mutable route : Route.t option;
    mutable max_specificity : int;
  }

  type t = { routes : Route.t list; exact : (string, Route.t) Hashtbl.t; root : node }
  type error = DuplicateId of string | DuplicatePath of string | AmbiguousPattern of string * string

  let rec find_duplicate_id = function
    | [] -> None
    | item :: rest ->
        let id = item.Route.id in
        if List.exists (fun other -> String.equal id other.Route.id) rest then Some id else find_duplicate_id rest

  let conflict routes =
    let rec loop = function
      | [] -> None
      | route :: rest -> (
          match
            List.find_map
              (fun other ->
                match RouterPattern.relationship route.Route.pattern other.Route.pattern with
                | Duplicate -> Some (DuplicatePath route.Route.path)
                | Ambiguous -> Some (AmbiguousPattern (route.Route.path, other.Route.path))
                | Distinct | CompatiblePrefix | IncompatiblePrefix -> None)
              rest
          with
          | Some error -> Some error
          | _ -> loop rest)
    in
    loop routes

  let node () =
    { static_children = Hashtbl.create 4; parameter_child = None; catch_all = None; route = None; max_specificity = -1 }

  let add root route =
    let rec loop current = function
      | [] ->
          current.max_specificity <- max current.max_specificity route.Route.specificity;
          current.route <- Some route
      | Static value :: segments ->
          current.max_specificity <- max current.max_specificity route.Route.specificity;
          let child =
            match Hashtbl.find_opt current.static_children value with
            | Some child -> child
            | None ->
                let child = node () in
                Hashtbl.add current.static_children value child;
                child
          in
          loop child segments
      | Parameter _ :: segments ->
          current.max_specificity <- max current.max_specificity route.Route.specificity;
          let child =
            match current.parameter_child with
            | Some child -> child
            | None ->
                let child = node () in
                current.parameter_child <- Some child;
                child
          in
          loop child segments
      | CatchAll _ :: _ ->
          current.max_specificity <- max current.max_specificity route.Route.specificity;
          current.catch_all <- Some route
    in
    loop root route.Route.segments

  let make routes =
    match find_duplicate_id routes with
    | Some id -> Error (DuplicateId id)
    | None -> (
        match conflict routes with
        | Some error -> Error error
        | None ->
            let root = node () in
            let exact = Hashtbl.create (List.length routes) in
            List.iter
              (fun route ->
                add root route;
                if route.Route.parameter_names = [] then Hashtbl.add exact route.Route.path route)
              routes;
            Ok { routes; exact; root })

  let raise_invalid = function
    | DuplicateId id -> invalid_arg ("duplicate route id " ^ id)
    | DuplicatePath path -> invalid_arg ("duplicate route path " ^ path)
    | AmbiguousPattern (left, right) -> invalid_arg ("ambiguous route patterns " ^ left ^ " and " ^ right)

  let makeExn routes = match make routes with Ok registry -> registry | Error error -> raise_invalid error
  let routes registry = registry.routes
end

module Match = struct
  type t = { route : Route.t; parameters : (string * string) list }
  type error = Path.error = MalformedEscape of string | EncodedSlash of string | InvalidPath of string

  let parameters route values =
    let rec loop parameters names values =
      match (names, values) with
      | [], [] -> List.rev parameters
      | name :: names, value :: values -> loop ((name, value) :: parameters) names values
      | _ -> assert false
    in
    loop [] route.Route.parameter_names (List.rev values)

  let match_segments root segments =
    let best = ref None in
    let best_specificity () = match !best with Some (specificity, _, _) -> specificity | None -> -1 in
    let rec loop (node : Registry.node) captured = function
      | _ when node.max_specificity <= best_specificity () -> ()
      | [] -> (
          match node.route with
          | Some route when route.Route.specificity > best_specificity () ->
              best := Some (route.Route.specificity, route, captured)
          | Some _ | None -> ())
      | value :: segments -> (
          (let static = Hashtbl.find_opt node.static_children value in
           let parameter = node.parameter_child in
           match (static, parameter) with
           | Some static, Some parameter when parameter.max_specificity > static.max_specificity ->
               loop parameter (value :: captured) segments;
               loop static captured segments
           | Some static, Some parameter ->
               loop static captured segments;
               loop parameter (value :: captured) segments
           | Some static, None -> loop static captured segments
           | None, Some parameter -> loop parameter (value :: captured) segments
           | None, None -> ());
          match node.catch_all with
          | Some route when route.Route.specificity > best_specificity () ->
              best := Some (route.Route.specificity, route, String.concat "/" (value :: segments) :: captured)
          | Some _ | None -> ())
    in
    loop root [] segments;
    match !best with None -> None | Some (_, route, values) -> Some { route; parameters = parameters route values }

  let find registry ~pathname =
    match Hashtbl.find_opt registry.Registry.exact pathname with
    | Some route -> Ok (Some { route; parameters = [] })
    | None -> (
        match Path.decodePathname pathname with
        | Error error -> Error error
        | Ok segments -> Ok (match_segments registry.Registry.root segments))
end

module Search = struct
  type t = (string * string list) list
  type error = RouterQuery.error = QueryTooLong

  let parse = RouterQuery.parse
  let values search name = match List.assoc_opt name search with Some values -> values | None -> []
  let unknown search ~owned = List.filter (fun (name, _) -> not (List.exists (String.equal name) owned)) search
end

module Input = struct
  type t = { parameters : (string * string) list; search : Search.t }

  let make ~parameters ~search = { parameters; search }
  let forSearch search = make ~parameters:[] ~search
end

module Decode = struct
  let parse_path_value ~name ~parse value =
    match parse value with Ok value -> Ok value | Error _ -> Error (RouterRuntime.Error.InvalidPathParameter { name })

  let path ~input ~name ~parse =
    match List.assoc_opt name input.Input.parameters with
    | Some value -> parse_path_value ~name ~parse value
    | None -> Error (RouterRuntime.Error.InvalidPathParameter { name })

  let parse_search ~name ~parse value =
    match parse value with
    | Ok value -> Ok value
    | Error _ -> Error (RouterRuntime.Error.InvalidSearchParameter { name })

  let searchRequired ~input ~name ~parse =
    match Search.values input.Input.search name with
    | value :: _ -> parse_search ~name ~parse value
    | [] -> Error (RouterRuntime.Error.InvalidSearchParameter { name })

  let searchOptional ~input ~name ~parse =
    match Search.values input.Input.search name with value :: _ -> Ok (Result.to_option (parse value)) | [] -> Ok None

  let searchDefault ~input ~name ~parse ~fallback =
    match Search.values input.Input.search name with
    | value :: _ -> Ok (Result.value (parse value) ~default:fallback)
    | [] -> Ok fallback

  let searchMany ~input ~name ~parse =
    Ok (List.filter_map (fun value -> Result.to_option (parse value)) (Search.values input.Input.search name))

  let searchValues ~input names = List.map (fun name -> (name, Search.values input.Input.search name)) names
end

let redirect_location destination =
  let href = RouterRuntime.href destination in
  let length = String.length href in
  let has_prefix prefix =
    length > String.length prefix && String.lowercase_ascii (String.sub href 0 (String.length prefix)) = prefix
  in
  let local = length > 0 && href.[0] = '/' && not (length > 1 && (href.[1] = '/' || href.[1] = '\\')) in
  if
    (local || has_prefix "http://" || has_prefix "https://")
    && String.for_all (fun character -> Char.code character >= 0x20 && Char.code character <> 0x7f) href
  then Some href
  else None

let unsafe_redirect destination = Invalid_argument ("unsafe redirect target " ^ RouterRuntime.href destination)
let fatal_exception = function Lwt.Canceled | Out_of_memory | Stack_overflow | Sys.Break -> true | _ -> false

module Execution = struct
  type ('result, 'error) t =
    | Done : 'result -> ('result, 'error) t
    | Redirect : RouterRuntime.destination -> ('result, 'error) t
    | PermanentRedirect : RouterRuntime.destination -> ('result, 'error) t
    | Load : {
        run : unit -> ('data, 'error) RouterRuntime.Loader.result Lwt.t;
        next : 'data -> ('result, 'error) t;
      }
        -> ('result, 'error) t
    | LoadWithBoundary : {
        run : unit -> ('data, 'error) RouterRuntime.Loader.result Lwt.t;
        failure : 'error RouterRuntime.Error.t -> 'result;
        next : 'data -> ('result, 'error) t;
      }
        -> ('result, 'error) t
    | Start : {
        run : unit -> ('data, 'error) RouterRuntime.Loader.result Lwt.t;
        next : ('data, 'error) RouterRuntime.Loader.result Lwt.t -> ('result, 'error) t;
      }
        -> ('result, 'error) t

  type ('data, 'error) started = ('data, 'error) RouterRuntime.Loader.result Lwt.t

  let done_ result = Done result
  let redirect destination = Redirect destination
  let permanentRedirect destination = PermanentRedirect destination
  let load run next = Load { run; next }
  let loadWithBoundary ~run ~failure ~next = LoadWithBoundary { run; failure; next }
  let start ~run ~next = Start { run; next }
  let await started () = started

  let run ?(diagnosticId = fun _ -> "internal") execution =
    let rec loop : type result error. (result, error) t -> (result, error) RouterRuntime.Loader.result Lwt.t = function
      | Done result -> Lwt.return (RouterRuntime.Loader.Data result)
      | Redirect destination -> Lwt.return (RouterRuntime.Loader.Redirect destination)
      | PermanentRedirect destination -> Lwt.return (RouterRuntime.Loader.PermanentRedirect destination)
      | Load loader ->
          Lwt.bind (loader.run ()) (function
            | RouterRuntime.Loader.Data data -> loop (loader.next data)
            | RouterRuntime.Loader.Error error -> Lwt.return (RouterRuntime.Loader.Error error)
            | RouterRuntime.Loader.NotFound -> Lwt.return RouterRuntime.Loader.NotFound
            | RouterRuntime.Loader.Redirect destination -> Lwt.return (RouterRuntime.Loader.Redirect destination)
            | RouterRuntime.Loader.PermanentRedirect destination ->
                Lwt.return (RouterRuntime.Loader.PermanentRedirect destination))
      | LoadWithBoundary loader ->
          Lwt.catch
            (fun () ->
              Lwt.bind (loader.run ()) (function
                | RouterRuntime.Loader.Data data -> loop (loader.next data)
                | RouterRuntime.Loader.Error error ->
                    Lwt.return (RouterRuntime.Loader.Data (loader.failure (RouterRuntime.Error.Application error)))
                | RouterRuntime.Loader.NotFound ->
                    Lwt.return
                      (RouterRuntime.Loader.Data
                         (loader.failure (RouterRuntime.Error.NotFound { reason = RouterRuntime.Error.LoaderNotFound })))
                | RouterRuntime.Loader.Redirect destination -> Lwt.return (RouterRuntime.Loader.Redirect destination)
                | RouterRuntime.Loader.PermanentRedirect destination ->
                    Lwt.return (RouterRuntime.Loader.PermanentRedirect destination)))
            (fun exception_ ->
              if fatal_exception exception_ then Lwt.fail exception_
              else
                Lwt.return
                  (RouterRuntime.Loader.Data
                     (loader.failure (RouterRuntime.Error.Internal { diagnosticId = diagnosticId exception_ }))))
      | Start loader -> loop (loader.next (Lwt.apply loader.run ()))
    in
    loop execution
end

let status_of_error ~application = function
  | RouterRuntime.Error.NotFound _ -> RouterRuntime.Status.NotFound
  | InvalidPathParameter _ | InvalidSearchParameter _ -> BadRequest
  | Application error -> application error
  | Internal _ -> InternalServerError

module Branch = struct
  module Scope = struct
    type t = { id : string; instance_key : string; search_key : string; reusable : bool }

    let frame value = string_of_int (String.length value) ^ ":" ^ value

    let make ~id ~parameters ~search ~reusable =
      let identity = parameters |> List.map (fun (name, value) -> frame name ^ frame value) |> String.concat "" in
      let search_key =
        search
        |> List.map (fun (name, values) -> frame name ^ frame (String.concat "" (List.map frame values)))
        |> String.concat ""
      in
      { id; instance_key = frame id ^ identity; search_key; reusable }

    let id scope = scope.id
    let instanceKey scope = scope.instance_key
    let reusable scope = scope.reusable
  end

  type t = Scope.t list

  let rec sharedPrefix from target =
    match (from, target) with
    | left :: from, right :: target
      when left.Scope.reusable && right.Scope.reusable
           && String.equal left.instance_key right.instance_key
           && String.equal left.search_key right.search_key ->
        1 + sharedPrefix from target
    | _ -> 0

  let layouts branch =
    List.map
      (fun scope -> RouterRuntime.Navigation.{ id = Scope.id scope; instanceKey = Scope.instanceKey scope })
      branch
end

let internal_error_text = "Something went wrong"

module Plan = struct
  module Scope = struct
    type 'view t = {
      layout : ('view -> 'view) option;
      metadata : (unit -> RouterRuntime.Metadata.t Lwt.t) option;
      headers : (unit -> RouterRuntime.Headers.t Lwt.t) option;
    }

    let make ?layout ?metadata ?headers () = { layout; metadata; headers }
  end

  type ('view, 'error) t =
    | Success of {
        scopes : 'view Scope.t list;
        page : 'view;
        failure : ('error RouterRuntime.Error.t -> ('view, 'error) t) option;
      }
    | Failure of {
        scopes : 'view Scope.t list;
        error : 'error RouterRuntime.Error.t;
        not_found : ('error RouterRuntime.Error.t -> 'view) option;
        error_boundary : ('error RouterRuntime.Error.t -> 'view) option;
      }

  type ('view, 'error) resolved = {
    element : 'view option;
    error : 'error RouterRuntime.Error.t option;
    status : RouterRuntime.Status.t;
    metadata : RouterRuntime.Metadata.t;
    headers : RouterRuntime.Headers.t;
  }

  let success ~scopes ~page = Success { scopes; page; failure = None }

  let withFailure plan failure =
    match plan with Success success -> Success { success with failure = Some failure } | Failure _ -> plan

  let fail plan error =
    match plan with
    | Success { failure = Some failure; _ } -> failure error
    | Success { scopes; _ } -> Failure { scopes; error; not_found = None; error_boundary = None }
    | Failure _ -> plan

  let failure ~scopes ~error ?notFound ?errorBoundary () =
    Failure { scopes; error; not_found = notFound; error_boundary = errorBoundary }

  let scopeCount = function
    | Success success -> List.length success.scopes
    | Failure failure -> List.length failure.scopes

  let empty_headers = match RouterRuntime.Headers.make [] with Ok headers -> headers | Error _ -> assert false

  let resolve_values scopes =
    let start = function None -> Lwt.return_none | Some make -> Lwt.map Option.some (Lwt.apply make ()) in
    let merge merge current = function None -> current | Some value -> merge current value in
    Lwt.map
      (List.fold_left
         (fun (metadata, headers) (scope_metadata, scope_headers) ->
           ( merge RouterRuntime.Metadata.merge metadata scope_metadata,
             merge RouterRuntime.Headers.merge headers scope_headers ))
         (RouterRuntime.Metadata.make (), empty_headers))
      (Lwt.all
         (List.map
            (fun scope ->
              let metadata = start scope.Scope.metadata in
              Lwt.both metadata (start scope.Scope.headers))
            scopes))

  let apply_layouts scopes element =
    List.fold_right
      (fun scope element -> match scope.Scope.layout with Some layout -> layout element | None -> element)
      scopes element

  type render = Full | Suffix of { omitted_scopes : int }

  let rec drop count values =
    if count <= 0 then values else match values with [] -> [] | _ :: values -> drop (count - 1) values

  let resolve ?(render = Full) plan ~applicationStatus =
    let scopes = match plan with Success success -> success.scopes | Failure failure -> failure.scopes in
    let rendered_scopes =
      match render with Full -> scopes | Suffix { omitted_scopes } -> drop omitted_scopes scopes
    in
    Lwt.map
      (fun (metadata, headers) ->
        match plan with
        | Success success ->
            {
              element = Some (apply_layouts rendered_scopes success.page);
              error = None;
              status = RouterRuntime.Status.Ok;
              metadata;
              headers;
            }
        | Failure failure ->
            let boundary =
              match failure.error with
              | RouterRuntime.Error.NotFound _ -> (
                  match failure.not_found with Some boundary -> Some boundary | None -> failure.error_boundary)
              | _ -> failure.error_boundary
            in
            {
              element = Option.map (fun boundary -> apply_layouts rendered_scopes (boundary failure.error)) boundary;
              error = Some failure.error;
              status = status_of_error ~application:applicationStatus failure.error;
              metadata;
              headers;
            })
      (resolve_values scopes)

  let resolvedElement (resolved : (React.element, 'error) resolved) =
    match resolved.element with
    | Some element -> element
    | None ->
        let text =
          match resolved.error with
          | Some (RouterRuntime.Error.NotFound _) -> "Not found"
          | Some (InvalidPathParameter _ | InvalidSearchParameter _) -> "Bad request"
          | Some (Application _ | Internal _) | None -> internal_error_text
        in
        React.createElement "p" [] [ React.string text ]
end

module Endpoint = struct
  type ('result, 'error, 'context) prepared = {
    branch : Branch.t;
    active_routes : string list option;
    execution : 'context -> ('result, 'error) Execution.t;
  }

  type ('result, 'error, 'context) t = {
    route : Route.t;
    active_routes : (string * string list) list;
    fingerprint : string;
    prefetch : RouterRuntime.PrefetchLevel.t;
    decode : Input.t -> (('result, 'error, 'context) prepared, 'error RouterRuntime.Error.t) result;
  }

  let make ~id ~path ~activeRoutes ~fingerprint ~decode =
    { route = Route.make ~id ~path; active_routes = activeRoutes; fingerprint; prefetch = Intent; decode }

  let withPrefetch endpoint prefetch = { endpoint with prefetch }
  let prepared ~branch ~execution = { branch; active_routes = None; execution }
  let recovered ~branch ~activeRoutes ~execution = { branch; active_routes = Some activeRoutes; execution }
  let route endpoint = endpoint.route
  let active_routes endpoint = endpoint.active_routes
  let prepared_active_routes (prepared : ('result, 'error, 'context) prepared) = prepared.active_routes
  let decode endpoint = endpoint.decode
  let branch prepared = prepared.branch
  let execution prepared ~context = prepared.execution context
  let fingerprint endpoint = endpoint.fingerprint
  let prefetch endpoint = endpoint.prefetch
end

module EndpointRegistry = struct
  type ('result, 'error, 'context) t = {
    raw : Registry.t;
    endpoints_by_id : (string, ('result, 'error, 'context) Endpoint.t) Hashtbl.t;
    fingerprint : string;
  }

  type ('result, 'error, 'context) matched = {
    endpoint : ('result, 'error, 'context) Endpoint.t;
    parameters : (string * string) list;
  }

  let make endpoints =
    match Registry.make (List.map Endpoint.route endpoints) with
    | Ok raw ->
        let endpoints_by_id = Hashtbl.create (List.length endpoints) in
        List.iter (fun endpoint -> Hashtbl.add endpoints_by_id (Endpoint.route endpoint |> Route.id) endpoint) endpoints;
        let fingerprint =
          endpoints |> List.map Endpoint.fingerprint |> String.concat "\n" |> Digest.string |> Digest.to_hex
        in
        Ok { raw; endpoints_by_id; fingerprint }
    | Error error -> Error error

  let makeExn endpoints =
    match make endpoints with Ok registry -> registry | Error error -> Registry.raise_invalid error

  let find registry ~pathname =
    match Match.find registry.raw ~pathname with
    | Error error -> Error error
    | Ok None -> Ok None
    | Ok (Some matched) ->
        let id = Route.id matched.Match.route in
        let endpoint = Hashtbl.find_opt registry.endpoints_by_id id in
        Ok (Option.map (fun endpoint -> { endpoint; parameters = matched.parameters }) endpoint)

  let decode matched ~search = Endpoint.decode matched.endpoint (Input.make ~parameters:matched.parameters ~search)
  let route matched = Endpoint.route matched.endpoint
  let parameters matched = matched.parameters
  let prefetch matched = Endpoint.prefetch matched.endpoint

  let matches matched prepared =
    let active_routes =
      match Endpoint.prepared_active_routes prepared with
      | None -> Endpoint.active_routes matched.endpoint
      | Some allowed ->
          List.filter
            (fun (route_id, _) -> List.exists (String.equal route_id) allowed)
            (Endpoint.active_routes matched.endpoint)
    in
    active_routes
    |> List.map (fun (route_id, parameter_names) ->
        let parameters = List.filter (fun (name, _) -> List.mem name parameter_names) matched.parameters in
        RouterRuntime.Navigation.{ routeId = route_id; parameters })

  let fingerprint registry = registry.fingerprint
end

module ServerEngine = struct
  type requestKind = Document | Rsc
  type navigationFacts = { from : string option; registry : string option; base_revision : string option }

  type request = {
    pathname : string;
    search : string;
    hash : string;
    kind : requestKind;
    navigation : navigationFacts option;
  }

  type ('view, 'error) full = {
    kind : requestKind;
    canonical_url : string;
    revision : string;
    registry_fingerprint : string;
    protocol_version : int;
    matches : RouterRuntime.Navigation.matched list;
    layouts : RouterRuntime.Navigation.layout list;
    resolved : ('view, 'error) Plan.resolved;
  }

  type ('view, 'error) patch = {
    kind : requestKind;
    canonical_url : string;
    base_revision : string;
    revision : string;
    registry_fingerprint : string;
    protocol_version : int;
    matches : RouterRuntime.Navigation.matched list;
    layouts : RouterRuntime.Navigation.layout list;
    replace_from : string;
    resolved : ('view, 'error) Plan.resolved;
  }

  type ('view, 'error) outcome =
    | Full of ('view, 'error) full
    | Patch of ('view, 'error) patch
    | ReloadRequired
    | Redirect of RouterRuntime.destination
    | PermanentRedirect of RouterRuntime.destination
    | PrefetchRefused of RouterRuntime.PrefetchLevel.t

  let empty_search : Search.t = []

  let required_headers ~kind ~response_kind ~protocol_version ~fingerprint =
    let values =
      [
        ("Vary", match kind with Document -> "Accept" | Rsc -> "Accept, Router-Prefetch");
        ("Content-Type", match kind with Document -> "text/html; charset=utf-8" | Rsc -> "application/react.component");
      ]
      @
      match kind with
      | Document -> []
      | Rsc ->
          [
            ("Router-Response", response_kind);
            ("Router-Registry", string_of_int protocol_version ^ "." ^ fingerprint);
            ("Cache-Control", "private, no-store");
          ]
    in
    match RouterRuntime.Headers.make values with Ok headers -> headers | Error _ -> assert false

  let refused prefetch matched =
    match prefetch with
    | Some prefetch -> RouterRuntime.PrefetchLevel.compare prefetch (EndpointRegistry.prefetch matched) > 0
    | None -> false

  let run ~registry ~basePath ~trailingSlash ~fallback ~applicationStatus ~diagnosticId ?(revision = fun () -> "")
      ~protocolVersion ?prefetch ?actionError ~context request =
    let fingerprint = EndpointRegistry.fingerprint registry in
    let canonical_url = request.pathname ^ request.search ^ request.hash in
    let full ~matches ~layouts plan =
      Lwt.map
        (fun (resolved : ('view, 'error) Plan.resolved) ->
          let required =
            required_headers ~kind:request.kind ~response_kind:"full" ~protocol_version:protocolVersion ~fingerprint
          in
          let resolved = { resolved with headers = RouterRuntime.Headers.merge resolved.headers required } in
          Full
            {
              kind = request.kind;
              canonical_url;
              revision = revision ();
              registry_fingerprint = fingerprint;
              protocol_version = protocolVersion;
              matches;
              layouts;
              resolved;
            })
        (Plan.resolve plan ~applicationStatus)
    in
    let fail ?(search = empty_search) error = full ~matches:[] ~layouts:[] (fallback ~context ~search ~error) in
    let expected_registry = string_of_int protocolVersion ^ "." ^ fingerprint in
    let registry_mismatch =
      match (request.kind, request.navigation) with
      | Rsc, Some { registry = Some registry; _ } -> (
          match String.split_on_char '.' registry with
          | [ version; _ ] -> (
              match int_of_string_opt version with
              | Some _ -> not (String.equal registry expected_registry)
              | None -> false)
          | _ -> false)
      | _ -> false
    in
    let patch_target ~target_branch ~plan =
      match (request.kind, request.navigation) with
      | Rsc, Some { from = Some from; base_revision = Some base_revision; _ } when String.length from <= 2048 -> (
          let from_pathname, from_search = Path.splitLocation from in
          match Path.stripBasePath ~basePath from_pathname with
          | None -> None
          | Some from_path -> (
              match (Search.parse from_search, EndpointRegistry.find registry ~pathname:from_path) with
              | Ok from_search, Ok (Some from_match) -> (
                  match EndpointRegistry.decode from_match ~search:from_search with
                  | Error _ -> None
                  | Ok prepared ->
                      let from_branch = Endpoint.branch prepared in
                      let shared = Branch.sharedPrefix from_branch target_branch in
                      if shared <= 0 || shared >= List.length target_branch then None
                      else
                        let depth = min shared (Plan.scopeCount plan) in
                        if depth <= 0 then None
                        else
                          Option.map
                            (fun scope -> (base_revision, depth, Branch.Scope.instanceKey scope))
                            (List.nth_opt target_branch (depth - 1)))
              | _ -> None))
      | _ -> None
    in
    let execute () =
      if registry_mismatch then Lwt.return ReloadRequired
      else
        match Path.stripTrailingSlashes request.pathname with
        | Some canonical -> (
            match trailingSlash with
            | TrailingSlash.Redirect
              when String.starts_with ~prefix:"//" canonical || String.starts_with ~prefix:"/\\" canonical ->
                fail (RouterRuntime.Error.NotFound { reason = RouterRuntime.Error.NoMatchingRoute })
            | TrailingSlash.Redirect ->
                Lwt.return
                  (PermanentRedirect (RouterRuntime.destination ~path:(canonical ^ request.search ^ request.hash)))
            | TrailingSlash.Reject ->
                fail (RouterRuntime.Error.NotFound { reason = RouterRuntime.Error.NoMatchingRoute }))
        | None -> (
            match Path.stripBasePath ~basePath request.pathname with
            | None -> fail (RouterRuntime.Error.NotFound { reason = RouterRuntime.Error.NoMatchingRoute })
            | Some pathname -> (
                match Search.parse request.search with
                | Error _ -> fail (RouterRuntime.Error.InvalidSearchParameter { name = "search" })
                | Ok search -> (
                    match EndpointRegistry.find registry ~pathname with
                    | Error _ -> fail ~search (RouterRuntime.Error.InvalidPathParameter { name = "pathname" })
                    | Ok None ->
                        fail ~search (RouterRuntime.Error.NotFound { reason = RouterRuntime.Error.NoMatchingRoute })
                    | Ok (Some matched) when refused prefetch matched ->
                        Lwt.return (PrefetchRefused (EndpointRegistry.prefetch matched))
                    | Ok (Some matched) -> (
                        match EndpointRegistry.decode matched ~search with
                        | Error error -> fail ~search error
                        | Ok prepared ->
                            let target_branch = Endpoint.branch prepared in
                            let execution = Endpoint.execution prepared ~context in
                            let matches = EndpointRegistry.matches matched prepared in
                            let layouts = Branch.layouts target_branch in
                            Lwt.bind (Execution.run ~diagnosticId execution) (function
                              | RouterRuntime.Loader.Data plan -> (
                                  let plan =
                                    match actionError with Some error -> Plan.fail plan error | None -> plan
                                  in
                                  match patch_target ~target_branch ~plan with
                                  | None -> full ~matches ~layouts plan
                                  | Some (base_revision, depth, replace_from) ->
                                      Lwt.map
                                        (fun (resolved : ('view, 'error) Plan.resolved) ->
                                          let required =
                                            required_headers ~kind:request.kind ~response_kind:"patch"
                                              ~protocol_version:protocolVersion ~fingerprint
                                          in
                                          let resolved =
                                            {
                                              resolved with
                                              headers = RouterRuntime.Headers.merge resolved.headers required;
                                            }
                                          in
                                          Patch
                                            {
                                              kind = request.kind;
                                              canonical_url;
                                              base_revision;
                                              revision = revision ();
                                              registry_fingerprint = fingerprint;
                                              protocol_version = protocolVersion;
                                              matches;
                                              layouts;
                                              replace_from;
                                              resolved;
                                            })
                                        (Plan.resolve plan
                                           ~render:(Plan.Suffix { omitted_scopes = depth })
                                           ~applicationStatus))
                              | RouterRuntime.Loader.Error error -> fail ~search (RouterRuntime.Error.Application error)
                              | RouterRuntime.Loader.NotFound ->
                                  fail ~search
                                    (RouterRuntime.Error.NotFound { reason = RouterRuntime.Error.LoaderNotFound })
                              | RouterRuntime.Loader.Redirect destination
                                when Option.is_none (redirect_location destination) ->
                                  fail ~search
                                    (RouterRuntime.Error.Internal
                                       { diagnosticId = diagnosticId (unsafe_redirect destination) })
                              | RouterRuntime.Loader.PermanentRedirect destination
                                when Option.is_none (redirect_location destination) ->
                                  fail ~search
                                    (RouterRuntime.Error.Internal
                                       { diagnosticId = diagnosticId (unsafe_redirect destination) })
                              | RouterRuntime.Loader.Redirect destination -> Lwt.return (Redirect destination)
                              | RouterRuntime.Loader.PermanentRedirect destination ->
                                  Lwt.return (PermanentRedirect destination))))))
    in
    let blank_internal error =
      let required =
        required_headers ~kind:request.kind ~response_kind:"full" ~protocol_version:protocolVersion ~fingerprint
      in
      let resolved : ('view, 'error) Plan.resolved =
        {
          element = None;
          error = Some error;
          status = RouterRuntime.Status.InternalServerError;
          metadata = RouterRuntime.Metadata.make ();
          headers = required;
        }
      in
      Lwt.return
        (Full
           {
             kind = request.kind;
             canonical_url;
             revision = revision ();
             registry_fingerprint = fingerprint;
             protocol_version = protocolVersion;
             matches = [];
             layouts = [];
             resolved;
           })
    in
    Lwt.catch execute (fun exception_ ->
        if fatal_exception exception_ then Lwt.fail exception_
        else
          let error = RouterRuntime.Error.Internal { diagnosticId = diagnosticId exception_ } in
          Lwt.catch
            (fun () -> fail error)
            (fun fallback_error ->
              if fatal_exception fallback_error then Lwt.fail fallback_error else blank_internal error))
end

module Server = struct
  type ('view, 'error, 'context) t = {
    base_path : string;
    registry : (('view, 'error) Plan.t, 'error, 'context) EndpointRegistry.t;
    trailing_slash : TrailingSlash.t;
    fallback : context:'context -> search:Search.t -> error:'error RouterRuntime.Error.t -> ('view, 'error) Plan.t;
    application_status : 'error -> RouterRuntime.Status.t;
    protocol_version : int;
    routes : string array;
    intercept_links : bool;
    view_transitions : bool;
    page_cache_max_age : float option;
  }

  let client_routes registry =
    registry.EndpointRegistry.raw |> Registry.routes |> List.map Route.path
    |> List.fold_left (fun paths path -> if List.mem path paths then paths else path :: paths) []
    |> List.rev |> Array.of_list

  let make ~basePath ~registry ?(trailingSlash = TrailingSlash.Redirect) ~fallback ~applicationStatus
      ?(protocolVersion = 1) ?(interceptLinks = true) ?(viewTransitions = false) ?pageCacheMaxAge () =
    if not (Path.validBasePath basePath) then invalid_arg ("invalid router base path " ^ basePath)
    else
      {
        base_path = basePath;
        registry;
        trailing_slash = trailingSlash;
        fallback;
        application_status = applicationStatus;
        protocol_version = protocolVersion;
        routes = client_routes registry;
        intercept_links = interceptLinks;
        view_transitions = viewTransitions;
        page_cache_max_age = pageCacheMaxAge;
      }

  let routes server = Array.copy server.routes
  let basePath server = server.base_path
  let protocolVersion server = server.protocol_version
  let fingerprint server = EndpointRegistry.fingerprint server.registry

  let clientRootWith ?pageCacheCapacity server ~make ~initial ~metadata ~children =
    make ~initial ~protocolVersion:server.protocol_version ~registryFingerprint:(fingerprint server)
      ~basePath:server.base_path ~routes:(routes server) ~interceptLinks:server.intercept_links
      ~viewTransitions:server.view_transitions ~pageCacheCapacity ~pageCacheMaxAge:server.page_cache_max_age ~metadata
      ~children

  let clientRoot ?pageCacheCapacity server =
    clientRootWith server ?pageCacheCapacity
      ~make:(fun
          ~initial
          ~protocolVersion
          ~registryFingerprint
          ~basePath
          ~routes
          ~interceptLinks
          ~viewTransitions
          ~pageCacheCapacity
          ~pageCacheMaxAge
          ~metadata
          ~children
        ->
        RouterClientRoot.make
          (RouterClientRoot.makeProps ~initial ~protocolVersion ~registryFingerprint ~basePath ?pageCacheCapacity
             ?pageCacheMaxAge ~routes ~interceptLinks ~viewTransitions ~metadata ~children ()))

  let run server ~diagnosticId ?revision ?prefetch ?actionError ~context request =
    ServerEngine.run ~registry:server.registry ~basePath:server.base_path ~trailingSlash:server.trailing_slash
      ~fallback:server.fallback ~applicationStatus:server.application_status ~diagnosticId ?revision
      ~protocolVersion:server.protocol_version ?prefetch ?actionError ~context request
end

let statusOfError = status_of_error
let redirectLocation = redirect_location
let unsafeRedirect = unsafe_redirect
let fatalException = fatal_exception
let internalErrorText = internal_error_text
