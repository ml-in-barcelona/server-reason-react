let lower = div ~children:[] () [@JSX]
let lower_empty_attr = div ~className:"" ~children:[] () [@JSX]
let lower_inline_styles = div ~style:(ReactDOM.Style.make ~backgroundColor:"gainsboro" ()) ~children:[] () [@JSX]
let lower_inner_html = div ~dangerouslySetInnerHTML:[%mel.obj { __html = text }] ~children:[] () [@JSX]
let lower_opt_attr = div ?tabIndex ~children:[] () [@JSX]
let lowerWithChildAndProps foo = a ~tabIndex:1 ~href:"https://example.com" ~children:[ foo ] () [@JSX]
let lower_child_static = div ~children:[ (span ~children:[] () [@JSX]) ] () [@JSX]
let lower_child_ident = div ~children:[ lolaspa ] () [@JSX]
let lower_child_single = div ~children:[ (div ~children:[] () [@JSX]) ] () [@JSX]
let lower_children_multiple foo bar = lower ~children:[ foo; bar ] () [@JSX]
let lower_child_with_upper_as_children = div ~children:[ (App.createElement ~children:[] () [@JSX]) ] () [@JSX]

let lower_children_nested =
  div ~className:"flex-container"
    ~children:
      [
        (div ~className:"sidebar"
           ~children:
             [
               (h2 ~className:"title" ~children:[ "jsoo-react" |> s ] () [@JSX]);
               (nav ~className:"menu"
                  ~children:
                    [
                      (ul
                         ~children:
                           [
                             examples
                             |> List.map (fun e ->
                                 (li ~key:e.path
                                    ~children:
                                      [
                                        (a ~href:e.path
                                           ~onClick:(fun event ->
                                             React.Event.Mouse.preventDefault event;
                                             ReactRouter.push e.path)
                                           ~children:[ e.title |> s ]
                                           () [@JSX]);
                                      ]
                                    () [@JSX]))
                             |> React.list;
                           ]
                         () [@JSX]);
                    ]
                  () [@JSX]);
             ]
           () [@JSX]);
      ]
    () [@JSX]

let lower_ref_with_children = button ~ref ~className:"FancyButton" ~children:[ children ] () [@JSX]

let lower_with_many_props =
  div ~translate:"yes"
    ~children:
      [
        (picture ~id:"idpicture"
           ~children:
             [
               (img ~src:"picture/img.png" ~alt:"test picture/img.png" ~id:"idimg" ~children:[] () [@JSX]);
               (source ~type_:"image/webp" ~src:"picture/img1.webp" ~children:[] () [@JSX]);
               (source ~type_:"image/jpeg" ~src:"picture/img2.jpg" ~children:[] () [@JSX]);
             ]
           () [@JSX]);
      ]
    () [@JSX]

let some_random_html_element = text ~dx:"1 2" ~dy:"3 4" ~children:[] () [@JSX]
let div = div ?onClick ~children:[] () [@JSX]
let self_closing_tag_with_children = meta ~children:[ React.string "Hello" ] () [@JSX]

let self_closing_tag_with_dangerouslySetInnerHtml =
  meta ~dangerouslySetInnerHTML:[%mel.obj { __html = "Hello" }] ~children:[] () [@JSX]
