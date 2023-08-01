open React

let jsx_attribute_to_html k =
  match k with
  | "className" -> "class"
  | "htmlFor" -> "for"
  (* serialize defaultX props to the X attribute *)
  (* FIXME: Add link *)
  | "defaultValue" -> "value"
  | "defaultChecked" -> "checked"
  | "defaultSelected" -> "selected"
  | _ -> k

let is_onclick_event event =
  match event with
  | Attribute.Event (name, _) when String.equal name "_onclick" -> true
  | _ -> false

let attribute_is_html tag attr_name =
  match DomProps.findByName tag attr_name with Ok _ -> true | Error _ -> false

let replace_reserved_names attr =
  match attr with "type" -> "type_" | "as" -> "as_" | _ -> attr

let get_key = function
  | Attribute.Bool (k, _) -> k
  | String (k, _) -> replace_reserved_names k
  | Ref _ -> "ref"
  | DangerouslyInnerHtml _ -> "dangerouslySetInnerHTML"
  | Style _ -> "style"
  | Event (name, _) -> (* FIXME: tolowercase? does it even matter? *) name

let is_react_custom_attribute attr =
  match get_key attr with
  | "dangerouslySetInnerHTML" | "ref" | "key" | "suppressContentEditableWarning"
  | "suppressHydrationWarning" ->
      true
  | _ -> false

let attribute_is_not_event attr =
  match attr with
  (* We treat _onclick as "not an event", so attribute_is_valid turns it true *)
  | Attribute.Event _ as event when is_onclick_event event -> true
  | Event _ -> false
  | _ -> true

let attribute_is_valid tag attr =
  attribute_is_html tag (get_key attr)
  && attribute_is_not_event attr
  && not (is_react_custom_attribute attr)

