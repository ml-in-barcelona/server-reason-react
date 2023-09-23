/* Mixin */
module Impl = (T: {
                 type t;
               }) => {
  [@mel.get] [@mel.return nullable]
  external previousElementSibling: T.t => option(Dom.element) =
    "previousElementSibling";
  [@mel.get] [@mel.return nullable]
  external nextElementSibling: T.t => option(Dom.element) =
    "nextElementSibling";
};
