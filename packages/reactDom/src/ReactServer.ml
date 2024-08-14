[@@@warning "-26-27"]

let is_react_custom_attribute attr =
  match attr with
  | "dangerouslySetInnerHTML" | "ref" | "key" | "suppressContentEditableWarning"
  | "suppressHydrationWarning" ->
      true
  | _ -> false

let attribute_to_html attr =
  match attr with
  (* ignores "ref" prop *)
  | React.JSX.Ref _ -> Html.omitted ()
  | Bool (name, _) when is_react_custom_attribute name -> Html.omitted ()
  (* false attributes don't get rendered *)
  | Bool (_name, false) -> Html.omitted ()
  (* true attributes render solely the attribute name *)
  | Bool (name, true) -> Html.present name
  | Style styles -> Html.attribute "style" styles
  | String (name, _value) when is_react_custom_attribute name -> Html.omitted ()
  | String (name, value) -> Html.attribute name value
  (* Events don't get rendered on SSR *)
  | Event _ -> Html.omitted ()
  (* Since we extracted the attribute as children (Element.InnerHtml) in createElement,
     we are very sure there's nothing to render here *)
  | DangerouslyInnerHtml _ -> Html.omitted ()

let attributes_to_html attrs = attrs |> List.map attribute_to_html

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
    match element with
    | React.Empty -> Html.null
    | Provider children -> render_element children
    | Consumer children -> render_element children
    | Fragment children -> render_element children
    | List list -> list |> Array.to_list |> List.map render_element |> Html.list
    | Upper_case_component component -> render_element (component ())
    | Async_component _component ->
        failwith
          "Asyncronous components can't be rendered to static markup, since \
           rendering is syncronous. Please use `renderToLwtStream` instead."
    | Lower_case_element { tag; attributes; _ }
      when Html.is_self_closing_tag tag ->
        is_root.contents <- false;
        Html.node tag (attributes_to_html attributes) []
    | Lower_case_element { tag; attributes; children } ->
        is_root.contents <- false;
        Html.node tag
          (attributes_to_html attributes)
          (List.map render_element children)
    | Text text -> (
        let is_previous_text_node = previous_was_text_node.contents in
        previous_was_text_node.contents <- true;
        match mode with
        | String when is_previous_text_node ->
            Html.list [ Html.raw "<!-- -->"; Html.string text ]
        | _ -> Html.string text)
    | InnerHtml text -> Html.raw text
    | Suspense { children; fallback } -> (
        match render_element children with
        | output ->
            Html.list [ Html.raw "<!--$-->"; output; Html.raw "<!--/$-->" ]
        | exception _e ->
            Html.list
              [
                Html.raw "<!--$!-->";
                render_element fallback;
                Html.raw "<!--/$-->";
              ])
  in
  render_element element

let renderToString element =
  (* TODO: try catch to avoid React.use usages *)
  let html = render_to_string ~mode:String element in
  Html.render html

let renderToStaticMarkup element =
  (* TODO: try catch to avoid React.use usages *)
  let html = render_to_string ~mode:Markup element in
  Html.render html

module Stream = struct
  let create () =
    let stream, push_to_stream = Lwt_stream.create () in
    let push v = push_to_stream @@ Some v in
    let close () = push_to_stream @@ None in
    (stream, push, close)
end

type context_state = {
  push : Yojson.Safe.t -> unit;
  close : unit -> unit;
  mutable boundary_id : int;
  mutable suspense_id : int;
  mutable waiting : int;
}

(* https://github.com/facebook/react/blob/493f72b0a7111b601c16b8ad8bc2649d82c184a0/packages/react-dom-bindings/src/server/fizz-instruction-set/ReactDOMFizzInstructionSetShared.js#L46 *)
let complete_boundary_script =
  {|function $RC(a,b){a=document.getElementById(a);b=document.getElementById(b);b.parentNode.removeChild(b);if(a){a=a.previousSibling;var f=a.parentNode,c=a.nextSibling,e=0;do{if(c&&8===c.nodeType){var d=c.data;if("/$"===d)if(0===e)break;else e--;else"$"!==d&&"$?"!==d&&"$!"!==d||e++}d=c.nextSibling;f.removeChild(c);c=d}while(c);for(;b.firstChild;)f.insertBefore(b.firstChild,c);a.data="$";a._reactRetry&&a._reactRetry()}}|}

let inline_complete_boundary_script =
  Html.node "script" [] [ Html.raw complete_boundary_script ]

let render_inline_rc_replacement replacements =
  let rc_payload =
    replacements
    |> List.map (fun (b, s) ->
           Html.raw (Printf.sprintf "$RC('B:%i','S:%i')" b s))
    |> Html.list ~separator:";"
  in
  Html.node "script" [] [ rc_payload ]

let render_to_stream ~context_state element =
  let rec render_element element =
    match element with
    | React.Empty -> Lwt.return Html.null
    | Provider children -> render_element children
    | Consumer children -> render_element children
    | Fragment children -> render_element children
    | List arr ->
        let%lwt children_elements =
          arr |> Array.to_list |> Lwt_list.map_p render_element
        in
        Lwt.return (Html.list children_elements)
    | Upper_case_component component -> render_element (component ())
    | Lower_case_element { tag; attributes; _ }
      when Html.is_self_closing_tag tag ->
        Lwt.return (Html.node tag (attributes_to_html attributes) [])
    | Lower_case_element { tag; attributes; children } ->
        let%lwt inner = children |> Lwt_list.map_p render_element in
        Lwt.return (Html.node tag (attributes_to_html attributes) inner)
    | Text text -> Lwt.return (Html.string text)
    | InnerHtml text -> Lwt.return (Html.raw text)
    | Async_component component ->
        let%lwt element = component () in
        render_element element
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
                Lwt.bind promise (fun _ ->
                    (* Enqueue the component with resolved data *)
                    let%lwt resolved =
                      render_resolved_element ~id:current_suspense_id children
                    in
                    context_state.push resolved;
                    (* Enqueue the inline script that replaces fallback by resolved *)
                    (* context_state.push inline_complete_boundary_script; *)
                    (* context_state.push
                       (render_inline_rc_replacement
                          [ (current_boundary_id, current_suspense_id) ]); *)
                    context_state.waiting <- context_state.waiting - 1;
                    context_state.suspense_id <- context_state.suspense_id + 1;
                    if context_state.waiting = 0 then context_state.close ();
                    Lwt.return_unit));
            (* Return the rendered fallback to SSR syncronous *)
            render_fallback ~boundary_id:current_boundary_id fallback
        | exception _exn ->
            (* TODO: log exn *)
            render_fallback ~boundary_id:context_state.boundary_id fallback)
  and render_resolved_element ~id:_ _element =
    (* render_element element
       |> Lwt.map (fun element ->
              Html.node "div"
                [
                  Html.present "hidden";
                  Html.attribute "id" (Printf.sprintf "S:%i" id);
                ]
                [ element ]) *)
    Lwt.return `Null
  and render_fallback ~boundary_id element =
    render_element element
    |> Lwt.map (fun element ->
           Html.list
             [
               Html.raw "<!--$?-->";
               Html.node "template"
                 [ Html.attribute "id" (Printf.sprintf "B:%i" boundary_id) ]
                 [];
               element;
               Html.raw "<!--/$-->";
             ])
  in
  render_element element

let prop_to_json (prop : React.JSX.prop) =
  match prop with
  | React.JSX.Bool (key, value) -> (key, `Bool value)
  | React.JSX.String (key, value) -> (key, `String value)
  | React.JSX.Style value -> ("style", `String value)
  | React.JSX.DangerouslyInnerHtml html ->
      ("dangerouslySetInnerHTML", `Assoc [ ("__html", `String html) ])
  | React.JSX.Ref _ -> failwith "TODO ref"
  | React.JSX.Event _ -> failwith "TODO event"

