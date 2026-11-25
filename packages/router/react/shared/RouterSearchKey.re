let pairs = search =>
  switch (
    RouterSearchParse.parse(
      ~text=Fun.id,
      ~slice=RouterUrl.slice,
      RouterUrl.utf8(search),
    )
  ) {
  | Ok(values) =>
    Some(
      List.stable_sort(
        ((left, _), (right, _)) => String.compare(left, right),
        values,
      ),
    )
  | Error(_) => None
  };

let splitHref = href => {
  let withoutHash =
    switch (String.index_opt(href, '#')) {
    | Some(index) => String.sub(href, 0, index)
    | None => href
    };
  switch (String.index_opt(withoutHash, '?')) {
  | Some(index) => (
      String.sub(withoutHash, 0, index),
      String.sub(withoutHash, index, String.length(withoutHash) - index),
    )
  | None => (withoutHash, "")
  };
};

let isCurrent = (~pathname, ~search, href) => {
  let (hrefPathname, hrefSearch) = splitHref(href);
  String.equal(hrefPathname, pathname)
  && (
    switch (pairs(hrefSearch), pairs(search)) {
    | (Some(target), Some(current)) => target == current
    | _ => false
    }
  );
};

let pathSegments = pathname => {
  let rec decode = (decoded, segments) =>
    switch (segments) {
    | [] => Some(List.rev(decoded))
    | ["", ...segments] => decode(decoded, segments)
    | [segment, ...segments] =>
      switch (RouterUrl.decodeSegment(RouterUrl.utf8(segment))) {
      | Ok(segment) => decode([segment, ...decoded], segments)
      | Error(_) => None
      }
    };
  decode([], String.split_on_char('/', pathname));
};

let rec startsWithSegments = (~prefix, segments) =>
  switch (prefix, segments) {
  | ([], _) => true
  | ([expected, ...prefix], [segment, ...segments]) =>
    String.equal(expected, segment) && startsWithSegments(~prefix, segments)
  | ([_, ..._], []) => false
  };

let isActive = (~prefix, ~pathname, href) => {
  switch (pathSegments(fst(splitHref(href))), pathSegments(pathname)) {
  | (Some(target), Some(current)) =>
    prefix ? startsWithSegments(~prefix=target, current) : target == current
  | _ => false
  };
};
