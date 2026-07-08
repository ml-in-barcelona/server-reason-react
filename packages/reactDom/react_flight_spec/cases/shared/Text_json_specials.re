/* JSON-hostile text: control characters use the short JSON escapes
   (\n \t \r \b \f), quotes and backslashes are escaped, and </script> is
   NOT escaped — the Flight payload is not HTML-embedded, so no <, > or /
   escaping happens (unlike React's HTML-inlined JSON). */
let app = () =>
  <pre>
    {React.string("newline\nand tab\tmixed")}
    {React.string("quote \" backslash \\ single ' backtick `")}
    {React.string("</script><script>alert(1)</script>")}
    {React.string("carriage\rreturn backspace\b formfeed\012")}
  </pre>;
