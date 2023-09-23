/* Mixin */
module Impl = (T: {
                 type t;
               }) => {
  [@mel.get] [@mel.return nullable]
  external assignedSlot: T.t => option(Dom.htmlSlotElement) = "assignedSlot";
};
