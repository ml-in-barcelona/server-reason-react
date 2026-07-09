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

