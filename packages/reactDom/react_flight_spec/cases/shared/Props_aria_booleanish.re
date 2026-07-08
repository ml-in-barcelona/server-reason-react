/* Boolean-valued aria props: React keeps the raw JS boolean in the payload
   ("aria-hidden":true); srr renders aria booleans as booleanish strings
   ("true"/"false") at JSX construction time. */
let app = () => <div ariaAtomic=false ariaHidden=true />;
