/* Only called on text that RouterUtf8.valid accepted. */
let utf8Text: string => string = [%mel.raw
  {|(bytes) => {
  let text = "";
  let index = 0;
  while (index < bytes.length) {
    const first = bytes.charCodeAt(index);
    if (first < 0x80) {
      text += bytes[index];
      index += 1;
    } else if (first < 0xe0) {
      text += String.fromCharCode(((first & 0x1f) << 6) | (bytes.charCodeAt(index + 1) & 0x3f));
      index += 2;
    } else if (first < 0xf0) {
      text += String.fromCharCode(
        ((first & 0x0f) << 12) | ((bytes.charCodeAt(index + 1) & 0x3f) << 6) | (bytes.charCodeAt(index + 2) & 0x3f),
      );
      index += 3;
    } else {
      text += String.fromCodePoint(
        ((first & 0x07) << 18) |
          ((bytes.charCodeAt(index + 1) & 0x3f) << 12) |
          ((bytes.charCodeAt(index + 2) & 0x3f) << 6) |
          (bytes.charCodeAt(index + 3) & 0x3f),
      );
      index += 4;
    }
  }
  return text;
}|}
];

/* location.search is ASCII; other input gets the UTF-8 escapes the server
   would read, and a lone surrogate becomes a malformed escape. */
let asciiSearch: string => string = [%mel.raw
  {|(search) =>
  /[^\x00-\x7f]/.test(search)
    ? search.replace(/[^\x00-\x7f]+/g, (text) => {
        try {
          return encodeURIComponent(text);
        } catch (error) {
          return "%";
        }
      })
    : search|}
];

let slice: (string, int, int) => string = [%mel.raw
  {|(value, start, stop) => value.substring(start, stop)|}
];

let parse = search =>
  RouterSearchParse.parse(~text=utf8Text, ~slice, asciiSearch(search));

let valid = search => Result.is_ok(parse(search));

let valuesFromString = search =>
  switch (parse(search)) {
  | Ok(values) => values
  | Error(_) => []
  };

let toString = values => {
  let encoded = RouterRuntime.encodeSearch(values);
  String.equal(encoded, "") ? "" : "?" ++ encoded;
};

/* The address bar may hold another spelling of the same values (`+` for a
   space, another order), so both sides go through the same encoder. */
let unchanged = (~current, ~next) =>
  String.equal(toString(valuesFromString(current)), toString(next));
