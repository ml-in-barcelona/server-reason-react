The attribute wraps the function body in React.Cache.run, with a key built from the typed arguments

  $ ../ppx.sh --output ml input.re
  type filter = { term : string; page : int } [@@deriving rsc]
  
  let calls = ref 0
  
  let viewer =
    let server_reason_react_cache =
      React.Cache.make ~name:"Output.viewer" ~scope:React.Cache.Request ()
    in
    fun ~(id : int) ->
      fun () ->
       React.Cache.run server_reason_react_cache
         ~key:(React.Cache.Key.parts [ React.Cache.Key.int id ])
         (fun () ->
           (incr calls;
            Lwt.return ("viewer-" ^ string_of_int id)
             : string Lwt.t))
  
  let appearance =
    let server_reason_react_cache =
      React.Cache.make ~name:"Output.appearance" ~scope:React.Cache.Process
        ~ttl:30. ~max:10 ()
    in
    fun ~(id : int) ->
      fun ~logger:(_ : string -> unit) ->
       React.Cache.run server_reason_react_cache
         ~key:(React.Cache.Key.parts [ React.Cache.Key.int id ])
         ~tags:[ `User id ]
         (fun () ->
           (incr calls;
            Lwt.return ("dark-" ^ string_of_int id)
             : string Lwt.t))
  
  module Search = struct
    let results =
      let server_reason_react_cache =
        React.Cache.make ~name:"Output.Search.results" ~scope:React.Cache.Request
          ~errors:React.Cache.Retry ()
      in
      fun (filter : filter) ->
        fun ?(limit : int option) ->
         fun (() : unit) ->
          React.Cache.run server_reason_react_cache
            ~key:
              (React.Cache.Key.parts
                 [
                   (fun value -> RSC.to_cache_key ([%to_rsc: filter] value))
                     filter;
                   (React.Cache.Key.option React.Cache.Key.int) limit;
                 ])
            (fun () ->
              (incr calls;
               Lwt.return
                 [
                   filter.term;
                   string_of_int filter.page;
                   Option.fold ~none:"" ~some:string_of_int limit;
                 ]
                : string list Lwt.t))
  end
  
  let everything =
    let server_reason_react_cache =
      React.Cache.make ~name:"Output.everything" ~scope:React.Cache.Request ()
    in
    fun ~(a : string) ->
      React.Cache.run server_reason_react_cache ~key:"all" (fun () ->
          (incr calls;
           Lwt.return a
            : string Lwt.t))
  
  let () =
    Lwt_main.run
      (React.Cache.request_scope (fun () ->
           [%lwt
             let _ = viewer ~id:1 () in
             [%lwt
               let _ = viewer ~id:1 () in
               [%lwt
                 let _ = viewer ~id:2 () in
                 [%lwt
                   let _ = appearance ~id:1 ~logger:ignore in
                   [%lwt
                     let _ = appearance ~id:1 ~logger:print_endline in
                     React.Cache.expire ~tag:(`User 1);
                     [%lwt
                       let _ = appearance ~id:1 ~logger:ignore in
                       [%lwt
                         let _ = Search.results { term = "a"; page = 1 } () in
                         [%lwt
                           let _ = Search.results { term = "a"; page = 1 } () in
                           [%lwt
                             let _ =
                               Search.results { term = "a"; page = 1 } ~limit:5 ()
                             in
                             [%lwt
                               let _ = everything ~a:"x" in
                               [%lwt
                                 let b = everything ~a:"y" in
                                 print_endline ("everything: " ^ b);
                                 print_endline ("calls: " ^ string_of_int !calls);
                                 Lwt.return ()]]]]]]]]]]]))

Without scope, ttl or max means Process; anything else means Request

  $ ../ppx.sh --output ml process_default.re | grep 'React.Cache.make'
      React.Cache.make ~name:"Output.request" ~scope:React.Cache.Request ()
      React.Cache.make ~name:"Output.ttl_only" ~scope:React.Cache.Process ~ttl:30.
      React.Cache.make ~name:"Output.max_only" ~scope:React.Cache.Process ~max:5

