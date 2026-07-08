/* aria-* props keep their hyphenated wire name in the payload: React emits
   "aria-current", never the camelCase JSX spelling. Props are in
   reason-react's [domProps] declaration order (aria props come before
   href). */
let app = () =>
  <a ariaCurrent="page" href="/inbox"> {React.string("Inbox")} </a>;
