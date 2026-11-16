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
    React.Static({
      prerendered: "<div style=\"background-color:gainsboro\"></div>",
      original:
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
        ),
    });
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
    (
      __jsx_value__001_ =>
        React.Writer({
          emit: (__buf, ~separators as _) => {
            Buffer.add_string(__buf, "<div");
            switch ((__jsx_value__001_: option(int))) {
            | None => ()
            | Some(v) =>
              Buffer.add_char(__buf, ' ');
              Buffer.add_string(__buf, "tabindex");
              Buffer.add_string(__buf, "=\"");
              ReactDOM.write_int_to_buffer(__buf, v: int);
              Buffer.add_char(__buf, '"');
            };
            Buffer.add_string(__buf, "></div>");
            ();
          },
          original: () =>
            React.createElement(
              "div",
              Stdlib.List.filter_map(
                Stdlib.Fun.id,
                [
                  switch ((__jsx_value__001_: option(int))) {
                  | None => None
                  | Some(v) =>
                    Some(
                      [@implicit_arity]
                      React.JSX.Int("tabindex", "tabIndex", v),
                    )
                  },
                ],
              ),
              [],
            ),
        })
    )(
      tabIndex,
    );
  let lowerWithChildAndProps = foo =>
    (
      __jsx_value__002_ =>
        React.Writer({
          emit: (__buf, ~separators as __separators) => {
            Buffer.add_string(
              __buf,
              "<a tabindex=\"1\" href=\"https://example.com\">",
            );
            {
              let (_: bool) =
                ReactDOM.write_element_to_buffer_internal(
                  __buf,
                  ~separators=__separators,
                  ~prev_text=false,
                  __jsx_value__002_,
                );
              ();
            };
            Buffer.add_string(__buf, "</a>");
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
                    React.JSX.Int("tabindex", "tabIndex", 1: int),
                  ),
                  Some(
                    [@implicit_arity]
                    React.JSX.String(
                      "href",
                      "href",
                      "https://example.com": string,
                    ),
                  ),
                ],
              ),
              [__jsx_value__002_],
            ),
        })
    )(
      foo,
    );
  let lower_child_static =
    (
      __jsx_value__003_ =>
        React.Writer({
          emit: (__buf, ~separators as __separators) => {
            Buffer.add_string(__buf, "<div>");
            {
              let (_: bool) =
                ReactDOM.write_element_to_buffer_internal(
                  __buf,
                  ~separators=__separators,
                  ~prev_text=false,
                  __jsx_value__003_,
                );
              ();
            };
            Buffer.add_string(__buf, "</div>");
            ();
          },
          original: () => React.createElement("div", [], [__jsx_value__003_]),
        })
    )(
      React.Static({
        prerendered: "<span></span>",
        original: React.createElement("span", [], []),
      }),
    );
  let lower_child_ident =
    (
      __jsx_value__004_ =>
        React.Writer({
          emit: (__buf, ~separators as __separators) => {
            Buffer.add_string(__buf, "<div>");
            {
              let (_: bool) =
                ReactDOM.write_element_to_buffer_internal(
                  __buf,
                  ~separators=__separators,
                  ~prev_text=false,
                  __jsx_value__004_,
                );
              ();
            };
            Buffer.add_string(__buf, "</div>");
            ();
          },
          original: () => React.createElement("div", [], [__jsx_value__004_]),
        })
    )(
      lolaspa,
    );
  let lower_child_single =
    (
      __jsx_value__005_ =>
        React.Writer({
          emit: (__buf, ~separators as __separators) => {
            Buffer.add_string(__buf, "<div>");
            {
              let (_: bool) =
                ReactDOM.write_element_to_buffer_internal(
                  __buf,
                  ~separators=__separators,
                  ~prev_text=false,
                  __jsx_value__005_,
                );
              ();
            };
            Buffer.add_string(__buf, "</div>");
            ();
          },
          original: () => React.createElement("div", [], [__jsx_value__005_]),
        })
    )(
      React.Static({
        prerendered: "<div></div>",
        original: React.createElement("div", [], []),
      }),
    );
  let lower_children_multiple = (foo, bar) =>
    (
      (__jsx_value__006_, __jsx_value__007_) =>
        React.Writer({
          emit: (__buf, ~separators as __separators) => {
            let __prev_text = ref(false);
            Buffer.add_string(__buf, "<lower>");
            __prev_text :=
              ReactDOM.write_element_to_buffer_internal(
                __buf,
                ~separators=__separators,
                ~prev_text=false,
                __jsx_value__006_,
              );
            __prev_text :=
              ReactDOM.write_element_to_buffer_internal(
                __buf,
                ~separators=__separators,
                ~prev_text=__prev_text^,
                __jsx_value__007_,
              );
            Buffer.add_string(__buf, "</lower>");
            ();
          },
          original: () =>
            React.createElement(
              "lower",
              [],
              [__jsx_value__006_, __jsx_value__007_],
            ),
        })
    )(
      foo,
      bar,
    );
  let lower_child_with_upper_as_children =
    (
      __jsx_value__008_ =>
        React.Writer({
          emit: (__buf, ~separators as __separators) => {
            Buffer.add_string(__buf, "<div>");
            {
              let (_: bool) =
                ReactDOM.write_element_to_buffer_internal(
                  __buf,
                  ~separators=__separators,
                  ~prev_text=false,
                  __jsx_value__008_,
                );
              ();
            };
            Buffer.add_string(__buf, "</div>");
            ();
          },
          original: () => React.createElement("div", [], [__jsx_value__008_]),
        })
    )(
      App.make(App.makeProps()),
    );
  let lower_children_nested =
    (
      __jsx_value__019_ =>
        React.Writer({
          emit: (__buf, ~separators as __separators) => {
            Buffer.add_string(__buf, "<div class=\"flex-container\">");
            {
              let (_: bool) =
                ReactDOM.write_element_to_buffer_internal(
                  __buf,
                  ~separators=__separators,
                  ~prev_text=false,
                  __jsx_value__019_,
                );
              ();
            };
            Buffer.add_string(__buf, "</div>");
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
              [__jsx_value__019_],
            ),
        })
    )(
      (
        (__jsx_value__017_, __jsx_value__018_) =>
          React.Writer({
            emit: (__buf, ~separators as __separators) => {
              let __prev_text = ref(false);
              Buffer.add_string(__buf, "<div class=\"sidebar\">");
              __prev_text :=
                ReactDOM.write_element_to_buffer_internal(
                  __buf,
                  ~separators=__separators,
                  ~prev_text=false,
                  __jsx_value__017_,
                );
              __prev_text :=
                ReactDOM.write_element_to_buffer_internal(
                  __buf,
                  ~separators=__separators,
                  ~prev_text=__prev_text^,
                  __jsx_value__018_,
                );
              Buffer.add_string(__buf, "</div>");
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
                [__jsx_value__017_, __jsx_value__018_],
              ),
          })
      )(
        (
          __jsx_value__009_ =>
            React.Writer({
              emit: (__buf, ~separators as __separators) => {
                Buffer.add_string(__buf, "<h2 class=\"title\">");
                {
                  let (_: bool) =
                    ReactDOM.write_element_to_buffer_internal(
                      __buf,
                      ~separators=__separators,
                      ~prev_text=false,
                      __jsx_value__009_,
                    );
                  ();
                };
                Buffer.add_string(__buf, "</h2>");
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
                        React.JSX.String("class", "className", "title": string),
                      ),
                    ],
                  ),
                  [__jsx_value__009_],
                ),
            })
        )(
          "jsoo-react" |> s,
        ),
        (
          __jsx_value__016_ =>
            React.Writer({
              emit: (__buf, ~separators as __separators) => {
                Buffer.add_string(__buf, "<nav class=\"menu\">");
                {
                  let (_: bool) =
                    ReactDOM.write_element_to_buffer_internal(
                      __buf,
                      ~separators=__separators,
                      ~prev_text=false,
                      __jsx_value__016_,
                    );
                  ();
                };
                Buffer.add_string(__buf, "</nav>");
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
                        React.JSX.String("class", "className", "menu": string),
                      ),
                    ],
                  ),
                  [__jsx_value__016_],
                ),
            })
        )(
          (
            __jsx_value__015_ =>
              React.Writer({
                emit: (__buf, ~separators as __separators) => {
                  Buffer.add_string(__buf, "<ul>");
                  {
                    let (_: bool) =
                      ReactDOM.write_element_to_buffer_internal(
                        __buf,
                        ~separators=__separators,
                        ~prev_text=false,
                        __jsx_value__015_,
                      );
                    ();
                  };
                  Buffer.add_string(__buf, "</ul>");
                  ();
                },
                original: () =>
                  React.createElement("ul", [], [__jsx_value__015_]),
              })
          )(
            examples
            |> List.map(e =>
                 (
                   (__jsx_value__013_, __jsx_value__014_) =>
                     React.Writer({
                       emit: (__buf, ~separators as __separators) => {
                         Buffer.add_string(__buf, "<li>");
                         {
                           let (_: bool) =
                             ReactDOM.write_element_to_buffer_internal(
                               __buf,
                               ~separators=__separators,
                               ~prev_text=false,
                               __jsx_value__014_,
                             );
                           ();
                         };
                         Buffer.add_string(__buf, "</li>");
                         ();
                       },
                       original: () =>
                         React.createElementWithKey(
                           ~key=__jsx_value__013_,
                           "li",
                           Stdlib.List.filter_map(
                             Stdlib.Fun.id,
                             [
                               Some(
                                 [@implicit_arity]
                                 React.JSX.String(
                                   "key",
                                   "key",
                                   __jsx_value__013_: string,
                                 ),
                               ),
                             ],
                           ),
                           [__jsx_value__014_],
                         ),
                     })
                 )(
                   e.path,
                   (
                     (__jsx_value__010_, __jsx_value__011_, __jsx_value__012_) =>
                       React.Writer({
                         emit: (__buf, ~separators as __separators) => {
                           Buffer.add_string(__buf, "<a");
                           {
                             Buffer.add_char(__buf, ' ');
                             Buffer.add_string(__buf, "href");
                             Buffer.add_string(__buf, "=\"");
                             ReactDOM.escape_to_buffer(
                               __buf,
                               __jsx_value__010_: string,
                             );
                             Buffer.add_char(__buf, '"');
                           };
                           Buffer.add_string(__buf, ">");
                           {
                             let (_: bool) =
                               ReactDOM.write_element_to_buffer_internal(
                                 __buf,
                                 ~separators=__separators,
                                 ~prev_text=false,
                                 __jsx_value__012_,
                               );
                             ();
                           };
                           Buffer.add_string(__buf, "</a>");
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
                                     "href",
                                     "href",
                                     __jsx_value__010_: string,
                                   ),
                                 ),
                                 Some(
                                   [@implicit_arity]
                                   React.JSX.Event(
                                     "onClick",
                                     React.JSX.Mouse(
                                       __jsx_value__011_:
                                                          React.Event.Mouse.t =>
                                                          unit,
                                     ),
                                   ),
                                 ),
                               ],
                             ),
                             [__jsx_value__012_],
                           ),
                       })
                   )(
                     e.path,
                     event => {
                       React.Event.Mouse.preventDefault(event);
                       ReactRouter.push(e.path);
                     },
                     e.title |> s,
                   ),
                 )
               )
            |> React.list,
          ),
        ),
      ),
    );
  let lower_ref_with_children =
    (
      (__jsx_value__020_, __jsx_value__021_) =>
        React.Writer({
          emit: (__buf, ~separators as __separators) => {
            Buffer.add_string(__buf, "<button class=\"FancyButton\">");
            {
              let (_: bool) =
                ReactDOM.write_element_to_buffer_internal(
                  __buf,
                  ~separators=__separators,
                  ~prev_text=false,
                  __jsx_value__021_,
                );
              ();
            };
            Buffer.add_string(__buf, "</button>");
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
                    React.JSX.String(
                      "class",
                      "className",
                      "FancyButton": string,
                    ),
                  ),
                  Some(React.JSX.Ref(__jsx_value__020_: React.domRef)),
                ],
              ),
              [__jsx_value__021_],
            ),
        })
    )(
      ref,
      children,
    );
  let lower_with_many_props =
    (
      __jsx_value__025_ =>
        React.Writer({
          emit: (__buf, ~separators as __separators) => {
            Buffer.add_string(__buf, "<div translate=\"yes\">");
            {
              let (_: bool) =
                ReactDOM.write_element_to_buffer_internal(
                  __buf,
                  ~separators=__separators,
                  ~prev_text=false,
                  __jsx_value__025_,
                );
              ();
            };
            Buffer.add_string(__buf, "</div>");
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
              [__jsx_value__025_],
            ),
        })
    )(
      (
        (__jsx_value__022_, __jsx_value__023_, __jsx_value__024_) =>
          React.Writer({
            emit: (__buf, ~separators as __separators) => {
              let __prev_text = ref(false);
              Buffer.add_string(__buf, "<picture id=\"idpicture\">");
              __prev_text :=
                ReactDOM.write_element_to_buffer_internal(
                  __buf,
                  ~separators=__separators,
                  ~prev_text=false,
                  __jsx_value__022_,
                );
              __prev_text :=
                ReactDOM.write_element_to_buffer_internal(
                  __buf,
                  ~separators=__separators,
                  ~prev_text=__prev_text^,
                  __jsx_value__023_,
                );
              __prev_text :=
                ReactDOM.write_element_to_buffer_internal(
                  __buf,
                  ~separators=__separators,
                  ~prev_text=__prev_text^,
                  __jsx_value__024_,
                );
              Buffer.add_string(__buf, "</picture>");
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
                [__jsx_value__022_, __jsx_value__023_, __jsx_value__024_],
              ),
          })
      )(
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
        }),
      ),
    );
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
    React.Static({
      prerendered: "<div></div>",
      original:
        React.createElement(
          "div",
          Stdlib.List.filter_map(
            Stdlib.Fun.id,
            [
              switch ((onClick: option(React.Event.Mouse.t => unit))) {
              | None => None
              | Some(v) =>
                Some(
                  [@implicit_arity]
                  React.JSX.Event("onClick", React.JSX.Mouse(v)),
                )
              },
            ],
          ),
          [],
        ),
    });
  let self_closing_tag_with_children = [%ocaml.error
    "server-reason-react: \"meta\" is a self-closing tag and must not have \"children\"."
  ];
  let self_closing_tag_with_dangerouslySetInnerHtml = [%ocaml.error
    "server-reason-react: \"meta\" is a self-closing tag and must not have \"dangerouslySetInnerHTML\"."
  ];
