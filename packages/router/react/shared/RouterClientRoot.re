[@react.client.component]
let make =
    (
      ~initial: RouterTypes.Navigation.committed,
      ~protocolVersion: int,
      ~registryFingerprint: string,
      ~basePath: string,
      ~pageCacheCapacity: int=30,
      ~pageCacheMaxAge: float=0.0,
      ~routes: array(string)=[||],
      ~interceptLinks: bool=true,
      ~viewTransitions: bool=false,
      ~metadata: React.element,
      ~children: React.element,
    ) => {
  <RouterReact.Provider
    initial
    protocolVersion
    registryFingerprint
    basePath
    pageCacheCapacity
    pageCacheMaxAge
    routes
    interceptLinks
    viewTransitions
    metadata>
    children
  </RouterReact.Provider>;
};
