module Percent = struct
  let is_hex = function '0' .. '9' | 'a' .. 'f' | 'A' .. 'F' -> true | _ -> false

  let validate value =
    let rec loop index =
      if index >= String.length value then true
      else if value.[index] <> '%' then loop (index + 1)
      else index + 2 < String.length value && is_hex value.[index + 1] && is_hex value.[index + 2] && loop (index + 3)
    in
    loop 0

  let decode ?(plus = false) value =
    if not (validate value) then Error value
    else
      let value = if plus then String.map (function '+' -> ' ' | character -> character) value else value in
      Ok (Uri.pct_decode value)
end

module Path = struct
  type segment = RouterPattern.segment = Static of string | Parameter of RouterPattern.parameter
  type error = MalformedEscape of string | EncodedSlash of string | InvalidPath of string

  let split path =
    if path = "/" then Ok []
    else if path = "" || path.[0] <> '/' then Error path
    else
      let segments = String.split_on_char '/' path |> List.tl in
      if List.exists (String.equal "") segments then Error path else Ok segments

  let decode_segment segment =
    match Percent.decode segment with
    | Error segment -> Error (MalformedEscape segment)
    | Ok decoded ->
        if String.contains decoded '/' then Error (EncodedSlash segment)
        else if decoded = "." || decoded = ".." then Error (InvalidPath segment)
        else Ok decoded

  let decodePathname pathname =
    match split pathname with
    | Error path -> Error (InvalidPath path)
    | Ok segments ->
        let rec decode_all decoded = function
          | [] -> Ok (List.rev decoded)
          | segment :: rest -> (
              match decode_segment segment with
              | Ok segment -> decode_all (segment :: decoded) rest
              | Error error -> Error error)
        in
        decode_all [] segments

  let stripBasePath ~basePath pathname =
    if String.equal basePath "/" then Some pathname
    else if String.equal pathname basePath then Some "/"
    else
      let prefix = basePath ^ "/" in
      if String.starts_with ~prefix pathname then
        Some (String.sub pathname (String.length basePath) (String.length pathname - String.length basePath))
      else None

  let splitLocation location =
    match String.index_opt location '?' with
    | None -> (location, "")
    | Some index -> (String.sub location 0 index, String.sub location index (String.length location - index))
end

module Route = struct
  type t = { id : string; path : string; segments : Path.segment list }

  let make ~id ~path =
    match RouterPattern.parse path with
    | Ok pattern -> { id; path; segments = RouterPattern.segments pattern }
    | Error _ -> invalid_arg ("invalid route path " ^ path)

  let id route = route.id
  let path route = route.path
end

module Registry = struct
  open Path

  type t = Route.t list

  type error =
    | DuplicateId of string
    | DuplicatePath of string
    | AmbiguousPattern of string * string
    | InvalidPattern of string

  let rec duplicate key = function
    | [] -> None
    | item :: rest ->
        if List.exists (fun other -> String.equal (key item) (key other)) rest then Some (key item)
        else duplicate key rest

  let ambiguous routes =
    let specificity route =
      List.fold_left (fun score -> function Static _ -> score + 1 | Parameter _ -> score) 0 route.Route.segments
    in
    let rec overlaps left right =
      match (left, right) with
      | [], [] -> true
      | Static left_value :: left, Static right_value :: right ->
          String.equal left_value right_value && overlaps left right
      | _ :: left, _ :: right -> overlaps left right
      | _ -> false
    in
    let rec loop = function
      | [] -> None
      | route :: rest -> (
          match
            List.find_opt
              (fun other -> specificity route = specificity other && overlaps route.Route.segments other.Route.segments)
              rest
          with
          | Some other when not (String.equal route.Route.path other.Route.path) ->
              Some (route.Route.path, other.Route.path)
          | _ -> loop rest)
    in
    loop routes

  let make routes =
    match duplicate (fun route -> route.Route.id) routes with
    | Some id -> Error (DuplicateId id)
    | None -> (
        match duplicate (fun route -> route.Route.path) routes with
        | Some path -> Error (DuplicatePath path)
        | None -> (
            match ambiguous routes with
            | Some (left, right) -> Error (AmbiguousPattern (left, right))
            | None -> Ok routes))

  let makeExn routes =
    match make routes with
    | Ok registry -> registry
    | Error (DuplicateId id) -> invalid_arg ("duplicate route id " ^ id)
    | Error (DuplicatePath path) -> invalid_arg ("duplicate route path " ^ path)
    | Error (AmbiguousPattern (left, right)) -> invalid_arg ("ambiguous route patterns " ^ left ^ " and " ^ right)
    | Error (InvalidPattern path) -> invalid_arg ("invalid route pattern " ^ path)

  let routes registry = registry
