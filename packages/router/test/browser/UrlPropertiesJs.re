let pattern = RouterEngine.pattern("/s/:v<string>");

let encodeSegment = value => {
  let href =
    RouterRuntime.href(
      RouterEngine.destinationFromPattern(
        ~pattern,
        ~parameters=[("v", value)],
        ~search=[],
      ),
    );
  String.sub(href, 3, String.length(href) - 3);
};

let platform: UrlCases.platform = {
  text: RouterSearch.utf8Text,
  encodeSearch: RouterEngine.encodeSearch,
  parseSearch: search => Result.to_option(RouterSearch.parse(search)),
  encodeSegment,
  decodeSegment: segment =>
    RouterUrl.decodeSegment(segment)
    |> Result.to_option
    |> Option.map(RouterSearch.utf8Text),
};

UrlCases.run(platform, print_endline);
