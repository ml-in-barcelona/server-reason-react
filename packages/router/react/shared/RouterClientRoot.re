[@react.client.component]
let make =
    (
      ~initial: RouterRuntime.Navigation.committed,
      ~protocolVersion: int,
      ~registryFingerprint: string,
      ~basePath: string,
      ~pageCacheCapacity: int=0,
      ~metadata: React.element,
      ~children: React.element,
    ) =>
  <RouterReact.Provider
    initial
    protocolVersion
    registryFingerprint
    basePath
    pageCacheCapacity
    metadata>
    children
  </RouterReact.Provider>;
