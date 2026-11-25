open RouterEngine

type signal = NotFound | Redirect of RouterRuntime.destination | PermanentRedirect of RouterRuntime.destination

exception Signal of signal

let slot : signal option ref Lwt.key = Lwt.new_key ()

let signal value =
  (match Lwt.get slot with
  | Some recorded when Option.is_none !recorded -> recorded := Some value
  | Some _ | None -> ());
  raise (Signal value)

let notFound () = signal NotFound

let redirect ?(permanent = false) destination =
  signal (if permanent then PermanentRedirect destination else Redirect destination)

let recording render =
  let recorded = ref None in
  let result =
    Lwt.catch
      (fun () -> Lwt.map (fun value -> Ok value) (Lwt.with_value slot (Some recorded) render))
      (fun exn -> match !recorded with Some _ -> Lwt.return (Error exn) | None -> Lwt.fail exn)
  in
  Lwt.map (fun result -> (result, recorded)) result

type 'a memoKey = 'a Type.Id.t
type entry = Entry : 'a memoKey * 'a Lwt.t -> entry

let table : (int * string, entry) Hashtbl.t Lwt.key = Lwt.new_key ()
let memoKey () = Type.Id.make ()
let requestScope run = Lwt.with_value table (Some (Hashtbl.create 16)) run

let reentering body =
  match Lwt.get table with
  | None -> body
  | Some _ as entries -> fun write -> Lwt.with_value table entries (fun () -> body write)

let memo (type a) (key : a memoKey) argument (run : unit -> a Lwt.t) : a Lwt.t =
  match Lwt.get table with
  | None -> run ()
  | Some entries -> (
      let slot = (Type.Id.uid key, argument) in
      let cached =
        Hashtbl.find_all entries slot
        |> List.find_map (fun (Entry (stored, promise)) : a Lwt.t option ->
            match Type.Id.provably_equal stored key with Some Type.Equal -> Some promise | None -> None)
      in
      match cached with
      | Some promise -> promise
      | None ->
          let promise = Lwt.apply run () in
          Hashtbl.add entries slot (Entry (key, promise));
          promise)

let metadataElement (metadata : RouterRuntime.Metadata.t) =
  let attribute name value = React.JSX.String (name, name, value) in
  let keyed key tag attributes = React.createElementWithKey ~key:("router:" ^ key) tag attributes [] in
  let title =
    Option.map
      (fun title -> React.createElementWithKey ~key:"router:title" "title" [] [ React.string title ])
      metadata.title
  in
  let description =
    Option.map
      (fun content -> keyed "description" "meta" [ attribute "name" "description"; attribute "content" content ])
      metadata.description
  in
  let entry = function
    | RouterRuntime.Metadata.Meta { key; attr; name; content } ->
        let attr = match attr with Name -> "name" | Property -> "property" in
        keyed key "meta" [ attribute attr name; attribute "content" content ]
    | Link { key; rel; href; attrs } ->
        let extra =
          List.filter_map
            (fun (name, value) ->
              match String.lowercase_ascii name with
              | "rel" | "href" -> None
              | _ when not (RouterTypes.validAttributeName name) -> None
              | _ -> Some (attribute name value))
            attrs
        in
        keyed key "link" (attribute "rel" rel :: attribute "href" href :: extra)
  in
  React.list (List.filter_map Fun.id [ title; description ] @ List.map entry metadata.entries)

let ssr_marker =
  React.createElementWithKey ~key:"router:ssr" "div"
    [ React.JSX.String ("id", "id", "ssr-query-param"); React.JSX.Style [ ("display", "display", "none") ] ]
    []

let committed ~canonical_url ~revision ~matches ~layouts : RouterRuntime.Navigation.committed =
  let pathname, search = Path.splitLocation canonical_url in
  { location = { RouterRuntime.Navigation.pathname; search; hash = ""; key = "server" }; revision; matches; layouts }

let scoped_element ~committed resolved =
  RouterReact.locationScope ~committed
    ~children:
      (RouterReact.errorBoundary
         ~fallback:(React.createElement "p" [] [ React.string internalErrorText ])
         ~children:(Plan.resolvedElement resolved) ())
    ()

