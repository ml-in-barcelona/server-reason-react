module RequestContext = struct
  type pending_cookie = {
    name : string;
    value : string;
    expires : float option;
    max_age : float option;
    domain : string option;
    path : string option;
    secure : bool option;
    http_only : bool option;
    same_site : [ `Strict | `Lax | `None ] option;
  }

  type phase = Render | Action of pending_cookie list ref

  let request_key : Dream.request Lwt.key = Lwt.new_key ()
  let phase_key : phase Lwt.key = Lwt.new_key ()

  let get_request () =
    match Lwt.get request_key with
    | Some request -> request
    | None ->
        failwith
          ("RequestContext.get_request: no request context. "
         ^ "This function must be called inside a server component or server function.")

  let get_header name = Dream.header (get_request ()) name
  let get_cookie ?(decrypt = false) = fun name -> Dream.cookie ~decrypt (get_request ()) name

  let set_cookie ?expires ?max_age ?domain ?path ?secure ?http_only ?same_site name value =
    match Lwt.get phase_key with
    | Some (Action pending) ->
        pending := { name; value; expires; max_age; domain; path; secure; http_only; same_site } :: !pending
    | Some Render ->
        failwith
          "RequestContext.set_cookie: cookies can only be modified in a server function (action), not during render."
    | None ->
        failwith
          ("RequestContext.set_cookie: no request context. " ^ "This function must be called inside a server function.")
end

let get_header = RequestContext.get_header
let get_cookie = RequestContext.get_cookie
let set_cookie = RequestContext.set_cookie

let with_render_context request =
 fun fn ->
  Lwt.with_value RequestContext.request_key (Some request) (fun () ->
      Lwt.with_value RequestContext.phase_key (Some RequestContext.Render) fn)

let with_action_context request =
 fun fn ->
  let pending = ref [] in
  let run () =
    Lwt.with_value RequestContext.request_key (Some request) (fun () ->
        Lwt.with_value RequestContext.phase_key (Some (RequestContext.Action pending)) fn)
  in
  (pending, run)

let serialize_pending_cookies pending =
  pending |> List.rev
  |> List.map (fun (cookie : RequestContext.pending_cookie) ->
      let header_value =
        Dream.to_set_cookie ?expires:cookie.expires ?max_age:cookie.max_age ?domain:cookie.domain ?path:cookie.path
          ?secure:cookie.secure ?http_only:cookie.http_only ?same_site:cookie.same_site cookie.name cookie.value
      in
      ("Set-Cookie", header_value))

let require_action_id actionId =
  match actionId with
  | Some id -> Ok id
  | None -> Error "Missing ACTION_ID header, this request was not created by server-reason-react"

let dispatch_handler ~lookup actionId dispatch =
  match require_action_id actionId with
  | Error msg -> Lwt.fail_with msg
  | Ok actionId -> (
      match lookup actionId with
      | None -> Lwt.fail_with ("Action " ^ actionId ^ " is not registered")
      | Some handler -> dispatch actionId handler)

let dreamFormDataToJs formData =
  let formDataJs = Js.FormData.make () in
  formData
  |> List.iter (fun (name, value) ->
      let _filename, value = value |> List.hd in
      Js.FormData.append formDataJs name (`String value));
  formDataJs

let handleFormRequest ~lookup actionId formData =
  let formDataJs = dreamFormDataToJs formData in
  match ReactServerDOM.decodeFormDataReply formDataJs with
  | Error msg -> Lwt.fail_with msg
  | Ok (args, formData) ->
      dispatch_handler ~lookup actionId (fun actionId handler ->
          match handler with
          | ReactServerDOM.FormData handler -> handler args formData
          | ReactServerDOM.Body _ ->
              Lwt.fail_with ("Action " ^ actionId ^ " is registered as Body handler but received FormData request"))

let handleRequestBody ~lookup request actionId =
  let%lwt body = Dream.body request in
  match ReactServerDOM.decodeReply body with
  | Error msg -> Lwt.fail_with msg
  | Ok args ->
      dispatch_handler ~lookup actionId (fun actionId handler ->
          match handler with
          | ReactServerDOM.Body handler -> handler args
          | ReactServerDOM.FormData _ ->
              Lwt.fail_with ("Action " ^ actionId ^ " is registered as FormData handler but received JSON body request"))

