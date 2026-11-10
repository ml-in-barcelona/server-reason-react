include RouterTypes;

type pattern =
  | Pattern(RouterPattern.t);

let encode = Js.Global.encodeURIComponent;
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
let destination = (~path) => makeDestination(path);

let pattern = path =>
  switch (RouterPattern.parse(path)) {
  | Ok(pattern) => Pattern(pattern)
  | Error(_) => invalid_arg("invalid generated route pattern " ++ path)
  };

/* encodeURIComponent throws on lone surrogates. URLSearchParams, which this
   replaced, turned them into U+FFFD, so search keeps doing that. */
let replaceLoneSurrogates: string => string = [%mel.raw
  {|(value) => value.replace(/[\uD800-\uDBFF](?![\uDC00-\uDFFF])|(?<![\uD800-\uDBFF])[\uDC00-\uDFFF]/g, "�")|}
];
let encodeSearchPart = value => encode(replaceLoneSurrogates(value));

/* UTF-16 order differs from code point order (and from native UTF-8 byte order) when astral
   characters meet U+E000-U+FFFF. Shifting surrogates above that range fixes the order and is
   total for lone surrogates. */
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
       List.map(
         value => encodeSearchPart(name) ++ "=" ++ encodeSearchPart(value),
         values,
       )
     )
  |> String.concat("&");

let destinationFromPattern = (~pattern, ~parameters, ~search) => {
  let Pattern(pattern) = pattern;
  let parameter = name => List.assoc_opt(name, parameters);
  let path =
    switch (
      RouterPattern.render(
        pattern,
        ~parameter,
        ~encodeStatic=RouterPattern.encodeStaticSegment,
        ~encodeParameter=encodeSegment,
      )
    ) {
    | Ok(path) => path
    | Error(InvalidPattern(message)) => invalid_arg(message)
    };
  let search = encodeSearch(search);
  let finalPath: string = search == "" ? path : path ++ "?" ++ search;
  destination(~path=finalPath);
};

let href = destinationHref;
