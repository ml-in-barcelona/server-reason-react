  $ cat > dune-project << EOF
  > (lang dune 3.10)
  > (using melange 0.1)
  > EOF

  $ cat > dune << EOF
  > (melange.emit
  >  (target js)
  >  (libraries reason-react)
  >  (preprocess (pps reason-react-ppx melange.ppx melange-json.ppx server-reason-react.ppx -js)))
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
  open Ppx_deriving_json_runtime.Primitives;
  
  [@deriving json]
  type lola = {name: string};
  /**@inline*/
  [@merlin.hide]
  include {
            let _ = (_: lola) => ();
            [@ocaml.warning "-39-11-27"];
            let rec lola_of_json: Js.Json.t => lola =
              x => {
                if ([@ocaml.warning "-ignored-extra-argument"]
                    Stdlib.(!)(
                      [@ocaml.warning "-ignored-extra-argument"]
                      Stdlib.(&&)(
                        [@ocaml.warning "-ignored-extra-argument"]
                        Stdlib.(==)(
                          [@ocaml.warning "-ignored-extra-argument"]
                          Js.typeof(x),
                          "object",
                        ),
                        [@ocaml.warning "-ignored-extra-argument"]
                        Stdlib.(&&)(
                          [@ocaml.warning "-ignored-extra-argument"]
                          Stdlib.(!)(
                            [@ocaml.warning "-ignored-extra-argument"]
                            Js.Array.isArray(x),
                          ),
                          [@ocaml.warning "-ignored-extra-argument"]
                          Stdlib.(!)(
                            [@ocaml.warning "-ignored-extra-argument"]
                            Stdlib.(===)(
                              [@ocaml.warning "-ignored-extra-argument"]
                              Obj.magic(x): Js.null('a),
                              Js.null,
                            ),
                          ),
                        ),
                      ),
                    )) {
                  [@ocaml.warning "-ignored-extra-argument"]
                  Ppx_deriving_json_runtime.of_json_error(
                    "expected a JSON object",
                  );
                };
                let fs: {. "name": Js.undefined(Js.Json.t)} =
                  [@ocaml.warning "-ignored-extra-argument"] Obj.magic(x);
                {
                  name:
                    switch (
                      [@ocaml.warning "-ignored-extra-argument"]
                      Js.Undefined.toOption(
                        Js.Private.Js_OO.unsafe_downgrade(fs)#name,
                      )
                    ) {
                    | Stdlib.Option.Some(v) =>
                      [@ocaml.warning "-ignored-extra-argument"]
                      string_of_json(v)
                    | Stdlib.Option.None =>
                      [@ocaml.warning "-ignored-extra-argument"]
                      Ppx_deriving_json_runtime.of_json_error(
                        "missing field \"name\"",
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
                    [@ocaml.warning "-ignored-extra-argument"]
                    Obj.magic(
                      {
                        module J = {
                          [@ocaml.warning "-unboxable-type-in-prim-decl"]
                          external unsafe_expr: (~name: 'a0) => {. "name": 'a0} =
                            ""
                            "\132\149\166\190\000\000\000\011\000\000\000\005\000\000\000\r\000\000\000\012\145\160\160A\144$name@";
                        };
                        [@ocaml.warning "-ignored-extra-argument"]
                        J.unsafe_expr(
                          ~name=
                            [@ocaml.warning "-ignored-extra-argument"]
                            string_to_json(x_name),
                        );
                      },
                    ): Js.Json.t
                  )
                };
            let _ = lola_to_json;
          };
  
  module Prop_with_many_annotation = {
    include {
              [@ocaml.warning "-unboxable-type-in-prim-decl"]
              external makeProps:
                (
                  ~initial: int,
                  ~lola: lola,
                  ~children: React.element,
                  ~promise: Js.Promise.t(string),
                  ~key: string=?,
                  unit
                ) =>
                {
                  .
                  "initial": int,
                  "lola": lola,
                  "children": React.element,
                  "promise": Js.Promise.t(string),
                } =
                ""
                "\132\149\166\190\000\000\000=\000\000\000\023\000\000\000@\000\000\000<\145\160\160A\144'initial\160\160A\144$lola\160\160A\144(children\160\160A\144'promise\160\160A\161#key@\160\160@@@";
              let make =
                [@warning "-16"]
                (
                  (~initial: int) =>
                    [@warning "-16"]
                    (
                      (~lola: lola) =>
                        [@warning "-16"]
                        (
                          (~children: React.element) =>
                            [@warning "-16"]
                            (
                              (~promise: Js.Promise.t(string)) => {
                                let value =
                                  [@ocaml.warning "-ignored-extra-argument"]
                                  [@ocaml.warning "-ignored-extra-argument"]
                                  React.Experimental.use(promise);
                                [@ocaml.warning "-ignored-extra-argument"]
                                [@ocaml.warning "-ignored-extra-argument"]
                                ReactDOM.jsxs(
                                  "div",
                                  [@ocaml.warning "-ignored-extra-argument"]
                                  [@ocaml.warning "-ignored-extra-argument"]
                                  ([@merlin.hide] ReactDOM.domProps)(
                                    ~children=
                                      [@ocaml.warning "-ignored-extra-argument"]
                                      [@ocaml.warning "-ignored-extra-argument"]
                                      React.array([|
                                        [@ocaml.warning
                                          "-ignored-extra-argument"
                                        ]
                                        [@ocaml.warning
                                          "-ignored-extra-argument"
                                        ]
                                        React.string(lola.name),
                                        [@ocaml.warning
                                          "-ignored-extra-argument"
                                        ]
                                        [@ocaml.warning
                                          "-ignored-extra-argument"
                                        ]
                                        React.int(initial),
                                        children,
                                        [@ocaml.warning
                                          "-ignored-extra-argument"
                                        ]
                                        [@ocaml.warning
                                          "-ignored-extra-argument"
                                        ]
                                        React.string(value),
                                      |]),
                                    (),
                                  ),
                                );
                              }
                            )
                        )
                    )
                );
              let make = {
                let Input$Prop_with_many_annotation =
                    (
                      Props: {
                        .
                        "initial": int,
                        "lola": lola,
                        "children": React.element,
                        "promise": Js.Promise.t(string),
                      },
                    ) =>
                  [@ocaml.warning "-ignored-extra-argument"]
                  [@ocaml.warning "-ignored-extra-argument"]
                  make(
                    ~promise=
                      (
                        [@ocaml.warning "-ignored-extra-argument"]
                        Js.Private.Js_OO.unsafe_downgrade(Props)
                      )#
                        promise,
                    ~children=
                      (
                        [@ocaml.warning "-ignored-extra-argument"]
                        Js.Private.Js_OO.unsafe_downgrade(Props)
                      )#
                        children,
                    ~lola=
                      (
                        [@ocaml.warning "-ignored-extra-argument"]
                        Js.Private.Js_OO.unsafe_downgrade(Props)
                      )#
                        lola,
                    ~initial=
                      (
                        [@ocaml.warning "-ignored-extra-argument"]
                        Js.Private.Js_OO.unsafe_downgrade(Props)
                      )#
                        initial,
                  );
                Input$Prop_with_many_annotation;
              };
              let make_client = props =>
                [@ocaml.warning "-ignored-extra-argument"]
                [@ocaml.warning "-ignored-extra-argument"]
                make(
                  {
                    module J = {
                      [@ocaml.warning "-unboxable-type-in-prim-decl"]
                      [@ocaml.warning "-unboxable-type-in-prim-decl"]
                      external unsafe_expr:
                        (
                          ~promise: 'a0,
                          ~children: 'a1,
                          ~lola: 'a2,
                          ~initial: 'a3
                        ) =>
                        {
                          .
                          "promise": 'a0,
                          "children": 'a1,
                          "lola": 'a2,
                          "initial": 'a3,
                        } =
                        ""
                        "\132\149\166\190\000\000\0000\000\000\000\017\000\000\000/\000\000\000+\145\160\160A\144'promise\160\160A\144(children\160\160A\144$lola\160\160A\144'initial@";
                    };
                    [@ocaml.warning "-ignored-extra-argument"]
                    [@ocaml.warning "-ignored-extra-argument"]
                    J.unsafe_expr(
                      ~promise=(
                                 [@ocaml.warning "-ignored-extra-argument"]
                                 Js.Private.Js_OO.unsafe_downgrade(props)
                               )#
                                 promise: Js.Promise.t(string),
                      ~children=(
                                  [@ocaml.warning "-ignored-extra-argument"]
                                  Js.Private.Js_OO.unsafe_downgrade(props)
                                )#
                                  children: React.element,
                      ~lola=
                        [@ocaml.warning "-ignored-extra-argument"]
                        [@ocaml.warning "-ignored-extra-argument"]
                        lola_of_json(
                          (
                            [@ocaml.warning "-ignored-extra-argument"]
                            Js.Private.Js_OO.unsafe_downgrade(props)
                          )#
                            lola,
                        ),
                      ~initial=
                        [@ocaml.warning "-ignored-extra-argument"]
                        [@ocaml.warning "-ignored-extra-argument"]
                        int_of_json(
                          (
                            [@ocaml.warning "-ignored-extra-argument"]
                            Js.Private.Js_OO.unsafe_downgrade(props)
                          )#
                            initial,
                        ),
                    );
                  },
                );
            };
  };

  $ cat _build/default/js/input.js
  // Generated by Melange
  'use strict';
  
  var Ppx_deriving_json_runtime = require("melange-json.ppx-runtime/ppx_deriving_json_runtime.js");
  var React = require("react");
  var JsxRuntime = require("react/jsx-runtime");
  
  function lola_of_json(x) {
    if (!(typeof x === "object" && !Array.isArray(x) && x !== null)) {
      Ppx_deriving_json_runtime.of_json_error("expected a JSON object");
    }
    var v = x.name;
    return {
            name: v !== undefined ? Ppx_deriving_json_runtime.Primitives.string_of_json(v) : Ppx_deriving_json_runtime.of_json_error("missing field \"name\"")
          };
  }
  
  function lola_to_json(x) {
    return {
            name: x.name
          };
  }
  
  function Input$Prop_with_many_annotation(Props) {
    var initial = Props.initial;
    var lola = Props.lola;
    var children = Props.children;
    var promise = Props.promise;
    var value = React.use(promise);
    return JsxRuntime.jsxs("div", {
                children: [
                  lola.name,
                  initial,
                  children,
                  value
                ]
              });
  }
  
  function make_client(props) {
    return Input$Prop_with_many_annotation({
                promise: props.promise,
                children: props.children,
                lola: lola_of_json(props.lola),
                initial: Ppx_deriving_json_runtime.Primitives.int_of_json(props.initial)
              });
  }
  
  var Prop_with_many_annotation = {
    make: Input$Prop_with_many_annotation,
    make_client: make_client
  };
  
  exports.lola_of_json = lola_of_json;
  exports.lola_to_json = lola_to_json;
  exports.Prop_with_many_annotation = Prop_with_many_annotation;
  /* react Not a pure module */
