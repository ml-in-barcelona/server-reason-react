[@warning "-26-27-32"];

open Ppx_deriving_json_runtime.Primitives;

module Square = {
  [@react.component]
  let make = (~isExpanded) => {
    <div
      className={Cx.make([
        isExpanded ? "" : "rotate-180",
        "w-6 h-6 rounded-md border-2 flex items-center justify-center pt-1 text-white text-sm select-none",
        "transition-[background-color] duration-250 ease-out",
        Theme.background(Theme.Color.fadedBlack),
        Theme.hover([Theme.background(Theme.Color.darkYellow)]),
      ])}>
      {React.string("^")}
    </div>;
  };
};

[@react.client.component]
let make =
    (
      ~id: int,
      ~title: string,
      ~children: React.element,
      ~expandedChildren: React.element,
    ) => {
  let router = ClientRouter.useRouter();
  let (isPending, startTransition) = React.useTransition();
  let (isExpanded, setIsExpanded) = React.useState(() => false);
  let isActive = false;
  /* let isActive =
     switch (router.location.selectedId) {
     | Some(id) => id == id
     | None => false
     }; */

  let baseClassName = "relative mb-3 p-4 w-full flex justify-between items-start flex-wrap transition-[max-height] duration-250 ease-out scale-100 rounded-md";

  <div
    className={Cx.make([
      /* isExpanded
         ? "max-h-[300px] transition-[max-height] duration-500 ease-linear" : "", */
      isActive
        ? Theme.border(Theme.Color.darkYellow) : Theme.border(Theme.none),
      baseClassName,
      Theme.background(Theme.Color.fadedBlack),
    ])}
    onMouseEnter={_ => {Js.log("onMouseEnter!!!!!!!!!!!!!!!!!!!!!!!")}}
    onClick={_ => {
      startTransition(() => {
        router.navigate({
          selectedId: Some(id),
          isEditing: false,
          searchText: None,
        })
      })
    }}>
    children
    <div
      className="outline-none cursor-pointer"
      onClick={e => {
        Js.log("EXPANDDDD");
        React.Event.Mouse.stopPropagation(e);
        setIsExpanded(prev => !prev);
      }}>
      <Square isExpanded />
    </div>
    {isExpanded ? expandedChildren : React.null}
  </div>;
};
