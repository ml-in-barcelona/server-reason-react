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

let request () = Lwt.get RequestContext.request_key
let get_header = RequestContext.get_header
let get_cookie = RequestContext.get_cookie
let set_cookie = RequestContext.set_cookie

let with_render_context request =
 fun fn ->
  Lwt.with_value RequestContext.request_key (Some request) (fun () ->
      Lwt.with_value RequestContext.phase_key (Some RequestContext.Render) (fun () -> RouterServer.requestScope fn))

let with_action_context request =
 fun fn ->
  let pending = ref [] in
  let run () =
    Lwt.with_value RequestContext.request_key (Some request) (fun () ->
        Lwt.with_value RequestContext.phase_key (Some (RequestContext.Action pending)) (fun () ->
            RouterServer.requestScope fn))
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

let streamFunctionResponse ?(debug = false) ?(timeout = stream_timeout) ~lookup request =
  let started_at = Mtime_clock.counter () in
  let pending, run = with_action_context request (fun () -> handleRequest ~lookup request) in
  let action =
    Lwt.catch
      (fun () ->
        let%lwt result = run () in
        let cookies = serialize_pending_cookies !pending in
        Lwt.return (`Settled (Lwt.return result, cookies)))
      (function
        | RouterServer.Signal (Redirect destination | PermanentRedirect destination) as exn -> (
            match RouterServer.actionRedirectHeader destination with
            | Some header ->
                let cookies = serialize_pending_cookies !pending in
                Lwt.return (`Settled (Lwt.return (React.Model.Element React.null), header :: cookies))
            | None ->
                pending := [];
                Lwt.return (`Settled (Lwt.fail exn, [])))
        | exn ->
            pending := [];
            Lwt.return (`Settled (Lwt.fail exn, [])))
  in
  let deadline =
    let%lwt () = Lwt_unix.sleep timeout in
    Lwt.return `Timed_out
  in
  let%lwt outcome = Lwt.choose [ action; deadline ] in
  let action_promise, cookie_headers =
    match outcome with
    | `Settled result ->
        Lwt.cancel deadline;
        result
    | `Timed_out ->
        Lwt.cancel action;
        pending := [];
        let pending_response, _resolve_response = Lwt.wait () in
        (pending_response, [])
  in
  Dream.stream ~headers:(("Content-Type", "application/react.action") :: cookie_headers) (fun stream ->
      let elapsed = Mtime_clock.count started_at |> Mtime.Span.to_uint64_ns |> Int64.to_float in
      let remaining_timeout = max 0. (timeout -. (elapsed /. 1_000_000_000.)) in
      let%lwt () =
        ReactServerDOM.create_action_response ~env:`Dev ~debug ~timeout:remaining_timeout
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

let write_response (response : RouterServer.response) =
  let code = response.status and headers = response.headers in
  match response.body with
  | None -> Dream.respond ~code ~headers ""
  | Some body ->
      Dream.stream ~code ~headers (fun stream ->
          let%lwt () =
            body (fun chunk ->
                let%lwt () = Dream.write stream chunk in
                Dream.flush stream)
          in
          Dream.flush stream)

let allow = [ "GET"; "HEAD"; "OPTIONS"; "POST" ]

let handler ~server ~context ~diagnosticId ~revision ?(ssr = fun _request -> true) ?(bootstrapModules = [])
    ?pageCacheCapacity ~document =
 fun request ->
  with_render_context request (fun () ->
      let%lwt response =
        RouterServer.serve server ~diagnosticId ~revision ?pageCacheCapacity ~document ~allow ~env:`Dev
          ~timeout:stream_timeout
          ~skipRoot:(not (ssr request))
          ~bootstrapModules
          ~context:(fun () -> context request)
          ~method_:(Dream.method_to_string (Dream.method_ request))
          ~target:(Dream.target request) ~headers:(Dream.all_headers request) ()
      in
      write_response response)

let is_form_post request =
  Option.is_none (Dream.header request "ACTION_ID")
  &&
  match Dream.header request "Content-Type" with
  | Some content_type -> String.starts_with content_type ~prefix:"multipart/form-data"
  | None -> false

let form_handler ~server ~context ~lookup ~diagnosticId ~revision ~ssr ~bootstrapModules ?pageCacheCapacity ~document
    ~actionHandler =
 fun request ->
  if not (is_form_post request) then actionHandler request
  else
    let%lwt body = Dream.body request in
    Dream.set_body request body;
    let pass_on () =
      Dream.set_body request body;
      actionHandler request
    in
    match%lwt Dream.multipart request ~csrf:false with
    | `Ok formData when not (List.exists (fun (name, _) -> String.starts_with ~prefix:"$ACTION_ID_" name) formData) ->
        pass_on ()
    | `Ok formData -> (
        let pending, run =
          with_action_context request (fun () -> RouterServer.runFormAction ~lookup (dreamFormDataToJs formData))
        in
        match%lwt run () with
        | None -> Dream.empty `Bad_Request
        | Some action ->
            let cookies =
              match action with
              | RouterServer.Failed _ -> []
              | Completed | Redirected _ -> serialize_pending_cookies !pending
            in
            with_render_context request (fun () ->
                let%lwt response =
                  RouterServer.serveFormAction server ~diagnosticId ~revision ~target:(Dream.target request)
                    ?pageCacheCapacity ~document ~env:`Dev ~timeout:stream_timeout
                    ~skipRoot:(not (ssr request))
                    ~bootstrapModules ~context:(context request)
                    (RouterServer.parseRequest ~target:(Dream.target request) ~headers:(Dream.all_headers request))
                    action
                in
                write_response { response with headers = response.headers @ cookies }))
    | _ -> pass_on ()

let random_id () = Dream.to_base64url (Dream.random 12)

let routes ~server ~context ~actionHandler ?lookup ?(diagnosticId = fun _ -> random_id ()) ?(revision = random_id)
    ?(ssr = fun _request -> true) ?(bootstrapModules = []) ?pageCacheCapacity ~document () =
  let basePath = RouterServer.basePath server |> Dream.from_percent_encoded in
  let handler = handler ~server ~context ~diagnosticId ~revision ~ssr ~bootstrapModules ?pageCacheCapacity ~document in
  let wildcard = if String.equal basePath "/" then "/**" else basePath ^ "/**" in
  let actionHandler =
    match lookup with
    | None -> actionHandler
    | Some lookup ->
        form_handler ~server ~context ~lookup ~diagnosticId ~revision ~ssr ~bootstrapModules ?pageCacheCapacity
          ~document ~actionHandler
  in
  let actionHandler = Dream.origin_referrer_check actionHandler in
  [
    Dream.post basePath actionHandler;
    Dream.post wildcard actionHandler;
    Dream.any basePath handler;
    Dream.any wildcard handler;
  ]
