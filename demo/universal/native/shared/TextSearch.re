let contains = (~needle, ~haystack) => {
  let needleLength = String.length(needle);
  let haystackLength = String.length(haystack);
  let rec search = start =>
    start <= haystackLength
    - needleLength
    && (
      String.sub(haystack, start, needleLength) == needle
      || search(start + 1)
    );
  needleLength <= haystackLength && search(0);
};
