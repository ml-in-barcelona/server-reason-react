let app = () =>
  <p title={js|"quoted" & <tagged>|js}>
    {React.string({js|unicode: ünïcødé — 中文 🚀|js})}
    {React.string("$dollar prefixed")}
    {React.string("$$double dollar")}
    {React.string("line\nbreak\ttab \\ backslash \" quote")}
  </p>;
