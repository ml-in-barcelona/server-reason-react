
  $ cat > dune-project << EOF
  > (lang dune 3.10)
  > (using melange 0.1)
  > (using directory-targets 0.1)
  > EOF

  $ cat > dune << EOF
  > (melange.emit
  >  (target js)
  >  (libraries reason-react)
  >  (preprocess (pps reason-react-ppx melange.ppx melange-json.ppx server-reason-react.ppx -melange)))
  > 
  > (rule
  >  (deps (alias melange))
  >  (target boostrap.js)
  >   (action
  >    (progn
  >     (with-stdout-to %{target}
  >      (run server_reason_react.extract_client_components js)))))
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
  let make = (~key as _: option(string)=?, ()) =>
    React.Client_component({
      import_module: __FILE__,
      import_name: "",
      props: [],
      client:
        React.createElementWithKey(
          ~key=None,
          "section",
          [],
          [
            React.createElementWithKey(
              ~key=None,
              "h1",
              [],
              [React.string("lola")],
            ),
            React.createElementWithKey(~key=None, "p", [], [React.int(1)]),
            React.createElementWithKey(
              ~key=None,
              "div",
              [],
              [React.string("children")],
            ),
          ],
        ),
    });
  
  let _ = make;
