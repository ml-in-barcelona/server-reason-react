module HTML = struct
  (* https://discuss.ocaml.org/t/html-encoding-of-string/4289/4 *)
  (* If problems http://projects.camlcity.org/projects/dl/ocamlnet-4.1.6/doc/html-main/Netencoding.Html.html *)
  let escape s =
    let add = Buffer.add_string in
    let len = String.length s in
    let b = Buffer.create len in
    let max_idx = len - 1 in
    let flush b start i =
      if start < len then Buffer.add_substring b s start (i - start)
    in
    let rec escape_inner start i =
      if i > max_idx then flush b start i
      else
        let next = i + 1 in
        match String.get s i with
        | '&' ->
            flush b start i;
            add b "&amp;";
            escape_inner next next
        | '<' ->
            flush b start i;
            add b "&lt;";
            escape_inner next next
        | '>' ->
            flush b start i;
            add b "&gt;";
            escape_inner next next
        | '\'' ->
            flush b start i;
            add b "&apos;";
            escape_inner next next
        | '\"' ->
            flush b start i;
            add b "&quot;";
            escape_inner next next
        | ' ' ->
            flush b start i;
            add b "&nbsp;";
            escape_inner next next
        | _ -> escape_inner start next
    in
    escape_inner 0 0 |> ignore;
    Buffer.contents b
end

module React = struct
  (* Self referencing modules to have recursive type records without collission *)
  module rec Element : sig
    type t =
      { tag : string
      ; attributes : Attribute.t list
      ; children : Node.t list
      }
  end =
    Element

  and Closed_element : sig
    type t =
      { tag : string
      ; attributes : Attribute.t list
      }
  end =
    Closed_element

  and Node : sig
    type t =
      | Element of Element.t
      | Closed_element of Closed_element.t
      | Text of string
      | Fragment of t list
      | Empty
      | Provider of (unit -> t) list
      | Consumer of (unit -> t list)
  end =
    Node

  and Attribute : sig
    type t =
      | Bool of (string * bool)
      | String of (string * string)
      | Style of (string * string) list
      | DangerouslyInnerHtml of string
  end =
    Attribute

  let is_self_closing_tag = function
    | "area" | "base" | "br" | "col" | "embed" | "hr" | "img" | "input" | "link"
    | "meta" | "param" | "source" | "track" | "wbr" ->
        true
    | _ -> false

  exception Invalid_children of string

  let compare_attribute left right =
    let open Attribute in
    match (left, right) with
    | Bool (left_key, _), Bool (right_key, _) ->
        String.compare left_key right_key
    | String (left_key, _), String (right_key, _) ->
        String.compare left_key right_key
    | Style left_styles, Style right_styles ->
        List.compare
          (fun (a, va) (b, vb) -> String.compare a b + String.compare va vb)
          left_styles right_styles
    | _ -> 0

  let clone_attribute acc attr new_attr =
    let open Attribute in
    match (attr, new_attr) with
    | Bool (left, _), Bool (right, value) when left == right ->
        Bool (left, value) :: acc
    | String (left, _), String (right, value) when left == right ->
        String (left, value) :: acc
    | _ -> new_attr :: acc

  module StringMap = Map.Make (String)

  type attributes = Attribute.t StringMap.t

  let attributes_to_map attrs =
    List.fold_left
      (fun acc attr ->
        match attr with
        | Attribute.Bool (key, value) ->
            acc |> StringMap.add key (Attribute.Bool (key, value))
        | Attribute.String (key, value) ->
            acc |> StringMap.add key (Attribute.String (key, value))
        | Attribute.DangerouslyInnerHtml _ -> acc
        | Attribute.Style _ -> acc)
      StringMap.empty attrs

  let clone_attributes attributes new_attributes =
    let attribute_map = attributes_to_map attributes in
    let new_attribute_map = attributes_to_map new_attributes in
    StringMap.merge
      (fun _key attr new_attr ->
        match (attr, new_attr) with
        | Some attr, Some new_attr -> Some (clone_attribute [] attr new_attr)
        | Some attr, None -> Some [ attr ]
        | None, Some new_attr -> Some [ new_attr ]
        | None, None -> None)
      attribute_map new_attribute_map
    |> StringMap.bindings
    |> List.map (fun (_, attrs) -> attrs)
    |> List.flatten |> List.rev
    |> List.sort compare_attribute

  let createElement tag attributes children =
    match is_self_closing_tag tag with
    | true when List.length children > 0 ->
        (* TODO: Add test for this *)
        (* Q: should raise or return monad? *)
        raise @@ Invalid_children "closing tag with children isn't valid"
    | true -> Node.Closed_element { tag; attributes }
    | false -> Node.Element { tag; attributes; children }

  (* cloneElements overrides childrens *)
  let cloneElement element new_attributes new_childrens =
    let open Node in
    match element with
    | Element { tag; attributes; children = _ } ->
        Element
          { tag
          ; attributes = clone_attributes attributes new_attributes
          ; children = new_childrens
          }
    | Closed_element { tag; attributes } ->
        Closed_element
          { tag; attributes = clone_attributes attributes new_attributes }
    | Fragment _childrens -> Fragment new_childrens
    | Text t -> Text t
    | Empty -> Empty
    (* FIXME: How does cloneElement does with Provider/Consumer *)
    | Provider child -> Provider child
    | Consumer child -> Consumer child

  (* let currentDispatcher = ref dispacher *)
  (* HooksDispatcherOnUpdateInDEV *)

  type 'a context =
    { current_value : 'a ref
    ; provider : value:'a -> children:(unit -> Node.t) list -> Node.t
    ; consumer : children:('a -> Node.t list) -> Node.t
    }

  let createContext (initial_value : 'a) : 'a context =
    let ref_value = ref initial_value in
    let provider ~value ~children =
      ref_value.contents <- value;
      Node.Provider children
    in
    let consumer ~children =
      Node.Consumer (fun () -> children ref_value.contents)
    in
    { current_value = ref_value; provider; consumer }

  let useContext context = context.current_value.contents

  let useState f_initial_value =
    let setState _ = () in
    (f_initial_value (), setState)

  let useStateValue initial_value =
    let setState _ = () in
    (initial_value, setState)

  let useMemo fn = fn ()
  let useMemo1 fn _ = fn ()
  let useMemo2 fn _ = fn ()
  let useMemo3 fn _ = fn ()
  let useMemo4 fn _ = fn ()
  let useMemo5 fn _ = fn ()
  let useMemo6 fn _ = fn ()
  let useCallback fn = fn
  let useCallback1 fn _ = fn
  let useCallback2 fn _ = fn
  let useCallback3 fn _ = fn
  let useCallback4 fn _ = fn
  let useCallback5 fn _ = fn
  let useCallback6 (fn : 'a -> 'b) = fn

  let useReducer :
      ('state -> 'action -> 'state) -> 'state -> 'state * ('action -> unit) =
   fun _ s -> (s, fun _ -> ())

  let useEffect0 : (unit -> (unit -> unit) option) -> unit = fun _ -> ()

  let useEffect1 : (unit -> (unit -> unit) option) -> 'dependency array -> unit
      =
   fun _ _ -> ()

  let useEffect2 :
      (unit -> (unit -> unit) option) -> 'dependency1 * 'dependency2 -> unit =
   fun _ _ -> ()

  let useEffect3 :
         (unit -> (unit -> unit) option)
      -> 'dependency1 * 'dependency2 * 'dependency3
      -> unit =
   fun _ _ -> ()

  let useEffect4 :
         (unit -> (unit -> unit) option)
      -> 'dependency1 * 'dependency2 * 'dependency3 * 'dependency4
      -> unit =
   fun _ _ -> ()

  let useEffect5 :
         (unit -> (unit -> unit) option)
      -> 'dependency1
         * 'dependency2
         * 'dependency3
         * 'dependency4
         * 'dependency5
      -> unit =
   fun _ _ -> ()

  let useEffect6 :
         (unit -> (unit -> unit) option)
      -> 'dependency1
         * 'dependency2
         * 'dependency3
         * 'dependency4
         * 'dependency5
         * 'dependency6
      -> unit =
   fun _ _ -> ()

  (* ReasonReact APIs *)
  let string txt = Node.Text txt
  let null = Node.Empty
  let int i = Node.Text (string_of_int i)

  (* FIXME: float_of_string might be different on the browser *)
  let float f = Node.Text (string_of_float f)
end

module ReactDOMServer = struct
  open React

  let attribute_name_to_jsx k =
    match k with
    | "className" -> "class"
    | "htmlFor" -> "for"
    (* serialize defaultX props to the X attribute *)
    (* FIXME: Add link *)
    | "defaultValue" -> "value"
    | "defaultChecked" -> "checked"
    | "defaultSelected" -> "selected"
    | _ -> k

  let styles_to_string styles =
    styles
    |> List.map (fun (k, v) -> k ^ ": " ^ String.trim v)
    |> String.concat "; "

  (* ignores "ref" prop *)
  let attribute_is_not_html = function "ref" -> true | _ -> false

  let attribute_to_string attr =
    let open Attribute in
    match attr with
    (* false attributes don't get rendered *)
    | Bool (_, false) -> ""
    | Bool (k, true) -> k
    | DangerouslyInnerHtml html -> html
    | Style styles -> Printf.sprintf "style=\"%s\"" (styles_to_string styles)
    | String (k, _) when attribute_is_not_html k -> ""
    | String (k, v) ->
        Printf.sprintf "%s=\"%s\"" (attribute_name_to_jsx k) (HTML.escape v)

  let attribute_is_not_empty = function
    | Attribute.String (k, _v) -> k != ""
    | Bool (k, _) -> k != ""
    | DangerouslyInnerHtml _ -> false
    | Style styles -> List.length styles != 0

  (* FIXME: Remove empty style attributes or class *)
  let attribute_is_not_valid = attribute_is_not_empty

  let attributes_to_string attrs =
    let attributes = List.filter attribute_is_not_valid attrs in
    match attributes with
    | [] -> ""
    | _ ->
        " "
        ^ (String.concat " " (attributes |> List.map attribute_to_string)
          |> String.trim)

  (* FIXME: Add link to source *)
  let react_root_attr_name = "data-reactroot"
  let data_react_root_attr = Printf.sprintf " %s=\"\"" react_root_attr_name

  let renderToStaticMarkup (component : Node.t) =
    (* is_root starts at true (when renderToString) and only goes to false when renders an element or closed element *)
    let is_root = ref false in
    let rec render_to_string_inner component =
      let root_attribute =
        match is_root.contents with true -> data_react_root_attr | false -> ""
      in
      match component with
      | Node.Empty -> ""
      | Fragment [] -> ""
      | Text text -> HTML.escape text
      | Provider children ->
          children
          |> List.map (fun f -> f ())
          |> List.map render_to_string_inner
          |> String.concat ""
      | Consumer children ->
          children () |> List.map render_to_string_inner |> String.concat ""
      | Fragment children ->
          children |> List.map render_to_string_inner |> String.concat ""
      | Element { tag; attributes; children } ->
          is_root.contents <- false;
          let attributes = attributes_to_string attributes in
          let childrens =
            children |> List.map render_to_string_inner |> String.concat ""
          in
          Printf.sprintf "<%s%s%s>%s</%s>" tag root_attribute attributes
            childrens tag
      | Closed_element { tag; attributes } ->
          is_root.contents <- false;
          let attributes = attributes_to_string attributes in
          Printf.sprintf "<%s%s%s />" tag root_attribute attributes
    in
    render_to_string_inner component
end

(*
  ********************************************************
  *                    TESTS                             *
  ********************************************************
*)

open Alcotest

let expect_msg = "should be equal"
let assert_string left right = (check string) expect_msg right left

let test_tag () =
  let div = React.createElement "div" [] [] in
  assert_string (ReactDOMServer.renderToStaticMarkup div) "<div></div>"

let test_empty_attributes () =
  let div = React.createElement "div" [ React.Attribute.String ("", "") ] [] in
  assert_string (ReactDOMServer.renderToStaticMarkup div) "<div></div>"

let test_empty_attribute () =
  let div =
    React.createElement "div" [ React.Attribute.String ("className", "") ] []
  in
  assert_string
    (ReactDOMServer.renderToStaticMarkup div)
    "<div class=\"\"></div>"

let test_attributes () =
  let a =
    React.createElement "a"
      [ React.Attribute.String ("href", "google.html")
      ; React.Attribute.String ("target", "_blank")
      ]
      []
  in
  assert_string
    (ReactDOMServer.renderToStaticMarkup a)
    "<a href=\"google.html\" target=\"_blank\"></a>"

let test_bool_attributes () =
  let a =
    React.createElement "input"
      [ React.Attribute.String ("type", "checkbox")
      ; React.Attribute.String ("name", "cheese")
      ; React.Attribute.Bool ("checked", true)
      ; React.Attribute.Bool ("disabled", false)
      ]
      []
  in
  assert_string
    (ReactDOMServer.renderToStaticMarkup a)
    "<input type=\"checkbox\" name=\"cheese\" checked />"

let test_closing_tag () =
  let input = React.createElement "input" [] [] in
  assert_string (ReactDOMServer.renderToStaticMarkup input) "<input />"

let test_innerhtml () =
  let p = React.createElement "p" [] [ React.string "text" ] in
  assert_string (ReactDOMServer.renderToStaticMarkup p) "<p>text</p>"

let test_children () =
  let children = React.createElement "div" [] [] in
  let div = React.createElement "div" [] [ children ] in
  assert_string
    (ReactDOMServer.renderToStaticMarkup div)
    "<div><div></div></div>"

let test_className () =
  let div =
    React.createElement "div" [ React.Attribute.String ("className", "lol") ] []
  in
  assert_string
    (ReactDOMServer.renderToStaticMarkup div)
    "<div class=\"lol\"></div>"

let test_fragment () =
  let div = React.createElement "div" [] [] in
  let component = React.Node.Fragment [ div; div ] in
  assert_string
    (ReactDOMServer.renderToStaticMarkup component)
    "<div></div><div></div>"

let test_nulls () =
  let div = React.createElement "div" [] [] in
  let span = React.createElement "span" [] [] in
  let component = React.createElement "div" [] [ div; span; React.null ] in
  assert_string
    (ReactDOMServer.renderToStaticMarkup component)
    "<div><div></div><span></span></div>"

let test_fragments_and_texts () =
  let component =
    React.createElement "div" []
      [ React.Node.Fragment [ React.Node.Text "foo" ]
      ; React.Node.Text "bar"
      ; React.createElement "b" [] []
      ]
  in
  assert_string
    (ReactDOMServer.renderToStaticMarkup component)
    "<div>foobar<b></b></div>"

let test_default_value () =
  let component =
    React.createElement "input"
      [ React.Attribute.String ("defaultValue", "lol") ]
      []
  in
  assert_string
    (ReactDOMServer.renderToStaticMarkup component)
    "<input value=\"lol\" />"

let test_inline_styles () =
  let component =
    React.createElement "button"
      [ React.Attribute.Style [ ("color", "red"); ("border", "none") ] ]
      []
  in
  assert_string
    (ReactDOMServer.renderToStaticMarkup component)
    "<button style=\"color: red; border: none\"></button>"

let test_escape_attributes () =
  let component =
    React.createElement "div"
      [ React.Attribute.String ("a", "\' <") ]
      [ React.string "& \"" ]
  in
  assert_string
    (ReactDOMServer.renderToStaticMarkup component)
    "<div a=\"&apos;&nbsp;&lt;\">&amp;&nbsp;&quot;</div>"

let test_clone_empty () =
  let component =
    React.createElement "div" [ React.Attribute.String ("val", "33") ] []
  in
  assert_string
    (ReactDOMServer.renderToStaticMarkup component)
    (ReactDOMServer.renderToStaticMarkup (React.cloneElement component [] []))

let test_clone_attributes () =
  let component =
    React.createElement "div" [ React.Attribute.String ("val", "33") ] []
  in
  let expected =
    React.createElement "div"
      [ React.Attribute.String ("val", "31")
      ; React.Attribute.Bool ("lola", true)
      ]
      []
  in
  let cloned =
    React.cloneElement component
      [ React.Attribute.Bool ("lola", true)
      ; React.Attribute.String ("val", "31")
      ]
      []
  in
  assert_string
    (ReactDOMServer.renderToStaticMarkup cloned)
    (ReactDOMServer.renderToStaticMarkup expected)

let test_clone_order_attributes () =
  let component = React.createElement "div" [] [] in
  let expected =
    React.createElement "div"
      [ React.Attribute.String ("val", "31")
      ; React.Attribute.Bool ("lola", true)
      ]
      []
  in
  let cloned =
    React.cloneElement component
      [ React.Attribute.Bool ("lola", true)
      ; React.Attribute.String ("val", "31")
      ]
      []
  in
  assert_string
    (ReactDOMServer.renderToStaticMarkup cloned)
    (ReactDOMServer.renderToStaticMarkup expected)

let test_context () =
  let context = React.createContext 10 in
  let component =
    context.provider ~value:20
      ~children:
        [ (fun () ->
            context.consumer ~children:(fun value ->
                [ React.createElement "section" [] [ React.int value ] ]))
        ]
  in
  assert_string
    (ReactDOMServer.renderToStaticMarkup component)
    "<section>20</section>"

let test_use_state () =
  let state, _setState = React.useStateValue "LOL" in
  let component = React.createElement "section" [] [ React.string state ] in
  assert_string
    (ReactDOMServer.renderToStaticMarkup component)
    "<section>LOL</section>"

let test_use_memo () =
  let memo = React.useMemo (fun () -> 23) in
  let component = React.createElement "header" [] [ React.int memo ] in
  assert_string
    (ReactDOMServer.renderToStaticMarkup component)
    "<header>23</header>"

let test_use_callback () =
  let memo = React.useCallback (fun () -> 23) in
  let component = React.createElement "header" [] [ React.int (memo ()) ] in
  assert_string
    (ReactDOMServer.renderToStaticMarkup component)
    "<header>23</header>"

let test_use_context () =
  let context = React.createContext 10 in
  let context_user () =
    let number = React.useContext context in
    React.createElement "section" [] [ React.int number ]
  in
  let component = context.provider ~value:0 ~children:[ context_user ] in
  assert_string
    (ReactDOMServer.renderToStaticMarkup component)
    "<section>0</section>"

module Component = struct
  let make () = React.createElement "div" [] []
end

let () =
  let open Alcotest in
  run "Tests"
    [ ( "renderToStaticMarkup"
      , [ test_case "div" `Quick test_tag
        ; test_case "empty attribute" `Quick test_empty_attribute
        ; test_case "empty attributes" `Quick test_empty_attributes
        ; test_case "bool attributes" `Quick test_bool_attributes
        ; test_case "ignore nulls" `Quick test_nulls
        ; test_case "attributes" `Quick test_attributes
        ; test_case "self-closing tag" `Quick test_closing_tag
        ; test_case "inner text" `Quick test_innerhtml
        ; test_case "children" `Quick test_children
        ; test_case "className turns into class" `Quick test_className
        ; test_case "fragment is empty" `Quick test_fragment
        ; test_case "fragment and text concat nicely" `Quick
            test_fragments_and_texts
        ; test_case "defaultValue should be value" `Quick test_default_value
        ; test_case "inline styles" `Quick test_inline_styles
        ; test_case "escape HTML attributes" `Quick test_escape_attributes
        ; test_case "createContext" `Quick test_context
        ; test_case "useContext" `Quick test_use_context
        ; test_case "useState" `Quick test_use_state
        ; test_case "useMemo" `Quick test_use_memo
        ; test_case "useCallback" `Quick test_use_callback
        ] )
    ; ( (* FIXME: those test shouldn't rely on renderToStaticMarkup,
           make an alcotest TESTABLE component *)
        "React.cloneElement"
      , [ test_case "empty component" `Quick test_clone_empty
        ; test_case "attributes component" `Quick test_clone_attributes
        ; test_case "ordered attributes component" `Quick
            test_clone_order_attributes
        ] )
    ]
