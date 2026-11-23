let app = () =>
  <pre>
    {React.string("newline\nand tab\tmixed")}
    {React.string("quote \" backslash \\ single ' backtick `")}
    {React.string("</script><script>alert(1)</script>")}
    {React.string("carriage\rreturn backspace\b formfeed\012")}
  </pre>;