let handleNoJsFormRequest ~lookup formDataJs =
  match ReactServerDOM.decodeAction formDataJs with
  | Some (actionId, userFormData) -> (
      match lookup actionId with
      | None -> Lwt.fail_with ("Action " ^ actionId ^ " is not registered")
      | Some handler -> (
          match handler with
          | ReactServerDOM.FormData handler -> handler [||] userFormData
          | ReactServerDOM.Body handler -> handler [||]))
  | None -> Lwt.fail_with "No ACTION_ID header and no $ACTION_* keys in FormData"

(* Dream has no request-disconnect promise: a failed write is the only disconnect signal and cannot fire while the
   renderer waits on a hung resource, so the timeout is the reliable backstop for RSC responses. *)
let stream_timeout = 30.0

let write_chunk ~debug ~label stream chunk =
  if debug then (
    Dream.log "%s" label;
    Dream.log "%s" chunk);
  let%lwt () = Dream.write stream chunk in
  Dream.flush stream

let handleRequest ~lookup request =
  let actionId = Dream.header request "ACTION_ID" in
  let contentType = Dream.header request "Content-Type" in
  match contentType with
  | Some contentType when String.starts_with contentType ~prefix:"multipart/form-data" -> (
      let%lwt multipart = Dream.multipart request ~csrf:false in
      match multipart with
      | `Ok formData -> (
          match actionId with
          | Some _ -> handleFormRequest ~lookup actionId formData
          | None -> handleNoJsFormRequest ~lookup (dreamFormDataToJs formData))
      | _ -> Lwt.fail_with "Missing form data, this request was not created by server-reason-react")
  | _ -> handleRequestBody ~lookup request actionId

let streamFunctionResponse ?(debug = false) ~lookup request =
  let pending, run = with_action_context request (fun () -> handleRequest ~lookup request) in
  let%lwt action_promise, cookie_headers =
    Lwt.catch
      (fun () ->
        let%lwt result = run () in
        let cookies = serialize_pending_cookies !pending in
        Lwt.return (Lwt.return result, cookies))
      (fun exn ->
        pending := [];
        Lwt.return (Lwt.fail exn, []))
  in
  Dream.stream ~headers:(("Content-Type", "application/react.action") :: cookie_headers) (fun stream ->
      let%lwt () =
        ReactServerDOM.create_action_response ~env:`Dev ~debug ~timeout:stream_timeout
          ~subscribe:(write_chunk ~debug ~label:"Action response" stream)
          action_promise
      in
      Dream.flush stream)

let is_react_component_header value = String.equal value "application/react.component"

let stream_model_value ?(debug = false) ?(code = 200) ?(headers = []) ~location app =
  let%lwt response =
    Dream.stream ~code ~headers (fun stream ->
        let%lwt () =
          ReactServerDOM.render_model_value ~env:`Dev ~debug ~timeout:stream_timeout
            ~subscribe:(write_chunk ~debug ~label:"Chunk" stream)
            app
        in
        Dream.flush stream)
  in
  Dream.set_header response "Content-Type" "application/react.component";
  Dream.set_header response "X-Content-Type-Options" "nosniff";
  Dream.set_header response "X-Location" location;
  Lwt.return response

let stream_model ?(debug = false) ?(code = 200) ?(headers = []) ~location app =
  stream_model_value ~debug ~code ~headers ~location (React.Model.Element app)

let stream_html ?(debug = false) ?(code = 200) ?(headers = []) ?(skipRoot = false) ?bootstrapScriptContent
    ?(bootstrapScripts = []) ?(bootstrapModules = []) app =
  let%lwt response =
    Dream.stream ~code ~headers (fun stream ->
        let%lwt html, subscribe =
          ReactServerDOM.render_html ~env:`Dev ~skipRoot ?bootstrapScriptContent ~bootstrapScripts ~bootstrapModules
            ~debug app
        in
        let%lwt () = Dream.write stream html in
        let%lwt () = Dream.flush stream in
        let%lwt () = subscribe (write_chunk ~debug ~label:"Chunk" stream) in
        Dream.flush stream)
  in
  Dream.set_header response "Content-Type" Dream.text_html;
  Lwt.return response