let attribute_to_string attr =
  match attr with
  (* ignores "ref" prop *)
  | Attribute.Ref _ -> ""
  (* false attributes don't get rendered *)
  | Bool (_, false) -> ""
  (* true attributes render solely the attribute name *)
  | Bool (k, true) -> k
  (* Since we extracted the attribute as children (Element.InnerHtml),
     we don't want to render anything here *)
  | DangerouslyInnerHtml _ -> ""
  (* We ignore events on SSR, the only exception is "_onclick" which renders as string onclick *)
  | Event (name, Inline value) when String.equal name "_onclick" ->
      Printf.sprintf "onclick=\"%s\"" value
  | Event _ -> ""
  | Style styles -> Printf.sprintf "style=\"%s\"" styles
  | String (k, v) ->
      Printf.sprintf "%s=\"%s\"" (jsx_attribute_to_html k) (Html.encode v)

let attributes_to_string tag attrs =
  let valid_attributes =
    attrs |> Array.to_list
    |> List.filter_map (fun attr ->
           if attribute_is_valid tag attr then Some (attribute_to_string attr)
           else None)
  in
  match valid_attributes with
  | [] -> ""
  | rest -> " " ^ (rest |> String.concat " " |> String.trim)

let react_root_attr_name = "data-reactroot"
let data_react_root_attr = Printf.sprintf " %s=\"\"" react_root_attr_name

type mode = String | Markup

let render_tree_to_string ~mode element =
  let buff = Buffer.create 16 in
  let push = Buffer.add_string buff in
  (* is_root starts at true (when renderToString) and only goes to false
     when renders an lower-case element or closed element *)
  let is_mode_to_string = mode = String in
  let is_root = ref is_mode_to_string in
  (* previous_was_text_node is the flag to enable rendering comments
     <!-- --> between text nodes *)
  let previous_was_text_node = ref false in
  let rec render_inner element =
    let root_attribute =
      match is_root.contents with true -> data_react_root_attr | false -> ""
    in
    match element with
    | Empty -> push ""
    | Provider childrens ->
        childrens |> List.map (fun f -> f ()) |> List.iter render_inner
    | Consumer children -> children () |> List.iter render_inner
    | Fragment children -> render_inner children
    | List list -> list |> Array.iter render_inner
    | Upper_case_component f -> render_inner (f ())
    | Lower_case_element { tag; attributes; _ }
      when Html.is_self_closing_tag tag ->
        is_root.contents <- false;
        push "<";
        push tag;
        push (attributes_to_string tag attributes);
        push " />"
    | Lower_case_element { tag; attributes; children } ->
        is_root.contents <- false;
        push "<";
        push tag;
        push root_attribute;
        push (attributes_to_string tag attributes);
        push ">";
        children |> List.iter render_inner;
        push "</";
        push tag;
        push ">"
    | Text text -> (
        let is_previous_text_node = previous_was_text_node.contents in
        previous_was_text_node.contents <- true;
        match mode with
        | String when is_previous_text_node ->
            push (Printf.sprintf "<!-- -->%s" (Html.encode text))
        | _ -> push (Html.encode text))
    | InnerHtml text -> push text
    | Suspense { children; _ } ->
        push "<!--$-->";
        children |> List.iter render_inner;
        push "<!--/$-->"
  in
  render_inner element;
  buff |> Buffer.contents

let renderToString element =
  (* TODO: try catch to avoid React.use usages *)
  render_tree_to_string ~mode:String element

let renderToStaticMarkup element =
  (* TODO: try catch to avoid React.use usages *)
  render_tree_to_string ~mode:Markup element

module Stream = struct
  let create () =
    let stream, push_to_stream = Lwt_stream.create () in
    let push v = push_to_stream @@ Some v in
    let close () = push_to_stream @@ None in
    (stream, push, close)
end

type context_state = {
  stream : string Lwt_stream.t;
  push : string -> unit;
  close : unit -> unit;
  mutable waiting : int;
}

let render_to_stream ~context_state element =
  let rec render_inner element =
    match element with
    | Empty -> ""
    | Provider childrens ->
        childrens |> List.map (fun f -> render_inner (f ())) |> String.concat ""
    | Consumer children ->
        children () |> List.map render_inner |> String.concat ""
    | Fragment children -> render_inner children
    | List arr ->
        arr |> Array.to_list |> List.map render_inner |> String.concat ""
    | Upper_case_component component -> (
        print_endline "Upper_case_component";
        let element =
          try Some (component ()) with
          | React.Suspend (Any_promise promise) ->
              print_endline "| React.Suspend (Any_promise promise) ->";
              context_state.waiting <- context_state.waiting + 1;
              Lwt.map
                (fun _ ->
                  context_state.push (render_inner element);
                  context_state.waiting <- context_state.waiting - 1;
                  if context_state.waiting = 0 then context_state.close ()
                  else ())
                promise
              |> Lwt.ignore_result;
              None
          | e -> raise e
        in
        match element with Some element -> render_inner element | None -> "")
    | Lower_case_element { tag; attributes; _ }
      when Html.is_self_closing_tag tag ->
        Printf.sprintf "<%s%s />" tag (attributes_to_string tag attributes)
    | Lower_case_element { tag; attributes; children } ->
        Printf.sprintf "<%s%s>%s</%s>" tag
          (attributes_to_string tag attributes)
          (children |> List.map render_inner |> String.concat "")
          tag
    | Text text -> Html.encode text
    | InnerHtml text -> text
    | Suspense { children; _ } ->
        Printf.sprintf "<!--$-->%s<!--/$-->"
          (children |> List.map render_inner |> String.concat "")
  in
  render_inner element

let renderToLwtStream element =
  print_endline "renderToLwtStream";
  let stream, push, close = Stream.create () in
  let context_state = { stream; push; close; waiting = 0 } in
  let shell = render_to_stream ~context_state element in
  push shell;
  if context_state.waiting = 0 then close ();
  (* TODO: Needs to flush the remaining loading fallbacks as HTML, and will attempt to render the rest on the client. *)
  let abort () = (* Lwt_stream.closed stream |> Lwt.ignore_result *) () in
  (stream, abort)

let querySelector _str = None

let fail_impossible_action_in_ssr =
  (* failwith seems bad, but I don't know any other way
     of warning the user without changing the types. Doing a unit *)
  (* failwith
     (Printf.sprintf "render shouldn't run on the server %s, line %d" __FILE__
        __LINE__) *)
  ()

let render _element _node = fail_impossible_action_in_ssr
let hydrate _element _node = fail_impossible_action_in_ssr
let createPortal _reactElement _domElement = _reactElement

module Style = ReactDOMStyle

let createDOMElementVariadic :
    string -> Attribute.t array -> React.element array -> element =
 fun tag props childrens ->
  React.createElement tag props (childrens |> Array.to_list)

let domProps = Props.domProps
