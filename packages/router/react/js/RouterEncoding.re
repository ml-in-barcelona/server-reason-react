type pattern =
  | Pattern(RouterPattern.t);

let encode = value =>
  try(Js.Global.encodeURIComponent(value)) {
  | _ => invalid_arg("URI malformed")
  };
let encodeSegment = value => {
  if (value == ""
      || value == "."
      || value == ".."
      || String.contains(value, '/')
      || !
           String.for_all(
             character => {
               let code = Char.code(character);
               code >= 0x20 && code != 0x7f;
             },
             value,
           )) {
    invalid_arg("route parameters must be valid non-empty path segments");
  };
  try(encode(value)) {
  | _ => invalid_arg("route parameters must be valid non-empty path segments")
  };
};

let pattern = path =>
  switch (RouterPattern.parseTemplate(path)) {
  | Ok(pattern) => Pattern(pattern)
  | Error(_) => invalid_arg("invalid generated route pattern " ++ path)
  };

let codePointUnitOrder = unit =>
  if (unit >= 0xd800 && unit <= 0xdfff) {
    unit + 0x2000;
  } else if (unit >= 0xe000) {
    unit - 0x800;
  } else {
    unit;
  };

let compareByCodePoint = (left, right) => {
  let leftLength = Js.String.length(left);
  let rightLength = Js.String.length(right);
  let rec loop = index =>
    if (index >= leftLength || index >= rightLength) {
      compare(leftLength, rightLength);
    } else {
      let order =
        compare(
          codePointUnitOrder(
            Js.String.charCodeAt(~index, left) |> int_of_float,
          ),
          codePointUnitOrder(
            Js.String.charCodeAt(~index, right) |> int_of_float,
          ),
        );
      order == 0 ? loop(index + 1) : order;
    };
  loop(0);
};

let encodeSearch = search =>
  search
  |> List.stable_sort(((left, _), (right, _)) =>
       compareByCodePoint(left, right)
     )
  |> List.concat_map(((name, values)) =>
       List.map(value => encode(name) ++ "=" ++ encode(value), values)
     )
  |> String.concat("&");

let destinationFromPattern = (~pattern, ~parameters, ~search) => {
  let Pattern(pattern) = pattern;
  RouterTypes.renderDestination(
    ~pattern,
    ~parameters,
    ~search,
    ~encodeParameter=encodeSegment,
    ~encodeSearch,
  );
};

let withHash = RouterTypes.destinationWithHash(~encode);
