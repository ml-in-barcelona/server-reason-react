type parameter = {
  name: string,
  typeName: string,
};

type segment =
  | Static(string)
  | Parameter(parameter);

type t = list(segment);

type error =
  | InvalidPattern(string);

let validLabel = value => {
  let length = String.length(value);
  let first = character =>
    character == '_' || character >= 'a' && character <= 'z';
  let rest = character =>
    first(character)
    || character >= 'A'
    && character <= 'Z'
    || character >= '0'
    && character <= '9'
    || character == '\'';
  length > 0
  && first(value.[0])
  && value
  |> String.to_seq
  |> Seq.for_all(rest);
};

let validTypeName = value => {
  let validPart = part => {
    let length = String.length(part);
    length > 0
    && part
    |> String.to_seq
    |> Seq.for_all(character =>
         character == '_'
         || character >= 'a'
         && character <= 'z'
         || character >= 'A'
         && character <= 'Z'
         || character >= '0'
         && character <= '9'
       );
  };
  value |> String.split_on_char('.') |> List.for_all(validPart);
};

let validStatic = value => {
  let ascii = character =>
    character >= 'a'
    && character <= 'z'
    || character >= 'A'
    && character <= 'Z'
    || character >= '0'
    && character <= '9'
    || (
      switch (character) {
      | '-'
      | '.'
      | '_'
      | '~'
      | '!'
      | '$'
      | '&'
      | '\''
      | '('
      | ')'
      | '*'
      | '+'
      | ','
      | ';'
      | '='
      | ':'
      | '@' => true
      | _ => false
      }
    );
  value != "."
  && value != ".."
  && value
  |> String.to_seq
  |> Seq.for_all(character =>
       Char.code(character) >= 0x80 || ascii(character)
     );
};

let parseParameter = (path, segment) =>
  if (!String.starts_with(~prefix=":", segment)) {
    None;
  } else {
    switch (String.index_opt(segment, '<'), String.index_opt(segment, '>')) {
    | (Some(opening), Some(closing))
        when opening > 1 && closing == String.length(segment) - 1 =>
      let name = String.sub(segment, 1, opening - 1);
      let typeName = String.sub(segment, opening + 1, closing - opening - 1);
      validLabel(name) && validTypeName(typeName)
        ? Some(
            Parameter({
              name,
              typeName,
            }),
          )
        : raise(Invalid_argument(path));
    | _ => raise(Invalid_argument(path))
    };
  };

let parse = path =>
  if (path == "") {
    Ok([]);
  } else if (!String.starts_with(~prefix="/", path)) {
    Error(InvalidPattern(path));
  } else if (path == "/") {
    Ok([]);
  } else {
    let segments = path |> String.split_on_char('/') |> List.tl;
    if (List.exists(segment => segment == "", segments)) {
      Error(InvalidPattern(path));
    } else {
      try(
        Ok(
          segments
          |> List.map(segment =>
               switch (parseParameter(path, segment)) {
               | Some(parameter) => parameter
               | None =>
                 validStatic(segment)
                   ? Static(segment) : raise(Invalid_argument(path))
               }
             ),
        )
      ) {
      | Invalid_argument(_) => Error(InvalidPattern(path))
      };
    };
  };

let toString = pattern =>
  switch (pattern) {
  | [] => "/"
  | segments =>
    "/"
    ++ (
      segments
      |> List.map(segment =>
           switch (segment) {
           | Static(value) => value
           | Parameter({ name, typeName }) =>
             ":" ++ name ++ "<" ++ typeName ++ ">"
           }
         )
      |> String.concat("/")
    )
  };

let segments = pattern => pattern;

let parameters = pattern =>
  pattern
  |> List.filter_map(segment =>
       switch (segment) {
       | Static(_) => None
       | Parameter(parameter) => Some(parameter)
       }
     );

let append = (parent, child) => parent @ child;

let isPrefix = (~prefix, pattern) => {
  let rec loop = (prefix, pattern) =>
    switch (prefix, pattern) {
    | ([], _) => true
    | ([Static(left), ...prefix], [Static(right), ...pattern])
        when String.equal(left, right) =>
      loop(prefix, pattern)
    | ([Parameter(left), ...prefix], [Parameter(right), ...pattern])
        when
          String.equal(left.name, right.name)
          && String.equal(left.typeName, right.typeName) =>
      loop(prefix, pattern)
    | _ => false
    };
  loop(prefix, pattern);
};

let render = (pattern, ~parameter, ~encode) => {
  let rec loop = (rendered, segments) =>
    switch (segments) {
    | [] => Ok("/" ++ (rendered |> List.rev |> String.concat("/")))
    | [Static(value), ...segments] =>
      loop([encode(value), ...rendered], segments)
    | [Parameter({ name, _ }), ...segments] =>
      switch (parameter(name)) {
      | Some(value) => loop([encode(value), ...rendered], segments)
      | None => Error(InvalidPattern("missing route parameter " ++ name))
      }
    };
  loop([], pattern);
};
