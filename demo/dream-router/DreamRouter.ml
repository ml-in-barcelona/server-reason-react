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

  let set_cookie ?expires =
   fun ?max_age ->
    fun ?domain ->
     fun ?path ->
      fun ?secure ->
       fun ?http_only ->
        fun ?same_site ->
         fun name ->
          fun value ->
           match Lwt.get phase_key with
           | Some (Action pending) ->
               pending := { name; value; expires; max_age; domain; path; secure; http_only; same_site } :: !pending
           | Some Render ->
               failwith
                 "RequestContext.set_cookie: cookies can only be modified in a server function (action), not during \
                  render."
           | None ->
               failwith
                 ("RequestContext.set_cookie: no request context. "
                ^ "This function must be called inside a server function.")
end

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

let handleRequestBody ~lookup =
 fun request ->
  fun actionId ->
   [%lwt
     let body = Dream.body request in
     match ReactServerDOM.decodeReply body with
     | Error msg -> Lwt.fail_with msg
     | Ok args ->
         dispatch_handler ~lookup actionId (fun actionId ->
             fun handler ->
              match handler with
              | ReactServerDOM.Body handler -> handler args
              | ReactServerDOM.FormData _ ->
                  Lwt.fail_with
                    ("Action " ^ actionId ^ " is registered as FormData handler but received JSON body request"))]

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

let handleRequest ~lookup =
 fun request ->
  let actionId = Dream.header request "ACTION_ID" in
  let contentType = Dream.header request "Content-Type" in
  match contentType with
  | Some contentType when String.starts_with contentType ~prefix:"multipart/form-data" ->
      [%lwt
        match Dream.multipart request ~csrf:false with
        | `Ok formData -> (
            match actionId with
            | Some _ -> handleFormRequest ~lookup actionId formData
            | None -> handleNoJsFormRequest ~lookup (dreamFormDataToJs formData))
        | _ -> Lwt.fail_with "Missing form data, this request was not created by server-reason-react"]
  | _ -> handleRequestBody ~lookup request actionId

let streamFunctionResponse ?(debug = false) =
 fun ~lookup ->
  fun request ->
   let pending, run = with_action_context request (fun () -> handleRequest ~lookup request) in
   [%lwt
     let action_promise, cookie_headers =
       Lwt.catch
         (fun () ->
           [%lwt
             let result = run () in
             let cookies = serialize_pending_cookies !pending in
             Lwt.return (Lwt.return result, cookies)])
         (fun exn ->
           pending := [];
           Lwt.return (Lwt.fail exn, []))
     in
     Dream.stream ~headers:(("Content-Type", "application/react.action") :: cookie_headers) (fun stream ->
         [%lwt
           let () =
             ReactServerDOM.create_action_response ~env:`Dev ~debug
               ~subscribe:(fun chunk ->
                 if debug then (
                   Dream.log "Action response";
                   Dream.log "%s" chunk);
                 [%lwt
                   let () = Dream.write stream chunk in
                   Dream.flush stream])
               action_promise
           in
           Dream.flush stream])]

let is_react_component_header str = String.equal str "application/react.component"

