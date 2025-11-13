  $ ../ppx.sh --output re input.re
  let lower = React.createElement("div", [], []);
  let lower_empty_attr =
    React.createElement(
      "div",
      Stdlib.List.filter_map(
        Stdlib.Fun.id,
        [
          Some(
            [@implicit_arity]
            React.JSX.String("class", "className", "": string),
          ),
        ],
      ),
      [],
    );
  let lower_inline_styles =
    React.createElement(
      "div",
      Stdlib.List.filter_map(
        Stdlib.Fun.id,
        [
          Some(
            React.JSX.Style(
              ReactDOM.Style.make(~backgroundColor="gainsboro", ()): ReactDOM.Style.t,
            ),
          ),
        ],
      ),
      [],
    );
  let lower_inner_html =
    React.createElement(
      "div",
      Stdlib.List.filter_map(
        Stdlib.Fun.id,
        [Some(React.JSX.dangerouslyInnerHtml({"__html": text}))],
      ),
      [],
    );
  let lower_opt_attr =
    React.createElement(
      "div",
      Stdlib.List.filter_map(
        Stdlib.Fun.id,
        [
          switch ((tabIndex: option(int))) {
          | None => None
          | Some(v) =>
            Some(
              [@implicit_arity]
              React.JSX.String(
                "tabindex",
                "tabIndex",
                Stdlib.Int.to_string(v),
              ),
            )
          },
        ],
      ),
      [],
    );
  let lowerWithChildAndProps = foo =>
    React.createElement(
      "a",
      Stdlib.List.filter_map(
        Stdlib.Fun.id,
        [
          Some(
            [@implicit_arity]
            React.JSX.String(
              "tabindex",
              "tabIndex",
              Stdlib.Int.to_string(1: int),
            ),
          ),
          Some(
            [@implicit_arity]
            React.JSX.String("href", "href", "https://example.com": string),
          ),
        ],
      ),
      [foo],
    );
  let lower_child_static =
    React.createElement("div", [], [React.createElement("span", [], [])]);
  let lower_child_ident = React.createElement("div", [], [lolaspa]);
  let lower_child_single =
    React.createElement("div", [], [React.createElement("div", [], [])]);
  let lower_children_multiple = (foo, bar) =>
    React.createElement("lower", [], [foo, bar]);
  let lower_child_with_upper_as_children =
    React.createElement("div", [], [App.make()]);
  let lower_children_nested =
    React.createElement(
      "div",
      Stdlib.List.filter_map(
        Stdlib.Fun.id,
        [
          Some(
            [@implicit_arity]
            React.JSX.String("class", "className", "flex-container": string),
          ),
        ],
      ),
      [
        React.createElement(
          "div",
          Stdlib.List.filter_map(
            Stdlib.Fun.id,
            [
              Some(
                [@implicit_arity]
                React.JSX.String("class", "className", "sidebar": string),
              ),
            ],
          ),
          [
            React.createElement(
              "h2",
              Stdlib.List.filter_map(
                Stdlib.Fun.id,
                [
                  Some(
                    [@implicit_arity]
                    React.JSX.String("class", "className", "title": string),
                  ),
                ],
              ),
              ["jsoo-react" |> s],
            ),
            React.createElement(
              "nav",
              Stdlib.List.filter_map(
                Stdlib.Fun.id,
                [
                  Some(
                    [@implicit_arity]
                    React.JSX.String("class", "className", "menu": string),
                  ),
                ],
              ),
              [
                React.createElement(
                  "ul",
                  [],
                  [
                    examples
                    |> List.map(e =>
                         React.createElementWithKey(
                           ~key=e.path,
                           "li",
                           Stdlib.List.filter_map(
                             Stdlib.Fun.id,
                             [
                               Some(
                                 [@implicit_arity]
                                 React.JSX.String("key", "key", e.path: string),
                               ),
                             ],
                           ),
                           [
                             React.createElement(
                               "a",
                               Stdlib.List.filter_map(
                                 Stdlib.Fun.id,
                                 [
                                   Some(
                                     [@implicit_arity]
                                     React.JSX.String(
                                       "href",
                                       "href",
                                       e.path: string,
                                     ),
                                   ),
                                   Some(
                                     [@implicit_arity]
                                     React.JSX.Event(
                                       "onClick",
                                       React.JSX.Mouse(
                                         event => {
                                           React.Event.Mouse.preventDefault(
                                             event,
                                           );
                                           ReactRouter.push(e.path);
                                         }: React.Event.Mouse.t => unit,
                                       ),
                                     ),
                                   ),
                                 ],
                               ),
                               [e.title |> s],
                             ),
                           ],
                         )
                       )
                    |> React.list,
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  let lower_ref_with_children =
    React.createElement(
      "button",
      Stdlib.List.filter_map(
        Stdlib.Fun.id,
        [
          Some(React.JSX.Ref(ref: React.domRef)),
          Some(
            [@implicit_arity]
            React.JSX.String("class", "className", "FancyButton": string),
          ),
        ],
      ),
      [children],
    );
  let lower_with_many_props =
    React.createElement(
      "div",
      Stdlib.List.filter_map(
        Stdlib.Fun.id,
        [
          Some(
            [@implicit_arity]
            React.JSX.String("translate", "translate", "yes": string),
          ),
        ],
      ),
      [
        React.createElement(
          "picture",
          Stdlib.List.filter_map(
            Stdlib.Fun.id,
            [
              Some(
                [@implicit_arity]
                React.JSX.String("id", "id", "idpicture": string),
              ),
            ],
          ),
          [
            React.createElement(
              "img",
              Stdlib.List.filter_map(
                Stdlib.Fun.id,
                [
                  Some(
                    [@implicit_arity]
                    React.JSX.String("src", "src", "picture/img.png": string),
                  ),
                  Some(
                    [@implicit_arity]
                    React.JSX.String(
                      "alt",
                      "alt",
                      "test picture/img.png": string,
                    ),
                  ),
                  Some(
                    [@implicit_arity]
                    React.JSX.String("id", "id", "idimg": string),
                  ),
                ],
              ),
              [],
            ),
            React.createElement(
              "source",
              Stdlib.List.filter_map(
                Stdlib.Fun.id,
                [
                  Some(
                    [@implicit_arity]
                    React.JSX.String("type", "type", "image/webp": string),
                  ),
                  Some(
                    [@implicit_arity]
                    React.JSX.String("src", "src", "picture/img1.webp": string),
                  ),
                ],
              ),
              [],
            ),
            React.createElement(
              "source",
              Stdlib.List.filter_map(
                Stdlib.Fun.id,
                [
                  Some(
                    [@implicit_arity]
                    React.JSX.String("type", "type", "image/jpeg": string),
                  ),
                  Some(
                    [@implicit_arity]
                    React.JSX.String("src", "src", "picture/img2.jpg": string),
                  ),
                ],
              ),
              [],
            ),
          ],
        ),
      ],
    );
  let some_random_html_element =
    React.createElement(
      "text",
      Stdlib.List.filter_map(
        Stdlib.Fun.id,
        [
          Some([@implicit_arity] React.JSX.String("dx", "dx", "1 2": string)),
          Some([@implicit_arity] React.JSX.String("dy", "dy", "3 4": string)),
        ],
      ),
      [],
    );
  let div =
    React.createElement(
      "div",
      Stdlib.List.filter_map(
        Stdlib.Fun.id,
        [
          switch ((onClick: option(React.Event.Mouse.t => unit))) {
          | None => None
          | Some(v) =>
            Some(
              [@implicit_arity] React.JSX.Event("onClick", React.JSX.Mouse(v)),
            )
          },
        ],
      ),
      [],
    );
  let self_closing_tag_with_children = [%ocaml.error
    "\"meta\" is a self-closing tag and must not have \"children\".\\n"
  ];
  let self_closing_tag_with_dangerouslySetInnerHtml = [%ocaml.error
    "server-reason-react: \"meta\" is a self-closing tag and must not have \"children\".\\n"
  ];
