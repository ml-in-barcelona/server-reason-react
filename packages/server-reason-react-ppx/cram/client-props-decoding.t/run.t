  $ cat > dune-project << EOF
  > (lang dune 3.10)
  > (using melange 0.1)
  > EOF

  $ cat > dune << EOF
  > (melange.emit
  >  (target js)
  >  (libraries reason-react melange-json)
  >  (preprocess (pps melange.ppx melange-json.ppx server-reason-react.ppx -shared-folder-prefix=/ -melange)))
  > EOF

  $ ../dune-describe-pp.sh input.re | sed '/\[@mel.internal.ffi/,/\]/d'
  open Melange_json.Primitives;
  
  [@warning "-27"];
  include {
            {
              module J = {
                [@ocaml.warning "-unboxable-type-in-prim-decl"]
                external unsafe_expr: _ => _ = "#raw_stmt";
              };
              J.unsafe_expr("// extract-client input.re");
            };
  
            [@react.component]
            let make =
                (
                  ~prop: int,
                  ~lola: list(int),
                  ~lolo: string,
                  ~lili: bool,
                  ~lulu: float,
                  ~tuple2: (int, int),
                  ~tuple3: (int, string, float),
                ) => React.null;
            let make_client = props =>
              React.createElement(
                make,
                {
                  module J = {
                    [@ocaml.warning "-unboxable-type-in-prim-decl"]
                    [@ocaml.warning "-unboxable-type-in-prim-decl"]
                    external unsafe_expr:
                      (
                        ~tuple3: 'a0,
                        ~tuple2: 'a1,
                        ~lulu: 'a2,
                        ~lili: 'a3,
                        ~lolo: 'a4,
                        ~lola: 'a5,
                        ~prop: 'a6
                      ) =>
                      {
                        .
                        "tuple3": 'a0,
                        "tuple2": 'a1,
                        "lulu": 'a2,
                        "lili": 'a3,
                        "lolo": 'a4,
                        "lola": 'a5,
                        "prop": 'a6,
                      } =
                      "" "";
                  };
                  J.unsafe_expr(
                    ~tuple3=
                      (
                        x =>
                          if (Stdlib.(&&)(
                                Js.Array.isArray(x),
                                Stdlib.(==)(
                                  Js.Array.length(
                                    Obj.magic(x): array(Js.Json.t),
                                  ),
                                  3,
                                ),
                              )) {
                            let es: array(Js.Json.t) = Obj.magic(x);
                            (
                              int_of_json(Js.Array.unsafe_get(es, 0)),
                              string_of_json(Js.Array.unsafe_get(es, 1)),
                              float_of_json(Js.Array.unsafe_get(es, 2)),
                            );
                          } else {
                            Melange_json.of_json_error(
                              ~json=x,
                              "expected a JSON array of length 3",
                            );
                          }
                      )(
                        Js.OO.unsafe_downgrade(props)#tuple3,
                      ),
                    ~tuple2=
                      (
                        x =>
                          if (Stdlib.(&&)(
                                Js.Array.isArray(x),
                                Stdlib.(==)(
                                  Js.Array.length(
                                    Obj.magic(x): array(Js.Json.t),
                                  ),
                                  2,
                                ),
                              )) {
                            let es: array(Js.Json.t) = Obj.magic(x);
                            (
                              int_of_json(Js.Array.unsafe_get(es, 0)),
                              int_of_json(Js.Array.unsafe_get(es, 1)),
                            );
                          } else {
                            Melange_json.of_json_error(
                              ~json=x,
                              "expected a JSON array of length 2",
                            );
                          }
                      )(
                        Js.OO.unsafe_downgrade(props)#tuple2,
                      ),
                    ~lulu=float_of_json(Js.OO.unsafe_downgrade(props)#lulu),
                    ~lili=bool_of_json(Js.OO.unsafe_downgrade(props)#lili),
                    ~lolo=string_of_json(Js.OO.unsafe_downgrade(props)#lolo),
                    ~lola=
                      (list_of_json(int_of_json))(
                        Js.OO.unsafe_downgrade(props)#lola,
                      ),
                    ~prop=int_of_json(Js.OO.unsafe_downgrade(props)#prop),
                  );
                },
              );
          };
