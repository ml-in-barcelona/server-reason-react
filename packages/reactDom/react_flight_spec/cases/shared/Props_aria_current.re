/* aria-current is the one aria attribute whose jsxName is camelCase
   ("ariaCurrent") in srr's DomProps table — every other aria-* uses the
   hyphenated name — so it serializes under the wrong key. React emits
   "aria-current". Props are in reason-react's [domProps] declaration order
   (aria props come before href). */
let app = () =>
  <a ariaCurrent="page" href="/inbox"> {React.string("Inbox")} </a>;
