[@react.client.component]
let make =
    (
      ~initial: RouterRuntime.Navigation.committed,
      ~registryFingerprint: string,
      ~basePath: string,
      ~children: React.element,
    ) =>
  <RouterReact.Provider initial registryFingerprint basePath>
    children
  </RouterReact.Provider>;
