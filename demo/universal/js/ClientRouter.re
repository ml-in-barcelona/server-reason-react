type t = Router.t(Fetch.Response.t);

external navigate: string => unit = "window.__navigate";
external useAction:
  (string, string) => ((Router.payload, Router.location, unit) => unit, bool) =
  "window.__useAction";

let useRouter: unit => t =
  () => {
    {
      location: Router.initialLocation,
      navigate: str => {
        navigate(Router.locationToString(str));
      },
      useAction: (endpoint, method) => {
        useAction(endpoint, method);
      },
      refresh: str => {
        Js.log(str);
      },
    };
  };
