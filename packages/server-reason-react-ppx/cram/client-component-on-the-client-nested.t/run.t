  $ cat > dune-project << EOF
  > (lang dune 3.10)
  > (using melange 0.1)
  > EOF

  $ cat > dune << EOF
  > (melange.emit
  >  (target js)
  >  (preprocess (pps server-reason-react.rsc.ppx server-reason-react.ppx -shared-folder-prefix=/ -melange)))
  > EOF

  $ ../dune-describe-pp.sh input.re
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
                    switch (Js.Undefined.toOption(fs##name)) {
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
            [%%raw "// extract-client input.re"];
            [@react.component]
            let make = (~initial: int, ~lola: lola, ~children: React.element) =>
              <section>
                <h1> {React.string(lola.name)} </h1>
                <p> {React.int(initial)} </p>
                <div> children </div>
              </section>;
            let make_client = props =>
              React.createElement(
                make,
                {
                  "children":
                    RSC.Primitives.react_element_of_rsc(props##children),
                  "lola": lola_of_rsc(props##lola),
                  "initial": RSC.Primitives.int_of_rsc(props##initial),
                },
              );
          };
  
  module InnerAfterNested = {
    module Very_nested = {
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
                                Stdlib.(===)(
                                  Obj.magic(x): Js.null('a),
                                  Js.null,
                                ),
                              ),
                            ),
                          ),
                        )) {
                      RSC.of_rsc_error(~rsc=x, "expected an object");
                    };
                    let fs: {. "name": Js.undefined(RSC.t) } = Obj.magic(x);
                    {
                      name:
                        switch (Js.Undefined.toOption(fs##name)) {
                        | Stdlib.Option.Some(v) =>
                          RSC.Primitives.string_of_rsc(v)
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
                          let bnds__002_ = [];
                          let bnds__002_ = [
                            ("name", RSC.Primitives.string_to_rsc(x_name)),
                            ...bnds__002_,
                          ];
                          bnds__002_;
                        },
                      )
                    };
                let _ = lola_to_rsc;
              };
  
      include {
                [%%raw "// extract-client input.re InnerAfterNested.Very_nested"];
                [@react.component]
                let make =
                    (~initial: int, ~lola: lola, ~children: React.element) =>
                  <section>
                    <h1> {React.string(lola.name)} </h1>
                    <p> {React.int(initial)} </p>
                    <div> children </div>
                  </section>;
                let make_client = props =>
                  React.createElement(
                    make,
                    {
                      "children":
                        RSC.Primitives.react_element_of_rsc(props##children),
                      "lola": lola_of_rsc(props##lola),
                      "initial": RSC.Primitives.int_of_rsc(props##initial),
                    },
                  );
              };
    };
  
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
                              Stdlib.(===)(
                                Obj.magic(x): Js.null('a),
                                Js.null,
                              ),
                            ),
                          ),
                        ),
                      )) {
                    RSC.of_rsc_error(~rsc=x, "expected an object");
                  };
                  let fs: {. "name": Js.undefined(RSC.t) } = Obj.magic(x);
                  {
                    name:
                      switch (Js.Undefined.toOption(fs##name)) {
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
                        let bnds__003_ = [];
                        let bnds__003_ = [
                          ("name", RSC.Primitives.string_to_rsc(x_name)),
                          ...bnds__003_,
                        ];
                        bnds__003_;
                      },
                    )
                  };
              let _ = lola_to_rsc;
            };
  
    include {
              [%%raw "// extract-client input.re InnerAfterNested"];
              [@react.component]
              let make = (~initial: int, ~lola: lola, ~children: React.element) =>
                <section>
                  <h1> {React.string(lola.name)} </h1>
                  <p> {React.int(initial)} </p>
                  <div> children </div>
                </section>;
              let make_client = props =>
                React.createElement(
                  make,
                  {
                    "children":
                      RSC.Primitives.react_element_of_rsc(props##children),
                    "lola": lola_of_rsc(props##lola),
                    "initial": RSC.Primitives.int_of_rsc(props##initial),
                  },
                );
            };
  };
  
  module InnerBeforeNested = {
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
                              Stdlib.(===)(
                                Obj.magic(x): Js.null('a),
                                Js.null,
                              ),
                            ),
                          ),
                        ),
                      )) {
                    RSC.of_rsc_error(~rsc=x, "expected an object");
                  };
                  let fs: {. "name": Js.undefined(RSC.t) } = Obj.magic(x);
                  {
                    name:
                      switch (Js.Undefined.toOption(fs##name)) {
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
                        let bnds__004_ = [];
                        let bnds__004_ = [
                          ("name", RSC.Primitives.string_to_rsc(x_name)),
                          ...bnds__004_,
                        ];
                        bnds__004_;
                      },
                    )
                  };
              let _ = lola_to_rsc;
            };
  
    include {
              [%%raw "// extract-client input.re InnerBeforeNested"];
              [@react.component]
              let make = (~initial: int, ~lola: lola, ~children: React.element) =>
                <section>
                  <h1> {React.string(lola.name)} </h1>
                  <p> {React.int(initial)} </p>
                  <div> children </div>
                </section>;
              let make_client = props =>
                React.createElement(
                  make,
                  {
                    "children":
                      RSC.Primitives.react_element_of_rsc(props##children),
                    "lola": lola_of_rsc(props##lola),
                    "initial": RSC.Primitives.int_of_rsc(props##initial),
                  },
                );
            };
    module Very_nested = {
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
                                Stdlib.(===)(
                                  Obj.magic(x): Js.null('a),
                                  Js.null,
                                ),
                              ),
                            ),
                          ),
                        )) {
                      RSC.of_rsc_error(~rsc=x, "expected an object");
                    };
                    let fs: {. "name": Js.undefined(RSC.t) } = Obj.magic(x);
                    {
                      name:
                        switch (Js.Undefined.toOption(fs##name)) {
                        | Stdlib.Option.Some(v) =>
                          RSC.Primitives.string_of_rsc(v)
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
                          let bnds__005_ = [];
                          let bnds__005_ = [
                            ("name", RSC.Primitives.string_to_rsc(x_name)),
                            ...bnds__005_,
                          ];
                          bnds__005_;
                        },
                      )
                    };
                let _ = lola_to_rsc;
              };
  
      include {
                [%%raw
                  "// extract-client input.re InnerBeforeNested.Very_nested"
                ];
                [@react.component]
                let make =
                    (~initial: int, ~lola: lola, ~children: React.element) =>
                  <section>
                    <h1> {React.string(lola.name)} </h1>
                    <p> {React.int(initial)} </p>
                    <div> children </div>
                  </section>;
                let make_client = props =>
                  React.createElement(
                    make,
                    {
                      "children":
                        RSC.Primitives.react_element_of_rsc(props##children),
                      "lola": lola_of_rsc(props##lola),
                      "initial": RSC.Primitives.int_of_rsc(props##initial),
                    },
                  );
              };
    };
  };