let createFromRequest ?(debug = false) ?(disableSSR = false) ?(layout = fun children -> children)
    ?(bootstrapModules = []) ?(bootstrapScripts = []) ?(bootstrapScriptContent = "") element request =
  with_render_context request (fun () ->
      match Dream.header request "Accept" with
      | Some accept when is_react_component_header accept ->
          stream_model ~debug ~location:(Dream.target request) element
      | _ ->
          stream_html ~debug ~skipRoot:disableSSR ~bootstrapScriptContent ~bootstrapScripts ~bootstrapModules
            (layout element))

let metadata_element metadata =
  let open RouterRuntime.Metadata in
  let title =
    Option.map
      (fun title -> React.createElementWithKey ~key:"router:title" "title" [] [ React.string title ])
      metadata.title
  in
  let description =
    Option.map
      (fun content ->
        React.createElementWithKey ~key:"router:description" "meta"
          [ React.JSX.String ("name", "name", "description"); React.JSX.String ("content", "content", content) ]
          [])
      metadata.description
  in
  let entries =
    List.map
      (fun entry ->
        React.createElementWithKey ~key:("router:" ^ entry.key) "meta"
          [ React.JSX.String ("name", "name", entry.name); React.JSX.String ("content", "content", entry.content) ]
          [])
      metadata.entries
  in
  React.list (List.filter_map Fun.id [ title; description ] @ entries)