end

module Match = struct
  open Path

  type t = { route : Route.t; parameters : (string * string) list }
  type error = Path.error = MalformedEscape of string | EncodedSlash of string | InvalidPath of string

  let match_route route segments =
    let rec loop parameters patterns values =
      match (patterns, values) with
      | [], [] -> Some (List.rev parameters)
      | Static expected :: patterns, value :: values when String.equal expected value -> loop parameters patterns values
      | Parameter parameter :: patterns, value :: values ->
          loop ((parameter.RouterPattern.name, value) :: parameters) patterns values
      | _ -> None
    in
    loop [] route.Route.segments segments

  let specificity route =
    List.fold_left (fun score -> function Static _ -> score + 1 | Parameter _ -> score) 0 route.Route.segments

  let find registry ~pathname =
    match Path.decodePathname pathname with
    | Error error -> Error error
    | Ok segments ->
        let matches =
          Registry.routes registry
          |> List.filter_map (fun route ->
              Option.map (fun parameters -> (specificity route, { route; parameters })) (match_route route segments))
          |> List.sort (fun (left, _) (right, _) -> Int.compare right left)
        in
        Ok (match matches with [] -> None | (_, matched) :: _ -> Some matched)
end

module Search = struct
  type t = (string * string list) list
  type error = MalformedEscape of string | QueryTooLong

  let decode value =
    match Percent.decode ~plus:true value with Ok value -> Ok value | Error value -> Error (MalformedEscape value)

  let parse_pair pair =
    match String.index_opt pair '=' with
    | None -> (pair, "")
    | Some index -> (String.sub pair 0 index, String.sub pair (index + 1) (String.length pair - index - 1))

  let parse search =
    if String.length search > 8192 then Error QueryTooLong
    else
      let search =
        if search <> "" && search.[0] = '?' then String.sub search 1 (String.length search - 1) else search
      in
      let pairs = if search = "" then [] else String.split_on_char '&' search in
      let values = Hashtbl.create (List.length pairs) in
      let keys = ref [] in
      let rec loop = function
        | [] -> Ok (List.rev_map (fun key -> (key, Hashtbl.find values key |> List.rev)) !keys)
        | pair :: rest -> (
            let key, value = parse_pair pair in
            match (decode key, decode value) with
            | Ok key, Ok value ->
                if not (Hashtbl.mem values key) then keys := key :: !keys;
                let current = match Hashtbl.find_opt values key with Some values -> values | None -> [] in
                Hashtbl.replace values key (value :: current);
                loop rest
            | Error error, _ | _, Error error -> Error error)
      in
      loop pairs

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
    match Search.values input.Input.search name with
    | value :: _ -> Result.map Option.some (parse_search ~name ~parse value)
    | [] -> Ok None

  let searchDefault ~input ~name ~parse ~fallback =
    match Search.values input.Input.search name with value :: _ -> parse_search ~name ~parse value | [] -> Ok fallback

  let searchMany ~input ~name ~parse =
    let rec loop decoded = function
      | [] -> Ok (List.rev decoded)
      | value :: values -> (
          match parse_search ~name ~parse value with
          | Ok value -> loop (value :: decoded) values
          | Error error -> Error error)
    in
    loop [] (Search.values input.Input.search name)
end

let fatal_exception = function Lwt.Canceled | Out_of_memory | Stack_overflow | Sys.Break -> true | _ -> false

