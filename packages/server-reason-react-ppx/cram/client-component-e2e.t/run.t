
  $ cat > dune-project << EOF
  > (lang dune 3.10)
  > (using melange 0.1)
  > (using directory-targets 0.1)
  > EOF

  $ cat > dune << EOF
  > (melange.emit
  >  (target js)
  >  (libraries reason-react server-reason-react.rsc)
  >  (preprocess (pps reason-react-ppx melange.ppx server-reason-react.rsc.ppx server-reason-react.ppx -shared-folder-prefix=/ -melange)))
  > 
  > (rule
  >  (deps (alias melange))
  >  (target boostrap.js)
  >   (action
  >    (progn
  >     (with-stdout-to %{target}
  >      (run server-reason-react.extract_client_components js)))))
  > EOF

  $ dune build

  $ ../dune-describe-pp.sh input.re | sed '/\[@mel.internal.ffi/,/\]/d'
  [@deriving rsc]
  type lola = {name: string};
  /**@inline*/
  [@merlin.hide]
  include {
            let _ = (_: lola) => ();
            [@ocaml.warning "-39-11-27"];
            let rec lola_of_rsc: RSC.t => lola =
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
                  RSC.of_rsc_error(~rsc=x, "expected an object");
                };
                let fs: {. "name": Js.undefined(RSC.t) } = Obj.magic(x);
                {
                  name:
                    switch (
                      Js.Undefined.toOption(Js.OO.unsafe_downgrade(fs)#name)
                    ) {
                    | Stdlib.Option.Some(v) => RSC.Primitives.string_of_rsc(v)
                    | Stdlib.Option.None =>
                      RSC.of_rsc_error(
                        ~rsc=x,
                        "expected field \"name\" to be present",
                      )
                    },
                };
              };
            let _ = lola_of_rsc;
            [@ocaml.warning "-39-11-27"];
            let rec lola_to_rsc: lola => RSC.t =
              x =>
                switch (x) {
                | { name: x_name } =>
                  RSC.Primitives.assoc_to_rsc(
                    {
                      let bnds__001_ = [];
                      let bnds__001_ = [
                        ("name", RSC.Primitives.string_to_rsc(x_name)),
                        ...bnds__001_,
                      ];
                      bnds__001_;
                    },
                  )
                };
            let _ = lola_to_rsc;
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
                (
                  ~initial: int,
                  ~lola: lola,
                  ~default: int=23,
                  ~children: React.element,
                  ~promise: Js.Promise.t(string),
                ) => {
                  let value = React.Experimental.usePromise(promise);
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
              React.createElement(
                make,
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
                    ~promise=
                      (
                        RSC.Primitives.promise_of_rsc(
                          RSC.Primitives.string_of_rsc,
                        )
                      )(
                        Js.OO.unsafe_downgrade(props)#promise,
                      ),
                    ~children=
                      RSC.Primitives.react_element_of_rsc(
                        Js.OO.unsafe_downgrade(props)#children,
                      ),
                    ~default=
                      (RSC.Primitives.option_of_rsc(RSC.Primitives.int_of_rsc))(
                        Js.OO.unsafe_downgrade(props)#default,
                      ),
                    ~lola=lola_of_rsc(Js.OO.unsafe_downgrade(props)#lola),
                    ~initial=
                      RSC.Primitives.int_of_rsc(
                        Js.OO.unsafe_downgrade(props)#initial,
                      ),
                  );
                },
              );
          };
  $ cat _build/default/js/input.js
  // Generated by Melange
  'use strict';
  
  const RSC = require("server-reason-react.rsc/RSC.js");
  const React = require("react");
  const JsxRuntime = require("react/jsx-runtime");
  
  function lola_of_rsc(x) {
    if (!(typeof x === "object" && !Array.isArray(x) && x !== null)) {
      RSC.of_rsc_error(undefined, undefined, x, "expected an object");
    }
    const v = x.name;
    return {
      name: v !== undefined ? RSC.Primitives.string_of_rsc(v) : RSC.of_rsc_error(undefined, undefined, x, "expected field \"name\" to be present")
    };
  }
  
  function lola_to_rsc(x) {
    return RSC.Primitives.assoc_to_rsc({
      hd: [
        "name",
        RSC.Primitives.string_to_rsc(x.name)
      ],
      tl: /* [] */ 0
    });
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
    return React.createElement(Input, {
      promise: RSC.Primitives.promise_of_rsc(RSC.Primitives.string_of_rsc, props.promise),
      children: RSC.Primitives.react_element_of_rsc(props.children),
      default: RSC.Primitives.option_of_rsc(RSC.Primitives.int_of_rsc, props.default),
      lola: lola_of_rsc(props.lola),
      initial: RSC.Primitives.int_of_rsc(props.initial)
    });
  }
  
  const make = Input;
  
  module.exports = {
    lola_of_rsc,
    lola_to_rsc,
    make,
    make_client,
  }
  /* react Not a pure module */

  $ cat _build/default/boostrap.js
  import React from "react";
  window.__client_manifest_map = window.__client_manifest_map || {};
  window.__server_functions_manifest_map = window.__server_functions_manifest_map || {};
  window.__client_manifest_map["input.re"] = React.lazy(() => import("$TESTCASE_ROOT/_build/default/js/input.js").then(module => {
    return { default: module.make_client }
  }).catch(err => { console.error(err); return { default: null }; }))
