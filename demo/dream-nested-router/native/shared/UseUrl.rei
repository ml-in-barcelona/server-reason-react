type t = URL.t;
let to_json: URL.t => [> | `String(string)];
let of_json: Melange_json.t => URL.t;

module Provider: {
  [@react.component]
  let make: (~serverUrl: t, ~children: React.element) => React.element;
};

let use: unit => URL.t;