Melange keeps a Request cache as the plain function

  $ ../ppx.sh --output ml -js input.re | sed -n '/let viewer/,/^$/p'
  let viewer ~(id : int) =
   fun () ->
    (incr calls;
     Lwt.return ("viewer-" ^ string_of_int id)
      : string Lwt.t)
  

Melange drops the tags of a Request cache with the rest of the cache

  $ ../ppx.sh --output ml -js process_default.re | sed -n '/let request/,/^$/p'
  let request ~(id : int) = (Lwt.return (string_of_int id) : string Lwt.t)
  

Melange rejects a Process cache

  $ ../ppx.sh --output ml -js process.re
  [%%ocaml.error
  "server-reason-react: [@cache] scope = Process is for server code only: the \
   browser has no process cache"]

A server function caches its call, so a call from a server component and a call from the browser share one entry. The browser keeps the client reference, for any scope

  $ ../ppx.sh --output ml server_function.re | sed -n '/let viewer/,/^  ;;/p'
    let viewer =
      {
        Runtime.id = "659777569";
        call =
          (let server_reason_react_cache =
             React.Cache.make ~name:"Output.viewer" ~scope:React.Cache.Process
               ~ttl:30. ()
           in
           fun ~(id : int) ->
             React.Cache.run server_reason_react_cache
               ~key:(React.Cache.Key.parts [ React.Cache.Key.int id ])
               ~tags:[ `User id ]
               (fun () ->
                 (incr calls;
                  Lwt.return ("viewer-" ^ string_of_int id)
                   : string Js.Promise.t)));
      }
    ;;
  $ ../ppx.sh --output ml -js server_function.re | sed -n '/let viewer/,/^    }/p'
    let viewer =
      {
        Runtime.id = "659777569";
        call =
          (fun ~(id : int) ->
            let action =
              ReactServerDOMEsbuild.createServerReference "659777569"
            in
            (action id [@u])
            |> Js.Promise.then_ (fun response ->
                Js.Promise.resolve ([%of_rsc: string] response)));
      }

Errors

  $ ../ppx.sh --output ml errors.re
  [%%ocaml.error
  "server-reason-react: [@cache] needs a type annotation on argument id, as in \
   (id : int)"]
  $ ../ppx.sh --output ml request_ttl.re
  [%%ocaml.error
  "server-reason-react: [@cache] ttl and max need scope = Process. Remove scope \
   = Request: ttl or max alone means Process"]
  $ ../ppx.sh --output ml unknown_field.re
  [%%ocaml.error
  "server-reason-react: [@cache] has no field lifetime. Fields: scope, ttl, max, \
   errors, tags, key"]
  $ ../ppx.sh --output ml server_function_form_data.re
  [%%ocaml.error
  "server-reason-react: [@cache] cannot build a key from a Js.FormData.t \
   argument. Give one, as in [@cache { key = ... }]"]
  $ ../ppx.sh --output ml local.re
  let f () =
    [%ocaml.error
      "server-reason-react: [@cache] goes on a top-level binding, so that its \
       cache is created once"]

It runs: equal arguments share one call, expire drops tagged entries, and a record argument goes through RSC

  $ cat > dune-project << EOF
  > (lang dune 3.10)
  > EOF

  $ cat > dune << EOF
  > (executable
  >  (name input)
  >  (modules input)
  >  (libraries server-reason-react.react server-reason-react.rsc-native lwt lwt.unix)
  >  (preprocess (pps server-reason-react.ppx lwt_ppx server-reason-react.rsc-native.ppx)))
  > (executable
  >  (name server_function)
  >  (modules server_function)
  >  (libraries server-reason-react.react server-reason-react.runtime server-reason-react.reactDom melange-json-native server-reason-react.rsc-native lwt lwt.unix)
  >  (preprocess (pps server-reason-react.ppx -shared-folder-prefix=/ server-reason-react.melange_ppx lwt_ppx server-reason-react.rsc-native.ppx)))
  > EOF

  $ dune build ./input.exe ./server_function.exe
  $ ./_build/default/input.exe
  everything: x
  calls: 7
  $ ./_build/default/server_function.exe
  server function calls: 3
