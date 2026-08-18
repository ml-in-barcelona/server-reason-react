type parameter = {
  name: string,
  typeName: string,
};

type segment =
  | Static(string)
  | Parameter(parameter)
  | CatchAll({name: string});

type t = list(segment);

type error =
  | InvalidPattern(string);

type relationship =
  | Distinct
  | Duplicate
  | Ambiguous
  | CompatiblePrefix
  | IncompatiblePrefix;

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
  let validModuleName = name => {
    let length = String.length(name);
    let rest = character =>
      character == '_'
      || character == '\''
      || character >= 'a'
      && character <= 'z'
      || character >= 'A'
      && character <= 'Z'
      || character >= '0'
      && character <= '9';
    length > 0
    && name.[0] >= 'A'
    && name.[0] <= 'Z'
    && name
    |> String.to_seq
    |> Seq.for_all(rest);
  };
  switch (String.split_on_char('.', value)) {
  | ["bool"]
  | ["int"]
  | ["string"] => true
  | parts =>
    switch (List.rev(parts)) {
    | ["t", ...moduleNames] when moduleNames != [] =>
      List.for_all(validModuleName, moduleNames)
    | _ => false
    }
  };
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

let encodeStaticSegment = value => {
  let hex = "0123456789ABCDEF";
  let unescaped = character =>
    character >= 'a'
    && character <= 'z'
    || character >= 'A'
    && character <= 'Z'
    || character >= '0'
    && character <= '9'
    || (
      switch (character) {
      | '-'
      | '_'
      | '.'
      | '!'
      | '~'
      | '*'
      | '\''
      | '('
      | ')' => true
      | _ => false
      }
    );
  value
  |> String.to_seq
  |> Seq.map(character =>
       if (unescaped(character)) {
         String.make(1, character);
       } else {
         let code = Char.code(character);
         "%"
         ++ String.make(1, hex.[code lsr 4])
         ++ String.make(1, hex.[code land 0x0f]);
       }
     )
  |> List.of_seq
  |> String.concat("");
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
      if (!validLabel(name)) {
        raise(Invalid_argument(path));
      } else if (typeName == "string...") {
        Some(CatchAll({ name: name }));
      } else if (validTypeName(typeName)) {
        Some(
          Parameter({
            name,
            typeName,
          }),
        );
      } else {
        raise(Invalid_argument(path));
      };
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
      let rec catchAllIsFinal = segments =>
        switch (segments) {
        | []
        | [CatchAll(_)] => true
        | [CatchAll(_), ..._] => false
        | [_, ...rest] => catchAllIsFinal(rest)
        };
      try({
        let parsed =
          segments
          |> List.map(segment =>
               switch (parseParameter(path, segment)) {
               | Some(parameter) => parameter
               | None =>
                 validStatic(segment)
                   ? Static(segment) : raise(Invalid_argument(path))
               }
             );
        catchAllIsFinal(parsed) ? Ok(parsed) : Error(InvalidPattern(path));
      }) {
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
           | CatchAll({ name }) => ":" ++ name ++ "<string...>"
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
       | CatchAll({ name }) =>
         Some({
           name,
           typeName: "string...",
         })
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

let isShapePrefix = (~prefix, pattern) => {
  let rec loop = (prefix, pattern) =>
    switch (prefix, pattern) {
    | ([], _) => true
    | ([Static(left), ...prefix], [Static(right), ...pattern])
        when String.equal(left, right) =>
      loop(prefix, pattern)
    | ([Parameter(_), ...prefix], [Parameter(_), ...pattern]) =>
      loop(prefix, pattern)
    | _ => false
    };
  loop(prefix, pattern);
};

/* Lexicographic (static count, finite shape) encoded as one int: a route
   without a catch-all beats a catch-all route with the same static count. */
let specificity = pattern => {
  let (statics, finite) =
    List.fold_left(
      ((statics, finite), segment) =>
        switch (segment) {
        | Static(_) => (statics + 1, finite)
        | Parameter(_) => (statics, finite)
        | CatchAll(_) => (statics, 0)
        },
      (0, 1),
      pattern,
    );
  statics * 2 + finite;
};

let overlaps = (left, right) => {
  let rec loop = (left, right) =>
    switch (left, right) {
    | ([], []) => true
    | (
        [Static(leftValue), ...leftRest],
        [Static(rightValue), ...rightRest],
      ) =>
      String.equal(leftValue, rightValue) && loop(leftRest, rightRest)
    | ([_, ...leftRest], [_, ...rightRest]) => loop(leftRest, rightRest)
    | _ => false
    };
  loop(left, right);
};

let relationship = (left, right) => {
  let leftSegments = segments(left);
  let rightSegments = segments(right);
  if (String.equal(toString(left), toString(right))) {
    Duplicate;
  } else if (List.length(leftSegments) == List.length(rightSegments)) {
    specificity(left) == specificity(right)
    && overlaps(leftSegments, rightSegments)
      ? Ambiguous : Distinct;
  } else {
    let (prefix, pattern) =
      List.length(leftSegments) < List.length(rightSegments)
        ? (left, right) : (right, left);
    if (isShapePrefix(~prefix, pattern)) {
      isPrefix(~prefix, pattern) ? CompatiblePrefix : IncompatiblePrefix;
    } else {
      Distinct;
    };
  };
};

let render = (pattern, ~parameter, ~encodeStatic, ~encodeParameter) => {
  let rec loop = (rendered, segments) =>
    switch (segments) {
    | [] => Ok("/" ++ (rendered |> List.rev |> String.concat("/")))
    | [Static(value), ...segments] =>
      loop([encodeStatic(value), ...rendered], segments)
    | [Parameter({ name, _ }), ...segments] =>
      switch (parameter(name)) {
      | Some(value) =>
        loop([encodeParameter(value), ...rendered], segments)
      | None => Error(InvalidPattern("missing route parameter " ++ name))
      }
    | [CatchAll({ name }), ...segments] =>
      switch (parameter(name)) {
      | Some(value) =>
        let encoded =
          value
          |> String.split_on_char('/')
          |> List.map(encodeParameter)
          |> String.concat("/");
        loop([encoded, ...rendered], segments);
      | None => Error(InvalidPattern("missing route parameter " ++ name))
      }
    };
  loop([], pattern);
};
