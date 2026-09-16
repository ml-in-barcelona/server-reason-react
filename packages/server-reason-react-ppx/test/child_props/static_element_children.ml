module Typed = struct
  let[@react.component] make ~(children : React.element) = React.Children.only children
end

module Optional = struct
  let[@react.component] make ?(children : React.element option) () =
    match children with None -> React.null | Some child -> React.Children.only child
end

module Default = struct
  let[@react.component] make ?(children : React.element = React.null) () = React.Children.only children
end

module Forward = struct
  let makeProps ~children () = children
  let make children = children
end

module Alias = Forward

module Inferred = struct
  let[@react.component] make ~children = React.list [ children ]
end

type element_alias = React.element

module TypeAlias = struct
  let[@react.component] make ~(children : element_alias) = React.list [ children ]
end

let marked = function React.Static_child child -> child | _ -> failwith "expected static element occurrence"

let () =
  let bare = React.createElement "span" [] [ React.string "child" ] in
  let props = Typed.makeProps ~children:bare () in
  assert (marked props#children == bare);
  let forwarded = match Typed.make props with React.Upper_case_component (_, run) -> run () | _ -> assert false in
  assert (forwarded == props#children);
  assert (React.Children.only (React.list [ forwarded ]) == forwarded);
  let cloned = React.cloneElement forwarded [ React.JSX.String ("id", "id", "clone") ] in
  assert (React.isValidElement (marked cloned));
  assert (ReactDOM.renderToStaticMarkup cloned = "<span id=\"clone\">child</span>");
  assert ((Typed.makeProps ~children:forwarded ())#children == forwarded);
  let dynamic = React.list [ bare ] in
  assert ((Typed.makeProps ~children:dynamic ())#children == dynamic);
  assert (React.Children.only (Typed.makeProps ~children:dynamic ())#children == bare);
  let writer =
    React.Writer { emit = (fun _ ~separators:_ -> ()); original = (fun () -> failwith "props must not force original") }
  in
  assert (marked (Typed.makeProps ~children:writer ())#children == writer);
  assert ((Optional.makeProps ())#children = None);
  assert (marked (Option.get (Optional.makeProps ~children:bare ())#children) == bare);
  assert (Option.get (Optional.makeProps ~children:dynamic ())#children == dynamic);
  assert (ReactDOM.renderToStaticMarkup (Optional.make (Optional.makeProps ~children:bare ())) = "<span>child</span>");
  assert ((Default.makeProps ())#children = None);
  assert (marked (Option.get (Default.makeProps ~children:bare ())#children) == bare);
  assert (ReactDOM.renderToStaticMarkup (Default.make (Default.makeProps ())) = "");
  let calls = ref 0 in
  let child () =
    incr calls;
    bare
  in
  let explicit = (Forward.createElement ~children:[ (child () : React.element) ] () [@JSX]) in
  assert (!calls = 1);
  assert (marked explicit == bare);
  let jsx = (Alias.createElement ~children:[ (span ~children:[] () [@JSX]) ] () [@JSX]) in
  assert (React.isValidElement (marked jsx));
  let unknown = (Alias.createElement ~children:[ bare ] () [@JSX]) in
  assert (unknown == bare);
  let custom = (Alias.createElement ~children:[ "custom" ] () [@JSX]) in
  assert (custom = "custom");
  let alias = (Alias.createElement ~children:[ (bare : element_alias) ] () [@JSX]) in
  assert (alias == bare);
  let alias_props = TypeAlias.makeProps ~children:bare () in
  assert (alias_props#children == bare);
  assert (ReactDOM.renderToStaticMarkup (TypeAlias.make alias_props) = "<span>child</span>");
  let inferred = (Inferred.createElement ~children:[ bare ] () [@JSX]) in
  (match inferred with
  | React.Upper_case_component (_, run) -> assert (React.Children.only (run ()) == bare)
  | _ -> assert false);
  let host = React.createElement "div" [] [ unknown ] in
  match host with
  | React.Lower_case_element { children = [ child ]; _ } -> assert (marked child == bare)
  | _ -> assert false
