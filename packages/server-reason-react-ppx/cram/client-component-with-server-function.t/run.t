  $ cat > dune-project << EOF
  > (lang dune 3.10)
  > EOF

  $ cat > dune << EOF
  > (executable
  >  (name input)
  >  (libraries server-reason-react.react server-reason-react.reactDom melange-json)
  >  (preprocess (pps server-reason-react.ppx server-reason-react.melange_ppx melange-json-native.ppx)))
  > EOF

  $ dune build
  $ dune describe pp input.re
  [@ocaml.ppx.context
    {
      tool_name: "ppx_driver",
      include_dirs: [],
      load_path: [],
      open_modules: [],
      for_package: None,
      debug: false,
      use_threads: false,
      use_vmthreads: false,
      recursive_types: false,
      principal: false,
      transparent_modules: false,
      unboxed_types: false,
      unsafe_string: false,
      cookies: [],
    }
  ];
  let make =
      (
        ~key as _: option(string)=?,
        ~initial: Runtime.React.server_function(int => Js.Promise.t(int)),
        (),
      ) =>
    React.Client_component({
      import_module: __FILE__,
      import_name: "",
      props: [("initial", React.Function(initial))],
      client:
        React.createElementWithKey(
          ~key=None,
          "button",
          Stdlib.List.filter_map(
            Fun.id,
            [
              Some(
                [@implicit_arity]
                React.JSX.Event(
                  "onClick",
                  React.JSX.Mouse(
                    _ => initial.call(1) |> ignore: React.Event.Mouse.t => unit,
                  ),
                ),
              ),
            ],
          ),
          [],
        ),
    });
  
  let _ = make;

