/* Router does nothing in native */
type t = Router.t(unit);

let useRouter: unit => t =
  () => {
    {
      location: Router.initialLocation,
      refresh: _ => (),
      navigate: _str => {
        Js.log("Navigate");
        ();
      },
    };
  };
