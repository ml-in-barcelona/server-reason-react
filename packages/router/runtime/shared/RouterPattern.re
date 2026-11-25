type parameter = {
  name: string,
  typeName: string,
};

type segment =
  | Static(string)
  | Parameter(parameter)
  | CatchAll({name: string});

type t = list((segment, bool));

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
  && value != "_"
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
  let buffer = Buffer.create(String.length(value));
  String.iter(
    character =>
      if (unescaped(character)) {
        Buffer.add_char(buffer, character);
      } else {
        let code = Char.code(character);
        Buffer.add_char(buffer, '%');
        Buffer.add_char(buffer, hex.[code lsr 4]);
        Buffer.add_char(buffer, hex.[code land 0x0f]);
      },
    value,
  );
  Buffer.contents(buffer);
};

let parseParameter = (~allowOptional, path, segment) =>
  if (!String.starts_with(~prefix=":", segment)) {
    None;
  } else {
    switch (String.index_opt(segment, '<'), String.index_opt(segment, '>')) {
    | (Some(opening), Some(closing))
        when opening > 1 && closing == String.length(segment) - 1 =>
      let label = String.sub(segment, 1, opening - 1);
      let optional = String.ends_with(~suffix="?", label);
      let name =
        optional ? String.sub(label, 0, String.length(label) - 1) : label;
      let typeName = String.sub(segment, opening + 1, closing - opening - 1);
      let segment =
        if (!validLabel(name) || optional && !allowOptional) {
          raise(Invalid_argument(path));
        } else if (typeName == "string...") {
          CatchAll({ name: name });
        } else if (validTypeName(typeName)) {
          Parameter({
            name,
            typeName,
          });
        } else {
          raise(Invalid_argument(path));
        };
      let item = (segment, optional);
      Some(item);
    | _ => raise(Invalid_argument(path))
    };
  };

let parseWith = (~allowOptional, path) =>
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
        | [(CatchAll(_), _)] => true
        | [(CatchAll(_), _), ..._] => false
        | [_, ...rest] => catchAllIsFinal(rest)
        };
      try({
        let parsed =
          segments
          |> List.map(segment =>
               switch (parseParameter(~allowOptional, path, segment)) {
               | Some(parameter) => parameter
               | None =>
                 validStatic(segment)
                   ? (Static(segment), false)
                   : raise(Invalid_argument(path))
               }
             );
        catchAllIsFinal(parsed) ? Ok(parsed) : Error(InvalidPattern(path));
      }) {
      | Invalid_argument(_) => Error(InvalidPattern(path))
      };
    };
  };

let parse = parseWith(~allowOptional=false);
let parseTemplate = parseWith(~allowOptional=true);

let toString = pattern =>
  switch (pattern) {
  | [] => "/"
  | segments =>
    "/"
    ++ (
      segments
      |> List.map(((segment, optional)) => {
           let marker = optional ? "?" : "";
           switch (segment) {
           | Static(value) => value
           | Parameter({ name, typeName }) =>
             ":" ++ name ++ marker ++ "<" ++ typeName ++ ">"
           | CatchAll({ name }) => ":" ++ name ++ marker ++ "<string...>"
           };
         })
      |> String.concat("/")
    )
  };

let segments = pattern => List.map(fst, pattern);

let optional = pattern =>
  pattern
  |> List.filter_map(((segment, optional)) =>
       switch (segment) {
       | Parameter({ name, _ })
       | CatchAll({ name }) when optional => Some(name)
       | Static(_)
       | Parameter(_)
       | CatchAll(_) => None
       }
     );

let rec shapes = pattern =>
  switch (pattern) {
  | [] => [[]]
  | [(segment, optional), ...rest] =>
    let rest = shapes(rest);
    let present = List.map(shape => [(segment, false), ...shape], rest);
    optional ? present @ rest : present;
  };

let parameters = pattern =>
  segments(pattern)
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

let isPrefixSegments = (prefix, pattern) => {
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
    | ([CatchAll(left), ...prefix], [CatchAll(right), ...pattern])
        when String.equal(left.name, right.name) =>
      loop(prefix, pattern)
    | _ => false
    };
  loop(prefix, pattern);
};

let isPrefix = (~prefix, pattern) =>
  isPrefixSegments(segments(prefix), segments(pattern));

