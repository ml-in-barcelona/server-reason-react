/* Boolean-valued aria props: React keeps the raw JS boolean in the Flight
   payload ("aria-hidden":true); the "true"/"false" stringification only
   happens when rendering HTML attributes. */
let app = () => <div ariaAtomic=false ariaHidden=true />;
