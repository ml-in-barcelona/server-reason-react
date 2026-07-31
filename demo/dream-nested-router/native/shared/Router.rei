exception No_provider(string);

type url = URL.t;
let url_to_rsc: url => RSC.t;
let url_of_rsc: RSC.t => url;

type t =
  (~replace: bool=?, ~revalidate: bool=?, ~shallow: bool=?, string) => unit;
let use: unit => t;

type router = {
  navigate: t,
  params: PathParams.t,
  url: URL.t,
  pathname: string,
  searchParams: URL.SearchParams.t,
  isNavigating: bool,
};

let useRouter: unit => router;

[@react.client.component]
let make:
  (
    ~serverUrl: url,
    ~initialPathParams: PathParams.t,
    ~registryFingerprint: string,
    ~children: React.element
  ) =>
  React.element;
