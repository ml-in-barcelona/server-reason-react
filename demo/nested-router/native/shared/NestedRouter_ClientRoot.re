[@deriving rsc]
type initial = {
  pathname: string,
  search: string,
  key: string,
  revision: string,
  matches: list(RouterWire.matched),
  layouts: list(RouterWire.layout),
};

[@react.client.component]
let make =
    (
      ~initial: initial,
      ~registryFingerprint: string,
      ~basePath: string,
      ~children: React.element,
    ) => {
  let committed =
    RouterRuntime.Navigation.{
      location: {
        pathname: initial.pathname,
        search: initial.search,
        hash: "",
        key: initial.key,
      },
      matches: List.map(RouterWire.matchedToRuntime, initial.matches),
      layouts: List.map(RouterWire.layoutToRuntime, initial.layouts),
      revision: initial.revision,
    };
  <RouterReact.Provider initial=committed registryFingerprint basePath>
    children
  </RouterReact.Provider>;
};
