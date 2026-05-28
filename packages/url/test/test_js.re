let assert_option_string = (actual, expected) =>
  if (actual != expected) {
    failwith("expected matching optional strings");
  };

let search = URL.SearchParams.makeExn("?currency=usd&managedPayments=true");

assert_option_string(URL.SearchParams.get(search, "currency"), Some("usd"));
assert_option_string(
  URL.SearchParams.get(search, "managedPayments"),
  Some("true"),
);

let search = URL.SearchParams.make("?currency=usd&managedPayments=true");
let currency =
  switch (search) {
  | Some(search) => URL.SearchParams.get(search, "currency")
  | None => None
  };

assert_option_string(currency, Some("usd"));

let url = URL.makeExn("https://example.com/pricing");
let url = URL.setSearchAsString(url, "?currency=usd&managedPayments=true");

assert_option_string(
  URL.search(url),
  Some("?currency=usd&managedPayments=true"),
);

let url = URL.makeExn("https://example.com/pricing?currency=usd");
let search =
  switch (URL.search(url)) {
  | Some(search) => URL.SearchParams.make(search)
  | None => None
  };
let currency =
  switch (search) {
  | Some(search) => URL.SearchParams.get(search, "currency")
  | None => None
  };

assert_option_string(currency, Some("usd"));
