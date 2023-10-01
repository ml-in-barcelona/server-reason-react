  $ ../ppx.sh --output re input.re
  let lower =
    React.createElement(
      "div",
      [||] |> Array.to_list |> List.filter_map(a => a) |> Array.of_list,
      [],
    );
  let lower_empty_attr =
    React.createElement(
      "div",
      [|Some([@implicit_arity] React.JSX.String("class", "": string))|]
      |> Array.to_list
      |> List.filter_map(a => a)
      |> Array.of_list,
      [],
    );
  let lower_inline_styles =
    React.createElement(
      "div",
      [|
        Some(
          React.JSX.Style(
            ReactDOM.Style.to_string(
              ReactDOM.Style.make(~backgroundColor="gainsboro", ()),
            ),
          ),
        ),
      |]
      |> Array.to_list
      |> List.filter_map(a => a)
      |> Array.of_list,
      [],
    );
  let lower_inner_html =
    React.createElement(
      "div",
      [|Some(React.JSX.DangerouslyInnerHtml(text))|]
      |> Array.to_list
      |> List.filter_map(a => a)
      |> Array.of_list,
      [],
    );
  let lower_opt_attr =
    React.createElement(
      "div",
      [|
        Option.map(
          v =>
            [@implicit_arity] React.JSX.String("tabIndex", string_of_int(v)),
          tabIndex: option(int),
        ),
      |]
      |> Array.to_list
      |> List.filter_map(a => a)
      |> Array.of_list,
      [],
    );
  let lowerWithChildAndProps = foo =>
    React.createElement(
      "a",
      [|
        Some(
          [@implicit_arity]
          React.JSX.String("tabIndex", string_of_int(1: int)),
        ),
        Some(
          [@implicit_arity]
          React.JSX.String("href", "https://example.com": string),
        ),
      |]
      |> Array.to_list
      |> List.filter_map(a => a)
      |> Array.of_list,
      [foo],
    );
  let lower_child_static =
    React.createElement(
      "div",
      [||] |> Array.to_list |> List.filter_map(a => a) |> Array.of_list,
      [
        React.createElement(
          "span",
          [||] |> Array.to_list |> List.filter_map(a => a) |> Array.of_list,
          [],
        ),
      ],
    );
  let lower_child_ident =
    React.createElement(
      "div",
      [||] |> Array.to_list |> List.filter_map(a => a) |> Array.of_list,
      [lolaspa],
    );
  let lower_child_single =
    React.createElement(
      "div",
      [||] |> Array.to_list |> List.filter_map(a => a) |> Array.of_list,
      [
        React.createElement(
          "div",
          [||] |> Array.to_list |> List.filter_map(a => a) |> Array.of_list,
          [],
        ),
      ],
    );
  let lower_children_multiple = (foo, bar) =>
    React.createElement(
      "lower",
      [||] |> Array.to_list |> List.filter_map(a => a) |> Array.of_list,
      [foo, bar],
    );
  let lower_child_with_upper_as_children =
    React.createElement(
      "div",
      [||] |> Array.to_list |> List.filter_map(a => a) |> Array.of_list,
      [React.Upper_case_component(() => App.make())],
    );
  let lower_children_nested =
    React.createElement(
      "div",
      [|
        Some(
          [@implicit_arity] React.JSX.String("class", "flex-container": string),
        ),
      |]
      |> Array.to_list
      |> List.filter_map(a => a)
      |> Array.of_list,
      [
        React.createElement(
          "div",
          [|
            Some(
              [@implicit_arity] React.JSX.String("class", "sidebar": string),
            ),
          |]
          |> Array.to_list
          |> List.filter_map(a => a)
          |> Array.of_list,
          [
            React.createElement(
              "h2",
              [|
                Some(
                  [@implicit_arity] React.JSX.String("class", "title": string),
                ),
              |]
              |> Array.to_list
              |> List.filter_map(a => a)
              |> Array.of_list,
              ["jsoo-react" |> s],
            ),
            React.createElement(
              "nav",
              [|
                Some(
                  [@implicit_arity] React.JSX.String("class", "menu": string),
                ),
              |]
              |> Array.to_list
              |> List.filter_map(a => a)
              |> Array.of_list,
              [
                React.createElement(
                  "ul",
                  [||]
                  |> Array.to_list
                  |> List.filter_map(a => a)
                  |> Array.of_list,
                  [
                    examples
                    |> List.map(e =>
                         React.createElement(
                           "li",
                           [|
                             Some(
                               [@implicit_arity]
                               React.JSX.String("key", e.path: string),
                             ),
                           |]
                           |> Array.to_list
                           |> List.filter_map(a => a)
                           |> Array.of_list,
                           [
                             React.createElement(
                               "a",
                               [|
                                 Some(
                                   [@implicit_arity]
                                   React.JSX.String("href", e.path: string),
                                 ),
                                 Some(
                                   [@implicit_arity]
                                   React.JSX.Event(
                                     "onClick",
                                     React.JSX.Mouse(
                                       event => {
                                         ReactEvent.Mouse.preventDefault(event);
                                         ReactRouter.push(e.path);
                                       }: ReactEvent.Mouse.t => unit,
                                     ),
                                   ),
                                 ),
                               |]
                               |> Array.to_list
                               |> List.filter_map(a => a)
                               |> Array.of_list,
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
      [|
        Some(React.JSX.Ref(ref)),
        Some(
          [@implicit_arity] React.JSX.String("class", "FancyButton": string),
        ),
      |]
      |> Array.to_list
      |> List.filter_map(a => a)
      |> Array.of_list,
      [children],
    );
  let lower_with_many_props =
    React.createElement(
      "div",
      [|Some([@implicit_arity] React.JSX.String("translate", "yes": string))|]
      |> Array.to_list
      |> List.filter_map(a => a)
      |> Array.of_list,
      [
        React.createElement(
          "picture",
          [|
            Some(
              [@implicit_arity] React.JSX.String("id", "idpicture": string),
            ),
          |]
          |> Array.to_list
          |> List.filter_map(a => a)
          |> Array.of_list,
          [
            React.createElement(
              "img",
              [|
                Some(
                  [@implicit_arity]
                  React.JSX.String("src", "picture/img.png": string),
                ),
                Some(
                  [@implicit_arity]
                  React.JSX.String("alt", "test picture/img.png": string),
                ),
                Some(
                  [@implicit_arity] React.JSX.String("id", "idimg": string),
                ),
              |]
              |> Array.to_list
              |> List.filter_map(a => a)
              |> Array.of_list,
              [],
            ),
            React.createElement(
              "source",
              [|
                Some(
                  [@implicit_arity]
                  React.JSX.String("type", "image/webp": string),
                ),
                Some(
                  [@implicit_arity]
                  React.JSX.String("src", "picture/img1.webp": string),
                ),
              |]
              |> Array.to_list
              |> List.filter_map(a => a)
              |> Array.of_list,
              [],
            ),
            React.createElement(
              "source",
              [|
                Some(
                  [@implicit_arity]
                  React.JSX.String("type", "image/jpeg": string),
                ),
                Some(
                  [@implicit_arity]
                  React.JSX.String("src", "picture/img2.jpg": string),
                ),
              |]
              |> Array.to_list
              |> List.filter_map(a => a)
              |> Array.of_list,
              [],
            ),
          ],
        ),
      ],
    );
  let some_random_html_element =
    React.createElement(
      "text",
      [|
        Some([@implicit_arity] React.JSX.String("dx", "1 2": string)),
        Some([@implicit_arity] React.JSX.String("dy", "3 4": string)),
      |]
      |> Array.to_list
      |> List.filter_map(a => a)
      |> Array.of_list,
      [],
    );

let lower_empty_attr =

let lower_inline_styles =

let lower_inner_html =

let lower_opt_attr =

let lowerWithChildAndProps foo =

let lower_child_static =

let lower_child_ident =

let lower_child_single =

let lower_children_multiple foo bar =

let lower_child_with_upper_as_children =

let lower_children_nested =

let fragment foo = (React.fragment ~children:(React.list [ foo ]) () [@bla])

let poly_children_fragment foo bar =

let nested_fragment foo bar baz =

let nested_fragment_with_lower foo =

let fragment_as_a_child =

let upper = React.Upper_case_component (fun () -> Upper.make ())
let upper_prop = React.Upper_case_component (fun () -> Upper.make ~count ())

let upper_children_single foo =

let upper_children_multiple foo bar =

let upper_children =

let upper_nested_module =

let upper_child_expr =

let upper_child_ident =

let upper_all_kinds_of_props =

let upper_ref_with_children =

let lower_ref_with_children =

let lower_with_many_props =

let some_random_html_element =
