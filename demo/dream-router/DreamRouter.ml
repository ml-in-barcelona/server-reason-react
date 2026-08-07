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

let dispatch_handler ~lookup =
 fun actionId ->
  fun dispatch ->
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

let handleFormRequest ~lookup =
 fun actionId ->
  fun formData ->
   let formDataJs = dreamFormDataToJs formData in
   match ReactServerDOM.decodeFormDataReply formDataJs with
   | Error msg -> Lwt.fail_with msg
   | Ok (args, formData) ->
       dispatch_handler ~lookup actionId (fun actionId ->
           fun handler ->
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

let handleNoJsFormRequest ~lookup =
 fun formDataJs ->
  match ReactServerDOM.decodeAction formDataJs with
  | Some (actionId, userFormData) -> (
      match lookup actionId with
      | None -> Lwt.fail_with ("Action " ^ actionId ^ " is not registered")
      | Some handler -> (
          match handler with
          | ReactServerDOM.FormData handler -> handler [||] userFormData
          | ReactServerDOM.Body handler -> handler [||]))
  | None -> Lwt.fail_with "No ACTION_ID header and no $ACTION_* keys in FormData"

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
        ReactServerDOM.create_action_response ~env:`Dev ~debug
          ~subscribe:(fun chunk ->
            if debug then (
              Dream.log "Action response";
              Dream.log "%s" chunk);
            let%lwt () = Dream.write stream chunk in
            Dream.flush stream)
          action_promise
      in
      Dream.flush stream)

let split_header delimiter value =
  let length = String.length value in
  let rec loop index start quoted escaped parts =
    if index = length then
      if quoted || escaped then None else Some (List.rev (String.sub value start (index - start) :: parts))
    else
      match (quoted, escaped, value.[index]) with
      | true, true, _ -> loop (index + 1) start true false parts
      | true, false, '\\' -> loop (index + 1) start true true parts
      | true, false, '"' -> loop (index + 1) start false false parts
      | false, false, '"' -> loop (index + 1) start true false parts
      | false, false, char when Char.equal char delimiter ->
          loop (index + 1) (index + 1) false false (String.sub value start (index - start) :: parts)
      | _ -> loop (index + 1) start quoted false parts
  in
  loop 0 0 false false []

let quality_is_acceptable value =
  let value = String.trim value in
  let length = String.length value in
  let rec suffix_is_valid index expected =
    index = length || (Char.equal value.[index] expected && suffix_is_valid (index + 1) expected)
  in
  if String.equal value "0" then Some false
  else if String.equal value "1" then Some true
  else if length >= 2 && length <= 5 && Char.equal value.[1] '.' then
    match value.[0] with
    | '0' ->
        if suffix_is_valid 2 '0' then Some false
        else
          let rec suffix_is_digits index =
            index = length
            ||
            let char = value.[index] in
            (char >= '0' && char <= '9') && suffix_is_digits (index + 1)
          in
          if suffix_is_digits 2 then Some true else None
    | '1' -> if suffix_is_valid 2 '0' then Some true else None
    | _ -> None
  else None

let range_accepts_react_component range =
  match split_header ';' range with
  | None | Some [] -> false
  | Some (media_type :: parameters) ->
      if not (String.equal (String.lowercase_ascii (String.trim media_type)) "application/react.component") then false
      else
        let rec find_quality quality = function
          | [] -> Option.value ~default:true quality
          | parameter :: rest -> (
              let parameter = String.trim parameter in
              match String.index_opt parameter '=' with
              | Some equals ->
                  let name = String.sub parameter 0 equals |> String.trim |> String.lowercase_ascii in
                  if String.equal name "q" then
                    if Option.is_some quality then false
                    else
                      let value = String.sub parameter (equals + 1) (String.length parameter - equals - 1) in
                      match quality_is_acceptable value with
                      | None -> false
                      | Some acceptable -> find_quality (Some acceptable) rest
                  else find_quality quality rest
              | None -> if String.equal (String.lowercase_ascii parameter) "q" then false else find_quality quality rest
              )
        in
        find_quality None parameters

let is_react_component_header value =
  match split_header ',' value with None -> false | Some ranges -> List.exists range_accepts_react_component ranges

let stream_model_value ?(debug = false) ?(code = 200) ?(headers = []) ~location app =
  let%lwt response =
    Dream.stream ~code ~headers (fun stream ->
        let%lwt () =
          ReactServerDOM.render_model_value ~env:`Dev ~debug
            ~subscribe:(fun chunk ->
              if debug then (
                Dream.log "Chunk";
                Dream.log "%s" chunk);
              let%lwt () = Dream.write stream chunk in
              Dream.flush stream)
            app
        in
        Dream.flush stream)
  in
  Dream.set_header response "Content-Type" "application/react.component";
  Dream.set_header response "X-Content-Type-Options" "nosniff";
  Dream.set_header response "X-Location" location;
  Lwt.return response