let stream_model_value ?(debug = false) =
 fun ?(code = 200) ->
  fun ?(headers = []) ->
   fun ~location ->
    fun app ->
     [%lwt
       let response =
         Dream.stream ~code ~headers (fun stream ->
             [%lwt
               let () =
                 ReactServerDOM.render_model_value ~env:`Dev ~debug
                   ~subscribe:(fun chunk ->
                     if debug then (
                       Dream.log "Chunk";
                       Dream.log "%s" chunk);
                     [%lwt
                       let () = Dream.write stream chunk in
                       Dream.flush stream])
                   app
               in
               Dream.flush stream])
       in
       Dream.set_header response "Content-Type" "application/react.component";
       Dream.set_header response "X-Content-Type-Options" "nosniff";
       Dream.set_header response "X-Location" location;
       Lwt.return response]

let stream_model ?(debug = false) =
 fun ?(code = 200) ->
  fun ?(headers = []) ->
   fun ~location -> fun app -> stream_model_value ~debug ~code ~headers ~location (React.Model.Element app)

let stream_html ?(debug = false) =
 fun ?(code = 200) ->
  fun ?(headers = []) ->
   fun ?(skipRoot = false) ->
    fun ?bootstrapScriptContent ->
     fun ?(bootstrapScripts = []) ->
      fun ?(bootstrapModules = []) ->
       fun app ->
        [%lwt
          let response =
            Dream.stream ~code ~headers (fun stream ->
                [%lwt
                  let html, subscribe =
                    ReactServerDOM.render_html ~env:`Dev ~skipRoot ?bootstrapScriptContent ~bootstrapScripts
                      ~bootstrapModules ~debug app
                  in
                  [%lwt
                    let () = Dream.write stream html in
                    [%lwt
                      let () = Dream.flush stream in
                      [%lwt
                        let () =
                          subscribe (fun chunk ->
                              if debug then (
                                Dream.log "Chunk";
                                Dream.log "%s" chunk);
                              [%lwt
                                let () = Dream.write stream chunk in
                                Dream.flush stream])
                        in
                        Dream.flush stream]]]])
          in
          Dream.set_header response "Content-Type" Dream.text_html;
          Lwt.return response]

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

let handler ~registry =
 fun ~basePath ->
  fun ~fallback ->
   fun ~applicationStatus ->
    fun ~diagnosticId ->
     fun ~revision ->
      fun ~protocolVersion ->
       fun ?(bootstrapModules = []) ->
        fun ~document ->
         fun ~rscModel ->
          fun ~rscPatch ->
           fun ~rscRedirect ->
            fun request ->
             with_render_context request (fun () ->
                 let pathname, query = Dream.target request |> Dream.split_target in
                 let search = match String.equal query "" with true -> "" | false -> "?" ^ query in
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
                   RouterServer.ServerEngine.run ~registry ~basePath ~fallback ~applicationStatus ~diagnosticId
                     ~revision ~protocolVersion
                     { RouterServer.ServerEngine.pathname; search; hash = ""; kind; navigation }
                 in
                 Lwt.bind outcome (fun outcome ->
                     match outcome with
                     | RouterServer.ServerEngine.Redirect destination -> (
                         match kind with
                         | RouterServer.ServerEngine.Document -> Dream.redirect request (RouterRuntime.href destination)
                         | RouterServer.ServerEngine.Rsc ->
                             stream_model_value ~code:200
                               ~headers:[ ("Vary", "Accept"); ("SRR-Response", "redirect") ]
                               ~location:(Dream.target request) (rscRedirect destination))
                     | RouterServer.ServerEngine.ReloadRequired ->
                         Dream.respond ~code:409
                           ~headers:
                             [
                               ("Vary", "Accept");
                               ("SRR-Response", "reload-required");
                               ("Cache-Control", "private, no-store");
                             ]
                           ""
                     | RouterServer.ServerEngine.Patch response ->
                         let code = response.resolved.status |> RouterRuntime.Status.toInt in
                         let headers = response.resolved.headers |> RouterRuntime.Headers.toList in
                         stream_model_value ~code ~headers ~location:response.canonical_url (rscPatch response)
                     | RouterServer.ServerEngine.Full response -> (
                         let code = response.resolved.status |> RouterRuntime.Status.toInt in
                         let headers = response.resolved.headers |> RouterRuntime.Headers.toList in
                         match response.kind with
                         | RouterServer.ServerEngine.Document ->
                             stream_html ~code ~headers ~bootstrapModules (document response)
                         | RouterServer.ServerEngine.Rsc ->
                             stream_model_value ~code ~headers ~location:response.canonical_url (rscModel response))))

let routes ~basePath =
 fun ~actionHandler ->
  fun handler ->
   [
     Dream.get basePath handler;
     Dream.get (basePath ^ "/**") handler;
     Dream.post basePath actionHandler;
     Dream.post (basePath ^ "/**") actionHandler;
   ]
