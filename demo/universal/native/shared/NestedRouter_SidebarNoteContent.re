open Melange_json.Primitives;
module DOM = Webapi.Dom;
module Location = DOM.Location;

module Square = {
  [@react.component]
  let make = (~isExpanded) => {
    <div
      className={Cx.make([
        isExpanded ? "" : "rotate-180",
        "w-full rounded-md flex items-center justify-center pt-1 text-sm select-none",
        "transition-[background-color] duration-250 ease-out",
        Theme.text(Theme.Color.Gray11),
        Theme.background(Theme.Color.Gray5),
        Theme.hover([Theme.background(Theme.Color.Gray7)]),
      ])}>
      {React.string("^")}
    </div>;
  };
};

[@react.client.component]
let make =
    (~id: int, ~children: React.element, ~expandedChildren: React.element) => {
  let navigate = Router.use();
  let dynamicParams = DynamicParams.use();
  let (isExpanded, setIsExpanded) = RR.useStateValue(false);
  let (isNavigating, startNavigating) = React.useTransition();

  let isActive =
    switch (DynamicParams.find("id", dynamicParams)) {
    | Some(selectedId) => selectedId == Int.to_string(id)
    | None => false
    };

  <div
    className={Cx.make([
      "mb-3 flex flex-col rounded-md border-2",
      Theme.background(Theme.Color.Gray4),
      isActive
        ? Theme.border(Theme.Color.Gray14) : Theme.border(Theme.Color.Gray4),
    ])}>
    <button
      disabled={isActive || isNavigating}
      className={Cx.make([
        "relative p-4 w-full justify-between items-start flex-wrap transition-[max-height] duration-250 ease-out scale-100 flex flex-col gap-1 cursor-pointer",
      ])}
      onClick=[%browser_only
        _ => {
          let queryParams =
            URL.makeExn(Location.href(DOM.window->DOM.Window.location))
            |> URL.searchParams
            |> URL.SearchParams.toString;
          let queryParamsSuffix = queryParams == "" ? "" : "?" ++ queryParams;
          startNavigating(() => {
            navigate(
              "/demo/router/" ++ Int.to_string(id) ++ queryParamsSuffix,
            )
          });
        }
      ]>
      children
      {isExpanded ? expandedChildren : React.null}
    </button>
    <div
      className="px-4 mt-1 mb-4 cursor-pointer self-center w-full"
      onClick={_ => setIsExpanded(!isExpanded)}>
      <Square isExpanded />
    </div>
  </div>;
};
