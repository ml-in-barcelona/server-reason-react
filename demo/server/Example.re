[@react.component]
let make =
    (
      ~className as _: string,
      ~placeholder as _: string,
      ~value as _: string,
      ~ariaLabel as _: string,
      ~autoFocus as _: bool,
      ~spellCheck as _: bool,
      ~dir as _: string,
      ~onChange as _: React.Event.Form.t => unit,
      ~onFocus as _,
    ) =>
  React.int(3);

let make =
  [@warning "-16"]
  (
    (
      ~key as _=?,
      ~className as _: string,
      ~placeholder as _: string,
      ~value as _: string,
      ~ariaLabel as _: string,
      ~autoFocus as _: bool,
      ~spellCheck as _: bool,
      ~dir as _: string,
      ~onChange as _: React.Event.Form.t => unit,
    ) =>
      [@warning "-16"] ((~onFocus as _, ()) => React.int(3))
  );
