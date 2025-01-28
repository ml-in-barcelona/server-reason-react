type t = Router.t(Fetch.Response.t);

external navigate: string => unit = "window.__navigate_rsc";

let useRouter: unit => t =
  () => {
    {
      location: Router.initialLocation,
      refresh: str => Js.log(str),
      navigate: str => {
        navigate(Router.locationToString(str));
      },
    };
  };
