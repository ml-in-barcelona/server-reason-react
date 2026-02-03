exception No_provider(string);

type url = URL.t;
let url_to_json: url => Melange_json.t;
let url_of_json: Melange_json.t => url;

type t =
  (~replace: bool=?, ~revalidate: bool=?, ~shallow: bool=?, string) => unit;
let use: unit => t;

type router = {
  navigate: t,
  params: DynamicParams.t,
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
    ~initialDynamicParams: DynamicParams.t,
    ~children: React.element
  ) =>
  React.element;
