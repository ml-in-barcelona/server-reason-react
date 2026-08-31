module Percent = struct
  let hex_value = function
    | '0' .. '9' as character -> Char.code character - Char.code '0'
    | 'a' .. 'f' as character -> Char.code character - Char.code 'a' + 10
    | 'A' .. 'F' as character -> Char.code character - Char.code 'A' + 10
    | _ -> -1

  let slice value start stop = if start = stop then "" else String.sub value start (stop - start)

  let rec decoded_size reject_slash value stop read size =
    if read = stop then Ok size
    else
      match value.[read] with
      | '%' when read + 2 < stop ->
          let high = hex_value value.[read + 1] in
          let low = hex_value value.[read + 2] in
          if high < 0 || low < 0 then Error `Malformed
          else if reject_slash && high = 2 && low = 15 then Error `Encoded_slash
          else decoded_size reject_slash value stop (read + 3) (size + 1)
      | '%' -> Error `Malformed
      | _ -> decoded_size reject_slash value stop (read + 1) (size + 1)

  let rec decode_valid plus value stop decoded read write =
    if read = stop then Bytes.unsafe_to_string decoded
    else
      match value.[read] with
      | '%' ->
          let high = hex_value value.[read + 1] in
          let low = hex_value value.[read + 2] in
          Bytes.set decoded write (Char.chr ((high lsl 4) lor low));
          decode_valid plus value stop decoded (read + 3) (write + 1)
      | '+' when plus ->
          Bytes.set decoded write ' ';
          decode_valid plus value stop decoded (read + 1) (write + 1)
      | character ->
          Bytes.set decoded write character;
          decode_valid plus value stop decoded (read + 1) (write + 1)

  let decode_escaped ?(plus = false) ?(reject_slash = false) value ~start ~stop ~first =
    match decoded_size reject_slash value stop first (first - start) with
    | Error error -> Error error
    | Ok size ->
        let decoded = Bytes.create size in
        Bytes.blit_string value start decoded 0 (first - start);
        Ok (decode_valid plus value stop decoded first (first - start))

  let decode_range ?(plus = false) value ~start ~stop ~first =
    if first < 0 then Ok (slice value start stop)
    else
      match decode_escaped ~plus value ~start ~stop ~first with
      | Ok decoded -> Ok decoded
      | Error _ -> Error (slice value start stop)
end

module Path = struct
  type segment = RouterPattern.segment =
    | Static of string
    | Parameter of RouterPattern.parameter
    | CatchAll of { name : string }

  type error = MalformedEscape of string | EncodedSlash of string | InvalidPath of string

  let valid_segment value =
    RouterUtf8.valid value
    && String.for_all (fun character -> Char.code character >= 0x20 && Char.code character <> 0x7f) value

  let decoded_segment raw decoded =
    if decoded = "." || decoded = ".." || not (valid_segment decoded) then Error (InvalidPath raw) else Ok decoded

  let decode_segment pathname ~has_escapes ~start ~stop =
    let first =
      if not has_escapes then -1
      else match String.index_from_opt pathname start '%' with Some index when index < stop -> index | _ -> -1
    in
    if first < 0 then
      let segment = Percent.slice pathname start stop in
      decoded_segment segment segment
    else
      match Percent.decode_escaped ~reject_slash:true pathname ~start ~stop ~first with
      | Error `Malformed -> Error (MalformedEscape (Percent.slice pathname start stop))
      | Error `Encoded_slash -> Error (EncodedSlash (Percent.slice pathname start stop))
      | Ok decoded -> decoded_segment (Percent.slice pathname start stop) decoded

  let rec decode_segments pathname has_escapes decoded error stop =
    let slash = String.rindex_from pathname (stop - 1) '/' in
    let start = slash + 1 in
    if start = stop then
      if slash = 0 then Error (InvalidPath pathname)
      else decode_segments pathname has_escapes decoded (Some (InvalidPath pathname)) slash
    else
      match decode_segment pathname ~has_escapes ~start ~stop with
      | Ok segment ->
          if slash = 0 then match error with Some error -> Error error | None -> Ok (segment :: decoded)
          else decode_segments pathname has_escapes (segment :: decoded) error slash
      | Error current ->
          if slash = 0 then Error current else decode_segments pathname has_escapes decoded (Some current) slash

  let decodePathname pathname =
    if String.equal pathname "/" then Ok []
    else if String.equal pathname "" || pathname.[0] <> '/' then Error (InvalidPath pathname)
    else
      let length = String.length pathname in
      let has_escapes = String.contains pathname '%' in
      decode_segments pathname has_escapes [] None length

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
    match (RouterUtf8.valid path, RouterPattern.parse path) with
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
    match duplicate (fun route -> route.Route.id) routes with
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

  let invalid = function
    | DuplicateId id -> invalid_arg ("duplicate route id " ^ id)
    | DuplicatePath path -> invalid_arg ("duplicate route path " ^ path)
    | AmbiguousPattern (left, right) -> invalid_arg ("ambiguous route patterns " ^ left ^ " and " ^ right)
    | InvalidPattern path -> invalid_arg ("invalid route pattern " ^ path)

  let makeExn routes = match make routes with Ok registry -> registry | Error error -> invalid error
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
          match node.route with Some route -> best := Some (route.Route.specificity, route, captured) | None -> ())
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
  type error = MalformedEscape of string | QueryTooLong
  type index = Small | Large of (string, string list ref) Hashtbl.t

  let decode search ~start ~stop ~first =
    match Percent.decode_range ~plus:true search ~start ~stop ~first with
    | Ok value -> Ok value
    | Error value -> Error (MalformedEscape value)

  let rec find_values key = function
    | [] -> None
    | (current_key, values) :: keys -> if String.equal key current_key then Some values else find_values key keys

  let parse search =
    if String.length search > 8192 then Error QueryTooLong
    else
      let length = String.length search in
      let first = if length > 0 && search.[0] = '?' then 1 else 0 in
      if first = length then Ok []
      else
        let keys = ref [] in
        let value_index = ref Small in
        let finish () = Ok (List.rev_map (fun (key, current) -> (key, List.rev !current)) !keys) in
        let rec loop start equals key_first value_first index =
          if index < length && search.[index] <> '&' then
            let character = search.[index] in
            if equals < 0 && character = '=' then loop start index key_first value_first (index + 1)
            else
              let escaped = character = '%' || character = '+' in
              let key_first = if equals < 0 && key_first < 0 && escaped then index else key_first in
              let value_first = if equals >= 0 && value_first < 0 && escaped then index else value_first in
              loop start equals key_first value_first (index + 1)
          else
            let key_stop = if equals < 0 then index else equals in
            let value_start = if equals < 0 then index else equals + 1 in
            match
              ( decode search ~start ~stop:key_stop ~first:key_first,
                decode search ~start:value_start ~stop:index ~first:value_first )
            with
            | Ok key, Ok value ->
                let current =
                  match !value_index with Small -> find_values key !keys | Large values -> Hashtbl.find_opt values key
                in
                (match current with
                | Some current -> current := value :: !current
                | None -> (
                    let current = ref [ value ] in
                    keys := (key, current) :: !keys;
                    match !value_index with
                    | Large values -> Hashtbl.add values key current
                    | Small when List.length !keys = 8 ->
                        let values = Hashtbl.create 16 in
                        List.iter (fun (key, current) -> Hashtbl.add values key current) !keys;
                        value_index := Large values
                    | Small -> ()));
                if index = length then finish () else loop (index + 1) (-1) (-1) (-1) (index + 1)
            | Error error, _ | _, Error error -> Error error
        in
        loop first (-1) (-1) (-1) first

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
    | Redirect : RouterRuntime.destination -> ('result, 'error) t
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
  let redirect destination = Redirect destination
  let load run next = Load { run; next }
  let loadWithBoundary ~run ~failure ~next = LoadWithBoundary { run; failure; next }

  let run ?(diagnosticId = fun _ -> "internal") execution =
    let rec loop : type result error. (result, error) t -> (result, error) RouterRuntime.Loader.result Lwt.t = function
      | Done result -> Lwt.return (RouterRuntime.Loader.Data result)
      | Redirect destination -> Lwt.return (RouterRuntime.Loader.Redirect destination)
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
    type t = { id : string; instance_key : string; graftable : bool }

    let frame value = string_of_int (String.length value) ^ ":" ^ value

    let instanceKeyOf ~id ~parameters =
      let identity = parameters |> List.map (fun (name, value) -> frame name ^ frame value) |> String.concat "" in
      frame id ^ identity

    let make ~id ~parameters ~graftable = { id; instance_key = instanceKeyOf ~id ~parameters; graftable }
    let id scope = scope.id
    let instanceKey scope = scope.instance_key
    let graftable scope = scope.graftable
  end

  type t = Scope.t list

  let insertionPoint ~from ~target ~maxDepth =
    let rec aux index bestInsertionPoint from target =
      match (from, target) with
      | left :: from, right :: target when String.equal left.Scope.instance_key right.Scope.instance_key ->
          let insertionPoint =
            if index < maxDepth && Scope.graftable right then Some (index, right) else bestInsertionPoint
          in
          aux (index + 1) insertionPoint from target
      | _, [] -> None
      | _ -> bestInsertionPoint
    in
    aux 0 None from target

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

  let scopeCount = function
    | Success success -> List.length success.scopes
    | Failure failure -> List.length failure.scopes

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
  type ('result, 'error) prepared = {
    branch : Branch.t;
    active_routes : string list option;
    execution : unit -> ('result, 'error) Execution.t;
  }

  type ('result, 'error) t = {
    route : Route.t;
    active_routes : (string * string list) list;
    fingerprint : string;
    decode : Input.t -> (('result, 'error) prepared, 'error RouterRuntime.Error.t) result;
  }

  let make ~id ~path ~activeRoutes ~fingerprint ~decode =
    { route = Route.make ~id ~path; active_routes = activeRoutes; fingerprint; decode }

  let prepared ~branch ~execution = { branch; active_routes = None; execution }
  let recovered ~branch ~activeRoutes ~execution = { branch; active_routes = Some activeRoutes; execution }
  let route endpoint = endpoint.route
  let active_routes endpoint = endpoint.active_routes
  let prepared_active_routes (prepared : ('result, 'error) prepared) = prepared.active_routes
  let decode endpoint = endpoint.decode
  let branch prepared = prepared.branch
  let execution prepared = prepared.execution ()
  let fingerprint endpoint = endpoint.fingerprint
end

module EndpointRegistry = struct
  type ('result, 'error) t = {
    raw : Registry.t;
    endpoints_by_id : (string, ('result, 'error) Endpoint.t) Hashtbl.t;
    fingerprint : string;
  }

  type ('result, 'error) matched = { endpoint : ('result, 'error) Endpoint.t; parameters : (string * string) list }

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

  let makeExn endpoints = match make endpoints with Ok registry -> registry | Error error -> Registry.invalid error

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
          [
            ("Router-Response", response_kind);
            ("Router-Registry", string_of_int protocol_version ^ "." ^ fingerprint);
            ("Cache-Control", "private, no-store");
          ]
    in
    match RouterRuntime.Headers.make values with Ok headers -> headers | Error _ -> assert false

  let run ~registry ~basePath ~trailingSlash ~fallback ~applicationStatus ~diagnosticId ~revision ~protocolVersion
      request =
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
    let patch_base ~target_branch ~plan =
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
                        Option.map
                          (fun (index, scope) -> (base_revision, index + 1, Branch.Scope.instanceKey scope))
                          (Branch.insertionPoint ~from:from_branch ~target:target_branch
                             ~maxDepth:(Plan.scopeCount plan)))
                | _ -> None))
      | _ -> None
    in
    let execute () =
      if registry_mismatch then Lwt.return ReloadRequired
      else
        match Path.stripTrailingSlashes request.pathname with
        | Some canonical -> (
            match trailingSlash with
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
                    | Ok (Some matched) -> (
                        match EndpointRegistry.decode matched ~search with
                        | Error error -> fail ~search error
                        | Ok prepared ->
                            let target_branch = Endpoint.branch prepared in
                            let execution = Endpoint.execution prepared in
                            let matches = EndpointRegistry.matches matched prepared in
                            let layouts = Branch.layouts target_branch in
                            Lwt.bind (Execution.run ~diagnosticId execution) (function
                              | RouterRuntime.Loader.Data plan -> (
                                  match patch_base ~target_branch ~plan with
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
                              | RouterRuntime.Loader.Redirect destination -> Lwt.return (Redirect destination))))))
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
    trailing_slash : TrailingSlash.t;
    fallback : search:Search.t -> error:'error RouterRuntime.Error.t -> ('view, 'error) Plan.t;
    application_status : 'error -> RouterRuntime.Status.t;
    protocol_version : int;
  }

  let make ~basePath ~registry ?(trailingSlash = TrailingSlash.Redirect) ~fallback ~applicationStatus
      ?(protocolVersion = 1) () =
    if not (Path.validBasePath basePath) then invalid_arg ("invalid router base path " ^ basePath)
    else
      {
        base_path = basePath;
        registry;
        trailing_slash = trailingSlash;
        fallback;
        application_status = applicationStatus;
        protocol_version = protocolVersion;
      }

  let basePath server = server.base_path
  let protocolVersion server = server.protocol_version
  let fingerprint server = EndpointRegistry.fingerprint server.registry

  let clientRootWith server ~make ~initial ~metadata ~children =
    make ~initial ~protocolVersion:server.protocol_version ~registryFingerprint:(fingerprint server)
      ~basePath:server.base_path ~metadata ~children

  let clientRoot server =
    clientRootWith server ~make:(fun ~initial ~protocolVersion ~registryFingerprint ~basePath ~metadata ~children ->
        RouterClientRoot.make
          (RouterClientRoot.makeProps ~initial ~protocolVersion ~registryFingerprint ~basePath ~metadata ~children ()))

  let run server ~diagnosticId ~revision request =
    ServerEngine.run ~registry:server.registry ~basePath:server.base_path ~trailingSlash:server.trailing_slash
      ~fallback:server.fallback ~applicationStatus:server.application_status ~diagnosticId ~revision
      ~protocolVersion:server.protocol_version request
end

let statusOfError = status_of_error
