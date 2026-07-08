/* Unicode text children: emoji (surrogate pairs + ZWJ sequences), CJK, RTL
   scripts and combining marks all cross the wire as raw UTF-8 inside JSON
   strings — JSON.stringify does not \u-escape anything above the control
   range. Lone surrogates are intentionally avoided (not representable in
   well-formed UTF-8). */
let app = () =>
  <p>
    {React.string({js|emoji: 🚀 🙈 👨‍👩‍👧‍👦 🇪🇸|js})}
    {React.string({js|CJK: 中文漢字 ひらがな カタカナ 한글|js})}
    {React.string({js|RTL: مرحبا بالعالم — שלום עולם|js})}
    {React.string({js|combining: café ñ Å|js})}
  </p>;
