[@react.client.component]
let make =
    (
      ~initial: RouterRuntime.Navigation.committed,
      ~protocolVersion: int,
      ~registryFingerprint: string,
      ~basePath: string,
      ~metadata: React.element,
      ~children: React.element,
    ) =>
  <RouterReact.Provider
    initial protocolVersion registryFingerprint basePath metadata>
    children
  </RouterReact.Provider>;
