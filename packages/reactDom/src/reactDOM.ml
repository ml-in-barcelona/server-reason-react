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

let render_to_string ~mode element =
  (* is_root starts at true (when renderToString) and only goes to false
     when renders an lower-case element or closed element *)
  let is_mode_to_string = mode = String in
  let is_root = ref is_mode_to_string in
  (* previous_was_text_node is the flag to enable rendering comments
     <!-- --> between text nodes *)
  let previous_was_text_node = ref false in
  let rec render_element element =
    let root_attribute =
      match is_root.contents with true -> data_react_root_attr | false -> ""
    in
    match element with
    | Empty -> ""
    | Provider childrens ->
        childrens
        |> List.map (fun f -> f ())
        |> List.map render_element |> String.concat ""
    | Consumer children ->
        children () |> List.map render_element |> String.concat ""
    | Fragment children -> render_element children
    | List list ->
        list |> Array.map render_element |> Array.to_list |> String.concat ""
    | Upper_case_component f -> render_element (f ())
    | Lower_case_element { tag; attributes; _ }
      when Html.is_self_closing_tag tag ->
        is_root.contents <- false;
        Printf.sprintf "<%s%s%s />" tag root_attribute
          (attributes_to_string tag attributes)
    | Lower_case_element { tag; attributes; children } ->
        is_root.contents <- false;
        Printf.sprintf "<%s%s%s>%s</%s>" tag root_attribute
          (attributes_to_string tag attributes)
          (children |> List.map render_element |> String.concat "")
          tag
    | Text text -> (
        let is_previous_text_node = previous_was_text_node.contents in
        previous_was_text_node.contents <- true;
        match mode with
        | String when is_previous_text_node ->
            Printf.sprintf "<!-- -->%s" (Html.encode text)
        | _ -> Html.encode text)
    | InnerHtml text -> text
    | Suspense { children; fallback } -> (
        match render_element children with
        | output -> Printf.sprintf "<!--$-->%s<!--/$-->" output
        | exception _e ->
            Printf.sprintf "<!--$!-->%s<!--/$-->" (render_element fallback))
  in
  render_element element

let renderToString element =
  (* TODO: try catch to avoid React.use usages *)
  render_to_string ~mode:String element

let renderToStaticMarkup element =
  (* TODO: try catch to avoid React.use usages *)
  render_to_string ~mode:Markup element

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
  mutable boundary_id : int;
  mutable suspense_id : int;
  mutable waiting : int;
}

(* https://github.com/facebook/react/blob/493f72b0a7111b601c16b8ad8bc2649d82c184a0/packages/react-dom-bindings/src/server/fizz-instruction-set/ReactDOMFizzInstructionSetShared.js#L46 *)
let complete_boundary_script =
  {|function $RC(a,b){a=document.getElementById(a);b=document.getElementById(b);b.parentNode.removeChild(b);if(a){a=a.previousSibling;var f=a.parentNode,c=a.nextSibling,e=0;do{if(c&&8===c.nodeType){var d=c.data;if("/$"===d)if(0===e)break;else e--;else"$"!==d&&"$?"!==d&&"$!"!==d||e++}d=c.nextSibling;f.removeChild(c);c=d}while(c);for(;b.firstChild;)f.insertBefore(b.firstChild,c);a.data="$";a._reactRetry&&a._reactRetry()}}|}

let inline_complete_boundary_script =
  Printf.sprintf {|<script>%s</script>|} complete_boundary_script

let render_inline_rc_replacement replacements =
  let rc_payload =
    replacements
    |> List.map (fun (b, s) -> Printf.sprintf "$RC('B:%i','S:%i')" b s)
    |> String.concat ";"
  in
  Printf.sprintf {|<script>%s</script>|} rc_payload

let render_to_stream ~context_state element =
  let rec render_element element =
    match element with
    | Empty -> ""
    | Provider childrens ->
        childrens
        |> List.map (fun f -> render_element (f ()))
        |> String.concat ""
    | Consumer children ->
        children () |> List.map render_element |> String.concat ""
    | Fragment children -> render_element children
    | List arr ->
        arr |> Array.to_list |> List.map render_element |> String.concat ""
    | Upper_case_component component -> render_element (component ())
    | Lower_case_element { tag; attributes; _ }
      when Html.is_self_closing_tag tag ->
        Printf.sprintf "<%s%s />" tag (attributes_to_string tag attributes)
    | Lower_case_element { tag; attributes; children } ->
        Printf.sprintf "<%s%s>%s</%s>" tag
          (attributes_to_string tag attributes)
          (children |> List.map render_element |> String.concat "")
          tag
    | Text text -> Html.encode text
    | InnerHtml text -> text
    | Suspense { children; fallback } -> (
        match render_element children with
        | output -> output
        | exception React.Suspend (Any_promise promise) ->
            context_state.waiting <- context_state.waiting + 1;
            (* We store to current_*_id to bypass the increment *)
            let current_boundary_id = context_state.boundary_id in
            let current_suspense_id = context_state.suspense_id in
            context_state.boundary_id <- context_state.boundary_id + 1;
            (* Wait for promise to resolve *)
            Lwt.async (fun () ->
                Lwt.map
                  (fun _ ->
                    (* Enqueue the component with resolved data *)
                    context_state.push
                      (render_resolved_element ~id:current_suspense_id children);
                    (* Enqueue the inline script that replaces fallback by resolved *)
                    context_state.push inline_complete_boundary_script;
                    context_state.push
                      (render_inline_rc_replacement
                         [ (current_boundary_id, current_suspense_id) ]);
                    context_state.waiting <- context_state.waiting - 1;
                    context_state.suspense_id <- context_state.suspense_id + 1;
                    if context_state.waiting = 0 then context_state.close ())
                  promise);
            (* Return the rendered fallback to SSR syncronous *)
            render_fallback ~boundary_id:current_boundary_id fallback
        | exception _exn ->
            (* TODO: log exn *)
            render_fallback ~boundary_id:context_state.boundary_id fallback)
  and render_resolved_element ~id element =
    Printf.sprintf "<div hidden id='S:%i'>%s</div>" id (render_element element)
  and render_fallback ~boundary_id element =
    Printf.sprintf "<!--$?--><template id='B:%i'></template>%s<!--/$-->"
      boundary_id (render_element element)
  in
  render_element element

let renderToLwtStream element =
  let stream, push, close = Stream.create () in
  let context_state =
    { stream; push; close; waiting = 0; boundary_id = 0; suspense_id = 0 }
  in
  let shell = render_to_stream ~context_state element in
  push shell;
  if context_state.waiting = 0 then close ();
  (* TODO: Needs to flush the remaining loading fallbacks as HTML, and will attempt to render the rest on the client. *)
  let abort () = (* Lwt_stream.closed stream |> Lwt.ignore_result *) () in
  (stream, abort)

let querySelector _str = None

exception Impossible_in_ssr of string

let fail_impossible_action_in_ssr fn =
  let msg = Printf.sprintf "'%s' shouldn't run on the server" fn in
  raise (Impossible_in_ssr msg)

let render _element _node = fail_impossible_action_in_ssr "ReactDOM.render"
let hydrate _element _node = fail_impossible_action_in_ssr "ReactDOM.hydrate"
let createPortal _reactElement _domElement = _reactElement

module Style = ReactDOMStyle

let createDOMElementVariadic :
    string -> Attribute.t array -> React.element array -> element =
 fun tag props childrens ->
  React.createElement tag props (childrens |> Array.to_list)

let domProps = Props.domProps
