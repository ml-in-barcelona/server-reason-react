  $ server-reason-react.extract_client_components ./ClientComponent.js
  window.__client_manifest_map = window.__client_manifest_map || {};
  window.__server_functions_manifest_map = window.__server_functions_manifest_map || {};
  window.__client_manifest_map["demo/universal/native/shared/Button.re"] = { load: () => import("$TESTCASE_ROOT/./ClientComponent.js").then(module => module.make_client) }

  $ server-reason-react.extract_client_components ./ClientComponentWithModule.js
  window.__client_manifest_map = window.__client_manifest_map || {};
  window.__server_functions_manifest_map = window.__server_functions_manifest_map || {};
  window.__client_manifest_map["demo/universal/native/shared/Button.re#WithModule"] = { load: () => import("$TESTCASE_ROOT/./ClientComponentWithModule.js").then(module => module.WithModule.make_client) }

  $ server-reason-react.extract_client_components ./ServerFunction.js
  window.__client_manifest_map = window.__client_manifest_map || {};
  window.__server_functions_manifest_map = window.__server_functions_manifest_map || {};
  window.__server_functions_manifest_map["1234-4567"] = require("$TESTCASE_ROOT/./ServerFunction.js").serverFunction
  window.__server_functions_manifest_map["7654-3210"] = require("$TESTCASE_ROOT/./ServerFunction.js").WithModule.serverFunctionWithModule


An ES module file is extracted as well, and a module compiled to both
module systems is registered once
  $ mkdir both
  $ cp ServerFunction.js both/ServerFunction.js
  $ cp ServerFunction.js both/ServerFunction.mjs
  $ server-reason-react.extract_client_components ./both
  window.__client_manifest_map = window.__client_manifest_map || {};
  window.__server_functions_manifest_map = window.__server_functions_manifest_map || {};
  window.__server_functions_manifest_map["1234-4567"] = require("$TESTCASE_ROOT/./both/ServerFunction.js").serverFunction
  window.__server_functions_manifest_map["7654-3210"] = require("$TESTCASE_ROOT/./both/ServerFunction.js").WithModule.serverFunctionWithModule

  $ mkdir esm
  $ cp ServerFunction.js esm/ServerFunction.mjs
  $ server-reason-react.extract_client_components ./esm
  window.__client_manifest_map = window.__client_manifest_map || {};
  window.__server_functions_manifest_map = window.__server_functions_manifest_map || {};
  window.__server_functions_manifest_map["1234-4567"] = require("$TESTCASE_ROOT/./esm/ServerFunction.mjs").serverFunction
  window.__server_functions_manifest_map["7654-3210"] = require("$TESTCASE_ROOT/./esm/ServerFunction.mjs").WithModule.serverFunctionWithModule

Two server functions with the same id fail the extraction
  $ mkdir duplicate
  $ cp ServerFunction.js duplicate/A.js
  $ cp ServerFunction.js duplicate/B.js
  $ server-reason-react.extract_client_components ./duplicate
  server-reason-react.extract_client_components: duplicate server function id "1234-4567" in $TESTCASE_ROOT/./duplicate/A.js and $TESTCASE_ROOT/./duplicate/B.js
  [1]

A malformed marker fails the extraction
  $ mkdir malformed
  $ echo '// extract-server-function' > malformed/Broken.js
  $ server-reason-react.extract_client_components ./malformed
  server-reason-react.extract_client_components: $TESTCASE_ROOT/./malformed/Broken.js: invalid `extract-server-function` line: "// extract-server-function"
  [1]
