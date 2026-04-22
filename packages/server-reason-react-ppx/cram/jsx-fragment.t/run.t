  $ ../ppx.sh --output re input.re
  let fragment = foo => [@bla] React.fragment(React.list([foo]));
  let poly_children_fragment = (foo, bar) =>
    React.fragment(React.list([foo, bar]));
  let nested_fragment = (foo, bar, baz) =>
    React.fragment(
      React.list([foo, React.fragment(React.list([bar, baz]))]),
    );
  let nested_fragment_with_lower = foo =>
    React.fragment(
      React.list([
        React.Writer({
          emit: b => {
            Buffer.add_string(b, "<div>");
            ReactDOM.write_to_buffer(b, foo);
            Buffer.add_string(b, "</div>");
            ();
          },
          original: () => React.createElement("div", [], [foo]),
        }),
      ]),
    );
  module Fragment = {
    include {
              let makeProps = (~name: option('name)=?, ()) => {
                let (__js_obj_cell_0, __js_obj_entry_0) =
                  Js.Obj.Internal.slot_ref(
                    ~method_name="name",
                    ~js_name="name",
                    ~present=
                      switch (name) {
                      | None => false
                      | Some(_) => true
                      },
                    name,
                  );
                let __js_obj = { as _; pub name = __js_obj_cell_0^ };
                (
                  Js.Obj.Internal.register_abstract(
                    __js_obj,
                    [__js_obj_entry_0],
                  ): {
                    .
                    "name": option('name),
                  }
                );
              };
              let make = (~key as _: option(string)=?, ~name="", ()) =>
                [@implicit_arity]
                React.Upper_case_component(
                  Stdlib.__FUNCTION__,
                  () =>
                    React.fragment(
                      React.list([
                        React.Writer({
                          emit: b => {
                            Buffer.add_string(b, "<div>");
                            ReactDOM.escape_to_buffer(b, "First " ++ name);
                            Buffer.add_string(b, "</div>");
                            ();
                          },
                          original: () =>
                            React.createElement(
                              "div",
                              [],
                              [React.string("First " ++ name)],
                            ),
                        }),
                        Hello.make(
                          Hello.makeProps(
                            ~children=React.string("2nd " ++ name),
                            ~one="1",
                            (),
                          ),
                        ),
                      ]),
                    ),
                );
              let make =
                  (~key: option(string)=?, Props: {. "name": option('name) }) =>
                make(~key?, ~name=?Props#name, ());
            };
  };
