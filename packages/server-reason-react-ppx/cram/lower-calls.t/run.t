  $ ../ppx.sh --output re input.re
  let lower = React.createElementWithKey(~key=None, "div", [], []);
  let lower_empty_attr =
    React.createElementWithKey(
      ~key=None,
      "div",
      Stdlib.List.filter_map(
        Fun.id,
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
    React.createElementWithKey(
      ~key=None,
      "div",
      Stdlib.List.filter_map(
        Fun.id,
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
    React.createElementWithKey(
      ~key=None,
      "div",
      Stdlib.List.filter_map(
        Fun.id,
        [Some(React.JSX.dangerouslyInnerHtml({"__html": text}))],
      ),
      [],
    );
  let lower_opt_attr =
    React.createElementWithKey(
      ~key=None,
      "div",
      Stdlib.List.filter_map(
        Fun.id,
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
    React.createElementWithKey(
      ~key=None,
      "a",
      Stdlib.List.filter_map(
        Fun.id,
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
    React.createElementWithKey(
      ~key=None,
      "div",
      [],
      [React.createElementWithKey(~key=None, "span", [], [])],
    );
  let lower_child_ident =
    React.createElementWithKey(~key=None, "div", [], [lolaspa]);
  let lower_child_single =
    React.createElementWithKey(
      ~key=None,
      "div",
      [],
      [React.createElementWithKey(~key=None, "div", [], [])],
    );
  let lower_children_multiple = (foo, bar) =>
    React.createElementWithKey(~key=None, "lower", [], [foo, bar]);
  let lower_child_with_upper_as_children =
    React.createElementWithKey(~key=None, "div", [], [App.make()]);
  let lower_children_nested =
    React.createElementWithKey(
      ~key=None,
      "div",
      Stdlib.List.filter_map(
        Fun.id,
        [
          Some(
            [@implicit_arity]
            React.JSX.String("class", "className", "flex-container": string),
          ),
        ],
      ),
      [
        React.createElementWithKey(
          ~key=None,
          "div",
          Stdlib.List.filter_map(
            Fun.id,
            [
              Some(
                [@implicit_arity]
                React.JSX.String("class", "className", "sidebar": string),
              ),
            ],
          ),
          [
            React.createElementWithKey(
              ~key=None,
              "h2",
              Stdlib.List.filter_map(
                Fun.id,
                [
                  Some(
                    [@implicit_arity]
                    React.JSX.String("class", "className", "title": string),
                  ),
                ],
              ),
              ["jsoo-react" |> s],
            ),
            React.createElementWithKey(
              ~key=None,
              "nav",
              Stdlib.List.filter_map(
                Fun.id,
                [
                  Some(
                    [@implicit_arity]
                    React.JSX.String("class", "className", "menu": string),
                  ),
                ],
              ),
              [
                React.createElementWithKey(
                  ~key=None,
                  "ul",
                  [],
                  [
                    examples
                    |> List.map(e =>
                         React.createElementWithKey(
                           ~key=Some(e.path),
                           "li",
                           Stdlib.List.filter_map(
                             Fun.id,
                             [
                               Some(
                                 [@implicit_arity]
                                 React.JSX.String("key", "key", e.path: string),
                               ),
                             ],
                           ),
                           [
                             React.createElementWithKey(
                               ~key=None,
                               "a",
                               Stdlib.List.filter_map(
                                 Fun.id,
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
    React.createElementWithKey(
      ~key=None,
      "button",
      Stdlib.List.filter_map(
        Fun.id,
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
    React.createElementWithKey(
      ~key=None,
      "div",
      Stdlib.List.filter_map(
        Fun.id,
        [
          Some(
            [@implicit_arity]
            React.JSX.String("translate", "translate", "yes": string),
          ),
        ],
      ),
      [
        React.createElementWithKey(
          ~key=None,
          "picture",
          Stdlib.List.filter_map(
            Fun.id,
            [
              Some(
                [@implicit_arity]
                React.JSX.String("id", "id", "idpicture": string),
              ),
            ],
          ),
          [
            React.createElementWithKey(
              ~key=None,
              "img",
              Stdlib.List.filter_map(
                Fun.id,
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
            React.createElementWithKey(
              ~key=None,
              "source",
              Stdlib.List.filter_map(
                Fun.id,
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
            React.createElementWithKey(
              ~key=None,
              "source",
              Stdlib.List.filter_map(
                Fun.id,
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
    React.createElementWithKey(
      ~key=None,
      "text",
      Stdlib.List.filter_map(
        Fun.id,
        [
          Some([@implicit_arity] React.JSX.String("dx", "dx", "1 2": string)),
          Some([@implicit_arity] React.JSX.String("dy", "dy", "3 4": string)),
        ],
      ),
      [],
    );
  let div =
    React.createElementWithKey(
      ~key=None,
      "div",
      Stdlib.List.filter_map(
        Fun.id,
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
