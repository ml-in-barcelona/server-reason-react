[@warning "-26-27-33"];

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

  let baseClassName = "relative mb-3 p-4 w-full flex justify-between items-start flex-wrap transition-[max-height] duration-250 ease-out scale-100";
  let expandedClassName =
    isExpanded
      ? " max-h-[300px] transition-[max-height] duration-500 ease-linear" : "";

  <div
    ref={ReactDOM.Ref.domRef(itemRef)}
    className={Cx.make([baseClassName, expandedClassName])}
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
      className={Cx.make([
        "absolute inset-0 w-full z-0 rounded-md text-left cursor-pointer text-transparent text-[0px] outline-none",
        Theme.background(Theme.Color.fadedBlack),
        isActive
          ? Theme.border(Theme.Color.darkYellow) : Theme.border(Theme.none),
      ])}
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
