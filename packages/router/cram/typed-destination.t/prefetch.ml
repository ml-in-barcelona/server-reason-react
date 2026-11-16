Router.make ~basePath:"/app"
  [
    Router.route Home ~page:HomePage ~path:"/";
    Router.group ~path:"/settings" ~prefetch:Viewport
      [
        Router.route Settings ~page:SettingsPage ~path:"/";
        Router.route Billing ~page:BillingPage ~path:"/billing" ~prefetch:Off;
      ];
  ]
