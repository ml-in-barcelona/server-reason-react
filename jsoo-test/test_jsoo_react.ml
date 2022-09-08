open Webtest.Suite

let suite = "baseSuite" >::: [ Test_reason.suite; Test_ml.suite ]
let () = Webtest_js.Runner.run suite
