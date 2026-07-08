/* String-valued aria-* attributes serialize under their hyphenated wire
   names. Props are listed in reason-react's [domProps] declaration order
   (see the note in Props_primitives.re). Boolean-valued aria props live in
   Props_aria_booleanish, the aria-current anomaly in Props_aria_current;
   data-* attributes are not expressible in typed Reason JSX on either side
   (reason-react's domProps has no data-* fields), so they are not
   covered. */
let app = () =>
  <button ariaDescribedby="help-text" ariaLabel="Close dialog">
    {React.string("x")}
  </button>;
