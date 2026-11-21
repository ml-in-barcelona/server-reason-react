let decode = part =>
  RouterPattern.percentDecode(~plus=true, ~malformed=Keep, part)
  |> Option.value(~default=part);

let pairs = search => {
  let search =
    String.length(search) > 0 && search.[0] == '?'
      ? String.sub(search, 1, String.length(search) - 1) : search;
  search
  |> String.split_on_char('&')
  |> List.filter(pair => pair != "")
  |> List.map(pair =>
       switch (String.index_opt(pair, '=')) {
       | Some(index) => (
           decode(String.sub(pair, 0, index)),
           decode(
             String.sub(pair, index + 1, String.length(pair) - index - 1),
           ),
         )
       | None => (decode(pair), "")
       }
     )
  |> List.stable_sort(((left, _), (right, _)) =>
       String.compare(left, right)
     );
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
  String.equal(hrefPathname, pathname) && pairs(hrefSearch) == pairs(search);
};
