[@react.client.component]
let make =
    (
      ~initial: RouterRuntime.Navigation.committed,
      ~protocolVersion: int,
      ~registryFingerprint: string,
      ~basePath: string,
      ~children: React.element,
    ) =>
  <RouterReact.Provider initial protocolVersion registryFingerprint basePath>
    children
  </RouterReact.Provider>;