module Execution = struct
  type ('result, 'error) t =
    | Done : 'result -> ('result, 'error) t
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

  let done_ result = Done result
  let load run next = Load { run; next }
  let loadWithBoundary ~run ~failure ~next = LoadWithBoundary { run; failure; next }

  let run ?(diagnosticId = fun _ -> "internal") execution =
    let rec loop : type result error. (result, error) t -> (result, error) RouterRuntime.Loader.result Lwt.t = function
      | Done result -> Lwt.return (RouterRuntime.Loader.Data result)
      | Load loader ->
          Lwt.bind (loader.run ()) (function
            | RouterRuntime.Loader.Data data -> loop (loader.next data)
            | RouterRuntime.Loader.Error error -> Lwt.return (RouterRuntime.Loader.Error error)
            | RouterRuntime.Loader.NotFound -> Lwt.return RouterRuntime.Loader.NotFound
            | RouterRuntime.Loader.Redirect destination -> Lwt.return (RouterRuntime.Loader.Redirect destination))
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
                | RouterRuntime.Loader.Redirect destination -> Lwt.return (RouterRuntime.Loader.Redirect destination)))
            (fun exception_ ->
              if fatal_exception exception_ then Lwt.fail exception_
              else
                Lwt.return
                  (RouterRuntime.Loader.Data
                     (loader.failure (RouterRuntime.Error.Internal { diagnosticId = diagnosticId exception_ }))))
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
    type t = { id : string; instance_key : string; reusable : bool }

    let frame value = string_of_int (String.length value) ^ ":" ^ value

    let make ~id ~parameters ~reusable =
      let identity = parameters |> List.map (fun (name, value) -> frame name ^ frame value) |> String.concat "" in
      { id; instance_key = frame id ^ identity; reusable }

    let id scope = scope.id
    let instanceKey scope = scope.instance_key
    let reusable scope = scope.reusable
  end

  type t = Scope.t list

  let rec sharedPrefix from target =
    match (from, target) with
    | left :: from, right :: target
      when left.Scope.reusable && right.Scope.reusable && String.equal left.instance_key right.instance_key ->
        1 + sharedPrefix from target
    | _ -> 0

  let layouts branch =
    List.map
      (fun scope -> RouterRuntime.Navigation.{ id = Scope.id scope; instanceKey = Scope.instanceKey scope })
      branch
end

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
    | Success of { scopes : 'view Scope.t list; page : 'view }
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

  let success ~scopes ~page = Success { scopes; page }

  let failure ~scopes ~error ?notFound ?errorBoundary () =
    Failure { scopes; error; not_found = notFound; error_boundary = errorBoundary }

  let empty_headers = match RouterRuntime.Headers.make [] with Ok headers -> headers | Error _ -> assert false

  let resolve_values scopes =
    let rec loop metadata headers = function
      | [] -> Lwt.return (metadata, headers)
      | scope :: scopes ->
          let metadata_promise =
            match scope.Scope.metadata with
            | None -> Lwt.return metadata
            | Some make -> Lwt.map (RouterRuntime.Metadata.merge metadata) (make ())
          in
          let headers_promise =
            match scope.Scope.headers with
            | None -> Lwt.return headers
            | Some make -> Lwt.map (RouterRuntime.Headers.merge headers) (make ())
          in
          Lwt.bind (Lwt.both metadata_promise headers_promise) (fun (metadata, headers) -> loop metadata headers scopes)
    in
    loop (RouterRuntime.Metadata.make ()) empty_headers scopes

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
end

