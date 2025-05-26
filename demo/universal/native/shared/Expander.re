[@warning "-26-27-32"];

open Melange_json.Primitives;

[@react.client.component]
let make =
    (
      ~id: int,
      ~title: string,
      ~children: React.element,
      ~expandedChildren: React.element,
    ) => {
  let (isExpanded, setIsExpanded) = RR.useStateValue(false);
  let (isPending, startTransition) = React.useTransition();

  <div
    className={Cx.make([
      "mb-3 flex flex-col rounded-md",
      Theme.background(Theme.Color.Gray4),
      Theme.border(Theme.Color.None),
    ])}>
    <div
      className={Cx.make([
        "relative p-4 w-full justify-between items-start flex-wrap transition-[max-height] duration-250 ease-out scale-100 flex flex-col gap-1 cursor-pointer",
      ])}>
      children
      {isExpanded ? expandedChildren : React.null}
    </div>
    <div
      className="px-4 mt-1 mb-4 cursor-pointer self-center w-full"
      onClick={_ => setIsExpanded(!isExpanded)}>
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
      </div>
    </div>
  </div>;
};
