let app = () =>
  <p>
    {React.string({js|emoji: 🚀 🙈 👨‍👩‍👧‍👦 🇪🇸|js})}
    {React.string({js|CJK: 中文漢字 ひらがな カタカナ 한글|js})}
    {React.string({js|RTL: مرحبا بالعالم — שלום עולם|js})}
    {React.string({js|combining: café ñ Å|js})}
  </p>;
