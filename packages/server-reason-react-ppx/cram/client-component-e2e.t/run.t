
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

  $ dune describe pp input.re | sed '/\[@mel.internal.ffi/,/\]/d'
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
  open Melange_json.Primitives;
  
  [@deriving json]
  type lola = {name: string};
  /**@inline*/
  [@merlin.hide]
  include {
            let _ = (_: lola) => ();
            [@ocaml.warning "-39-11-27"];
            let rec lola_of_json: Js.Json.t => lola =
              x => {
                if (Stdlib.(!)(
                      Stdlib.(&&)(
                        Stdlib.(==)(Js.typeof(x), "object"),
                        Stdlib.(&&)(
                          Stdlib.(!)(Js.Array.isArray(x)),
                          Stdlib.(!)(
                            Stdlib.(===)(Obj.magic(x): Js.null('a), Js.null),
                          ),
                        ),
                      ),
                    )) {
                  Melange_json.of_json_error(~json=x, "expected a JSON object");
                };
                let fs: {. "name": Js.undefined(Js.Json.t)} = Obj.magic(x);
                {
                  name:
                    switch (
                      Js.Undefined.toOption(Js.OO.unsafe_downgrade(fs)#name)
                    ) {
                    | Stdlib.Option.Some(v) => string_of_json(v)
                    | Stdlib.Option.None =>
                      Melange_json.of_json_error(
                        ~json=x,
                        "expected field \"name\" to be present",
                      )
                    },
                };
              };
            let _ = lola_of_json;
            [@ocaml.warning "-39-11-27"];
            let rec lola_to_json: lola => Js.Json.t =
              x =>
                switch (x) {
                | {name: x_name} => (
                    Obj.magic(
                      {
                        module J = {
                          [@ocaml.warning "-unboxable-type-in-prim-decl"]
                          external unsafe_expr: (~name: 'a0) => {. "name": 'a0} =
                            "" "";
                        };
                        J.unsafe_expr(~name=string_to_json(x_name));
                      },
                    ): Js.Json.t
                  )
                };
            let _ = lola_to_json;
          };
  
  include {
            {
              module J = {
                [@ocaml.warning "-unboxable-type-in-prim-decl"]
                external unsafe_expr: _ => _ = "#raw_stmt";
              };
              J.unsafe_expr("// extract-client input.re");
            };
  
            [@ocaml.warning "-unboxable-type-in-prim-decl"]
            external makeProps:
              (
                ~initial: int,
                ~lola: lola,
                ~default: int=?,
                ~children: React.element,
                ~promise: Js.Promise.t(string),
                ~key: string=?,
                unit
              ) =>
              {
                .
                "initial": int,
                "lola": lola,
                "default": option(int),
                "children": React.element,
                "promise": Js.Promise.t(string),
              } =
              "" "";
            let make =
              [@warning "-16"]
              (
                (~initial: int) =>
                  [@ppxlib.migration.stop_taking]
                  [@warning "-16"]
                  (
                    (~lola: lola) =>
                      [@ppxlib.migration.stop_taking]
                      [@warning "-16"]
                      (
                        (~default: int=23) =>
                          [@ppxlib.migration.stop_taking]
                          [@warning "-16"]
                          (
                            (~children: React.element) =>
                              [@ppxlib.migration.stop_taking]
                              [@warning "-16"]
                              (
                                (~promise: Js.Promise.t(string)) => {
                                  let value = React.Experimental.use(promise);
                                  ReactDOM.jsxs(
                                    "div",
                                    ([@merlin.hide] ReactDOM.domProps)(
                                      ~children=
                                        React.array([|
                                          React.string(lola.name),
                                          React.int(initial),
                                          React.int(default),
                                          children,
                                          React.string(value),
                                        |]),
                                      (),
                                    ),
                                  );
                                }
                              )
                          )
                      )
                  )
              );
            let make = {
              let Input =
                  (
                    Props: {
                      .
                      "initial": int,
                      "lola": lola,
                      "default": option(int),
                      "children": React.element,
                      "promise": Js.Promise.t(string),
                    },
                  ) =>
                make(
                  ~promise=Js.OO.unsafe_downgrade(Props)#promise,
                  ~children=Js.OO.unsafe_downgrade(Props)#children,
                  ~default=?Js.OO.unsafe_downgrade(Props)#default,
                  ~lola=Js.OO.unsafe_downgrade(Props)#lola,
                  ~initial=Js.OO.unsafe_downgrade(Props)#initial,
                );
              Input;
            };
            let make_client = props =>
              make(
                {
                  module J = {
                    [@ocaml.warning "-unboxable-type-in-prim-decl"]
                    [@ocaml.warning "-unboxable-type-in-prim-decl"]
                    external unsafe_expr:
                      (
                        ~promise: 'a0,
                        ~children: 'a1,
                        ~default: 'a2,
                        ~lola: 'a3,
                        ~initial: 'a4
                      ) =>
                      {
                        .
                        "promise": 'a0,
                        "children": 'a1,
                        "default": 'a2,
                        "lola": 'a3,
                        "initial": 'a4,
                      } =
                      "" "";
                  };
                  J.unsafe_expr(
                    ~promise=Js.OO.unsafe_downgrade(props)#promise:
                                                                     Js.Promise.t(
                                                                      string,
                                                                     ),
                    ~children=Js.OO.unsafe_downgrade(props)#children: React.element,
                    ~default=
                      (option_of_json(int_of_json))(
                        Js.OO.unsafe_downgrade(props)#default,
                      ),
                    ~lola=lola_of_json(Js.OO.unsafe_downgrade(props)#lola),
                    ~initial=
                      int_of_json(Js.OO.unsafe_downgrade(props)#initial),
                  );
                },
              );
          };
  $ cat _build/default/js/input.js
  // Generated by Melange
  'use strict';
  
  const Melange_json = require("melange-json/melange_json.js");
  const React = require("react");
  const JsxRuntime = require("react/jsx-runtime");
  
  function lola_of_json(x) {
    if (!(typeof x === "object" && !Array.isArray(x) && x !== null)) {
      Melange_json.of_json_error(undefined, undefined, x, "expected a JSON object");
    }
    const v = x.name;
    return {
      name: v !== undefined ? Melange_json.Primitives.string_of_json(v) : Melange_json.of_json_error(undefined, undefined, x, "expected field \"name\" to be present")
    };
  }
  
  function lola_to_json(x) {
    return {
      name: Melange_json.Primitives.string_to_json(x.name)
    };
  }
  
  // extract-client input.re
  
  function Input(Props) {
    let initial = Props.initial;
    let lola = Props.lola;
    let defaultOpt = Props.default;
    let children = Props.children;
    let promise = Props.promise;
    const $$default = defaultOpt !== undefined ? defaultOpt : 23;
    const value = React.use(promise);
    return JsxRuntime.jsxs("div", {
      children: [
        lola.name,
        initial,
        $$default,
        children,
        value
      ]
    });
  }
  
  function make_client(props) {
    return Input({
      promise: props.promise,
      children: props.children,
      default: Melange_json.Primitives.option_of_json(Melange_json.Primitives.int_of_json, props.default),
      lola: lola_of_json(props.lola),
      initial: Melange_json.Primitives.int_of_json(props.initial)
    });
  }
  
  const make = Input;
  
  module.exports = {
    lola_of_json,
    lola_to_json,
    make,
    make_client,
  }
  /* Melange_json Not a pure module */

  $ cat _build/default/boostrap.js
  import React from "react";
  window.__client_manifest_map = window.__client_manifest_map || {};
  window.__server_functions_manifest_map = window.__server_functions_manifest_map || {};
  window.__client_manifest_map["input.re"] = React.lazy(() => import("$TESTCASE_ROOT/_build/default/js/input.js").then(module => {
    return { default: module.make_client }
  }).catch(err => { console.error(err); return { default: null }; }))
