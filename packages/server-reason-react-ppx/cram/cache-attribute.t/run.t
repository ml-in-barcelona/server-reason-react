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
         ~tags:[ "user:" ^ string_of_int id ]
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
                     React.Cache.expire ~tag:"user:1";
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

Melange keeps a Request cache as the plain function

  $ ../ppx.sh --output ml -js input.re | sed -n '/let viewer/,/^$/p'
  let viewer ~(id : int) =
   fun () ->
    (incr calls;
     Lwt.return ("viewer-" ^ string_of_int id)
      : string Lwt.t)
  

Melange rejects a Process cache

  $ ../ppx.sh --output ml -js process.re
  [%%ocaml.error
  "server-reason-react: [@cache] scope = Process is for server code only: the \
   browser has no process cache"]

Errors

  $ ../ppx.sh --output ml errors.re
  [%%ocaml.error
  "server-reason-react: [@cache] needs a type annotation on argument id, as in \
   (id : int)"]
  $ ../ppx.sh --output ml request_ttl.re
  [%%ocaml.error "server-reason-react: [@cache] ttl needs scope = Process"]
  $ ../ppx.sh --output ml unknown_field.re
  [%%ocaml.error
  "server-reason-react: [@cache] has no field lifetime. Fields: scope, ttl, max, \
   errors, tags, key"]
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
  > EOF

  $ dune build ./input.exe
  $ ./_build/default/input.exe
  everything: x
  calls: 7