let resolved_element (resolved : (React.element, 'error) RouterServer.Plan.resolved) =
  Option.value ~default:React.null resolved.element

(* The marker lets the bootstrap module detect from the DOM whether the server rendered the root markup: it sits next
   to the routed root, so [skipRoot] drops it together with the markup it signals. *)
let ssr_marker =
  React.createElementWithKey ~key:"router:ssr" "div"
    [ React.JSX.String ("id", "id", "ssr-query-param"); React.JSX.Style [ ("display", "display", "none") ] ]
    []

let document_element ~router ~document (response : (React.element, 'error) RouterServer.ServerEngine.full) =
  let pathname, query = Dream.split_target response.canonical_url in
  let search = if String.equal query "" then "" else "?" ^ query in
  let initial : RouterRuntime.Navigation.committed =
    {
      location = { RouterRuntime.Navigation.pathname; search; hash = ""; key = "server" };
      revision = response.revision;
      matches = response.matches;
      layouts = response.layouts;
    }
  in
  let children =
    RouterServer.Server.clientRoot router ~initial
      ~metadata:(metadata_element response.resolved.metadata)
      ~children:(resolved_element response.resolved)
  in
  document (React.list [ ssr_marker; children ])

let full_model (response : (React.element, 'error) RouterServer.ServerEngine.full) =
  let full : React.element RouterRuntime.NavigationResponse.full =
    {
      protocolVersion = response.protocol_version;
      registryFingerprint = response.registry_fingerprint;
      canonicalUrl = response.canonical_url;
      status = RouterRuntime.Status.toInt response.resolved.status;
      matches = response.matches;
      layouts = response.layouts;
      targetRevision = response.revision;
      metadata = metadata_element response.resolved.metadata;
      payload = resolved_element response.resolved;
    }
  in
  RouterRuntime.NavigationResponse.full_to_rsc RSC.Primitives.react_element_to_rsc full |> RSC.to_model

let patch_model (response : (React.element, 'error) RouterServer.ServerEngine.patch) =
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
      metadata = metadata_element response.resolved.metadata;
      payload = resolved_element response.resolved;
    }
  in
  RouterRuntime.NavigationResponse.patch_to_rsc RSC.Primitives.react_element_to_rsc patch |> RSC.to_model

let redirect_model ~protocolVersion ~registryFingerprint destination =
  let redirect : RouterRuntime.NavigationResponse.redirect =
    { protocolVersion; registryFingerprint; location = RouterRuntime.href destination; status = 200 }
  in
  RouterRuntime.NavigationResponse.redirect_to_rsc redirect |> RSC.to_model

let handler ~router ~diagnosticId ~revision ?(ssr = fun _request -> true) ?(bootstrapModules = []) ~document =
  let protocolVersion = RouterServer.Server.protocolVersion router in
  let registryFingerprint = RouterServer.Server.fingerprint router in
  fun request ->
    with_render_context request (fun () ->
        let pathname, query = Dream.target request |> Dream.split_target in
        let search = if String.equal query "" then "" else "?" ^ query in
        let kind =
          match Dream.header request "Accept" with
          | Some accept when is_react_component_header accept -> RouterServer.ServerEngine.Rsc
          | Some _ | None -> RouterServer.ServerEngine.Document
        in
        let navigation =
          match kind with
          | RouterServer.ServerEngine.Document -> None
          | RouterServer.ServerEngine.Rsc ->
              Some
                {
                  RouterServer.ServerEngine.from = Dream.header request "Router-Navigation-From";
                  registry = Dream.header request "Router-Registry";
                  base_revision = Dream.header request "Router-Base-Revision";
                }
        in
        let outcome =
          RouterServer.Server.run router ~diagnosticId ~revision
            { RouterServer.ServerEngine.pathname; search; hash = ""; kind; navigation }
        in
        let redirect ?status destination =
          match kind with
          | RouterServer.ServerEngine.Document -> Dream.redirect ?status request (RouterRuntime.href destination)
          | RouterServer.ServerEngine.Rsc ->
              stream_model_value ~code:200
                ~headers:
                  [
                    ("Content-Type", "application/react.component");
                    ("Cache-Control", "private, no-store");
                    ("Vary", "Accept");
                    ("Router-Response", "redirect");
                  ]
                ~location:(Dream.target request)
                (redirect_model ~protocolVersion ~registryFingerprint destination)
        in
        Lwt.bind outcome (function
          | RouterServer.ServerEngine.Redirect destination -> redirect destination
          | RouterServer.ServerEngine.PermanentRedirect destination -> redirect ~status:`Permanent_Redirect destination
          | RouterServer.ServerEngine.ReloadRequired ->
              Dream.respond ~code:409
                ~headers:
                  [ ("Vary", "Accept"); ("Router-Response", "reload-required"); ("Cache-Control", "private, no-store") ]
                ""
          | RouterServer.ServerEngine.Patch response ->
              let code = response.resolved.status |> RouterRuntime.Status.toInt in
              let headers = response.resolved.headers |> RouterRuntime.Headers.toList in
              stream_model_value ~code ~headers ~location:response.canonical_url (patch_model response)
          | RouterServer.ServerEngine.Full response -> (
              let code = response.resolved.status |> RouterRuntime.Status.toInt in
              let headers = response.resolved.headers |> RouterRuntime.Headers.toList in
              match response.kind with
              | RouterServer.ServerEngine.Document ->
                  stream_html ~code ~headers
                    ~skipRoot:(not (ssr request))
                    ~bootstrapModules
                    (document_element ~router ~document response)
              | RouterServer.ServerEngine.Rsc ->
                  stream_model_value ~code ~headers ~location:response.canonical_url (full_model response))))

let routes ~router ~actionHandler ?(diagnosticId = fun _ -> string_of_int (Random.bits ()))
    ?(revision = fun () -> string_of_int (Random.bits ())) ?(ssr = fun _request -> true) ?(bootstrapModules = [])
    ~document () =
  let basePath = RouterServer.Server.basePath router |> Dream.from_percent_encoded in
  let handler = handler ~router ~diagnosticId ~revision ~ssr ~bootstrapModules ~document in
  [
    Dream.get basePath handler;
    Dream.get (basePath ^ "/**") handler;
    Dream.post basePath actionHandler;
    Dream.post (basePath ^ "/**") actionHandler;
  ]