let isShapePrefixSegments = (prefix, pattern) => {
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

let specificitySegments = segments => {
  let (statics, finite) =
    List.fold_left(
      ((statics, finite), segment) =>
        switch (segment) {
        | Static(_) => (statics + 1, finite)
        | Parameter(_) => (statics, finite)
        | CatchAll(_) => (statics, 0)
        },
      (0, 1),
      segments,
    );
  statics * 2 + finite;
};

let specificity = pattern => specificitySegments(segments(pattern));

let overlaps = (left, right) => {
  let rec loop = (left, right) =>
    switch (left, right) {
    | ([], []) => true
    | ([CatchAll(_), ..._], [_, ..._])
    | ([_, ..._], [CatchAll(_), ..._]) => true
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
  if (left == right) {
    Duplicate;
  } else if (specificitySegments(leftSegments)
             == specificitySegments(rightSegments)
             && overlaps(leftSegments, rightSegments)) {
    Ambiguous;
  } else if (List.length(leftSegments) == List.length(rightSegments)) {
    Distinct;
  } else {
    let (prefix, pattern) =
      List.length(leftSegments) < List.length(rightSegments)
        ? (leftSegments, rightSegments) : (rightSegments, leftSegments);
    if (isShapePrefixSegments(prefix, pattern)) {
      isPrefixSegments(prefix, pattern)
        ? CompatiblePrefix : IncompatiblePrefix;
    } else {
      Distinct;
    };
  };
};

let render = (pattern, ~parameter, ~encodeStatic, ~encodeParameter) => {
  let rec loop = (rendered, segments) =>
    switch (segments) {
    | [] => Ok("/" ++ (rendered |> List.rev |> String.concat("/")))
    | [(Static(value), _), ...segments] =>
      loop([encodeStatic(value), ...rendered], segments)
    | [(Parameter({ name, _ }), optional), ...segments] =>
      switch (parameter(name)) {
      | Some(value) =>
        loop([encodeParameter(value), ...rendered], segments)
      | None when optional => loop(rendered, segments)
      | None => Error(InvalidPattern("missing route parameter " ++ name))
      }
    | [(CatchAll({ name }), optional), ...segments] =>
      switch (parameter(name)) {
      | Some(value) =>
        let encoded =
          value
          |> String.split_on_char('/')
          |> List.map(encodeParameter)
          |> String.concat("/");
        loop([encoded, ...rendered], segments);
      | None when optional => loop(rendered, segments)
      | None => Error(InvalidPattern("missing route parameter " ++ name))
      }
    };
  loop([], pattern);
};

let unicodeStrings = String.length({js|é|js}) == 1;

let utf8 = value =>
  if (!unicodeStrings) {
    value;
  } else {
    let length = String.length(value);
    let buffer = Buffer.create(length);
    let add = code => Buffer.add_char(buffer, Char.chr(code));
    let rec loop = index =>
      if (index < length) {
        let unit = Char.code(value.[index]);
        let low = index + 1 < length ? Char.code(value.[index + 1]) : 0;
        let (code, next) =
          if (unit >= 0xd800
              && unit <= 0xdbff
              && low >= 0xdc00
              && low <= 0xdfff) {
            (0x10000 + (unit - 0xd800) lsl 10 + (low - 0xdc00), index + 2);
          } else {
            (unit, index + 1);
          };
        if (code < 0x80) {
          add(code);
        } else if (code < 0x800) {
          add(0xc0 lor code lsr 6);
          add(0x80 lor (code land 0x3f));
        } else if (code < 0x10000) {
          add(0xe0 lor code lsr 12);
          add(0x80 lor (code lsr 6 land 0x3f));
          add(0x80 lor (code land 0x3f));
        } else {
          add(0xf0 lor code lsr 18);
          add(0x80 lor (code lsr 12 land 0x3f));
          add(0x80 lor (code lsr 6 land 0x3f));
          add(0x80 lor (code land 0x3f));
        };
        loop(next);
      };
    loop(0);
    Buffer.contents(buffer);
  };

let hexValue = character =>
  switch (character) {
  | '0' .. '9' => Some(Char.code(character) - Char.code('0'))
  | 'a' .. 'f' => Some(Char.code(character) - Char.code('a') + 10)
  | 'A' .. 'F' => Some(Char.code(character) - Char.code('A') + 10)
  | _ => None
  };

type malformedEscape =
  | Reject
  | Keep;

let percentDecode = (~plus, ~malformed, value) => {
  let length = String.length(value);
  let buffer = Buffer.create(length);
  let rec loop = index =>
    if (index >= length) {
      Some(Buffer.contents(buffer));
    } else {
      switch (value.[index]) {
      | '+' when plus =>
        Buffer.add_char(buffer, ' ');
        loop(index + 1);
      | '%' =>
        let escaped =
          index + 2 < length
            ? switch (
                hexValue(value.[index + 1]),
                hexValue(value.[index + 2]),
              ) {
              | (Some(high), Some(low)) => Some(high lsl 4 lor low)
              | _ => None
              }
            : None;
        switch (escaped, malformed) {
        | (Some(byte), _) =>
          Buffer.add_char(buffer, Char.chr(byte));
          loop(index + 3);
        | (None, Keep) =>
          Buffer.add_char(buffer, '%');
          loop(index + 1);
        | (None, Reject) => None
        };
      | character =>
        Buffer.add_char(buffer, character);
        loop(index + 1);
      };
    };
  loop(0);
};

let validUtf8 = value => {
  let length = String.length(value);
  let byte = index => Char.code(String.unsafe_get(value, index));
  let continuation = index => index < length && byte(index) land 0xc0 == 0x80;
  let rec from = index =>
    if (index >= length) {
      true;
    } else {
      let first = byte(index);
      if (first < 0x80) {
        from(index + 1);
      } else if (first < 0xc2) {
        false;
      } else if (first < 0xe0) {
        continuation(index + 1) && from(index + 2);
      } else if (index + 1 >= length) {
        false;
      } else {
        let second = byte(index + 1);
        if (first < 0xf0) {
          (
            switch (first) {
            | 0xe0 => second >= 0xa0
            | 0xed => second < 0xa0
            | _ => true
            }
          )
          && continuation(index + 1)
          && continuation(index + 2)
          && from(index + 3);
        } else if (first < 0xf5) {
          (
            switch (first) {
            | 0xf0 => second >= 0x90
            | 0xf4 => second < 0x90
            | _ => true
            }
          )
          && continuation(index + 1)
          && continuation(index + 2)
          && continuation(index + 3)
          && from(index + 4);
        } else {
          false;
        };
      };
    };
  from(0);
};

let validSegment = value =>
  value != ""
  && value != "."
  && value != ".."
  && !String.contains(value, '/')
  && validUtf8(value)
  && String.for_all(
       character => {
         let code = Char.code(character);
         code >= 0x20 && code != 0x7f;
       },
       value,
     );

let decodeSegment = segment =>
  switch (percentDecode(~plus=false, ~malformed=Reject, segment)) {
  | Some(decoded) when validSegment(decoded) => Some(decoded)
  | Some(_)
  | None => None
  };

let matchesShape = (pattern, pathSegments) => {
  let rec loop = (pattern, pathSegments) =>
    switch (pattern, pathSegments) {
    | ([], []) => true
    | ([(CatchAll(_), _)], [_, ..._]) =>
      List.for_all(segment => decodeSegment(segment) != None, pathSegments)
    | ([(Static(value), _), ...pattern], [segment, ...pathSegments]) =>
      decodeSegment(segment) == Some(utf8(value))
      && loop(pattern, pathSegments)
    | ([(Parameter(_), _), ...pattern], [segment, ...pathSegments]) =>
      decodeSegment(segment) != None && loop(pattern, pathSegments)
    | _ => false
    };
  loop(pattern, pathSegments);
};

let pathSegments = path =>
  if (path == "/") {
    Some([]);
  } else if (String.starts_with(~prefix="/", path)) {
    Some(List.tl(String.split_on_char('/', path)));
  } else {
    None;
  };

let rec stripBase = (base, path) =>
  switch (base, path) {
  | ([], rest) => Some(rest)
  | ([baseSegment, ...base], [segment, ...path]) =>
    switch (decodeSegment(baseSegment)) {
    | Some(decoded) when decodeSegment(segment) == Some(decoded) =>
      stripBase(base, path)
    | _ => None
    }
  | ([_, ..._], []) => None
  };

let matchesPath = (~basePath="/", pattern, pathname) =>
  switch (pathSegments(basePath), pathSegments(pathname)) {
  | (Some(base), Some(path)) =>
    switch (stripBase(base, path)) {
    | Some(rest) =>
      List.exists(shape => matchesShape(shape, rest), shapes(pattern))
    | None => false
    }
  | _ => false
  };
