
/* A user variant whose `None` constructor shadows option's `None`.
   Without an expected-type annotation on the optional attribute value,
   the bare `None` in `disabled ? None : Some(href)` would resolve to
   `roundness.None` and fail to type-check (the styled-ppx `styles=` on a
   host element regression). The emit fast path must annotate the optional
   scrutinee with its concrete option type, exactly like the variant-tree
   path does. */
type roundness =
  | Full
  | None;

let link = (~href, ~disabled) =>
  <a styles=x href=?{disabled ? None : Some(href)}> {React.string("x")} </a>;