let stream_model ?(debug = false) =
 fun ?(code = 200) ->
  fun ?(headers = []) ->
   fun ~location -> fun app -> stream_model_value ~debug ~code ~headers ~location (React.Model.Element app)

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
        let%lwt () =
          subscribe (fun chunk ->
              if debug then (
                Dream.log "Chunk";
                Dream.log "%s" chunk);
              let%lwt () = Dream.write stream chunk in
              Dream.flush stream)
        in
        Dream.flush stream)
  in
  Dream.set_header response "Content-Type" Dream.text_html;
  Lwt.return response

let createFromRequest ?(debug = false) =
 fun ?(disableSSR = false) ->
  fun ?(layout = fun children -> children) ->
   fun ?(bootstrapModules = []) ->
    fun ?(bootstrapScripts = []) ->
     fun ?(bootstrapScriptContent = "") ->
      fun element ->
       fun request ->
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
  document children

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

let handler ~router ~diagnosticId ~revision ?(bootstrapModules = []) ~document =
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
                  RouterServer.ServerEngine.from = Dream.header request "SRR-Navigation-From";
                  registry = Dream.header request "SRR-Registry";
                  base_revision = Dream.header request "SRR-Base-Revision";
                }
        in
        let outcome =
          RouterServer.Server.run router ~diagnosticId ~revision
            { RouterServer.ServerEngine.pathname; search; hash = ""; kind; navigation }
        in
        Lwt.bind outcome (function
          | RouterServer.ServerEngine.Redirect destination -> (
              match kind with
              | RouterServer.ServerEngine.Document -> Dream.redirect request (RouterRuntime.href destination)
              | RouterServer.ServerEngine.Rsc ->
                  stream_model_value ~code:200
                    ~headers:
                      [
                        ("Content-Type", "application/react.component");
                        ("Cache-Control", "private, no-store");
                        ("Vary", "Accept");
                        ("SRR-Response", "redirect");
                      ]
                    ~location:(Dream.target request)
                    (redirect_model ~protocolVersion ~registryFingerprint destination))
          | RouterServer.ServerEngine.ReloadRequired ->
              Dream.respond ~code:409
                ~headers:
                  [ ("Vary", "Accept"); ("SRR-Response", "reload-required"); ("Cache-Control", "private, no-store") ]
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
                  stream_html ~code ~headers ~bootstrapModules (document_element ~router ~document response)
              | RouterServer.ServerEngine.Rsc ->
                  stream_model_value ~code ~headers ~location:response.canonical_url (full_model response))))

let routes ~router ~actionHandler ?(diagnosticId = fun _ -> string_of_int (Random.bits ()))
    ?(revision = fun () -> string_of_int (Random.bits ())) ?(bootstrapModules = []) ~document () =
  let basePath = RouterServer.Server.basePath router in
  let handler = handler ~router ~diagnosticId ~revision ~bootstrapModules ~document in
  [
    Dream.get basePath handler;
    Dream.get (basePath ^ "/**") handler;
    Dream.post basePath actionHandler;
    Dream.post (basePath ^ "/**") actionHandler;
  ]