let document_element server ?pageCacheCapacity ~document (response : (React.element, 'error) ServerEngine.full) =
  let initial =
    committed ~canonical_url:response.canonical_url ~revision:response.revision ~matches:response.matches
      ~layouts:response.layouts
  in
  let head = metadataElement response.resolved.metadata in
  let root =
    match
      Server.clientRoot ?pageCacheCapacity server ~initial ~metadata:head
        ~children:(scoped_element ~committed:initial response.resolved)
    with
    | React.Client_component component -> React.Client_component { component with key = Some "router:root" }
    | root -> root
  in
  document ~head (React.list [ ssr_marker; root ])

let full_model (response : (React.element, 'error) ServerEngine.full) =
  let full : React.element RouterRuntime.NavigationResponse.full =
    {
      protocolVersion = response.protocol_version;
      registryFingerprint = response.registry_fingerprint;
      canonicalUrl = response.canonical_url;
      status = RouterRuntime.Status.toInt response.resolved.status;
      matches = response.matches;
      layouts = response.layouts;
      targetRevision = response.revision;
      metadata = metadataElement response.resolved.metadata;
      payload =
        scoped_element
          ~committed:
            (committed ~canonical_url:response.canonical_url ~revision:response.revision ~matches:response.matches
               ~layouts:response.layouts)
          response.resolved;
    }
  in
  RouterRuntime.NavigationResponse.full_to_rsc RSC.Primitives.react_element_to_rsc full |> RSC.to_model

let patch_model (response : (React.element, 'error) ServerEngine.patch) =
  let patch : React.element RouterRuntime.NavigationResponse.patch =
    {
      protocolVersion = response.protocol_version;
      registryFingerprint = response.registry_fingerprint;
      baseRevision = response.base_revision;
      targetRevision = response.revision;
      replaceFrom = response.replace_from;
      canonicalUrl = response.canonical_url;
      status = RouterRuntime.Status.toInt response.resolved.status;
      matches = response.matches;
      layouts = response.layouts;
      metadata = metadataElement response.resolved.metadata;
      payload =
        scoped_element
          ~committed:
            (committed ~canonical_url:response.canonical_url ~revision:response.revision ~matches:response.matches
               ~layouts:response.layouts)
          response.resolved;
    }
  in
  RouterRuntime.NavigationResponse.patch_to_rsc RSC.Primitives.react_element_to_rsc patch |> RSC.to_model

let redirect_model ~protocolVersion ~registryFingerprint destination =
  let redirect : RouterRuntime.NavigationResponse.redirect =
    { protocolVersion; registryFingerprint; location = RouterRuntime.href destination; status = 200 }
  in
  RouterRuntime.NavigationResponse.redirect_to_rsc redirect |> RSC.to_model

type request = { engine : ServerEngine.request; prefetch : RouterRuntime.PrefetchLevel.t option }
type body = Empty | Html of React.element | Model of { location : string; model : React.model_value }
type reply = { status : int; headers : (string * string) list; body : body }

let methodReply ~allow method_ =
  let headers = [ ("Allow", String.concat ", " allow) ] in
  if String.equal method_ "OPTIONS" then Some { status = 204; headers; body = Empty }
  else if List.exists (String.equal method_) allow then None
  else Some { status = 405; headers; body = Empty }

let prefetch_refused_reply level =
  {
    status = 204;
    headers =
      [
        ("Vary", "Accept, Router-Prefetch");
        ("Router-Prefetch-Refused", RouterRuntime.PrefetchLevel.toString level);
        ("Cache-Control", "private, no-store");
      ];
    body = Empty;
  }

type formAction = Completed | Redirected of RouterRuntime.destination | Failed of exn

let runFormAction ~lookup formData =
  match ReactServerDOM.decodeAction formData with
  | None -> Lwt.return_none
  | Some (actionId, userFormData) -> (
      match lookup actionId with
      | None -> Lwt.return_none
      | Some handler ->
          Lwt.catch
            (fun () ->
              let model =
                match handler with
                | ReactServerDOM.FormData handler -> handler [||] userFormData
                | ReactServerDOM.Body handler -> handler [||]
              in
              Lwt.map (fun _ -> Some Completed) model)
            (function
              | Signal (Redirect destination | PermanentRedirect destination)
                when Option.is_none (redirectLocation destination) ->
                  Lwt.return_some (Failed (unsafeRedirect destination))
              | Signal (Redirect destination | PermanentRedirect destination) ->
                  Lwt.return_some (Redirected destination)
              | exception_ when fatalException exception_ -> Lwt.fail exception_
              | exception_ -> Lwt.return_some (Failed exception_)))

let actionRedirectHeader destination =
  Option.map (fun location -> ("Router-Redirect", location)) (redirectLocation destination)

let see_other location = { status = 303; headers = [ ("Location", location) ]; body = Empty }
let unsafe_redirect_reply = { status = 500; headers = [ ("Vary", "Accept") ]; body = Empty }

let reply server ~target ?pageCacheCapacity ~document ~kind outcome =
  let protocolVersion = Server.protocolVersion server in
  let registryFingerprint = Server.fingerprint server in
  let redirect ~status destination =
    match ((kind : ServerEngine.requestKind), redirectLocation destination) with
    | _, None -> unsafe_redirect_reply
    | Document, Some location -> { status; headers = [ ("Vary", "Accept"); ("Location", location) ]; body = Empty }
    | Rsc, Some _ ->
        {
          status = 200;
          headers =
            [
              ("Content-Type", "application/react.component");
              ("Cache-Control", "private, no-store");
              ("Vary", "Accept, Router-Prefetch");
              ("Router-Response", "redirect");
              ("Router-Registry", string_of_int protocolVersion ^ "." ^ registryFingerprint);
            ];
          body = Model { location = target; model = redirect_model ~protocolVersion ~registryFingerprint destination };
        }
  in
  match (outcome : (React.element, 'error) ServerEngine.outcome) with
  | Redirect destination -> redirect ~status:303 destination
  | PermanentRedirect destination -> redirect ~status:308 destination
  | PrefetchRefused level -> prefetch_refused_reply level
  | ReloadRequired ->
      {
        status = 409;
        headers =
          [
            ("Vary", "Accept, Router-Prefetch");
            ("Router-Response", "reload-required");
            ("Cache-Control", "private, no-store");
          ];
        body = Empty;
      }
  | Patch response ->
      {
        status = RouterRuntime.Status.toInt response.resolved.status;
        headers = RouterRuntime.Headers.toList response.resolved.headers;
        body = Model { location = response.canonical_url; model = patch_model response };
      }
  | Full response ->
      let status = RouterRuntime.Status.toInt response.resolved.status in
      let headers = RouterRuntime.Headers.toList response.resolved.headers in
      let body =
        match response.kind with
        | Document -> Html (document_element server ?pageCacheCapacity ~document response)
        | Rsc -> Model { location = response.canonical_url; model = full_model response }
      in
      { status; headers; body }

let form_failure_reply server ~diagnosticId ?revision ~target ?pageCacheCapacity ~document ~context
    (request : ServerEngine.request) actionError =
  Lwt.map
    (fun (outcome : (React.element, 'error) ServerEngine.outcome) ->
      match outcome with
      | Redirect destination | PermanentRedirect destination -> (
          match redirectLocation destination with Some location -> see_other location | None -> unsafe_redirect_reply)
      | outcome -> reply server ~target ?pageCacheCapacity ~document ~kind:Document outcome)
    (Server.run server ~diagnosticId ?revision ~actionError ~context
       { request with kind = Document; navigation = None })

let form_action_reply server ~diagnosticId ?revision ~target ?pageCacheCapacity ~document ~context
    (request : ServerEngine.request) action =
  match action with
  | Completed ->
      Lwt.return
        (match redirectLocation (RouterRuntime.destination ~path:target) with
        | Some location -> see_other location
        | None -> unsafe_redirect_reply)
  | Redirected destination ->
      Lwt.return
        (match redirectLocation destination with Some location -> see_other location | None -> unsafe_redirect_reply)
  | Failed exception_ ->
      form_failure_reply server ~diagnosticId ?revision ~target ?pageCacheCapacity ~document ~context request
        (RouterRuntime.Error.Internal { diagnosticId = diagnosticId exception_ })

let formActionReply server ~diagnosticId ?revision ~target ?pageCacheCapacity ~document ~context (request : request)
    action =
  requestScope (fun () ->
      form_action_reply server ~diagnosticId ?revision ~target ?pageCacheCapacity ~document ~context request.engine
        action)

let header headers name =
  List.find_map
    (fun (key, value) -> if String.equal (String.lowercase_ascii key) name then Some value else None)
    headers

let parseRequest ~target ~headers =
  let target = match String.index_opt target '#' with Some index -> String.sub target 0 index | None -> target in
  let pathname, search = Path.splitLocation target in
  let search = if String.equal search "?" then "" else search in
  match header headers "accept" with
  | Some "application/react.component" ->
      {
        engine =
          {
            pathname;
            search;
            hash = "";
            kind = Rsc;
            navigation =
              Some
                {
                  from = header headers "router-navigation-from";
                  registry = header headers "router-registry";
                  base_revision = header headers "router-base-revision";
                };
          };
        prefetch = Option.bind (header headers "router-prefetch") RouterRuntime.PrefetchLevel.fromString;
      }
  | Some _ | None -> { engine = { pathname; search; hash = ""; kind = Document; navigation = None }; prefetch = None }

let defaultAllow = [ "GET"; "HEAD"; "OPTIONS" ]

let handle server ~diagnosticId ?revision ?pageCacheCapacity ~document ?(allow = defaultAllow) ~context ~method_ ~target
    ~headers () =
  match methodReply ~allow method_ with
  | Some reply -> Lwt.return reply
  | None ->
      let { engine; prefetch } = parseRequest ~target ~headers in
      requestScope @@ fun () ->
      Lwt.map
        (fun outcome ->
          let reply = reply server ~target ?pageCacheCapacity ~document ~kind:engine.kind outcome in
          if String.equal method_ "HEAD" then { reply with body = Empty } else reply)
        (Server.run server ~diagnosticId ?revision ?prefetch ~context engine)

type response = { status : int; headers : (string * string) list; body : ((string -> unit Lwt.t) -> unit Lwt.t) option }

let set_header name value headers =
  let lower = String.lowercase_ascii name in
  List.filter (fun (key, _) -> not (String.equal (String.lowercase_ascii key) lower)) headers @ [ (name, value) ]

let response ?env ?timeout ?(skipRoot = false) ?bootstrapModules ?nonce (reply : reply) =
  match reply.body with
  | Empty -> { status = reply.status; headers = reply.headers; body = None }
  | Html element ->
      {
        status = reply.status;
        headers = set_header "Content-Type" "text/html; charset=utf-8" reply.headers;
        body =
          Some
            (fun write ->
              Lwt.bind (ReactServerDOM.render_html ?env ?timeout ~skipRoot ?bootstrapModules ?nonce element)
                (fun (html, rest) -> Lwt.bind (write html) (fun () -> rest write)));
      }
  | Model { location; model } ->
      {
        status = reply.status;
        headers =
          reply.headers
          |> set_header "Content-Type" "application/react.component"
          |> set_header "X-Content-Type-Options" "nosniff"
          |> set_header "X-Location" location;
        body = Some (fun write -> ReactServerDOM.render_model_value ?env ?timeout ~subscribe:write model);
      }

type shell = Committed of response | Signaled of signal | ShellFailed of exn

let render_html_shell ?env ?timeout ?skipRoot ?bootstrapModules ?nonce (reply : reply) element =
  let abort, stop = Lwt.wait () in
  Lwt.map
    (fun (result, recorded) ->
      match (!recorded, result) with
      | Some signal, _ ->
          Lwt.wakeup_later stop ();
          Signaled signal
      | None, Error exn -> ShellFailed exn
      | None, Ok (html, rest) ->
          let committed = response ?env ?timeout ?skipRoot ?bootstrapModules ?nonce reply in
          Committed { committed with body = Some (fun write -> Lwt.bind (write html) (fun () -> rest write)) })
    (Lwt.catch
       (fun () ->
         recording (fun () ->
             ReactServerDOM.render_html ?env ?timeout ?skipRoot ?bootstrapModules ?nonce ~abort element))
       (fun exn -> if fatalException exn then Lwt.fail exn else Lwt.return (Error exn, ref None)))

let render_model_shell ?env ?timeout (reply : reply) model =
  let abort, stop = Lwt.wait () in
  let first, produced = Lwt.wait () in
  let gate, release = Lwt.wait () in
  let buffered = Queue.create () in
  let sink = ref None in
  let subscribe chunk =
    match !sink with
    | Some write -> write chunk
    | None ->
        Queue.push chunk buffered;
        if Lwt.is_sleeping first then Lwt.wakeup_later produced ();
        gate
  in
  let rendering = ref (Lwt.return ()) in
  Lwt.map
    (fun (result, recorded) ->
      match (!recorded, result) with
      | Some signal, _ ->
          sink := Some (fun _ -> Lwt.return ());
          Lwt.wakeup_later release ();
          Lwt.wakeup_later stop ();
          Signaled signal
      | None, Error exn -> raise exn
      | None, Ok () ->
          let committed = response ?env ?timeout reply in
          let body write =
            let rec drain () =
              match Queue.take_opt buffered with
              | Some chunk -> Lwt.bind (write chunk) drain
              | None ->
                  sink := Some write;
                  Lwt.wakeup_later release ();
                  !rendering
            in
            drain ()
          in
          Committed { committed with body = Some body })
    (recording (fun () ->
         rendering := ReactServerDOM.render_model_value ?env ?timeout ~abort ~subscribe model;
         Lwt.choose [ first; Lwt.map ignore !rendering ]))

let render_shell ?env ?timeout ?skipRoot ?bootstrapModules ?nonce (reply : reply) =
  match reply.body with
  | Empty -> Lwt.return (Committed (response reply))
  | Html element -> render_html_shell ?env ?timeout ?skipRoot ?bootstrapModules ?nonce reply element
  | Model { model; _ } -> render_model_shell ?env ?timeout reply model

let render_with_signals ?env ?timeout ?skipRoot ?bootstrapModules ?nonce ~diagnosticId ~rerun ~redirect first =
  let render reply = render_shell ?env ?timeout ?skipRoot ?bootstrapModules ?nonce reply in
  let commit = function
    | Committed response -> Lwt.return response
    | Signaled _ -> Lwt.return (response { status = 500; headers = [ ("Vary", "Accept") ]; body = Empty })
    | ShellFailed exn -> Lwt.fail exn
  in
  Lwt.map
    (fun (response : response) -> { response with body = Option.map reentering response.body })
    (Lwt.bind (Lwt.bind first render) (function
      | Committed response -> Lwt.return response
      | Signaled NotFound ->
          Lwt.bind
            (rerun (RouterRuntime.Error.NotFound { reason = RouterRuntime.Error.RenderNotFound }))
            (fun reply -> Lwt.bind (render reply) commit)
      | Signaled (Redirect destination) -> Lwt.bind (render (redirect ~permanent:false destination)) commit
      | Signaled (PermanentRedirect destination) -> Lwt.bind (render (redirect ~permanent:true destination)) commit
      | ShellFailed exn ->
          Lwt.bind
            (rerun (RouterRuntime.Error.Internal { diagnosticId = diagnosticId exn }))
            (fun reply -> Lwt.bind (render reply) commit)))

let serve server ~diagnosticId ?revision ?pageCacheCapacity ~document ?(allow = defaultAllow) ?env ?timeout ?skipRoot
    ?bootstrapModules ?nonce ~context ~method_ ~target ~headers () =
  match methodReply ~allow method_ with
  | Some reply -> Lwt.return (response reply)
  | None when String.equal method_ "HEAD" ->
      Lwt.map response
        (handle server ~diagnosticId ?revision ?pageCacheCapacity ~document ~allow ~context ~method_ ~target ~headers ())
  | None ->
      let { engine; prefetch } = parseRequest ~target ~headers in
      requestScope @@ fun () ->
      let reply_to outcome = reply server ~target ?pageCacheCapacity ~document ~kind:engine.kind outcome in
      let run ?actionError () =
        Lwt.map reply_to (Server.run server ~diagnosticId ?revision ?prefetch ?actionError ~context engine)
      in
      render_with_signals ?env ?timeout ?skipRoot ?bootstrapModules ?nonce ~diagnosticId
        ~rerun:(fun actionError -> run ~actionError ())
        ~redirect:(fun ~permanent destination ->
          reply_to (if permanent then ServerEngine.PermanentRedirect destination else ServerEngine.Redirect destination))
        (run ())

let serveFormAction server ~diagnosticId ?revision ~target ?pageCacheCapacity ~document ?env ?timeout ?skipRoot
    ?bootstrapModules ?nonce ~context (request : request) action =
  let request = request.engine in
  requestScope @@ fun () ->
  render_with_signals ?env ?timeout ?skipRoot ?bootstrapModules ?nonce ~diagnosticId
    ~rerun:(form_failure_reply server ~diagnosticId ?revision ~target ?pageCacheCapacity ~document ~context request)
    ~redirect:(fun ~permanent:_ destination ->
      match redirectLocation destination with Some location -> see_other location | None -> unsafe_redirect_reply)
    (form_action_reply server ~diagnosticId ?revision ~target ?pageCacheCapacity ~document ~context request action)

let run server ~diagnosticId ?revision ?actionError ~context (request : request) =
  Server.run server ~diagnosticId ?revision ?prefetch:request.prefetch ?actionError ~context request.engine

type ('view, 'error, 'context) t = ('view, 'error, 'context) Server.t
type ('view, 'error) outcome = ('view, 'error) ServerEngine.outcome

let basePath = Server.basePath
let clientRoot = Server.clientRoot
let clientRootWith = Server.clientRootWith
let statusOfError = statusOfError
let redirectLocation = redirectLocation
