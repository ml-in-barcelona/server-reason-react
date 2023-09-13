/* Mixin */
module Impl = (T: {
                 type t;
               }) => {
  [@mel.get] external children: T.t => Dom.htmlCollection = "children";
  [@mel.get] [@mel.return nullable]
  external firstElementChild: T.t => option(Dom.element) =
    "firstElementChild";
  [@mel.get] [@mel.return nullable]
  external lastElementChild: T.t => option(Dom.element) = "lastElementChild";
  [@mel.get] external childElementCount: T.t => int = "childElementCount";
  [@mel.send.pipe: T.t] [@mel.return nullable]
  external querySelector: string => option(Dom.element) = "querySelector";
  [@mel.send.pipe: T.t]
  external querySelectorAll: string => Dom.nodeList = "querySelectorAll";
};
