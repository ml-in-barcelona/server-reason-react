open Ppx_deriving_json_runtime.Primitives;

Js.log("SNC, loaded???");

[@react.client.component]
let make =
    (
      ~id: string,
      ~title: string,
      ~children: React.element,
      ~expandedChildren: React.element,
    ) => {
  Js.log("AAA!!!");
  Js.log(title);

  let router = ClientRouter.useRouter();
  let (isPending, startTransition) = React.useTransition();
  ignore(isPending);
  let (isExpanded, setIsExpanded) = React.useState(() => false);
  let isActive =
    switch (router.location.selectedId) {
    | Some(id) => id == id
    | None => false
    };

  let baseClassName = "relative mb-3 p-4 w-full flex justify-between items-start flex-wrap transition-[max-height] duration-250 ease-out scale-100";
  let expandedClassName =
    isExpanded
      ? " max-h-[300px] transition-[max-height] duration-500 ease-linear" : "";

  <div
    className={Cx.make([baseClassName, expandedClassName])}
    onClick={_ => {
      Js.log("onClick");
      startTransition(() => {
        Js.log("onClick");
        router.navigate({
          selectedId: Some(id),
          isEditing: false,
          searchText: None,
        });
      });
    }}>
    children
    <button
      className={Cx.make([
        "absolute inset-0 w-full z-0 rounded-md text-left text-transparent text-[0px] outline-none",
        Theme.background(Theme.Color.fadedBlack),
        isActive
          ? Theme.border(Theme.Color.darkYellow) : Theme.border(Theme.none),
      ])}>
      {React.string("Open note for preview")}
    </button>
    <button
      className="sidebar-note-toggle-expand"
      onClick={e => {
        Js.log("EXPANDDDD");
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
