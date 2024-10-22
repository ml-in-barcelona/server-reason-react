external window: Js.t({..}) = "window";

type client_component('a) = Js.t('a) => React.component('a);
type t('a) = Js.Dict.t(client_component('a));

let empty: t({.}) = Js.Dict.empty();

let () = window##__exported_components #= empty;

let register = (name: string, render: 'a) => {
  let components = window##__exported_components;
  Js.Dict.set(components, name, render);
};

let import = name => {
  let components = window##__exported_components;
  Js.Dict.get(components, name);
};
