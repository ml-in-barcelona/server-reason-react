  $ cat > dune-project << EOF
  > (lang dune 3.10)
  > EOF

  $ cat > dune << EOF
  > (executable
  >  (name input)
  >  (libraries server-reason-react.react server-reason-react.reactDom melange-json)
  >  (preprocess (pps server-reason-react.ppx -shared-folder-prefix=/ server-reason-react.melange_ppx melange-json-native.ppx)))
  > EOF

  $ dune describe pp input.re
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
  let unsafeWhenNotZero = (prop, value) =>
    if (value == 0) {
      [];
    } else {
      [prop ++ "-" ++ Int.to_string(value)];
    };
  
  let make =
      (
        ~key as _: option(string)=?,
        ~children=?,
        ~top=0,
        ~left=0,
        ~right=0,
        ~bottom=0,
        ~all=0,
        (),
      ) =>
    [@implicit_arity]
    React.Upper_case_component(
      Stdlib.__FUNCTION__,
      () => {
        let className =
          Cx.make(
            List.flatten([
              unsafeWhenNotZero("mt", top),
              unsafeWhenNotZero("mb", bottom),
              unsafeWhenNotZero("ml", left),
              unsafeWhenNotZero("mr", right),
              unsafeWhenNotZero("m", all),
            ]),
          );
  
        React.createElementWithKey(
          ~key=None,
          "div",
          Stdlib.List.filter_map(
            Stdlib.Fun.id,
            [
              Some(
                [@implicit_arity]
                React.JSX.String("class", "className", className: string),
              ),
            ],
          ),
          [
            switch (children) {
            | None => React.null
            | Some(c) => c
            },
          ],
        );
      },
    );