module Endpoint = struct
  type ('result, 'error) prepared = { branch : Branch.t; execution : unit -> ('result, 'error) Execution.t }

  type ('result, 'error) t = {
    route : Route.t;
    active_routes : (string * string list) list;
    fingerprint : string;
    decode : Input.t -> (('result, 'error) prepared, 'error RouterRuntime.Error.t) result;
  }

  let make ~id ~path ~activeRoutes ~fingerprint ~decode =
    { route = Route.make ~id ~path; active_routes = activeRoutes; fingerprint; decode }

  let prepared ~branch ~execution = { branch; execution }
  let route endpoint = endpoint.route
  let active_routes endpoint = endpoint.active_routes
  let decode endpoint = endpoint.decode
  let branch prepared = prepared.branch
  let execution prepared = prepared.execution ()
  let fingerprint endpoint = endpoint.fingerprint
end

module EndpointRegistry = struct
  type ('result, 'error) t = { raw : Registry.t; endpoints : ('result, 'error) Endpoint.t list; fingerprint : string }
  type ('result, 'error) matched = { endpoint : ('result, 'error) Endpoint.t; parameters : (string * string) list }

  let make endpoints =
    match Registry.make (List.map Endpoint.route endpoints) with
    | Ok raw ->
        let fingerprint =
          endpoints |> List.map Endpoint.fingerprint |> String.concat "\n" |> Digest.string |> Digest.to_hex
        in
        Ok { raw; endpoints; fingerprint }
    | Error error -> Error error

  let makeExn endpoints =
    match make endpoints with
    | Ok registry -> registry
    | Error (Registry.DuplicateId id) -> invalid_arg ("duplicate route id " ^ id)
    | Error (DuplicatePath path) -> invalid_arg ("duplicate route path " ^ path)
    | Error (AmbiguousPattern (left, right)) -> invalid_arg ("ambiguous route patterns " ^ left ^ " and " ^ right)
    | Error (InvalidPattern path) -> invalid_arg ("invalid route pattern " ^ path)

  let find registry ~pathname =
    match Match.find registry.raw ~pathname with
    | Error error -> Error error
    | Ok None -> Ok None
    | Ok (Some matched) ->
        let id = Route.id matched.Match.route in
        let endpoint =
          List.find_opt (fun endpoint -> String.equal id (Endpoint.route endpoint |> Route.id)) registry.endpoints
        in
        Ok (Option.map (fun endpoint -> { endpoint; parameters = matched.parameters }) endpoint)

  let decode matched ~search = Endpoint.decode matched.endpoint (Input.make ~parameters:matched.parameters ~search)
  let route matched = Endpoint.route matched.endpoint
  let parameters matched = matched.parameters

  let matches matched =
    Endpoint.active_routes matched.endpoint
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

  let empty_search = match Search.parse "" with Ok search -> search | Error _ -> assert false

  let required_headers ~kind ~response_kind ~protocol_version ~fingerprint =
    let values =
      [
        ("Vary", "Accept");
        ("Content-Type", match kind with Document -> "text/html; charset=utf-8" | Rsc -> "application/react.component");
      ]
      @
      match kind with
      | Document -> []
      | Rsc ->
          [ ("SRR-Response", response_kind); ("SRR-Registry", string_of_int protocol_version ^ "." ^ fingerprint) ]
          @ if String.equal response_kind "patch" then [ ("Cache-Control", "private, no-store") ] else []
    in
    match RouterRuntime.Headers.make values with Ok headers -> headers | Error _ -> assert false

  let run ~registry ~basePath ~fallback ~applicationStatus ~diagnosticId ~revision ~protocolVersion request =
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
    let fail ?(search = empty_search) error = full ~matches:[] ~layouts:[] (fallback ~search ~error) in
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
    let patch_base ~target_branch =
      match (request.kind, request.navigation) with
      | Rsc, Some { from = Some from; base_revision = Some base_revision; _ } when String.length from <= 2048 -> (
          let from_pathname, from_search = Path.splitLocation from in
          if not (String.equal from_search request.search) then None
          else
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
                          Option.map
                            (fun scope -> (base_revision, shared, Branch.Scope.instanceKey scope))
                            (List.nth_opt target_branch (shared - 1)))
                | _ -> None))
      | _ -> None
    in
    let execute () =
      if registry_mismatch then Lwt.return ReloadRequired
      else
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
                | Ok (Some matched) -> (
                    match EndpointRegistry.decode matched ~search with
                    | Error error -> fail ~search error
                    | Ok prepared ->
                        let target_branch = Endpoint.branch prepared in
                        let execution = Endpoint.execution prepared in
                        let matches = EndpointRegistry.matches matched in
                        let layouts = Branch.layouts target_branch in
                        Lwt.bind (Execution.run ~diagnosticId execution) (function
                          | RouterRuntime.Loader.Data plan -> (
                              match patch_base ~target_branch with
                              | None -> full ~matches ~layouts plan
                              | Some (base_revision, shared, replace_from) ->
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
                                       ~render:(Plan.Suffix { omitted_scopes = shared })
                                       ~applicationStatus))
                          | RouterRuntime.Loader.Error error -> fail ~search (RouterRuntime.Error.Application error)
                          | RouterRuntime.Loader.NotFound ->
                              fail ~search
                                (RouterRuntime.Error.NotFound { reason = RouterRuntime.Error.LoaderNotFound })
                          | RouterRuntime.Loader.Redirect destination -> Lwt.return (Redirect destination)))))
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
  type ('view, 'error) t = {
    base_path : string;
    registry : (('view, 'error) Plan.t, 'error) EndpointRegistry.t;
    fallback : search:Search.t -> error:'error RouterRuntime.Error.t -> ('view, 'error) Plan.t;
    application_status : 'error -> RouterRuntime.Status.t;
    protocol_version : int;
  }

  let make ~basePath ~registry ~fallback ~applicationStatus ?(protocolVersion = 1) () =
    {
      base_path = basePath;
      registry;
      fallback;
      application_status = applicationStatus;
      protocol_version = protocolVersion;
    }

  let basePath server = server.base_path
  let protocolVersion server = server.protocol_version
  let fingerprint server = EndpointRegistry.fingerprint server.registry

  let clientRoot server ~initial ~metadata ~children =
    RouterClientRoot.make
      (RouterClientRoot.makeProps ~initial ~protocolVersion:server.protocol_version
         ~registryFingerprint:(fingerprint server) ~basePath:server.base_path ~metadata ~children ())

  let run server ~diagnosticId ~revision request =
    ServerEngine.run ~registry:server.registry ~basePath:server.base_path ~fallback:server.fallback
      ~applicationStatus:server.application_status ~diagnosticId ~revision ~protocolVersion:server.protocol_version
      request
end

let statusOfError = status_of_error
