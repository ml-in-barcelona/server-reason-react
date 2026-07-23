/* Case 1: Optional ~styles arg.
   PPX should split it into ~className=? / ~style=? on the FFI side. */
module Optional = {
  [@mel.module "some-lib"] [@react.component]
  external make: (~styles: (string, ReactDOM.Style.t)=?, ~children: React.element) =>
                   React.element = "default";
};

/* Case 2: Required ~styles arg.
   The FFI args stay optional (React's contract), but the wrapper requires
   ~styles and forwards Some(fst)/Some(snd). */
module Required = {
  [@mel.module "some-lib"] [@react.component]
  external make: (~styles: (string, ReactDOM.Style.t), ~children: React.element) =>
                   React.element = "default";
};

/* Case 3: Extra args (other than ~styles + ~children) pass through unchanged. */
module Extra = {
  [@mel.module "some-lib"] [@react.component]
  external make:
    (~styles: (string, ReactDOM.Style.t)=?, ~onClick: ReactEvent.Mouse.t => unit=?,
     ~id: string, ~children: React.element) =>
    React.element =
    "default";
};

/* Case 4: External without ~styles is left untouched. */
module NoStyles = {
  [@mel.module "some-lib"] [@react.component]
  external make: (~className: string=?, ~children: React.element) => React.element = "default";
};

/* Case 5: Conflicting ~styles + ~className raises a PPX error. */
module ConflictClassName = {
  [@mel.module "some-lib"] [@react.component]
  external make:
    (~styles: (string, ReactDOM.Style.t)=?, ~className: string=?, ~children: React.element) =>
    React.element =
    "default";
};

/* Case 6: Conflicting ~styles + ~style raises a PPX error. */
module ConflictStyle = {
  [@mel.module "some-lib"] [@react.component]
  external make:
    (~styles: (string, ReactDOM.Style.t)=?, ~style: ReactDOM.Style.t=?, ~children: React.element) =>
    React.element =
    "default";
};
