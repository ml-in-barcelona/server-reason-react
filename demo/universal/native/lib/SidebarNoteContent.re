[@warning "-33-26"];

open Ppx_deriving_json_runtime.Primitives;

[@react.client.component]
let make =
    (
      ~id: string,
      ~title: string,
      ~children: React.element,
      ~expandedChildren: React.element,
    ) => {
  let router = Router.useRouter();
  let (isPending, startTransition) = React.useTransition();
  let (isExpanded, setIsExpanded) = React.useState(() => false);
  let isActive =
    switch (router.location.selectedId) {
    | Some(id) => id == id
    | None => false
    };

  let itemRef = React.useRef(Js.Nullable.null);
  let prevTitleRef = React.useRef(title);

  React.useEffect1(
    () => {
      if (title != prevTitleRef.current) {
        prevTitleRef.current = title;
        switch (Js.Nullable.toOption(itemRef.current)) {
        | Some(element) =>
          element
          |> Webapi.Dom.Element.classList
          |> Webapi.Dom.DomTokenList.add("flash")
        | None => ()
        };
      };
      None;
    },
    [|title|],
  );

  let baseClassName = "sidebar-note-list-item";
  let expandedClassName = isExpanded ? " note-expanded" : "";
  let className = baseClassName ++ expandedClassName;

  <div
    ref={ReactDOM.Ref.domRef(itemRef)}
    className
    onAnimationEnd={_ => {
      switch (Js.Nullable.toOption(itemRef.current)) {
      | Some(element) =>
        element
        |> Webapi.Dom.Element.classList
        |> Webapi.Dom.DomTokenList.remove("flash")
      | None => ()
      }
    }}>
    children
    <button
      className="sidebar-note-open"
      style={ReactDOM.Style.make(
        ~backgroundColor=
          switch (isPending, isActive) {
          | (true, _) => "var(--gray-80)"
          | (_, true) => "var(--tertiary-blue)"
          | _ => ""
          },
        ~border=
          isActive
            ? "1px solid var(--primary-border)" : "1px solid transparent",
        (),
      )}
      onClick={_ => {
        startTransition(() => {
          router.navigate({
            selectedId: Some(id),
            isEditing: false,
            searchText: None,
          })
        })
      }}>
      {React.string("Open note for preview")}
    </button>
    <button
      className="sidebar-note-toggle-expand"
      onClick={e => {
        React.Event.Mouse.stopPropagation(e);
        setIsExpanded(prev => !prev);
      }}>
      {if (isExpanded) {
         <img
           src="chevron-down.svg"
           width="10px"
           height="10px"
           alt="Collapse"
         />;
       } else {
         <img src="chevron-up.svg" width="10px" height="10px" alt="Expand" />;
       }}
    </button>
    {isExpanded ? expandedChildren : React.null}
  </div>;
};
