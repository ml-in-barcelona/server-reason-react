// Shared route definitions used by both client Router and server

type t = {
  path: string,
  component: React.element,
};

let routes = [
  {
    path: "/demo/router",
    component:
      <div className="text-white text-6xl"> {React.string("1")} </div>,
  },
  {
    path: "/demo/router/about",
    component:
      <div className="text-white text-6xl"> {React.string("2")} </div>,
  },
  {
    path: "/demo/router/dashboard",
    component:
      <div className="text-white text-6xl"> {React.string("3")} </div>,
  },
  {
    path: "/demo/router/profile",
    component:
      <div className="text-white text-6xl"> {React.string("4")} </div>,
  },
];

[@react.component]
let make = () => {
  routes
  |> List.map((route: t) =>
       <Supersonic.Route path={route.path} component={route.component} />
     )
  |> Array.of_list
  |> React.array;
};
