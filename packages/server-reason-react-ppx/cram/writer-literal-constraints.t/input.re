type roundness =
  | Full
  | None;

let make = value =>
  <div
    title=(("hello": string): string)
    tabIndex=(1: int)
    hidden=(false: bool)
    id=?(None: option(string))
    dataState=(value: string)
  />;

print_endline(ReactDOM.renderToStaticMarkup(make("value")));
