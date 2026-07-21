/* Minimal reproduction of ahrefs/WEB-844: hydration mismatch (React error
   #418) caused by inline-style CSS custom properties serializing in a
   different order on the server (server-reason-react) than on the client
   (Melange/reason-react).

   styled-ppx in CSS-extraction mode hoists every $(...) interpolation into an
   inline-style custom property and builds the style prop by folding
   ReactDOM.Style.unsafeAddProp over the vars, in declaration order (see
   styled-ppx packages/runtime/{native,melange}/CSS.ml). [makeStyle] below is
   that exact runtime, inlined.

   reason-react's unsafeAddProp is Object.assign: a new key lands last, so the
   client keeps declaration order. server-reason-react <= 20260616 snapshots
   prepended in unsafeAddProp, so SSR emitted the vars reversed and React
   reported a hydration mismatch on every element carrying two or more hoisted
   vars. Fixed by c9daf826 ("Emit style properties in signature order,
   matching React", first released in 0.5.0). */

let makeStyle = vars =>
  List.fold_left(
    (style, (key, value)) =>
      ReactDOM.Style.unsafeAddProp(style, key, value),
    ReactDOM.Style.make(),
    vars,
  );

/* Mirrors the extracted CSS of the failing ahrefs.com `Link_Css.link`: a
   top-level `color: $(color)` plus a nested
   `@media (hover: hover) { &:hover { color: $(hoverColor) } }`. */
let extractedCss = {|
  .repro-link { cursor: pointer; color: var(--color-czybvw); }
  @media (hover: hover) {
    .repro-link:hover { color: var(--hoverColor-1eveqlc); }
  }
|};

[@react.component]
let make = () => {
  let style =
    makeStyle([
      ("--color-czybvw", "#3A57FC"),
      ("--hoverColor-1eveqlc", "#F75A03"),
    ]);
  <DemoLayout background=Theme.Color.Gray2>
    <style> {React.string(extractedCss)} </style>
    <Stack gap=8 justify=`start>
      <h1 className="text-xl font-bold">
        {React.string("Hydration: inline-style custom property order")}
      </h1>
      <p className="text-sm text-gray-500">
        {React.string(
           "This anchor carries two hoisted custom properties, built exactly "
           ++ "like styled-ppx's CSS-extraction runtime does (a fold over "
           ++ "ReactDOM.Style.unsafeAddProp). If the server serializes them "
           ++ "in a different order than the client, hydration fails with "
           ++ "React error #418. Open the console: it must be free of "
           ++ "hydration errors, and hovering the link must turn it orange.",
         )}
      </p>
      <a className="repro-link text-l font-bold" href="#" style>
        {React.string("I must be blue, orange on hover, and hydrate clean")}
      </a>
      /* Adjacent text nodes under a static-optimizable element: SSR must
         emit a <!-- --> separator between them or hydration fails with
         React #418 (the ahrefs.com LandingHero H1 shape, WEB-844). */
      <p className="text-sm">
        {React.string("Adjacent")}
        {React.string(" text nodes must hydrate clean too ")}
        <i> {React.string("(text separator regression)")} </i>
      </p>
    </Stack>
  </DemoLayout>;
};
