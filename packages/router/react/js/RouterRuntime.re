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
  let search =
    search
    |> List.sort(((left, _), (right, _)) => String.compare(left, right))
    |> List.concat_map(((name, values)) =>
         List.map(value => encode(name) ++ "=" ++ encode(value), values)
       )
    |> String.concat("&");
  let finalPath: string = search == "" ? path : path ++ "?" ++ search;
  destination(~path=finalPath);
};

let href = destinationHref;
