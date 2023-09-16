/* Mixin */
module Impl = (T: {
                 type t;
               }) => {
  [@mel.send.pipe: T.t] [@mel.return nullable]
  external getElementById: string => option(Dom.element) = "getElementById";
};