let props_to_json props = List.map prop_to_json props

let node ~tag ?(key = None) ~attributes children : Yojson.Safe.t =
  let key = match key with None -> `Null | Some key -> `String key in
  let props =
    match children with
    | [] -> props_to_json attributes
    | [ one_children ] -> ("children", one_children) :: props_to_json attributes
    | childrens -> ("children", `List childrens) :: props_to_json attributes
  in
  `List [ `String "$"; `String tag; key; `Assoc props ]

(* TODO: Add key on Lower_case_element ? *)
let element_to_payload ~context_state:_ element : Yojson.Safe.t =
  let rec element_to_payload_rec element =
    match element with
    | React.Empty -> `Null
    (* TODO: Should we html encode this? *)
    | React.Text t -> `String t
    | React.Lower_case_element { tag; attributes; children } ->
        node ~key:None ~tag ~attributes
          (List.map element_to_payload_rec children)
    | React.Fragment children -> element_to_payload_rec children
    | React.List children ->
        `List (Array.map element_to_payload_rec children |> Array.to_list)
    | React.InnerHtml text ->
        failwith
          "It does not exist in RSC, this looks like a bug in \
           server-reason-react"
    | React.Upper_case_component component -> failwith "TODO"
    | React.Async_component _component -> failwith "TODO"
    | React.Suspense { children; fallback } -> failwith "TODO"
    | React.Provider children -> failwith "TODO"
    | React.Consumer children -> failwith "TODO"
  in
  element_to_payload_rec element

let render element =
  let stream, push, close = Stream.create () in
  let push_html x = push x in
  let context_state =
    { push = push_html; close; waiting = 0; boundary_id = 0; suspense_id = 0 }
  in
  let json = element_to_payload ~context_state element in
  push_html json;
  if context_state.waiting = 0 then close ();
  let abort () =
    (* TODO: Needs to flush the remaining loading fallbacks as HTML, and React.js will try to render the rest on the client. *)
    (* Lwt_stream.closed stream |> Lwt.ignore_result *)
    failwith "abort() isn't supported yet"
  in
  Lwt.return (stream, abort)
