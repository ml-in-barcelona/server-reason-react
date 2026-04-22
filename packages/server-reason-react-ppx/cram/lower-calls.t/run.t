  $ ../ppx.sh --output re input.re
  let lower =
    React.Static({
      prerendered: "<div></div>",
      original: React.createElement("div", [], []),
    });
  let lower_empty_attr =
    React.Static({
      prerendered: "<div class=\"\"></div>",
      original:
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
        ),
    });
  let lower_inline_styles =
    React.createElement(
      "div",
      Stdlib.List.filter_map(
        Stdlib.Fun.id,
        [
          Some(
            React.JSX.Style(
              (
                [
                  ("background-color", "backgroundColor", "gainsboro"),
                  ...([]: list((string, string, string))),
                ]: ReactDOM.Style.t
              ): ReactDOM.Style.t,
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
        [Some(React.JSX.dangerouslyInnerHtml({ "__html": text }))],
      ),
      [],
    );
  let lower_opt_attr =
    React.Writer({
      emit: b => {
        Buffer.add_string(b, "<div");
        switch (tabIndex) {
        | None => ()
        | Some(v) =>
          Buffer.add_char(b, ' ');
          Buffer.add_string(b, "tabindex");
          Buffer.add_string(b, "=\"");
          Printf.bprintf(b, "%d", v: int);
          Buffer.add_char(b, '"');
        };
        Buffer.add_string(b, "></div>");
        ();
      },
      original: () =>
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
        ),
    });
  let lowerWithChildAndProps = foo =>
    React.Writer({
      emit: b => {
        Buffer.add_string(b, "<a tabindex=\"1\" href=\"https://example.com\">");
        ReactDOM.write_to_buffer(b, foo);
        Buffer.add_string(b, "</a>");
        ();
      },
      original: () =>
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
        ),
    });
  let lower_child_static =
    React.Writer({
      emit: b => {
        Buffer.add_string(b, "<div>");
        ReactDOM.write_to_buffer(
          b,
          React.Static({
            prerendered: "<span></span>",
            original: React.createElement("span", [], []),
          }),
        );
        Buffer.add_string(b, "</div>");
        ();
      },
      original: () =>
        React.createElement(
          "div",
          [],
          [
            React.Static({
              prerendered: "<span></span>",
              original: React.createElement("span", [], []),
            }),
          ],
        ),
    });
  let lower_child_ident =
    React.Writer({
      emit: b => {
        Buffer.add_string(b, "<div>");
        ReactDOM.write_to_buffer(b, lolaspa);
        Buffer.add_string(b, "</div>");
        ();
      },
      original: () => React.createElement("div", [], [lolaspa]),
    });
  let lower_child_single =
    React.Writer({
      emit: b => {
        Buffer.add_string(b, "<div>");
        ReactDOM.write_to_buffer(
          b,
          React.Static({
            prerendered: "<div></div>",
            original: React.createElement("div", [], []),
          }),
        );
        Buffer.add_string(b, "</div>");
        ();
      },
      original: () =>
        React.createElement(
          "div",
          [],
          [
            React.Static({
              prerendered: "<div></div>",
              original: React.createElement("div", [], []),
            }),
          ],
        ),
    });
  let lower_children_multiple = (foo, bar) =>
    React.Writer({
      emit: b => {
        Buffer.add_string(b, "<lower>");
        ReactDOM.write_to_buffer(b, foo);
        ReactDOM.write_to_buffer(b, bar);
        Buffer.add_string(b, "</lower>");
        ();
      },
      original: () => React.createElement("lower", [], [foo, bar]),
    });
  let lower_child_with_upper_as_children =
    React.Writer({
      emit: b => {
        Buffer.add_string(b, "<div>");
        ReactDOM.write_to_buffer(b, App.make(App.makeProps()));
        Buffer.add_string(b, "</div>");
        ();
      },
      original: () =>
        React.createElement("div", [], [App.make(App.makeProps())]),
    });
  let lower_children_nested =
    React.Writer({
      emit: b => {
        Buffer.add_string(b, "<div class=\"flex-container\">");
        ReactDOM.write_to_buffer(
          b,
          React.Writer({
            emit: b => {
              Buffer.add_string(b, "<div class=\"sidebar\">");
              ReactDOM.write_to_buffer(
                b,
                React.Writer({
                  emit: b => {
                    Buffer.add_string(b, "<h2 class=\"title\">");
                    ReactDOM.write_to_buffer(b, "jsoo-react" |> s);
                    Buffer.add_string(b, "</h2>");
                    ();
                  },
                  original: () =>
                    React.createElement(
                      "h2",
                      Stdlib.List.filter_map(
                        Stdlib.Fun.id,
                        [
                          Some(
                            [@implicit_arity]
                            React.JSX.String(
                              "class",
                              "className",
                              "title": string,
                            ),
                          ),
                        ],
                      ),
                      ["jsoo-react" |> s],
                    ),
                }),
              );
              ReactDOM.write_to_buffer(
                b,
                React.Writer({
                  emit: b => {
                    Buffer.add_string(b, "<nav class=\"menu\">");
                    ReactDOM.write_to_buffer(
                      b,
                      React.Writer({
                        emit: b => {
                          Buffer.add_string(b, "<ul>");
                          ReactDOM.write_to_buffer(
                            b,
                            examples
                            |> List.map(e =>
                                 React.Writer({
                                   emit: b => {
                                     Buffer.add_string(b, "<li>");
                                     ReactDOM.write_to_buffer(
                                       b,
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
                                                   }:
                                                      React.Event.Mouse.t => unit,
                                                 ),
                                               ),
                                             ),
                                           ],
                                         ),
                                         [e.title |> s],
                                       ),
                                     );
                                     Buffer.add_string(b, "</li>");
                                     ();
                                   },
                                   original: () =>
                                     React.createElementWithKey(
                                       ~key=e.path,
                                       "li",
                                       Stdlib.List.filter_map(
                                         Stdlib.Fun.id,
                                         [
                                           Some(
                                             [@implicit_arity]
                                             React.JSX.String(
                                               "key",
                                               "key",
                                               e.path: string,
                                             ),
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
                                                     }:
                                                        React.Event.Mouse.t =>
                                                        unit,
                                                   ),
                                                 ),
                                               ),
                                             ],
                                           ),
                                           [e.title |> s],
                                         ),
                                       ],
                                     ),
                                 })
                               )
                            |> React.list,
                          );
                          Buffer.add_string(b, "</ul>");
                          ();
                        },
                        original: () =>
                          React.createElement(
                            "ul",
                            [],
                            [
                              examples
                              |> List.map(e =>
                                   React.Writer({
                                     emit: b => {
                                       Buffer.add_string(b, "<li>");
                                       ReactDOM.write_to_buffer(
                                         b,
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
                                                     }:
                                                        React.Event.Mouse.t =>
                                                        unit,
                                                   ),
                                                 ),
                                               ),
                                             ],
                                           ),
                                           [e.title |> s],
                                         ),
                                       );
                                       Buffer.add_string(b, "</li>");
                                       ();
                                     },
                                     original: () =>
                                       React.createElementWithKey(
                                         ~key=e.path,
                                         "li",
                                         Stdlib.List.filter_map(
                                           Stdlib.Fun.id,
                                           [
                                             Some(
                                               [@implicit_arity]
                                               React.JSX.String(
                                                 "key",
                                                 "key",
                                                 e.path: string,
                                               ),
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
                                                         ReactRouter.push(
                                                           e.path,
                                                         );
                                                       }:
                                                          React.Event.Mouse.t =>
                                                          unit,
                                                     ),
                                                   ),
                                                 ),
                                               ],
                                             ),
                                             [e.title |> s],
                                           ),
                                         ],
                                       ),
                                   })
                                 )
                              |> React.list,
                            ],
                          ),
                      }),
                    );
                    Buffer.add_string(b, "</nav>");
                    ();
                  },
                  original: () =>
                    React.createElement(
                      "nav",
                      Stdlib.List.filter_map(
                        Stdlib.Fun.id,
                        [
                          Some(
                            [@implicit_arity]
                            React.JSX.String(
                              "class",
                              "className",
                              "menu": string,
                            ),
                          ),
                        ],
                      ),
                      [
                        React.Writer({
                          emit: b => {
                            Buffer.add_string(b, "<ul>");
                            ReactDOM.write_to_buffer(
                              b,
                              examples
                              |> List.map(e =>
                                   React.Writer({
                                     emit: b => {
                                       Buffer.add_string(b, "<li>");
                                       ReactDOM.write_to_buffer(
                                         b,
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
                                                     }:
                                                        React.Event.Mouse.t =>
                                                        unit,
                                                   ),
                                                 ),
                                               ),
                                             ],
                                           ),
                                           [e.title |> s],
                                         ),
                                       );
                                       Buffer.add_string(b, "</li>");
                                       ();
                                     },
                                     original: () =>
                                       React.createElementWithKey(
                                         ~key=e.path,
                                         "li",
                                         Stdlib.List.filter_map(
                                           Stdlib.Fun.id,
                                           [
                                             Some(
                                               [@implicit_arity]
                                               React.JSX.String(
                                                 "key",
                                                 "key",
                                                 e.path: string,
                                               ),
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
                                                         ReactRouter.push(
                                                           e.path,
                                                         );
                                                       }:
                                                          React.Event.Mouse.t =>
                                                          unit,
                                                     ),
                                                   ),
                                                 ),
                                               ],
                                             ),
                                             [e.title |> s],
                                           ),
                                         ],
                                       ),
                                   })
                                 )
                              |> React.list,
                            );
                            Buffer.add_string(b, "</ul>");
                            ();
                          },
                          original: () =>
                            React.createElement(
                              "ul",
                              [],
                              [
                                examples
                                |> List.map(e =>
                                     React.Writer({
                                       emit: b => {
                                         Buffer.add_string(b, "<li>");
                                         ReactDOM.write_to_buffer(
                                           b,
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
                                                         ReactRouter.push(
                                                           e.path,
                                                         );
                                                       }:
                                                          React.Event.Mouse.t =>
                                                          unit,
                                                     ),
                                                   ),
                                                 ),
                                               ],
                                             ),
                                             [e.title |> s],
                                           ),
                                         );
                                         Buffer.add_string(b, "</li>");
                                         ();
                                       },
                                       original: () =>
                                         React.createElementWithKey(
                                           ~key=e.path,
                                           "li",
                                           Stdlib.List.filter_map(
                                             Stdlib.Fun.id,
                                             [
                                               Some(
                                                 [@implicit_arity]
                                                 React.JSX.String(
                                                   "key",
                                                   "key",
                                                   e.path: string,
                                                 ),
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
                                                           ReactRouter.push(
                                                             e.path,
                                                           );
                                                         }:
                                                            React.Event.Mouse.t =>
                                                            unit,
                                                       ),
                                                     ),
                                                   ),
                                                 ],
                                               ),
                                               [e.title |> s],
                                             ),
                                           ],
                                         ),
                                     })
                                   )
                                |> React.list,
                              ],
                            ),
                        }),
                      ],
                    ),
                }),
              );
              Buffer.add_string(b, "</div>");
              ();
            },
            original: () =>
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
                  React.Writer({
                    emit: b => {
                      Buffer.add_string(b, "<h2 class=\"title\">");
                      ReactDOM.write_to_buffer(b, "jsoo-react" |> s);
                      Buffer.add_string(b, "</h2>");
                      ();
                    },
                    original: () =>
                      React.createElement(
                        "h2",
                        Stdlib.List.filter_map(
                          Stdlib.Fun.id,
                          [
                            Some(
                              [@implicit_arity]
                              React.JSX.String(
                                "class",
                                "className",
                                "title": string,
                              ),
                            ),
                          ],
                        ),
                        ["jsoo-react" |> s],
                      ),
                  }),
                  React.Writer({
                    emit: b => {
                      Buffer.add_string(b, "<nav class=\"menu\">");
                      ReactDOM.write_to_buffer(
                        b,
                        React.Writer({
                          emit: b => {
                            Buffer.add_string(b, "<ul>");
                            ReactDOM.write_to_buffer(
                              b,
                              examples
                              |> List.map(e =>
                                   React.Writer({
                                     emit: b => {
                                       Buffer.add_string(b, "<li>");
                                       ReactDOM.write_to_buffer(
                                         b,
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
                                                     }:
                                                        React.Event.Mouse.t =>
                                                        unit,
                                                   ),
                                                 ),
                                               ),
                                             ],
                                           ),
                                           [e.title |> s],
                                         ),
                                       );
                                       Buffer.add_string(b, "</li>");
                                       ();
                                     },
                                     original: () =>
                                       React.createElementWithKey(
                                         ~key=e.path,
                                         "li",
                                         Stdlib.List.filter_map(
                                           Stdlib.Fun.id,
                                           [
                                             Some(
                                               [@implicit_arity]
                                               React.JSX.String(
                                                 "key",
                                                 "key",
                                                 e.path: string,
                                               ),
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
                                                         ReactRouter.push(
                                                           e.path,
                                                         );
                                                       }:
                                                          React.Event.Mouse.t =>
                                                          unit,
                                                     ),
                                                   ),
                                                 ),
                                               ],
                                             ),
                                             [e.title |> s],
                                           ),
                                         ],
                                       ),
                                   })
                                 )
                              |> React.list,
                            );
                            Buffer.add_string(b, "</ul>");
                            ();
                          },
                          original: () =>
                            React.createElement(
                              "ul",
                              [],
                              [
                                examples
                                |> List.map(e =>
                                     React.Writer({
                                       emit: b => {
                                         Buffer.add_string(b, "<li>");
                                         ReactDOM.write_to_buffer(
                                           b,
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
                                                         ReactRouter.push(
                                                           e.path,
                                                         );
                                                       }:
                                                          React.Event.Mouse.t =>
                                                          unit,
                                                     ),
                                                   ),
                                                 ),
                                               ],
                                             ),
                                             [e.title |> s],
                                           ),
                                         );
                                         Buffer.add_string(b, "</li>");
                                         ();
                                       },
                                       original: () =>
                                         React.createElementWithKey(
                                           ~key=e.path,
                                           "li",
                                           Stdlib.List.filter_map(
                                             Stdlib.Fun.id,
                                             [
                                               Some(
                                                 [@implicit_arity]
                                                 React.JSX.String(
                                                   "key",
                                                   "key",
                                                   e.path: string,
                                                 ),
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
                                                           ReactRouter.push(
                                                             e.path,
                                                           );
                                                         }:
                                                            React.Event.Mouse.t =>
                                                            unit,
                                                       ),
                                                     ),
                                                   ),
                                                 ],
                                               ),
                                               [e.title |> s],
                                             ),
                                           ],
                                         ),
                                     })
                                   )
                                |> React.list,
                              ],
                            ),
                        }),
                      );
                      Buffer.add_string(b, "</nav>");
                      ();
                    },
                    original: () =>
                      React.createElement(
                        "nav",
                        Stdlib.List.filter_map(
                          Stdlib.Fun.id,
                          [
                            Some(
                              [@implicit_arity]
                              React.JSX.String(
                                "class",
                                "className",
                                "menu": string,
                              ),
                            ),
                          ],
                        ),
                        [
                          React.Writer({
                            emit: b => {
                              Buffer.add_string(b, "<ul>");
                              ReactDOM.write_to_buffer(
                                b,
                                examples
                                |> List.map(e =>
                                     React.Writer({
                                       emit: b => {
                                         Buffer.add_string(b, "<li>");
                                         ReactDOM.write_to_buffer(
                                           b,
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
                                                         ReactRouter.push(
                                                           e.path,
                                                         );
                                                       }:
                                                          React.Event.Mouse.t =>
                                                          unit,
                                                     ),
                                                   ),
                                                 ),
                                               ],
                                             ),
                                             [e.title |> s],
                                           ),
                                         );
                                         Buffer.add_string(b, "</li>");
                                         ();
                                       },
                                       original: () =>
                                         React.createElementWithKey(
                                           ~key=e.path,
                                           "li",
                                           Stdlib.List.filter_map(
                                             Stdlib.Fun.id,
                                             [
                                               Some(
                                                 [@implicit_arity]
                                                 React.JSX.String(
                                                   "key",
                                                   "key",
                                                   e.path: string,
                                                 ),
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
                                                           ReactRouter.push(
                                                             e.path,
                                                           );
                                                         }:
                                                            React.Event.Mouse.t =>
                                                            unit,
                                                       ),
                                                     ),
                                                   ),
                                                 ],
                                               ),
                                               [e.title |> s],
                                             ),
                                           ],
                                         ),
                                     })
                                   )
                                |> React.list,
                              );
                              Buffer.add_string(b, "</ul>");
                              ();
                            },
                            original: () =>
                              React.createElement(
                                "ul",
                                [],
                                [
                                  examples
                                  |> List.map(e =>
                                       React.Writer({
                                         emit: b => {
                                           Buffer.add_string(b, "<li>");
                                           ReactDOM.write_to_buffer(
                                             b,
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
                                                           ReactRouter.push(
                                                             e.path,
                                                           );
                                                         }:
                                                            React.Event.Mouse.t =>
                                                            unit,
                                                       ),
                                                     ),
                                                   ),
                                                 ],
                                               ),
                                               [e.title |> s],
                                             ),
                                           );
                                           Buffer.add_string(b, "</li>");
                                           ();
                                         },
                                         original: () =>
                                           React.createElementWithKey(
                                             ~key=e.path,
                                             "li",
                                             Stdlib.List.filter_map(
                                               Stdlib.Fun.id,
                                               [
                                                 Some(
                                                   [@implicit_arity]
                                                   React.JSX.String(
                                                     "key",
                                                     "key",
                                                     e.path: string,
                                                   ),
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
                                                             ReactRouter.push(
                                                               e.path,
                                                             );
                                                           }:
                                                              React.Event.Mouse.t =>
                                                              unit,
                                                         ),
                                                       ),
                                                     ),
                                                   ],
                                                 ),
                                                 [e.title |> s],
                                               ),
                                             ],
                                           ),
                                       })
                                     )
                                  |> React.list,
                                ],
                              ),
                          }),
                        ],
                      ),
                  }),
                ],
              ),
          }),
        );
        Buffer.add_string(b, "</div>");
        ();
      },
      original: () =>
        React.createElement(
          "div",
          Stdlib.List.filter_map(
            Stdlib.Fun.id,
            [
              Some(
                [@implicit_arity]
                React.JSX.String(
                  "class",
                  "className",
                  "flex-container": string,
                ),
              ),
            ],
          ),
          [
            React.Writer({
              emit: b => {
                Buffer.add_string(b, "<div class=\"sidebar\">");
                ReactDOM.write_to_buffer(
                  b,
                  React.Writer({
                    emit: b => {
                      Buffer.add_string(b, "<h2 class=\"title\">");
                      ReactDOM.write_to_buffer(b, "jsoo-react" |> s);
                      Buffer.add_string(b, "</h2>");
                      ();
                    },
                    original: () =>
                      React.createElement(
                        "h2",
                        Stdlib.List.filter_map(
                          Stdlib.Fun.id,
                          [
                            Some(
                              [@implicit_arity]
                              React.JSX.String(
                                "class",
                                "className",
                                "title": string,
                              ),
                            ),
                          ],
                        ),
                        ["jsoo-react" |> s],
                      ),
                  }),
                );
                ReactDOM.write_to_buffer(
                  b,
                  React.Writer({
                    emit: b => {
                      Buffer.add_string(b, "<nav class=\"menu\">");
                      ReactDOM.write_to_buffer(
                        b,
                        React.Writer({
                          emit: b => {
                            Buffer.add_string(b, "<ul>");
                            ReactDOM.write_to_buffer(
                              b,
                              examples
                              |> List.map(e =>
                                   React.Writer({
                                     emit: b => {
                                       Buffer.add_string(b, "<li>");
                                       ReactDOM.write_to_buffer(
                                         b,
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
                                                     }:
                                                        React.Event.Mouse.t =>
                                                        unit,
                                                   ),
                                                 ),
                                               ),
                                             ],
                                           ),
                                           [e.title |> s],
                                         ),
                                       );
                                       Buffer.add_string(b, "</li>");
                                       ();
                                     },
                                     original: () =>
                                       React.createElementWithKey(
                                         ~key=e.path,
                                         "li",
                                         Stdlib.List.filter_map(
                                           Stdlib.Fun.id,
                                           [
                                             Some(
                                               [@implicit_arity]
                                               React.JSX.String(
                                                 "key",
                                                 "key",
                                                 e.path: string,
                                               ),
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
                                                         ReactRouter.push(
                                                           e.path,
                                                         );
                                                       }:
                                                          React.Event.Mouse.t =>
                                                          unit,
                                                     ),
                                                   ),
                                                 ),
                                               ],
                                             ),
                                             [e.title |> s],
                                           ),
                                         ],
                                       ),
                                   })
                                 )
                              |> React.list,
                            );
                            Buffer.add_string(b, "</ul>");
                            ();
                          },
                          original: () =>
                            React.createElement(
                              "ul",
                              [],
                              [
                                examples
                                |> List.map(e =>
                                     React.Writer({
                                       emit: b => {
                                         Buffer.add_string(b, "<li>");
                                         ReactDOM.write_to_buffer(
                                           b,
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
                                                         ReactRouter.push(
                                                           e.path,
                                                         );
                                                       }:
                                                          React.Event.Mouse.t =>
                                                          unit,
                                                     ),
                                                   ),
                                                 ),
                                               ],
                                             ),
                                             [e.title |> s],
                                           ),
                                         );
                                         Buffer.add_string(b, "</li>");
                                         ();
                                       },
                                       original: () =>
                                         React.createElementWithKey(
                                           ~key=e.path,
                                           "li",
                                           Stdlib.List.filter_map(
                                             Stdlib.Fun.id,
                                             [
                                               Some(
                                                 [@implicit_arity]
                                                 React.JSX.String(
                                                   "key",
                                                   "key",
                                                   e.path: string,
                                                 ),
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
                                                           ReactRouter.push(
                                                             e.path,
                                                           );
                                                         }:
                                                            React.Event.Mouse.t =>
                                                            unit,
                                                       ),
                                                     ),
                                                   ),
                                                 ],
                                               ),
                                               [e.title |> s],
                                             ),
                                           ],
                                         ),
                                     })
                                   )
                                |> React.list,
                              ],
                            ),
                        }),
                      );
                      Buffer.add_string(b, "</nav>");
                      ();
                    },
                    original: () =>
                      React.createElement(
                        "nav",
                        Stdlib.List.filter_map(
                          Stdlib.Fun.id,
                          [
                            Some(
                              [@implicit_arity]
                              React.JSX.String(
                                "class",
                                "className",
                                "menu": string,
                              ),
                            ),
                          ],
                        ),
                        [
                          React.Writer({
                            emit: b => {
                              Buffer.add_string(b, "<ul>");
                              ReactDOM.write_to_buffer(
                                b,
                                examples
                                |> List.map(e =>
                                     React.Writer({
                                       emit: b => {
                                         Buffer.add_string(b, "<li>");
                                         ReactDOM.write_to_buffer(
                                           b,
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
                                                         ReactRouter.push(
                                                           e.path,
                                                         );
                                                       }:
                                                          React.Event.Mouse.t =>
                                                          unit,
                                                     ),
                                                   ),
                                                 ),
                                               ],
                                             ),
                                             [e.title |> s],
                                           ),
                                         );
                                         Buffer.add_string(b, "</li>");
                                         ();
                                       },
                                       original: () =>
                                         React.createElementWithKey(
                                           ~key=e.path,
                                           "li",
                                           Stdlib.List.filter_map(
                                             Stdlib.Fun.id,
                                             [
                                               Some(
                                                 [@implicit_arity]
                                                 React.JSX.String(
                                                   "key",
                                                   "key",
                                                   e.path: string,
                                                 ),
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
                                                           ReactRouter.push(
                                                             e.path,
                                                           );
                                                         }:
                                                            React.Event.Mouse.t =>
                                                            unit,
                                                       ),
                                                     ),
                                                   ),
                                                 ],
                                               ),
                                               [e.title |> s],
                                             ),
                                           ],
                                         ),
                                     })
                                   )
                                |> React.list,
                              );
                              Buffer.add_string(b, "</ul>");
                              ();
                            },
                            original: () =>
                              React.createElement(
                                "ul",
                                [],
                                [
                                  examples
                                  |> List.map(e =>
                                       React.Writer({
                                         emit: b => {
                                           Buffer.add_string(b, "<li>");
                                           ReactDOM.write_to_buffer(
                                             b,
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
                                                           ReactRouter.push(
                                                             e.path,
                                                           );
                                                         }:
                                                            React.Event.Mouse.t =>
                                                            unit,
                                                       ),
                                                     ),
                                                   ),
                                                 ],
                                               ),
                                               [e.title |> s],
                                             ),
                                           );
                                           Buffer.add_string(b, "</li>");
                                           ();
                                         },
                                         original: () =>
                                           React.createElementWithKey(
                                             ~key=e.path,
                                             "li",
                                             Stdlib.List.filter_map(
                                               Stdlib.Fun.id,
                                               [
                                                 Some(
                                                   [@implicit_arity]
                                                   React.JSX.String(
                                                     "key",
                                                     "key",
                                                     e.path: string,
                                                   ),
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
                                                             ReactRouter.push(
                                                               e.path,
                                                             );
                                                           }:
                                                              React.Event.Mouse.t =>
                                                              unit,
                                                         ),
                                                       ),
                                                     ),
                                                   ],
                                                 ),
                                                 [e.title |> s],
                                               ),
                                             ],
                                           ),
                                       })
                                     )
                                  |> React.list,
                                ],
                              ),
                          }),
                        ],
                      ),
                  }),
                );
                Buffer.add_string(b, "</div>");
                ();
              },
              original: () =>
                React.createElement(
                  "div",
                  Stdlib.List.filter_map(
                    Stdlib.Fun.id,
                    [
                      Some(
                        [@implicit_arity]
                        React.JSX.String(
                          "class",
                          "className",
                          "sidebar": string,
                        ),
                      ),
                    ],
                  ),
                  [
                    React.Writer({
                      emit: b => {
                        Buffer.add_string(b, "<h2 class=\"title\">");
                        ReactDOM.write_to_buffer(b, "jsoo-react" |> s);
                        Buffer.add_string(b, "</h2>");
                        ();
                      },
                      original: () =>
                        React.createElement(
                          "h2",
                          Stdlib.List.filter_map(
                            Stdlib.Fun.id,
                            [
                              Some(
                                [@implicit_arity]
                                React.JSX.String(
                                  "class",
                                  "className",
                                  "title": string,
                                ),
                              ),
                            ],
                          ),
                          ["jsoo-react" |> s],
                        ),
                    }),
                    React.Writer({
                      emit: b => {
                        Buffer.add_string(b, "<nav class=\"menu\">");
                        ReactDOM.write_to_buffer(
                          b,
                          React.Writer({
                            emit: b => {
                              Buffer.add_string(b, "<ul>");
                              ReactDOM.write_to_buffer(
                                b,
                                examples
                                |> List.map(e =>
                                     React.Writer({
                                       emit: b => {
                                         Buffer.add_string(b, "<li>");
                                         ReactDOM.write_to_buffer(
                                           b,
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
                                                         ReactRouter.push(
                                                           e.path,
                                                         );
                                                       }:
                                                          React.Event.Mouse.t =>
                                                          unit,
                                                     ),
                                                   ),
                                                 ),
                                               ],
                                             ),
                                             [e.title |> s],
                                           ),
                                         );
                                         Buffer.add_string(b, "</li>");
                                         ();
                                       },
                                       original: () =>
                                         React.createElementWithKey(
                                           ~key=e.path,
                                           "li",
                                           Stdlib.List.filter_map(
                                             Stdlib.Fun.id,
                                             [
                                               Some(
                                                 [@implicit_arity]
                                                 React.JSX.String(
                                                   "key",
                                                   "key",
                                                   e.path: string,
                                                 ),
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
                                                           ReactRouter.push(
                                                             e.path,
                                                           );
                                                         }:
                                                            React.Event.Mouse.t =>
                                                            unit,
                                                       ),
                                                     ),
                                                   ),
                                                 ],
                                               ),
                                               [e.title |> s],
                                             ),
                                           ],
                                         ),
                                     })
                                   )
                                |> React.list,
                              );
                              Buffer.add_string(b, "</ul>");
                              ();
                            },
                            original: () =>
                              React.createElement(
                                "ul",
                                [],
                                [
                                  examples
                                  |> List.map(e =>
                                       React.Writer({
                                         emit: b => {
                                           Buffer.add_string(b, "<li>");
                                           ReactDOM.write_to_buffer(
                                             b,
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
                                                           ReactRouter.push(
                                                             e.path,
                                                           );
                                                         }:
                                                            React.Event.Mouse.t =>
                                                            unit,
                                                       ),
                                                     ),
                                                   ),
                                                 ],
                                               ),
                                               [e.title |> s],
                                             ),
                                           );
                                           Buffer.add_string(b, "</li>");
                                           ();
                                         },
                                         original: () =>
                                           React.createElementWithKey(
                                             ~key=e.path,
                                             "li",
                                             Stdlib.List.filter_map(
                                               Stdlib.Fun.id,
                                               [
                                                 Some(
                                                   [@implicit_arity]
                                                   React.JSX.String(
                                                     "key",
                                                     "key",
                                                     e.path: string,
                                                   ),
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
                                                             ReactRouter.push(
                                                               e.path,
                                                             );
                                                           }:
                                                              React.Event.Mouse.t =>
                                                              unit,
                                                         ),
                                                       ),
                                                     ),
                                                   ],
                                                 ),
                                                 [e.title |> s],
                                               ),
                                             ],
                                           ),
                                       })
                                     )
                                  |> React.list,
                                ],
                              ),
                          }),
                        );
                        Buffer.add_string(b, "</nav>");
                        ();
                      },
                      original: () =>
                        React.createElement(
                          "nav",
                          Stdlib.List.filter_map(
                            Stdlib.Fun.id,
                            [
                              Some(
                                [@implicit_arity]
                                React.JSX.String(
                                  "class",
                                  "className",
                                  "menu": string,
                                ),
                              ),
                            ],
                          ),
                          [
                            React.Writer({
                              emit: b => {
                                Buffer.add_string(b, "<ul>");
                                ReactDOM.write_to_buffer(
                                  b,
                                  examples
                                  |> List.map(e =>
                                       React.Writer({
                                         emit: b => {
                                           Buffer.add_string(b, "<li>");
                                           ReactDOM.write_to_buffer(
                                             b,
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
                                                           ReactRouter.push(
                                                             e.path,
                                                           );
                                                         }:
                                                            React.Event.Mouse.t =>
                                                            unit,
                                                       ),
                                                     ),
                                                   ),
                                                 ],
                                               ),
                                               [e.title |> s],
                                             ),
                                           );
                                           Buffer.add_string(b, "</li>");
                                           ();
                                         },
                                         original: () =>
                                           React.createElementWithKey(
                                             ~key=e.path,
                                             "li",
                                             Stdlib.List.filter_map(
                                               Stdlib.Fun.id,
                                               [
                                                 Some(
                                                   [@implicit_arity]
                                                   React.JSX.String(
                                                     "key",
                                                     "key",
                                                     e.path: string,
                                                   ),
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
                                                             ReactRouter.push(
                                                               e.path,
                                                             );
                                                           }:
                                                              React.Event.Mouse.t =>
                                                              unit,
                                                         ),
                                                       ),
                                                     ),
                                                   ],
                                                 ),
                                                 [e.title |> s],
                                               ),
                                             ],
                                           ),
                                       })
                                     )
                                  |> React.list,
                                );
                                Buffer.add_string(b, "</ul>");
                                ();
                              },
                              original: () =>
                                React.createElement(
                                  "ul",
                                  [],
                                  [
                                    examples
                                    |> List.map(e =>
                                         React.Writer({
                                           emit: b => {
                                             Buffer.add_string(b, "<li>");
                                             ReactDOM.write_to_buffer(
                                               b,
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
                                                             ReactRouter.push(
                                                               e.path,
                                                             );
                                                           }:
                                                              React.Event.Mouse.t =>
                                                              unit,
                                                         ),
                                                       ),
                                                     ),
                                                   ],
                                                 ),
                                                 [e.title |> s],
                                               ),
                                             );
                                             Buffer.add_string(b, "</li>");
                                             ();
                                           },
                                           original: () =>
                                             React.createElementWithKey(
                                               ~key=e.path,
                                               "li",
                                               Stdlib.List.filter_map(
                                                 Stdlib.Fun.id,
                                                 [
                                                   Some(
                                                     [@implicit_arity]
                                                     React.JSX.String(
                                                       "key",
                                                       "key",
                                                       e.path: string,
                                                     ),
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
                                                               ReactRouter.push(
                                                                 e.path,
                                                               );
                                                             }:
                                                                React.Event.Mouse.t =>
                                                                unit,
                                                           ),
                                                         ),
                                                       ),
                                                     ],
                                                   ),
                                                   [e.title |> s],
                                                 ),
                                               ],
                                             ),
                                         })
                                       )
                                    |> React.list,
                                  ],
                                ),
                            }),
                          ],
                        ),
                    }),
                  ],
                ),
            }),
          ],
        ),
    });
  let lower_ref_with_children =
    React.Writer({
      emit: b => {
        Buffer.add_string(b, "<button class=\"FancyButton\">");
        ReactDOM.write_to_buffer(b, children);
        Buffer.add_string(b, "</button>");
        ();
      },
      original: () =>
        React.createElement(
          "button",
          Stdlib.List.filter_map(
            Stdlib.Fun.id,
            [
              Some(
                [@implicit_arity]
                React.JSX.String("class", "className", "FancyButton": string),
              ),
              Some(React.JSX.Ref(ref: React.domRef)),
            ],
          ),
          [children],
        ),
    });
  let lower_with_many_props =
    React.Writer({
      emit: b => {
        Buffer.add_string(b, "<div translate=\"yes\">");
        ReactDOM.write_to_buffer(
          b,
          React.Writer({
            emit: b => {
              Buffer.add_string(b, "<picture id=\"idpicture\">");
              ReactDOM.write_to_buffer(
                b,
                React.Static({
                  prerendered: "<img src=\"picture/img.png\" alt=\"test picture/img.png\" id=\"idimg\" />",
                  original:
                    React.createElement(
                      "img",
                      Stdlib.List.filter_map(
                        Stdlib.Fun.id,
                        [
                          Some(
                            [@implicit_arity]
                            React.JSX.String(
                              "src",
                              "src",
                              "picture/img.png": string,
                            ),
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
                }),
              );
              ReactDOM.write_to_buffer(
                b,
                React.Static({
                  prerendered: "<source type=\"image/webp\" src=\"picture/img1.webp\" />",
                  original:
                    React.createElement(
                      "source",
                      Stdlib.List.filter_map(
                        Stdlib.Fun.id,
                        [
                          Some(
                            [@implicit_arity]
                            React.JSX.String(
                              "type",
                              "type",
                              "image/webp": string,
                            ),
                          ),
                          Some(
                            [@implicit_arity]
                            React.JSX.String(
                              "src",
                              "src",
                              "picture/img1.webp": string,
                            ),
                          ),
                        ],
                      ),
                      [],
                    ),
                }),
              );
              ReactDOM.write_to_buffer(
                b,
                React.Static({
                  prerendered: "<source type=\"image/jpeg\" src=\"picture/img2.jpg\" />",
                  original:
                    React.createElement(
                      "source",
                      Stdlib.List.filter_map(
                        Stdlib.Fun.id,
                        [
                          Some(
                            [@implicit_arity]
                            React.JSX.String(
                              "type",
                              "type",
                              "image/jpeg": string,
                            ),
                          ),
                          Some(
                            [@implicit_arity]
                            React.JSX.String(
                              "src",
                              "src",
                              "picture/img2.jpg": string,
                            ),
                          ),
                        ],
                      ),
                      [],
                    ),
                }),
              );
              Buffer.add_string(b, "</picture>");
              ();
            },
            original: () =>
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
                  React.Static({
                    prerendered: "<img src=\"picture/img.png\" alt=\"test picture/img.png\" id=\"idimg\" />",
                    original:
                      React.createElement(
                        "img",
                        Stdlib.List.filter_map(
                          Stdlib.Fun.id,
                          [
                            Some(
                              [@implicit_arity]
                              React.JSX.String(
                                "src",
                                "src",
                                "picture/img.png": string,
                              ),
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
                  }),
                  React.Static({
                    prerendered: "<source type=\"image/webp\" src=\"picture/img1.webp\" />",
                    original:
                      React.createElement(
                        "source",
                        Stdlib.List.filter_map(
                          Stdlib.Fun.id,
                          [
                            Some(
                              [@implicit_arity]
                              React.JSX.String(
                                "type",
                                "type",
                                "image/webp": string,
                              ),
                            ),
                            Some(
                              [@implicit_arity]
                              React.JSX.String(
                                "src",
                                "src",
                                "picture/img1.webp": string,
                              ),
                            ),
                          ],
                        ),
                        [],
                      ),
                  }),
                  React.Static({
                    prerendered: "<source type=\"image/jpeg\" src=\"picture/img2.jpg\" />",
                    original:
                      React.createElement(
                        "source",
                        Stdlib.List.filter_map(
                          Stdlib.Fun.id,
                          [
                            Some(
                              [@implicit_arity]
                              React.JSX.String(
                                "type",
                                "type",
                                "image/jpeg": string,
                              ),
                            ),
                            Some(
                              [@implicit_arity]
                              React.JSX.String(
                                "src",
                                "src",
                                "picture/img2.jpg": string,
                              ),
                            ),
                          ],
                        ),
                        [],
                      ),
                  }),
                ],
              ),
          }),
        );
        Buffer.add_string(b, "</div>");
        ();
      },
      original: () =>
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
            React.Writer({
              emit: b => {
                Buffer.add_string(b, "<picture id=\"idpicture\">");
                ReactDOM.write_to_buffer(
                  b,
                  React.Static({
                    prerendered: "<img src=\"picture/img.png\" alt=\"test picture/img.png\" id=\"idimg\" />",
                    original:
                      React.createElement(
                        "img",
                        Stdlib.List.filter_map(
                          Stdlib.Fun.id,
                          [
                            Some(
                              [@implicit_arity]
                              React.JSX.String(
                                "src",
                                "src",
                                "picture/img.png": string,
                              ),
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
                  }),
                );
                ReactDOM.write_to_buffer(
                  b,
                  React.Static({
                    prerendered: "<source type=\"image/webp\" src=\"picture/img1.webp\" />",
                    original:
                      React.createElement(
                        "source",
                        Stdlib.List.filter_map(
                          Stdlib.Fun.id,
                          [
                            Some(
                              [@implicit_arity]
                              React.JSX.String(
                                "type",
                                "type",
                                "image/webp": string,
                              ),
                            ),
                            Some(
                              [@implicit_arity]
                              React.JSX.String(
                                "src",
                                "src",
                                "picture/img1.webp": string,
                              ),
                            ),
                          ],
                        ),
                        [],
                      ),
                  }),
                );
                ReactDOM.write_to_buffer(
                  b,
                  React.Static({
                    prerendered: "<source type=\"image/jpeg\" src=\"picture/img2.jpg\" />",
                    original:
                      React.createElement(
                        "source",
                        Stdlib.List.filter_map(
                          Stdlib.Fun.id,
                          [
                            Some(
                              [@implicit_arity]
                              React.JSX.String(
                                "type",
                                "type",
                                "image/jpeg": string,
                              ),
                            ),
                            Some(
                              [@implicit_arity]
                              React.JSX.String(
                                "src",
                                "src",
                                "picture/img2.jpg": string,
                              ),
                            ),
                          ],
                        ),
                        [],
                      ),
                  }),
                );
                Buffer.add_string(b, "</picture>");
                ();
              },
              original: () =>
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
                    React.Static({
                      prerendered: "<img src=\"picture/img.png\" alt=\"test picture/img.png\" id=\"idimg\" />",
                      original:
                        React.createElement(
                          "img",
                          Stdlib.List.filter_map(
                            Stdlib.Fun.id,
                            [
                              Some(
                                [@implicit_arity]
                                React.JSX.String(
                                  "src",
                                  "src",
                                  "picture/img.png": string,
                                ),
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
                    }),
                    React.Static({
                      prerendered: "<source type=\"image/webp\" src=\"picture/img1.webp\" />",
                      original:
                        React.createElement(
                          "source",
                          Stdlib.List.filter_map(
                            Stdlib.Fun.id,
                            [
                              Some(
                                [@implicit_arity]
                                React.JSX.String(
                                  "type",
                                  "type",
                                  "image/webp": string,
                                ),
                              ),
                              Some(
                                [@implicit_arity]
                                React.JSX.String(
                                  "src",
                                  "src",
                                  "picture/img1.webp": string,
                                ),
                              ),
                            ],
                          ),
                          [],
                        ),
                    }),
                    React.Static({
                      prerendered: "<source type=\"image/jpeg\" src=\"picture/img2.jpg\" />",
                      original:
                        React.createElement(
                          "source",
                          Stdlib.List.filter_map(
                            Stdlib.Fun.id,
                            [
                              Some(
                                [@implicit_arity]
                                React.JSX.String(
                                  "type",
                                  "type",
                                  "image/jpeg": string,
                                ),
                              ),
                              Some(
                                [@implicit_arity]
                                React.JSX.String(
                                  "src",
                                  "src",
                                  "picture/img2.jpg": string,
                                ),
                              ),
                            ],
                          ),
                          [],
                        ),
                    }),
                  ],
                ),
            }),
          ],
        ),
    });
  let some_random_html_element =
    React.Static({
      prerendered: "<text dx=\"1 2\" dy=\"3 4\"></text>",
      original:
        React.createElement(
          "text",
          Stdlib.List.filter_map(
            Stdlib.Fun.id,
            [
              Some(
                [@implicit_arity] React.JSX.String("dx", "dx", "1 2": string),
              ),
              Some(
                [@implicit_arity] React.JSX.String("dy", "dy", "3 4": string),
              ),
            ],
          ),
          [],
        ),
    });
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
