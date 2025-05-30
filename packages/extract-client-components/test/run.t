  $ server_reason_react.extract_client_components ./ClientComponent.js
  import React from "react";
  window.__client_manifest_map = window.__client_manifest_map || {};
  window.__server_functions_manifest_map = window.__server_functions_manifest_map || {};
  window.__client_manifest_map["demo/universal/native/shared/Button.re"] = React.lazy(() => import("$TESTCASE_ROOT/./ClientComponent.js").then(module => {
    return { default: module.make_client }
  }).catch(err => { console.error(err); return { default: null }; }))

  $ server_reason_react.extract_client_components ./ClientComponentWithModule.js
  import React from "react";
  window.__client_manifest_map = window.__client_manifest_map || {};
  window.__server_functions_manifest_map = window.__server_functions_manifest_map || {};
  window.__client_manifest_map["demo/universal/native/shared/Button.re#WithModule"] = React.lazy(() => import("$TESTCASE_ROOT/./ClientComponentWithModule.js").then(module => {
    return { default: module.WithModule.make_client }
  }).catch(err => { console.error(err); return { default: null }; }))

  $ server_reason_react.extract_client_components ./ServerFunction.js
  import React from "react";
  window.__client_manifest_map = window.__client_manifest_map || {};
  window.__server_functions_manifest_map = window.__server_functions_manifest_map || {};
  window.__server_functions_manifest_map["1234-4567"] = require("$TESTCASE_ROOT/./ServerFunction.js").serverFunction
  window.__server_functions_manifest_map["7654-3210"] = require("$TESTCASE_ROOT/./ServerFunction.js").WithModule.serverFunctionWithModule

