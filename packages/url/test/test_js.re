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

let url = URL.makeExn("https://example.com/pricing");
let url = URL.setSearchAsString(url, "?currency=usd&managedPayments=true");

assert_option_string(
  URL.search(url),
  Some("?currency=usd&managedPayments=true"),
);
