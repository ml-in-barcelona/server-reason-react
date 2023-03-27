  $ cat >index.js <<EOF
  > const emotion = require("@emotion/css");
  > console.log(emotion.css({ "display": "flex" }));
  > EOF

  $ node index.js
  css-k008qs

  $ cat >index.js <<EOF
  > const hash = require("@emotion/hash").default;
  > console.log(hash("display: flex;"))
  > EOF

  $ node index.js
  etlvsf
