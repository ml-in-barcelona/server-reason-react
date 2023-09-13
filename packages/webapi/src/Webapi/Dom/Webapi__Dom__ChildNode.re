/* Mixin */
module Impl = (T: {
                 type t;
               }) => {
  [@mel.send.pipe: T.t] external remove: unit = "remove";
};
