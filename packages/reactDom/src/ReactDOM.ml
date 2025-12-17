module Style = ReactDOMStyle
module Ref = React.Ref

type domRef = Ref.t

let is_react_custom_attribute attr =
  match attr with
  | "dangerouslySetInnerHTML" | "ref" | "key" | "suppressContentEditableWarning" | "suppressHydrationWarning" -> true
  | _ -> false

let write_attribute_to_buffer buf (attr : React.JSX.prop) =
  match attr with
  (* ignores "ref" prop *)
  | Ref _ -> ()
  (* react custom attributes are not rendered *)
  | Bool (name, _, _) when is_react_custom_attribute name -> ()
  (* false attributes don't get rendered *)
  | Bool (_name, _, false) -> ()
  (* true attributes render solely the attribute name *)
  | Bool (name, _, true) ->
      Buffer.add_char buf ' ';
      Buffer.add_string buf name
  | Action (_, _, _) -> ()
  | Style styles ->
      Buffer.add_string buf " style=\"";
      Style.write_to_buffer buf styles;
      Buffer.add_char buf '"'
  | String (name, _, _value) when is_react_custom_attribute name -> ()
  | String (name, _, value) ->
      Buffer.add_char buf ' ';
      Buffer.add_string buf name;
      Buffer.add_string buf "=\"";
      Html.escape buf value;
      Buffer.add_char buf '"'
  (* Events don't get rendered on SSR *)
  | Event _ -> ()
  (* Since we extracted the attribute as children, we are sure there's nothing to render here *)
  | DangerouslyInnerHtml _ -> ()

let write_attributes_to_buffer buf attrs = List.iter (write_attribute_to_buffer buf) attrs

let attribute_to_html (attr : React.JSX.prop) =
  match attr with
  (* ignores "ref" prop *)
  | Ref _ -> Html.omitted ()
  (* react custom attributes are not rendered *)
  | Bool (name, _, _) when is_react_custom_attribute name -> Html.omitted ()
  (* false attributes don't get rendered *)
  | Bool (_name, _, false) -> Html.omitted ()
  (* true attributes render solely the attribute name *)
  | Bool (name, _, true) -> Html.present name
  | Action (_, _, _) -> Html.omitted ()
  | Style styles -> Html.attribute "style" (ReactDOMStyle.to_string styles)
  | String (name, _, _value) when is_react_custom_attribute name -> Html.omitted ()
  | String (name, _, value) -> Html.attribute name value
  (* Events don't get rendered on SSR *)
  | Event _ -> Html.omitted ()
  (* Since we extracted the attribute as children, we are sure there's nothing to render here *)
  | DangerouslyInnerHtml _ -> Html.omitted ()

let attributes_to_html attrs = List.map attribute_to_html attrs

let getDangerouslyInnerHtml attributes =
  List.find_map (function React.JSX.DangerouslyInnerHtml str -> Some str | _ -> None) attributes

type mode = String | Markup

let render_to_buffer ~mode buf element =
  let add_separator_between_text_nodes = mode = String in
  let previous_was_text_node = ref false in
  let should_add_doctype = ref true in

  let rec render_element element =
    match (element : React.element) with
    | Empty -> ()
    | DangerouslyInnerHtml html ->
        should_add_doctype := false;
        Buffer.add_string buf html
    | Client_component { import_module; _ } ->
        raise
          (Invalid_argument
             ("Client components can't be rendered on the server via renderToString or renderToStaticMarkup. Please \
               use the React server components API instead. module: " ^ import_module))
    | Provider children -> render_element children
    | Consumer children -> render_element children
    | Fragment children -> render_element children
    | List list -> List.iter render_element list
    | Array arr -> Array.iter render_element arr
    | Upper_case_component (_, component) -> render_element (component ())
    | Async_component (_name, _component) ->
        raise
          (Invalid_argument
             "Async components can't be rendered to static markup, since rendering is synchronous. Please use \
              `renderToStream` instead.")
    | Lower_case_element { key; tag; attributes; children } -> render_lower_case ~key tag attributes children
    | Text text ->
        let is_previous_text_node = !previous_was_text_node in
        previous_was_text_node := true;
        if is_previous_text_node && add_separator_between_text_nodes then Buffer.add_string buf "<!-- -->";
        Html.escape buf text;
        should_add_doctype := false
    | Suspense { key = _; children; fallback } -> (
        match render_element children with
        | () ->
            Buffer.add_string buf "<!--$-->";
            render_element children;
            Buffer.add_string buf "<!--/$-->"
        | exception _e ->
            Buffer.add_string buf "<!--$!-->";
            render_element fallback;
            Buffer.add_string buf "<!--/$-->")
  and render_lower_case ~key:_ tag attributes children =
    let inner_html = getDangerouslyInnerHtml attributes in
    if Html.is_self_closing_tag tag then (
      should_add_doctype := false;
      if add_separator_between_text_nodes then previous_was_text_node := false;
      Buffer.add_char buf '<';
      Buffer.add_string buf tag;
      write_attributes_to_buffer buf attributes;
      Buffer.add_string buf " />")
    else
      let doctype = !should_add_doctype in
      should_add_doctype := false;
      if add_separator_between_text_nodes then previous_was_text_node := false;
      if tag = "html" && doctype then Buffer.add_string buf "<!DOCTYPE html>";
      Buffer.add_char buf '<';
      Buffer.add_string buf tag;
      write_attributes_to_buffer buf attributes;
      Buffer.add_char buf '>';
      (match inner_html with Some html -> Buffer.add_string buf html | None -> List.iter render_element children);
      Buffer.add_string buf "</";
      Buffer.add_string buf tag;
      Buffer.add_char buf '>'
  in
  render_element element

let write_to_buffer buf element =
  let rec render element =
    match (element : React.element) with
    | Empty -> ()
    | DangerouslyInnerHtml html -> Buffer.add_string buf html
    | Client_component { import_module; _ } ->
        raise (Invalid_argument ("Client components can't be rendered via write_to_buffer. module: " ^ import_module))
    | Provider children -> render children
    | Consumer children -> render children
    | Fragment children -> render children
    | List list -> List.iter render list
    | Array arr -> Array.iter render arr
    | Upper_case_component (_, component) -> render (component ())
    | Async_component (_name, _component) ->
        raise (Invalid_argument "Async components can't be rendered synchronously via write_to_buffer.")
    | Lower_case_element { key = _; tag; attributes; children } ->
        let inner_html = getDangerouslyInnerHtml attributes in
        if Html.is_self_closing_tag tag then (
          Buffer.add_char buf '<';
          Buffer.add_string buf tag;
          write_attributes_to_buffer buf attributes;
          Buffer.add_string buf " />")
        else (
          Buffer.add_char buf '<';
          Buffer.add_string buf tag;
          write_attributes_to_buffer buf attributes;
          Buffer.add_char buf '>';
          (match inner_html with Some html -> Buffer.add_string buf html | None -> List.iter render children);
          Buffer.add_string buf "</";
          Buffer.add_string buf tag;
          Buffer.add_char buf '>')
    | Text text -> Html.escape buf text
    | Suspense { children; fallback; _ } -> (
        match render children with () -> render children | exception _e -> render fallback)
  in
  render element

let escape_to_buffer = Html.escape

let renderToString element =
  (* TODO: try catch to avoid React.use usages *)
  let buf = Buffer.create 1024 in
  render_to_buffer ~mode:String buf element;
  Buffer.contents buf

let renderToStaticMarkup element =
  (* TODO: try catch to avoid React.use usages *)
  let buf = Buffer.create 1024 in
  render_to_buffer ~mode:Markup buf element;
  Buffer.contents buf

type stream_context = {
  push : string -> unit;
  close : unit -> unit;
  mutable closed : bool;
  mutable has_rc_script_been_injected : bool;
  mutable boundary_id : int;
  mutable suspense_id : int;
  mutable waiting : int;
}

(* https://github.com/facebook/react/blob/493f72b0a7111b601c16b8ad8bc2649d82c184a0/packages/react-dom-bindings/src/server/fizz-instruction-set/ReactDOMFizzInstructionSetShared.js#L46 *)
let complete_boundary_script =
  {|function $RC(a,b){a=document.getElementById(a);b=document.getElementById(b);b.parentNode.removeChild(b);if(a){a=a.previousSibling;var f=a.parentNode,c=a.nextSibling,e=0;do{if(c&&8===c.nodeType){var d=c.data;if("/$"===d)if(0===e)break;else e--;else"$"!==d&&"$?"!==d&&"$!"!==d||e++}d=c.nextSibling;f.removeChild(c);c=d}while(c);for(;b.firstChild;)f.insertBefore(b.firstChild,c);a.data="$";a._reactRetry&&a._reactRetry()}}|}

let replacement b s = Printf.sprintf "$RC('B:%i','S:%i')" b s

let write_inline_complete_boundary_script buf has_rc_script_been_injected boundary_id suspense_id =
  let rc_call = replacement boundary_id suspense_id in
  if not has_rc_script_been_injected then (
    Buffer.add_string buf "<script>";
    Buffer.add_string buf complete_boundary_script;
    Buffer.add_string buf rc_call;
    Buffer.add_string buf "</script>")
  else (
    Buffer.add_string buf "<script>";
    Buffer.add_string buf rc_call;
    Buffer.add_string buf "</script>")

let write_suspense_resolved_element buf ~id html =
  Buffer.add_string buf "<div hidden id=\"S:";
  Buffer.add_string buf (Int.to_string id);
  Buffer.add_string buf "\">";
  Buffer.add_string buf html;
  Buffer.add_string buf "</div>"

let write_suspense_fallback buf ~boundary_id fallback =
  Buffer.add_string buf "<!--$?--><template id=\"B:";
  Buffer.add_string buf (Int.to_string boundary_id);
  Buffer.add_string buf "\"></template>";
  Buffer.add_string buf fallback;
  Buffer.add_string buf "<!--/$-->"

let write_suspense_fallback_error buf ~exn fallback =
  let backtrace = Printexc.get_backtrace () in
  Buffer.add_string buf "<!--$!--><template data-msg=\"";
  Html.escape buf (Printexc.to_string exn ^ "\n" ^ backtrace);
  Buffer.add_string buf "\"></template>";
  Buffer.add_string buf fallback;
  Buffer.add_string buf "<!--/$-->"

let rec render_to_stream_buffer ~stream_context buf element =
  let should_add_doctype = ref true in
  let previous_was_text_node = ref false in

  let rec render_element element =
    match (element : React.element) with
    | Empty -> Lwt.return ()
    | DangerouslyInnerHtml html ->
        should_add_doctype := false;
        Buffer.add_string buf html;
        Lwt.return ()
    | Client_component { import_module; _ } ->
        raise
          (Invalid_argument
             ("Client components can't be rendered on the server via renderToStream. Please use the React server \
               components API instead. module: " ^ import_module))
    | Provider children -> render_element children
    | Consumer children -> render_element children
    | Fragment children -> render_element children
    | List list -> Lwt_list.iter_s render_element list
    | Array arr -> Lwt_list.iter_s render_element (Array.to_list arr)
    | Lower_case_element { key; tag; attributes; children } -> render_lower_case ~key tag attributes children
    | Text text ->
        let is_previous_text_node = !previous_was_text_node in
        previous_was_text_node := true;
        if is_previous_text_node then Buffer.add_string buf "<!-- -->";
        should_add_doctype := false;
        Html.escape buf text;
        Lwt.return ()
    | Upper_case_component (_, component) -> ( try render_element (component ()) with exn -> raise_notrace exn)
    | Async_component (_, component) -> (
        let promise = component () in
        match Lwt.state promise with
        | Lwt.Return element -> render_element element
        | Lwt.Fail exn -> raise_notrace exn
        | Lwt.Sleep -> raise_notrace (React.Suspend (Any_promise promise)))
    | Suspense { children; fallback; _ } -> (
        (* TODO: We assume fallback can't have errors or suspensions, it might not be the case *)
        let render_fallback_html () =
          let fallback_buf = Buffer.create 128 in
          let%lwt () = render_element_to_buffer fallback_buf fallback in
          Lwt.return (Buffer.contents fallback_buf)
        in
        try%lwt
          let%lwt () = render_element children in
          Lwt.return ()
        with
        | React.Suspend (Any_promise promise) -> (
            match Lwt.state promise with
            | Lwt.Return _ -> render_element children
            | Lwt.Fail exn ->
                let%lwt fallback_html = render_fallback_html () in
                write_suspense_fallback_error buf ~exn fallback_html;
                Lwt.return ()
            | Lwt.Sleep ->
                let%lwt fallback_html = render_fallback_html () in
                let current_boundary_id = stream_context.boundary_id in
                let current_suspense_id = stream_context.suspense_id in
                stream_context.boundary_id <- stream_context.boundary_id + 1;
                stream_context.suspense_id <- stream_context.suspense_id + 1;
                stream_context.waiting <- stream_context.waiting + 1;

                Lwt.async (fun () ->
                    let%lwt _ = promise in
                    let async_buf = Buffer.create 512 in
                    let%lwt () = render_with_resolved_buffer ~stream_context async_buf children in
                    stream_context.waiting <- stream_context.waiting - 1;
                    if not stream_context.closed then (
                      let inner_html = Buffer.contents async_buf in
                      Buffer.clear async_buf;
                      write_suspense_resolved_element async_buf ~id:current_suspense_id inner_html;
                      stream_context.push (Buffer.contents async_buf);
                      Buffer.clear async_buf;
                      write_inline_complete_boundary_script async_buf stream_context.has_rc_script_been_injected
                        current_boundary_id current_suspense_id;
                      stream_context.push (Buffer.contents async_buf));
                    stream_context.has_rc_script_been_injected <- true;
                    if stream_context.waiting = 0 then (
                      stream_context.closed <- true;
                      stream_context.close ());
                    Lwt.return ());

                write_suspense_fallback buf ~boundary_id:current_boundary_id fallback_html;
                Lwt.return ())
        | exn ->
            let%lwt fallback_html = render_fallback_html () in
            write_suspense_fallback_error buf ~exn fallback_html;
            Lwt.return ())
  and render_element_to_buffer target_buf element =
    match (element : React.element) with
    | Empty -> Lwt.return ()
    | DangerouslyInnerHtml html ->
        Buffer.add_string target_buf html;
        Lwt.return ()
    | Client_component { import_module; _ } ->
        raise
          (Invalid_argument
             ("Client components can't be rendered on the server via renderToStream. Please use the React server \
               components API instead. module: " ^ import_module))
    | Provider children -> render_element_to_buffer target_buf children
    | Consumer children -> render_element_to_buffer target_buf children
    | Fragment children -> render_element_to_buffer target_buf children
    | List list -> Lwt_list.iter_s (render_element_to_buffer target_buf) list
    | Array arr -> Lwt_list.iter_s (render_element_to_buffer target_buf) (Array.to_list arr)
    | Lower_case_element { key; tag; attributes; children } ->
        render_lower_case_to_buffer target_buf ~key tag attributes children
    | Text text ->
        Html.escape target_buf text;
        Lwt.return ()
    | Upper_case_component (_, component) -> (
        try render_element_to_buffer target_buf (component ()) with exn -> raise_notrace exn)
    | Async_component (_, component) -> (
        let promise = component () in
        match Lwt.state promise with
        | Lwt.Return element -> render_element_to_buffer target_buf element
        | Lwt.Fail exn -> raise_notrace exn
        | Lwt.Sleep -> raise_notrace (React.Suspend (Any_promise promise)))
    | Suspense { children; fallback; _ } -> (
        let render_fallback () =
          let fallback_buf = Buffer.create 128 in
          let%lwt () = render_element_to_buffer fallback_buf fallback in
          Lwt.return (Buffer.contents fallback_buf)
        in
        try%lwt render_element_to_buffer target_buf children with
        | React.Suspend (Any_promise promise) -> (
            match Lwt.state promise with
            | Lwt.Return _ -> render_element_to_buffer target_buf children
            | Lwt.Fail exn ->
                let%lwt html = render_fallback () in
                write_suspense_fallback_error target_buf ~exn html;
                Lwt.return ()
            | Lwt.Sleep ->
                let%lwt fallback_html = render_fallback () in
                let current_boundary_id = stream_context.boundary_id in
                let current_suspense_id = stream_context.suspense_id in
                stream_context.boundary_id <- stream_context.boundary_id + 1;
                stream_context.suspense_id <- stream_context.suspense_id + 1;
                stream_context.waiting <- stream_context.waiting + 1;

                Lwt.async (fun () ->
                    let%lwt _ = promise in
                    let async_buf = Buffer.create 512 in
                    let%lwt () = render_with_resolved_buffer ~stream_context async_buf children in
                    stream_context.waiting <- stream_context.waiting - 1;
                    if not stream_context.closed then (
                      let inner_html = Buffer.contents async_buf in
                      Buffer.clear async_buf;
                      write_suspense_resolved_element async_buf ~id:current_suspense_id inner_html;
                      stream_context.push (Buffer.contents async_buf);
                      Buffer.clear async_buf;
                      write_inline_complete_boundary_script async_buf stream_context.has_rc_script_been_injected
                        current_boundary_id current_suspense_id;
                      stream_context.push (Buffer.contents async_buf));
                    stream_context.has_rc_script_been_injected <- true;
                    if stream_context.waiting = 0 then (
                      stream_context.closed <- true;
                      stream_context.close ());
                    Lwt.return ());

                write_suspense_fallback target_buf ~boundary_id:current_boundary_id fallback_html;
                Lwt.return ())
        | exn ->
            let%lwt fallback_html = render_fallback () in
            write_suspense_fallback_error target_buf ~exn fallback_html;
            Lwt.return ())
  and render_lower_case ~key:_ tag attributes children =
    let inner_html = getDangerouslyInnerHtml attributes in
    if Html.is_self_closing_tag tag then (
      should_add_doctype := false;
      previous_was_text_node := false;
      Buffer.add_char buf '<';
      Buffer.add_string buf tag;
      write_attributes_to_buffer buf attributes;
      Buffer.add_string buf " />";
      Lwt.return ())
    else
      let doctype = !should_add_doctype in
      should_add_doctype := false;
      previous_was_text_node := false;
      if tag = "html" && doctype then Buffer.add_string buf "<!DOCTYPE html>";
      Buffer.add_char buf '<';
      Buffer.add_string buf tag;
      write_attributes_to_buffer buf attributes;
      Buffer.add_char buf '>';
      let%lwt () =
        match inner_html with
        | Some html ->
            Buffer.add_string buf html;
            Lwt.return ()
        | None -> Lwt_list.iter_s render_element children
      in
      Buffer.add_string buf "</";
      Buffer.add_string buf tag;
      Buffer.add_char buf '>';
      Lwt.return ()
  and render_lower_case_to_buffer target_buf ~key:_ tag attributes children =
    let inner_html = getDangerouslyInnerHtml attributes in
    if Html.is_self_closing_tag tag then (
      Buffer.add_char target_buf '<';
      Buffer.add_string target_buf tag;
      write_attributes_to_buffer target_buf attributes;
      Buffer.add_string target_buf " />";
      Lwt.return ())
    else (
      Buffer.add_char target_buf '<';
      Buffer.add_string target_buf tag;
      write_attributes_to_buffer target_buf attributes;
      Buffer.add_char target_buf '>';
      let%lwt () =
        match inner_html with
        | Some html ->
            Buffer.add_string target_buf html;
            Lwt.return ()
        | None -> Lwt_list.iter_s (render_element_to_buffer target_buf) children
      in
      Buffer.add_string target_buf "</";
      Buffer.add_string target_buf tag;
      Buffer.add_char target_buf '>';
      Lwt.return ())
  in
  render_element element

and render_with_resolved_buffer ~stream_context buf element =
  let previous_was_text_node = ref false in

  let rec render_element element =
    match (element : React.element) with
    | Empty -> Lwt.return ()
    | Client_component { import_module; _ } ->
        raise
          (Invalid_argument
             ("Client components can't be rendered on the server via renderToStream. Please use the React server \
               components API instead. module: " ^ import_module))
    | Provider children -> render_element children
    | Consumer children -> render_element children
    | Fragment children -> render_element children
    | List list -> Lwt_list.iter_s render_element list
    | Array arr -> Lwt_list.iter_s render_element (Array.to_list arr)
    | Upper_case_component (_, component) -> render_element (component ())
    | Lower_case_element { key; tag; attributes; children } -> render_lower_case ~key tag attributes children
    | Text text ->
        let is_previous_text_node = !previous_was_text_node in
        previous_was_text_node := true;
        if is_previous_text_node then Buffer.add_string buf "<!-- -->";
        Html.escape buf text;
        Lwt.return ()
    | Async_component (_, component) -> (
        let promise = component () in
        match Lwt.state promise with
        | Lwt.Return resolved -> render_element resolved
        | Lwt.Fail exn -> raise_notrace exn
        | Lwt.Sleep ->
            let%lwt resolved = promise in
            render_element resolved)
    | DangerouslyInnerHtml html ->
        Buffer.add_string buf html;
        Lwt.return ()
    | Suspense _ -> render_to_stream_buffer ~stream_context buf element
  and render_lower_case ~key:_ tag attributes children =
    let inner_html = getDangerouslyInnerHtml attributes in
    if Html.is_self_closing_tag tag then (
      previous_was_text_node := false;
      Buffer.add_char buf '<';
      Buffer.add_string buf tag;
      write_attributes_to_buffer buf attributes;
      Buffer.add_string buf " />";
      Lwt.return ())
    else (
      previous_was_text_node := false;
      Buffer.add_char buf '<';
      Buffer.add_string buf tag;
      write_attributes_to_buffer buf attributes;
      Buffer.add_char buf '>';
      let%lwt () =
        match inner_html with
        | Some html ->
            Buffer.add_string buf html;
            Lwt.return ()
        | None -> Lwt_list.iter_s render_element children
      in
      Buffer.add_string buf "</";
      Buffer.add_string buf tag;
      Buffer.add_char buf '>';
      Lwt.return ())
  in
  render_element element

let renderToStream ?pipe:_ element =
  let stream, push_to_stream, close = Push_stream.make () in
  let stream_context =
    {
      push = push_to_stream;
      close;
      closed = false;
      waiting = 0;
      boundary_id = 0;
      suspense_id = 0;
      has_rc_script_been_injected = false;
    }
  in
  let abort () =
    (* TODO: Needs to flush the remaining loading fallbacks as HTML, and React.js will try to render the rest on the client. *)
    Lwt_stream.closed stream |> Lwt.ignore_result
  in
  let buf = Buffer.create 1024 in
  try%lwt
    let%lwt () = render_to_stream_buffer ~stream_context buf element in
    push_to_stream (Buffer.contents buf);
    if stream_context.waiting = 0 then close ();
    Lwt.return (stream, abort)
  with
  | React.Suspend (Any_promise promise) ->
      (* In case of getting a React.Suspend exn means that either an async component is being rendered without
         React.Suspense or React.use is being used without a Suspense boundary. In both cases, we need to await
         for the promise to resolve and then render the resolved element. *)
      let%lwt _ = promise in
      Buffer.clear buf;
      let%lwt () = render_with_resolved_buffer ~stream_context buf element in
      push_to_stream (Buffer.contents buf);
      if stream_context.waiting = 0 then close ();
      Lwt.return (stream, abort)
  (* non suspend exceptions propagate to the parent *)
  | exn -> Lwt.fail exn

let querySelector _str = Runtime.fail_impossible_action_in_ssr "ReactDOM.querySelector"
let render _element _node = Runtime.fail_impossible_action_in_ssr "ReactDOM.render"
let hydrate _element _node = Runtime.fail_impossible_action_in_ssr "ReactDOM.hydrate"

(* TODO: Should this fail_impossible_action_in_ssr? *)
let createPortal _reactElement _domElement = _reactElement

let createDOMElementVariadic (tag : string) ~props (childrens : React.element array) =
  React.createElement tag props (Array.to_list childrens)

let add kind value map = match value with Some i -> map |> List.cons (kind i) | None -> map

type dangerouslySetInnerHTML = < __html : string >

(* `Booleanish_string` are JSX attributes represented as boolean values but rendered as strings on HTML https://github.com/facebook/react/blob/a17467e7e2cd8947c595d1834889b5d184459f12/packages/react-dom-bindings/src/server/ReactFizzConfigDOM.js#L1165-L1176 *)
let booleanish_string name jsxName v = React.JSX.string name jsxName (string_of_bool v)

[@@@ocamlformat "disable"]
(* domProps isn't used by the generated code from the ppx, and it's purpose is to
   allow usages from user's code via createElementVariadic and custom usages outside JSX. It needs to be in sync with domProps *)
let domProps
  ?key
  ?ref
  ?ariaDetails
  ?ariaDisabled
  ?ariaHidden
  ?ariaKeyshortcuts
  ?ariaLabel
  ?ariaRoledescription
  ?ariaExpanded
  ?ariaLevel
  ?ariaModal
  ?ariaMultiline
  ?ariaMultiselectable
  ?ariaPlaceholder
  ?ariaReadonly
  ?ariaRequired
  ?ariaSelected
  ?ariaSort
  ?ariaValuemax
  ?ariaValuemin
  ?ariaValuenow
  ?ariaValuetext
  ?ariaAtomic
  ?ariaBusy
  ?ariaRelevant
  ?ariaGrabbed
  ?ariaActivedescendant
  ?ariaColcount
  ?ariaColindex
  ?ariaColspan
  ?ariaControls
  ?ariaDescribedby
  ?ariaErrormessage
  ?ariaFlowto
  ?ariaLabelledby
  ?ariaOwns
  ?ariaPosinset
  ?ariaRowcount
  ?ariaRowindex
  ?ariaRowspan
  ?ariaSetsize
  ?defaultChecked
  ?defaultValue
  ?accessKey
  ?className
  ?contentEditable
  ?contextMenu
  ?dir
  ?draggable
  ?hidden
  ?id
  ?lang
  ?role
  ?style
  ?spellCheck
  ?tabIndex
  ?title
  ?itemID
  ?itemProp
  ?itemRef
  ?itemScope
  ?itemType
  ?accept
  ?acceptCharset
  ?action
  ?allowFullScreen
  ?alt
  ?async
  ?autoComplete
  ?autoCapitalize
  ?autoFocus
  ?autoPlay
  ?challenge
  ?charSet
  ?checked
  ?cite
  ?crossOrigin
  ?cols
  ?colSpan
  ?content
  ?controls
  ?coords
  ?data
  ?dateTime
  ?default
  ?defer
  ?disabled
  ?download
  ?encType
  ?form
  ?formAction
  ?formTarget
  ?formMethod
  ?headers
  ?height
  ?high
  ?href
  ?hrefLang
  ?htmlFor
  ?httpEquiv
  ?icon
  ?inputMode
  ?integrity
  ?keyType
  ?kind
  ?label
  ?list
  ?loop
  ?low
  ?manifest
  ?max
  ?maxLength
  ?media
  ?mediaGroup
  ?method_
  ?min
  ?minLength
  ?multiple
  ?muted
  ?name
  ?nonce
  ?noValidate
  ?open_
  ?optimum
  ?pattern
  ?placeholder
  ?playsInline
  ?poster
  ?preload
  ?radioGroup
  ?readOnly
  ?rel
  ?required
  ?reversed
  ?rows
  ?rowSpan
  ?sandbox
  ?scope
  ?scoped
  ?scrolling
  ?selected
  ?shape
  ?size
  ?sizes
  ?span
  ?src
  ?srcDoc
  ?srcLang
  ?srcSet
  ?start
  ?step
  ?summary
  ?target
  ?type_
  ?useMap
  ?value
  ?width
  ?wrap
  ?onCopy
  ?onCut
  ?onPaste
  ?onCompositionEnd
  ?onCompositionStart
  ?onCompositionUpdate
  ?onKeyDown
  ?onKeyPress
  ?onKeyUp
  ?onFocus
  ?onBlur
  ?onChange
  ?onInput
  ?onSubmit
  ?onInvalid
  ?onClick
  ?onContextMenu
  ?onDoubleClick
  ?onDrag
  ?onDragEnd
  ?onDragEnter
  ?onDragExit
  ?onDragLeave
  ?onDragOver
  ?onDragStart
  ?onDrop
  ?onMouseDown
  ?onMouseEnter
  ?onMouseLeave
  ?onMouseMove
  ?onMouseOut
  ?onMouseOver
  ?onMouseUp
  ?onSelect
  ?onTouchCancel
  ?onTouchEnd
  ?onTouchMove
  ?onTouchStart
  ?onPointerOver
  ?onPointerEnter
  ?onPointerDown
  ?onPointerMove
  ?onPointerUp
  ?onPointerCancel
  ?onPointerOut
  ?onPointerLeave
  ?onGotPointerCapture
  ?onLostPointerCapture
  ?onScroll
  ?onWheel
  ?onAbort
  ?onCanPlay
  ?onCanPlayThrough
  ?onDurationChange
  ?onEmptied
  ?onEncrypetd
  ?onEnded
  ?onError
  ?onLoadedData
  ?onLoadedMetadata

  ?onLoadStart
  ?onPause
  ?onPlay
  ?onPlaying
  ?onProgress
  ?onRateChange
  ?onSeeked

  ?onSeeking
  ?onStalled
  ?onSuspend
  ?onTimeUpdate
  ?onVolumeChange
  ?onWaiting

  ?onAnimationStart
  ?onAnimationEnd
  ?onAnimationIteration
  ?onTransitionEnd

  ?accentHeight
  ?accumulate
  ?additive
  ?alignmentBaseline
  ?allowReorder

  ?alphabetic
  ?amplitude
  ?arabicForm
  ?ascent
  ?attributeName
  ?attributeType
  ?autoReverse
  ?azimuth
  ?baseFrequency
  ?baseProfile
  ?baselineShift
  ?bbox
  ?begin_
  ?bias
  ?by
  ?calcMode
  ?capHeight
  ?clip
  ?clipPath
  ?clipPathUnits
  ?clipRule
  ?colorInterpolation
  ?colorInterpolationFilters
  ?colorProfile
  ?colorRendering
  ?contentScriptType
  ?contentStyleType
  ?cursor
  ?cx
  ?cy
  ?d
  ?decelerate
  ?descent
  ?diffuseConstant
  ?direction
  ?display
  ?divisor
  ?dominantBaseline
  ?dur
  ?dx
  ?dy
  ?edgeMode
  ?elevation
  ?enableBackground
  ?end_
  ?exponent
  ?externalResourcesRequired
  ?fill
  ?fillOpacity
  ?fillRule
  ?filter
  ?filterRes
  ?filterUnits
  ?floodColor
  ?floodOpacity
  ?focusable
  ?fontFamily
  ?fontSize
  ?fontSizeAdjust
  ?fontStretch
  ?fontStyle
  ?fontVariant
  ?fontWeight
  ?fomat
  ?from
  ?fx
  ?fy
  ?g1
  ?g2
  ?glyphName
  ?glyphOrientationHorizontal
  ?glyphOrientationVertical
  ?glyphRef
  ?gradientTransform
  ?gradientUnits
  ?hanging
  ?horizAdvX
  ?horizOriginX
  ?ideographic
  ?imageRendering
  ?in_
  ?in2
  ?intercept
  ?k
  ?k1
  ?k2
  ?k3
  ?k4
  ?kernelMatrix
  ?kernelUnitLength
  ?kerning
  ?keyPoints
  ?keySplines
  ?keyTimes
  ?lengthAdjust
  ?letterSpacing
  ?lightingColor
  ?limitingConeAngle
  ?local
  ?markerEnd
  ?markerHeight
  ?markerMid
  ?markerStart
  ?markerUnits
  ?markerWidth
  ?mask
  ?maskContentUnits
  ?maskUnits
  ?mathematical
  ?mode
  ?numOctaves
  ?offset
  ?opacity
  ?operator
  ?order
  ?orient
  ?orientation
  ?origin
  ?overflow
  ?overflowX
  ?overflowY
  ?overlinePosition
  ?overlineThickness
  ?paintOrder
  ?panose1
  ?pathLength
  ?patternContentUnits
  ?patternTransform
  ?patternUnits
  ?pointerEvents
  ?points
  ?pointsAtX
  ?pointsAtY
  ?pointsAtZ
  ?preserveAlpha
  ?preserveAspectRatio
  ?primitiveUnits
  ?r
  ?radius
  ?refX
  ?refY
  ?renderingIntent
  ?repeatCount
  ?repeatDur
  ?requiredExtensions
  ?requiredFeatures
  ?restart
  ?result
  ?rotate
  ?rx
  ?ry
  ?scale
  ?seed
  ?shapeRendering
  ?slope
  ?spacing
  ?specularConstant
  ?specularExponent
  ?speed
  ?spreadMethod
  ?startOffset
  ?stdDeviation
  ?stemh
  ?stemv
  ?stitchTiles
  ?stopColor
  ?stopOpacity
  ?strikethroughPosition
  ?strikethroughThickness
  ?stroke
  ?strokeDasharray
  ?strokeDashoffset
  ?strokeLinecap
  ?strokeLinejoin
  ?strokeMiterlimit
  ?strokeOpacity
  ?strokeWidth
  ?surfaceScale
  ?systemLanguage
  ?tableValues
  ?targetX
  ?targetY
  ?textAnchor
  ?textDecoration
  ?textLength
  ?textRendering
  ?to_
  ?transform
  ?u1
  ?u2
  ?underlinePosition
  ?underlineThickness
  ?unicode
  ?unicodeBidi
  ?unicodeRange
  ?unitsPerEm
  ?vAlphabetic
  ?vHanging
  ?vIdeographic
  ?vMathematical
  ?values
  ?vectorEffect
  ?version
  ?vertAdvX
  ?vertAdvY
  ?vertOriginX
  ?vertOriginY
  ?viewBox
  ?viewTarget
  ?visibility
  ?widths
  ?wordSpacing
  ?writingMode
  ?x
  ?x1
  ?x2
  ?xChannelSelector
  ?xHeight
  ?xlinkActuate
  ?xlinkArcrole
  ?xlinkHref
  ?xlinkRole
  ?xlinkShow
  ?xlinkTitle
  ?xlinkType
  ?xmlns
  ?xmlnsXlink
  ?xmlBase
  ?xmlLang
  ?xmlSpace
  ?y
  ?y1
  ?y2
  ?yChannelSelector
  ?z
  ?zoomAndPan
  ?about
  ?datatype
  ?inlist
  ?prefix
  ?property
  ?resource
  ?typeof
  ?vocab
  ?dangerouslySetInnerHTML
  ?suppressContentEditableWarning
  ?suppressHydrationWarning
  () =
  []
  |> add (React.JSX.string "key" "key") key
  |> add React.JSX.ref ref
  |> add (React.JSX.string "aria-details" "aria-details") ariaDetails
  |> add (booleanish_string "aria-disabled" "aria-disabled") ariaDisabled
  |> add (booleanish_string "aria-hidden" "aria-hidden") ariaHidden
  |> add (React.JSX.string "aria-keyshortcuts" "aria-keyshortcuts") ariaKeyshortcuts
  |> add (React.JSX.string "aria-label" "aria-label") ariaLabel
  |> add (React.JSX.string "aria-roledescription" "aria-roledescription") ariaRoledescription
  |> add (booleanish_string "aria-expanded" "aria-expanded") ariaExpanded
  |> add (React.JSX.int "aria-level" "aria-level") ariaLevel
  |> add (booleanish_string "aria-modal" "aria-modal") ariaModal
  |> add (booleanish_string "aria-multiline" "aria-multiline") ariaMultiline
  |> add (booleanish_string "aria-multiselectable" "aria-multiselectable") ariaMultiselectable
  |> add (React.JSX.string "aria-placeholder" "aria-placeholder") ariaPlaceholder
  |> add (booleanish_string "aria-readonly" "aria-readonly") ariaReadonly
  |> add (booleanish_string "aria-required" "aria-required") ariaRequired
  |> add (booleanish_string "aria-selected" "aria-selected") ariaSelected
  |> add (React.JSX.string "aria-sort" "aria-sort") ariaSort
  |> add (React.JSX.float "aria-valuemax" "aria-valuemax") ariaValuemax
  |> add (React.JSX.float "aria-valuemin" "aria-valuemin") ariaValuemin
  |> add (React.JSX.float "aria-valuenow" "aria-valuenow") ariaValuenow
  |> add (React.JSX.string "aria-valuetext" "aria-valuetext") ariaValuetext
  |> add (booleanish_string "aria-atomic" "aria-atomic") ariaAtomic
  |> add (booleanish_string "aria-busy" "aria-busy") ariaBusy
  |> add (React.JSX.string "aria-relevant" "aria-relevant") ariaRelevant
  |> add (React.JSX.bool "aria-grabbed" "aria-grabbed") ariaGrabbed
  |> add (React.JSX.string "aria-activedescendant" "aria-activedescendant") ariaActivedescendant
  |> add (React.JSX.int "aria-colcount" "aria-colcount") ariaColcount
  |> add (React.JSX.int "aria-colindex" "aria-colindex") ariaColindex
  |> add (React.JSX.int "aria-colspan" "aria-colspan") ariaColspan
  |> add (React.JSX.string "aria-controls" "aria-controls") ariaControls
  |> add (React.JSX.string "aria-describedby" "aria-describedby") ariaDescribedby
  |> add (React.JSX.string "aria-errormessage" "aria-errormessage") ariaErrormessage
  |> add (React.JSX.string "aria-flowto" "aria-flowto") ariaFlowto
  |> add (React.JSX.string "aria-labelledby" "aria-labelledby") ariaLabelledby
  |> add (React.JSX.string "aria-owns" "aria-owns") ariaOwns
  |> add (React.JSX.int "aria-posinset" "aria-posinset") ariaPosinset
  |> add (React.JSX.int "aria-rowcount" "aria-rowcount") ariaRowcount
  |> add (React.JSX.int "aria-rowindex" "aria-rowindex") ariaRowindex
  |> add (React.JSX.int "aria-rowspan" "aria-rowspan") ariaRowspan
  |> add (React.JSX.int "aria-setsize" "aria-setsize") ariaSetsize
  |> add (React.JSX.bool "defaultChecked" "defaultChecked") defaultChecked
  |> add (React.JSX.string "defaultValue" "defaultValue") defaultValue
  |> add (React.JSX.string "accesskey" "accessKey") accessKey
  |> add (React.JSX.string "class" "className") className
  |> add (booleanish_string "contenteditable" "contentEditable") contentEditable
  |> add (React.JSX.string "contextmenu" "contextMenu") contextMenu
  |> add (React.JSX.string "dir" "dir") dir
  |> add (booleanish_string "draggable" "draggable") draggable
  |> add (React.JSX.bool "hidden" "hidden") hidden
  |> add (React.JSX.string "id" "id") id
  |> add (React.JSX.string "lang" "lang") lang
  |> add (React.JSX.string "role" "role") role
  |> add (React.JSX.style) style
  |> add (booleanish_string "spellcheck" "spellCheck") spellCheck
  |> add (React.JSX.int "tabindex" "tabIndex") tabIndex
  |> add (React.JSX.string "title" "title") title
  |> add (React.JSX.string "itemid" "itemID") itemID
  |> add (React.JSX.string "itemorop" "itemProp") itemProp
  |> add (React.JSX.string "itemref" "itemRef") itemRef
  |> add (React.JSX.bool "itemccope" "itemScope") itemScope
  |> add (React.JSX.string "itemtype" "itemType") itemType
  |> add (React.JSX.string "accept" "accept") accept
  |> add (React.JSX.string "accept-charset" "acceptCharset") acceptCharset
  |> add (React.JSX.string "action" "action") action
  |> add (React.JSX.bool "allowfullscreen" "allowFullScreen") allowFullScreen
  |> add (React.JSX.string "alt" "alt") alt
  |> add (React.JSX.bool "async" "async") async
  |> add (React.JSX.string "autocomplete" "autoComplete") autoComplete
  |> add (React.JSX.string "autocapitalize" "autoCapitalize") autoCapitalize
  |> add (React.JSX.bool "autofocus" "autoFocus") autoFocus
  |> add (React.JSX.bool "autoplay" "autoPlay") autoPlay
  |> add (React.JSX.string "challenge" "challenge") challenge
  |> add (React.JSX.string "charSet" "charSet") charSet
  |> add (React.JSX.bool "checked" "checked") checked
  |> add (React.JSX.string "cite" "cite") cite
  |> add (React.JSX.string "crossorigin" "crossOrigin") crossOrigin
  |> add (React.JSX.int "cols" "cols") cols
  |> add (React.JSX.int "colspan" "colSpan") colSpan
  |> add (React.JSX.string "content" "content") content
  |> add (React.JSX.bool "controls" "controls") controls
  |> add (React.JSX.string "coords" "coords") coords
  |> add (React.JSX.string "data" "data") data
  |> add (React.JSX.string "datetime" "dateTime") dateTime
  |> add (React.JSX.bool "default" "default") default
  |> add (React.JSX.bool "defer" "defer") defer
  |> add (React.JSX.bool "disabled" "disabled") disabled
  |> add (React.JSX.string "download" "download") download
  |> add (React.JSX.string "enctype" "encType") encType
  |> add (React.JSX.string "form" "form") form
  |> add (React.JSX.string "formction" "formAction") formAction
  |> add (React.JSX.string "formtarget" "formTarget") formTarget
  |> add (React.JSX.string "formmethod" "formMethod") formMethod
  |> add (React.JSX.string "headers" "headers") headers
  |> add (React.JSX.string "height" "height") height
  |> add (React.JSX.int "high" "high") high
  |> add (React.JSX.string "href" "href") href
  |> add (React.JSX.string "hreflang" "hrefLang") hrefLang
  |> add (React.JSX.string "for" "htmlFor") htmlFor
  |> add (React.JSX.string "http-equiv" "httpEquiv") httpEquiv
  |> add (React.JSX.string "icon" "icon") icon
  |> add (React.JSX.string "inputmode" "inputMode") inputMode
  |> add (React.JSX.string "integrity" "integrity") integrity
  |> add (React.JSX.string "keytype" "keyType") keyType
  |> add (React.JSX.string "kind" "kind") kind
  |> add (React.JSX.string "label" "label") label
  |> add (React.JSX.string "list" "list") list
  |> add (React.JSX.bool "loop" "loop") loop
  |> add (React.JSX.int "low" "low") low
  |> add (React.JSX.string "manifest" "manifest") manifest
  |> add (React.JSX.string "max" "max") max
  |> add (React.JSX.int "maxlength" "maxLength") maxLength
  |> add (React.JSX.string "media" "media") media
  |> add (React.JSX.string "mediagroup" "mediaGroup") mediaGroup
  |> add (React.JSX.string "method" "method") method_
  |> add (React.JSX.string "min" "min") min
  |> add (React.JSX.int "minlength" "minLength") minLength
  |> add (React.JSX.bool "multiple" "multiple") multiple
  |> add (React.JSX.bool "muted" "muted") muted
  |> add (React.JSX.string "name" "name") name
  |> add (React.JSX.string "nonce" "nonce") nonce
  |> add (React.JSX.bool "noValidate" "noValidate") noValidate
  |> add (React.JSX.bool "open" "open") open_
  |> add (React.JSX.int "optimum" "optimum") optimum
  |> add (React.JSX.string "pattern" "pattern") pattern
  |> add (React.JSX.string "placeholder" "placeholder") placeholder
  |> add (React.JSX.bool "playsInline" "playsInline") playsInline
  |> add (React.JSX.string "poster" "poster") poster
  |> add (React.JSX.string "preload" "preload") preload
  |> add (React.JSX.string "radioGroup" "radioGroup") radioGroup (* Unsure if it exists? *)
  |> add (React.JSX.bool "readonly" "readOnly") readOnly
  |> add (React.JSX.string "rel" "rel") rel
  |> add (React.JSX.bool "required" "required") required
  |> add (React.JSX.bool "reversed" "reversed") reversed
  |> add (React.JSX.int "rows" "rows") rows
  |> add (React.JSX.int "rowspan" "rowSpan") rowSpan
  |> add (React.JSX.string "sandbox" "sandbox") sandbox
  |> add (React.JSX.string "scope" "scope") scope
  |> add (React.JSX.bool "scoped" "scoped") scoped
  |> add (React.JSX.string "scrolling" "scrolling") scrolling
  |> add (React.JSX.bool "selected" "selected") selected
  |> add (React.JSX.string "shape" "shape") shape
  |> add (React.JSX.int "size" "size") size
  |> add (React.JSX.string "sizes" "sizes") sizes
  |> add (React.JSX.int "span" "span") span
  |> add (React.JSX.string "src" "src") src
  |> add (React.JSX.string "srcdoc" "srcDoc") srcDoc
  |> add (React.JSX.string "srclang" "srcLang") srcLang
  |> add (React.JSX.string "srcset" "srcSet") srcSet
  |> add (React.JSX.int "start" "start") start
  |> add (React.JSX.float "step" "step") step
  |> add (React.JSX.string "summary" "summary") summary
  |> add (React.JSX.string "target" "target") target
  |> add (React.JSX.string "type" "type") type_
  |> add (React.JSX.string "useMap" "useMap") useMap
  |> add (React.JSX.string "value" "value") value
  |> add (React.JSX.string "width" "width") width
  |> add (React.JSX.string "wrap" "wrap") wrap
  |> add (React.JSX.Event.clipboard "onCopy") onCopy
  |> add (React.JSX.Event.clipboard "onCut") onCut
  |> add (React.JSX.Event.clipboard "onPaste") onPaste
  |> add (React.JSX.Event.composition "onCompositionEnd") onCompositionEnd
  |> add (React.JSX.Event.composition "onCompositionStart") onCompositionStart
  |> add (React.JSX.Event.composition "onCompositionUpdate") onCompositionUpdate
  |> add (React.JSX.Event.keyboard "onKeyDown") onKeyDown
  |> add (React.JSX.Event.keyboard "onKeyPress") onKeyPress
  |> add (React.JSX.Event.keyboard "onKeyUp") onKeyUp
  |> add (React.JSX.Event.focus "onFocus") onFocus
  |> add (React.JSX.Event.focus "onBlur") onBlur
  |> add (React.JSX.Event.form "onChange") onChange
  |> add (React.JSX.Event.form "onInput") onInput
  |> add (React.JSX.Event.form "onSubmit") onSubmit
  |> add (React.JSX.Event.form "onInvalid") onInvalid
  |> add (React.JSX.Event.mouse "onClick") onClick
  |> add (React.JSX.Event.mouse "onContextMenu") onContextMenu
  |> add (React.JSX.Event.mouse "onDoubleClick") onDoubleClick
  |> add (React.JSX.Event.mouse "onDrag") onDrag
  |> add (React.JSX.Event.mouse "onDragEnd") onDragEnd
  |> add (React.JSX.Event.mouse "onDragEnter") onDragEnter
  |> add (React.JSX.Event.mouse "onDragExit") onDragExit
  |> add (React.JSX.Event.mouse "onDragLeave") onDragLeave
  |> add (React.JSX.Event.mouse "onDragOver") onDragOver
  |> add (React.JSX.Event.mouse "onDragStart") onDragStart
  |> add (React.JSX.Event.mouse "onDrop") onDrop
  |> add (React.JSX.Event.mouse "onMouseDown") onMouseDown
  |> add (React.JSX.Event.mouse "onMouseEnter") onMouseEnter
  |> add (React.JSX.Event.mouse "onMouseLeave") onMouseLeave
  |> add (React.JSX.Event.mouse "onMouseMove") onMouseMove
  |> add (React.JSX.Event.mouse "onMouseOut") onMouseOut
  |> add (React.JSX.Event.mouse "onMouseOver") onMouseOver
  |> add (React.JSX.Event.mouse "onMouseUp") onMouseUp
  |> add (React.JSX.Event.selection "onSelect") onSelect
  |> add (React.JSX.Event.touch "onTouchCancel") onTouchCancel
  |> add (React.JSX.Event.touch "onTouchEnd") onTouchEnd
  |> add (React.JSX.Event.touch "onTouchMove") onTouchMove
  |> add (React.JSX.Event.touch "onTouchStart") onTouchStart
  |> add (React.JSX.Event.pointer "onPointerOver") onPointerOver
  |> add (React.JSX.Event.pointer "onPointerEnter") onPointerEnter
  |> add (React.JSX.Event.pointer "onPointerDown") onPointerDown
  |> add (React.JSX.Event.pointer "onPointerMove") onPointerMove
  |> add (React.JSX.Event.pointer "onPointerUp") onPointerUp
  |> add (React.JSX.Event.pointer "onPointerCancel") onPointerCancel
  |> add (React.JSX.Event.pointer "onPointerOut") onPointerOut
  |> add (React.JSX.Event.pointer "onPointerLeave") onPointerLeave
  |> add (React.JSX.Event.pointer "onGotPointerCapture") onGotPointerCapture
  |> add (React.JSX.Event.pointer "onLostPointerCapture") onLostPointerCapture
  |> add (React.JSX.Event.ui "onScroll") onScroll
  |> add (React.JSX.Event.wheel "onWheel") onWheel
  |> add (React.JSX.Event.media "onAbort") onAbort
  |> add (React.JSX.Event.media "onCanPlay") onCanPlay
  |> add (React.JSX.Event.media "onCanPlayThrough") onCanPlayThrough
  |> add (React.JSX.Event.media "onDurationChange") onDurationChange
  |> add (React.JSX.Event.media "onEmptied") onEmptied
  |> add (React.JSX.Event.media "onEncrypetd") onEncrypetd
  |> add (React.JSX.Event.media "onEnded") onEnded
  |> add (React.JSX.Event.media "onError") onError
  |> add (React.JSX.Event.media "onLoadedData") onLoadedData
  |> add (React.JSX.Event.media "onLoadedMetadata") onLoadedMetadata
  |> add (React.JSX.Event.media "onLoadStart") onLoadStart
  |> add (React.JSX.Event.media "onPause") onPause
  |> add (React.JSX.Event.media "onPlay") onPlay
  |> add (React.JSX.Event.media "onPlaying") onPlaying
  |> add (React.JSX.Event.media "onProgress") onProgress
  |> add (React.JSX.Event.media "onRateChange") onRateChange
  |> add (React.JSX.Event.media "onSeeked") onSeeked
  |> add (React.JSX.Event.media "onSeeking") onSeeking
  |> add (React.JSX.Event.media "onStalled") onStalled
  |> add (React.JSX.Event.media "onSuspend") onSuspend
  |> add (React.JSX.Event.media "onTimeUpdate") onTimeUpdate
  |> add (React.JSX.Event.media "onVolumeChange") onVolumeChange
  |> add (React.JSX.Event.media "onWaiting") onWaiting
  |> add (React.JSX.Event.animation "onAnimationStart") onAnimationStart
  |> add (React.JSX.Event.animation "onAnimationEnd") onAnimationEnd
  |> add (React.JSX.Event.animation "onAnimationIteration") onAnimationIteration
  |> add (React.JSX.Event.transition "onTransitionEnd") onTransitionEnd
  |> add (React.JSX.string "accent-height" "accentHeight") accentHeight
  |> add (React.JSX.string "accumulate" "accumulate") accumulate
  |> add (React.JSX.string "additive" "additive") additive
  |> add (React.JSX.string "alignment-baseline" "alignmentBaseline") alignmentBaseline
  |> add (React.JSX.string "allowReorder" "allowReorder") allowReorder (* Does it exist? *)
  |> add (React.JSX.string "alphabetic" "alphabetic") alphabetic
  |> add (React.JSX.string "amplitude" "amplitude") amplitude
  |> add (React.JSX.string "arabic-form" "arabicForm") arabicForm
  |> add (React.JSX.string "ascent" "ascent") ascent
  |> add (React.JSX.string "attributeName" "attributeName") attributeName
  |> add (React.JSX.string "attributeType" "attributeType") attributeType
  |> add (React.JSX.string "autoReverse" "autoReverse") autoReverse (* Does it exist? *)
  |> add (React.JSX.string "azimuth" "azimuth") azimuth
  |> add (React.JSX.string "baseFrequency" "baseFrequency") baseFrequency
  |> add (React.JSX.string "baseProfile" "baseProfile") baseProfile
  |> add (React.JSX.string "baselineShift" "baselineShift") baselineShift
  |> add (React.JSX.string "bbox" "bbox") bbox
  |> add (React.JSX.string "begin" "begin") begin_
  |> add (React.JSX.string "bias" "bias") bias
  |> add (React.JSX.string "by" "by") by
  |> add (React.JSX.string "calcMode" "calcMode") calcMode
  |> add (React.JSX.string "capHeight" "capHeight") capHeight
  |> add (React.JSX.string "clip" "clip") clip
  |> add (React.JSX.string "clipPath" "clipPath") clipPath
  |> add (React.JSX.string "clipPathUnits" "clipPathUnits") clipPathUnits
  |> add (React.JSX.string "clipRule" "clipRule") clipRule
  |> add (React.JSX.string "colorInterpolation" "colorInterpolation") colorInterpolation
  |> add (React.JSX.string "colorInterpolationFilters" "colorInterpolationFilters") colorInterpolationFilters
  |> add (React.JSX.string "colorProfile" "colorProfile") colorProfile
  |> add (React.JSX.string "colorRendering" "colorRendering") colorRendering
  |> add (React.JSX.string "contentScriptType" "contentScriptType") contentScriptType
  |> add (React.JSX.string "contentStyleType" "contentStyleType") contentStyleType
  |> add (React.JSX.string "cursor" "cursor") cursor
  |> add (React.JSX.string "cx" "cx") cx
  |> add (React.JSX.string "cy" "cy") cy
  |> add (React.JSX.string "d" "d") d
  |> add (React.JSX.string "decelerate" "decelerate") decelerate
  |> add (React.JSX.string "descent" "descent") descent
  |> add (React.JSX.string "diffuseConstant" "diffuseConstant") diffuseConstant
  |> add (React.JSX.string "direction" "direction") direction
  |> add (React.JSX.string "display" "display") display
  |> add (React.JSX.string "divisor" "divisor") divisor
  |> add (React.JSX.string "dominantBaseline" "dominantBaseline") dominantBaseline
  |> add (React.JSX.string "dur" "dur") dur
  |> add (React.JSX.string "dx" "dx") dx
  |> add (React.JSX.string "dy" "dy") dy
  |> add (React.JSX.string "edgeMode" "edgeMode") edgeMode
  |> add (React.JSX.string "elevation" "elevation") elevation
  |> add (React.JSX.string "enableBackground" "enableBackground") enableBackground
  |> add (React.JSX.string "end" "end") end_
  |> add (React.JSX.string "exponent" "exponent") exponent
  |> add (React.JSX.string "externalResourcesRequired" "externalResourcesRequired") externalResourcesRequired
  |> add (React.JSX.string "fill" "fill") fill
  |> add (React.JSX.string "fillOpacity" "fillOpacity") fillOpacity
  |> add (React.JSX.string "fillRule" "fillRule") fillRule
  |> add (React.JSX.string "filter" "filter") filter
  |> add (React.JSX.string "filterRes" "filterRes") filterRes
  |> add (React.JSX.string "filterUnits" "filterUnits") filterUnits
  |> add (React.JSX.string "flood-color" "floodColor") floodColor
  |> add (React.JSX.string "flood-opacity" "floodOpacity") floodOpacity
  |> add (React.JSX.string "focusable" "focusable") focusable
  |> add (React.JSX.string "font-family" "fontFamily") fontFamily
  |> add (React.JSX.string "font-size" "fontSize") fontSize
  |> add (React.JSX.string "font-size-adjust" "fontSizeAdjust") fontSizeAdjust
  |> add (React.JSX.string "font-stretch" "fontStretch") fontStretch
  |> add (React.JSX.string "font-style" "fontStyle") fontStyle
  |> add (React.JSX.string "font-variant" "fontVariant") fontVariant
  |> add (React.JSX.string "font-weight" "fontWeight") fontWeight
  |> add (React.JSX.string "fomat" "fomat") fomat
  |> add (React.JSX.string "from" "from") from
  |> add (React.JSX.string "fx" "fx") fx
  |> add (React.JSX.string "fy" "fy") fy
  |> add (React.JSX.string "g1" "g1") g1
  |> add (React.JSX.string "g2" "g2") g2
  |> add (React.JSX.string "glyph-name" "glyphName") glyphName
  |> add (React.JSX.string "glyph-orientation-horizontal" "glyphOrientationHorizontal") glyphOrientationHorizontal
  |> add (React.JSX.string "glyph-orientation-vertical" "glyphOrientationVertical") glyphOrientationVertical
  |> add (React.JSX.string "glyphRef" "glyphRef") glyphRef
  |> add (React.JSX.string "gradientTransform" "gradientTransform") gradientTransform
  |> add (React.JSX.string "gradientUnits" "gradientUnits") gradientUnits
  |> add (React.JSX.string "hanging" "hanging") hanging
  |> add (React.JSX.string "horiz-adv-x" "horizAdvX") horizAdvX
  |> add (React.JSX.string "horiz-origin-x" "horizOriginX") horizOriginX
  (* |> add (React.JSX.string "horiz-origin-y" "horizOriginY") horizOriginY *) (* Should be added *)
  |> add (React.JSX.string "ideographic" "ideographic") ideographic
  |> add (React.JSX.string "image-rendering" "imageRendering") imageRendering
  |> add (React.JSX.string "in" "in") in_
  |> add (React.JSX.string "in2" "in2") in2
  |> add (React.JSX.string "intercept" "intercept") intercept
  |> add (React.JSX.string "k" "k") k
  |> add (React.JSX.string "k1" "k1") k1
  |> add (React.JSX.string "k2" "k2") k2
  |> add (React.JSX.string "k3" "k3") k3
  |> add (React.JSX.string "k4" "k4") k4
  |> add (React.JSX.string "kernelMatrix" "kernelMatrix") kernelMatrix
  |> add (React.JSX.string "kernelUnitLength" "kernelUnitLength") kernelUnitLength
  |> add (React.JSX.string "kerning" "kerning") kerning
  |> add (React.JSX.string "keyPoints" "keyPoints") keyPoints
  |> add (React.JSX.string "keySplines" "keySplines") keySplines
  |> add (React.JSX.string "keyTimes" "keyTimes") keyTimes
  |> add (React.JSX.string "lengthAdjust" "lengthAdjust") lengthAdjust
  |> add (React.JSX.string "letterSpacing" "letterSpacing") letterSpacing
  |> add (React.JSX.string "lightingColor" "lightingColor") lightingColor
  |> add (React.JSX.string "limitingConeAngle" "limitingConeAngle") limitingConeAngle
  |> add (React.JSX.string "local" "local") local
  |> add (React.JSX.string "marker-end" "markerEnd") markerEnd
  |> add (React.JSX.string "marker-height" "markerHeight") markerHeight
  |> add (React.JSX.string "marker-mid" "markerMid") markerMid
  |> add (React.JSX.string "marker-start" "markerStart") markerStart
  |> add (React.JSX.string "marker-units" "markerUnits") markerUnits
  |> add (React.JSX.string "markerWidth" "markerWidth") markerWidth
  |> add (React.JSX.string "mask" "mask") mask
  |> add (React.JSX.string "maskContentUnits" "maskContentUnits") maskContentUnits
  |> add (React.JSX.string "maskUnits" "maskUnits") maskUnits
  |> add (React.JSX.string "mathematical" "mathematical") mathematical
  |> add (React.JSX.string "mode" "mode") mode
  |> add (React.JSX.string "numOctaves" "numOctaves") numOctaves
  |> add (React.JSX.string "offset" "offset") offset
  |> add (React.JSX.string "opacity" "opacity") opacity
  |> add (React.JSX.string "operator" "operator") operator
  |> add (React.JSX.string "order" "order") order
  |> add (React.JSX.string "orient" "orient") orient
  |> add (React.JSX.string "orientation" "orientation") orientation
  |> add (React.JSX.string "origin" "origin") origin
  |> add (React.JSX.string "overflow" "overflow") overflow
  |> add (React.JSX.string "overflowX" "overflowX") overflowX
  |> add (React.JSX.string "overflowY" "overflowY") overflowY
  |> add (React.JSX.string "overline-position" "overlinePosition") overlinePosition
  |> add (React.JSX.string "overline-thickness" "overlineThickness") overlineThickness
  |> add (React.JSX.string "paint-order" "paintOrder") paintOrder
  |> add (React.JSX.string "panose1" "panose1") panose1
  |> add (React.JSX.string "pathLength" "pathLength") pathLength
  |> add (React.JSX.string "patternContentUnits" "patternContentUnits") patternContentUnits
  |> add (React.JSX.string "patternTransform" "patternTransform") patternTransform
  |> add (React.JSX.string "patternUnits" "patternUnits") patternUnits
  |> add (React.JSX.string "pointerEvents" "pointerEvents") pointerEvents
  |> add (React.JSX.string "points" "points") points
  |> add (React.JSX.string "pointsAtX" "pointsAtX") pointsAtX
  |> add (React.JSX.string "pointsAtY" "pointsAtY") pointsAtY
  |> add (React.JSX.string "pointsAtZ" "pointsAtZ") pointsAtZ
  |> add (React.JSX.string "preserveAlpha" "preserveAlpha") preserveAlpha
  |> add (React.JSX.string "preserveAspectRatio" "preserveAspectRatio") preserveAspectRatio
  |> add (React.JSX.string "primitiveUnits" "primitiveUnits") primitiveUnits
  |> add (React.JSX.string "r" "r") r
  |> add (React.JSX.string "radius" "radius") radius
  |> add (React.JSX.string "refX" "refX") refX
  |> add (React.JSX.string "refY" "refY") refY
  |> add (React.JSX.string "renderingIntent" "renderingIntent") renderingIntent (* Does it exist? *)
  |> add (React.JSX.string "repeatCount" "repeatCount") repeatCount
  |> add (React.JSX.string "repeatDur" "repeatDur") repeatDur
  |> add (React.JSX.string "requiredExtensions" "requiredExtensions") requiredExtensions (* Does it exists? *)
  |> add (React.JSX.string "requiredFeatures" "requiredFeatures") requiredFeatures
  |> add (React.JSX.string "restart" "restart") restart
  |> add (React.JSX.string "result" "result") result
  |> add (React.JSX.string "rotate" "rotate") rotate
  |> add (React.JSX.string "rx" "rx") rx
  |> add (React.JSX.string "ry" "ry") ry
  |> add (React.JSX.string "scale" "scale") scale
  |> add (React.JSX.string "seed" "seed") seed
  |> add (React.JSX.string "shape-rendering" "shapeRendering") shapeRendering
  |> add (React.JSX.string "slope" "slope") slope
  |> add (React.JSX.string "spacing" "spacing") spacing
  |> add (React.JSX.string "specularConstant" "specularConstant") specularConstant
  |> add (React.JSX.string "specularExponent" "specularExponent") specularExponent
  |> add (React.JSX.string "speed" "speed") speed
  |> add (React.JSX.string "spreadMethod" "spreadMethod") spreadMethod
  |> add (React.JSX.string "startOffset" "startOffset") startOffset
  |> add (React.JSX.string "stdDeviation" "stdDeviation") stdDeviation
  |> add (React.JSX.string "stemh" "stemh") stemh
  |> add (React.JSX.string "stemv" "stemv") stemv
  |> add (React.JSX.string "stitchTiles" "stitchTiles") stitchTiles
  |> add (React.JSX.string "stopColor" "stopColor") stopColor
  |> add (React.JSX.string "stopOpacity" "stopOpacity") stopOpacity
  |> add (React.JSX.string "strikethrough-position" "strikethroughPosition") strikethroughPosition
  |> add (React.JSX.string "strikethrough-thickness" "strikethroughThickness") strikethroughThickness
  |> add (React.JSX.string "stroke" "stroke") stroke
  |> add (React.JSX.string "stroke-dasharray" "strokeDasharray") strokeDasharray
  |> add (React.JSX.string "stroke-dashoffset" "strokeDashoffset") strokeDashoffset
  |> add (React.JSX.string "stroke-linecap" "strokeLinecap") strokeLinecap
  |> add (React.JSX.string "stroke-linejoin" "strokeLinejoin") strokeLinejoin
  |> add (React.JSX.string "stroke-miterlimit" "strokeMiterlimit") strokeMiterlimit
  |> add (React.JSX.string "stroke-opacity" "strokeOpacity") strokeOpacity
  |> add (React.JSX.string "stroke-width" "strokeWidth") strokeWidth
  |> add (React.JSX.string "surfaceScale" "surfaceScale") surfaceScale
  |> add (React.JSX.string "systemLanguage" "systemLanguage") systemLanguage
  |> add (React.JSX.string "tableValues" "tableValues") tableValues
  |> add (React.JSX.string "targetX" "targetX") targetX
  |> add (React.JSX.string "targetY" "targetY") targetY
  |> add (React.JSX.string "text-anchor" "textAnchor") textAnchor
  |> add (React.JSX.string "text-decoration" "textDecoration") textDecoration
  |> add (React.JSX.string "textLength" "textLength") textLength
  |> add (React.JSX.string "text-rendering" "textRendering") textRendering
  |> add (React.JSX.string "to" "to") to_
  |> add (React.JSX.string "transform" "transform") transform
  |> add (React.JSX.string "u1" "u1") u1
  |> add (React.JSX.string "u2" "u2") u2
  |> add (React.JSX.string "underline-position" "underlinePosition") underlinePosition
  |> add (React.JSX.string "underline-thickness" "underlineThickness") underlineThickness
  |> add (React.JSX.string "unicode" "unicode") unicode
  |> add (React.JSX.string "unicode-bidi" "unicodeBidi") unicodeBidi
  |> add (React.JSX.string "unicode-range" "unicodeRange") unicodeRange
  |> add (React.JSX.string "units-per-em" "unitsPerEm") unitsPerEm
  |> add (React.JSX.string "v-alphabetic" "vAlphabetic") vAlphabetic
  |> add (React.JSX.string "v-hanging" "vHanging") vHanging
  |> add (React.JSX.string "v-ideographic" "vIdeographic") vIdeographic
  |> add (React.JSX.string "vMathematical" "vMathematical") vMathematical (* Does it exists? *)
  |> add (React.JSX.string "values" "values") values
  |> add (React.JSX.string "vector-effect" "vectorEffect") vectorEffect
  |> add (React.JSX.string "version" "version") version
  |> add (React.JSX.string "vert-adv-x" "vertAdvX") vertAdvX
  |> add (React.JSX.string "vert-adv-y" "vertAdvY") vertAdvY
  |> add (React.JSX.string "vert-origin-x" "vertOriginX") vertOriginX
  |> add (React.JSX.string "vert-origin-y" "vertOriginY") vertOriginY
  |> add (React.JSX.string "viewBox" "viewBox") viewBox
  |> add (React.JSX.string "viewTarget" "viewTarget") viewTarget
  |> add (React.JSX.string "visibility" "visibility") visibility
  |> add (React.JSX.string "widths" "widths") widths
  |> add (React.JSX.string "word-spacing" "wordSpacing") wordSpacing
  |> add (React.JSX.string "writing-mode" "writingMode") writingMode
  |> add (React.JSX.string "x" "x") x
  |> add (React.JSX.string "x1" "x1") x1
  |> add (React.JSX.string "x2" "x2") x2
  |> add (React.JSX.string "xChannelSelector" "xChannelSelector") xChannelSelector
  |> add (React.JSX.string "x-height" "xHeight") xHeight
  |> add (React.JSX.string "xlink:arcrole" "xlinkActuate") xlinkActuate
  |> add (React.JSX.string "xlinkArcrole" "xlinkArcrole") xlinkArcrole
  |> add (React.JSX.string "xlink:href" "xlinkHref") xlinkHref
  |> add (React.JSX.string "xlink:role" "xlinkRole") xlinkRole
  |> add (React.JSX.string "xlink:show" "xlinkShow") xlinkShow
  |> add (React.JSX.string "xlink:title" "xlinkTitle") xlinkTitle
  |> add (React.JSX.string "xlink:type" "xlinkType") xlinkType
  |> add (React.JSX.string "xmlns" "xmlns") xmlns
  |> add (React.JSX.string "xmlnsXlink" "xmlnsXlink") xmlnsXlink
  |> add (React.JSX.string "xml:base" "xmlBase") xmlBase
  |> add (React.JSX.string "xml:lang" "xmlLang") xmlLang
  |> add (React.JSX.string "xml:space" "xmlSpace") xmlSpace
  |> add (React.JSX.string "y" "y") y
  |> add (React.JSX.string "y1" "y1") y1
  |> add (React.JSX.string "y2" "y2") y2
  |> add (React.JSX.string "yChannelSelector" "yChannelSelector") yChannelSelector
  |> add (React.JSX.string "z" "z") z
  |> add (React.JSX.string "zoomAndPan" "zoomAndPan") zoomAndPan
  |> add (React.JSX.string "about" "about") about
  |> add (React.JSX.string "datatype" "datatype") datatype
  |> add (React.JSX.string "inlist" "inlist") inlist
  |> add (React.JSX.string "prefix" "prefix") prefix
  |> add (React.JSX.string "property" "property") property
  |> add (React.JSX.string "resource" "resource") resource
  |> add (React.JSX.string "typeof" "typeof") typeof
  |> add (React.JSX.string "vocab" "vocab") vocab
  |> add (React.JSX.dangerouslyInnerHtml) dangerouslySetInnerHTML
  |> add (React.JSX.bool "suppressContentEditableWarning" "suppressContentEditableWarning") suppressContentEditableWarning
  |> add (React.JSX.bool "suppressHydrationWarning" "suppressHydrationWarning") suppressHydrationWarning
