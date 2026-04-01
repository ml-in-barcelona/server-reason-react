  $ cat > dune-project << EOF
  > (lang dune 3.10)
  > EOF

  $ cat > dune << EOF
  > (include_subdirs unqualified)
  > (executable
  >  (name input)
  >  (libraries server-reason-react.react server-reason-react.runtime server-reason-react.reactDom melange-json)
  >  (preprocess (pps server-reason-react.ppx -shared-folder-prefix=native/ server-reason-react.melange_ppx melange-json-native.ppx)))
  > EOF

  $ dune describe pp native/input.ml
  [@@@ocaml.ppx.context
    {
      tool_name = "ppx_driver";
      include_dirs = [];
      hidden_include_dirs = [];
      load_path = ([], []);
      open_modules = [];
      for_package = None;
      debug = false;
      use_threads = false;
      use_vmthreads = false;
      recursive_types = false;
      principal = false;
      no_alias_deps = false;
      unboxed_types = false;
      unsafe_string = false;
      cookies = []
    }]
  include
    struct
      let makeProps () =
        let __js_obj = object  end in
        (Js.Obj.Internal.register_abstract __js_obj [] : <  >  Js.t)
      let make ?key:(key : string option) () =
        React.Client_component
          {
            key;
            import_module = "input.ml";
            import_name = "";
            props = [];
            client =
              (React.Upper_case_component
                 (Stdlib.__FUNCTION__, (fun () -> React.null)))
          }
      let make ?key:(key : string option) (_Props : <  >  Js.t) = make ?key ()
    end
