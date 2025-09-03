  $ cat > dune-project << EOF
  > (lang dune 3.10)
  > EOF

  $ cat > dune << EOF
  > (include_subdirs unqualified)
  > (executable
  >  (name input)
  >  (libraries server-reason-react.react server-reason-react.runtime server-reason-react.reactDom melange-json)
  >  (preprocess (pps server-reason-react.ppx --shared-folder-prefix=native/ server-reason-react.melange_ppx melange-json-native.ppx)))
  > EOF

  $ dune describe pp native/input.re
  [@ocaml.ppx.context
    {
      tool_name: "ppx_driver",
      include_dirs: [],
      hidden_include_dirs: [],
      load_path: [@ppxlib.migration.load_path ([], [])] [],
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
  let make = (~key as _: option(string)=?, ()) =>
    React.Client_component({
      import_module: "input.re",
      import_name: "",
      props: [],
      client: React.null,
    });
