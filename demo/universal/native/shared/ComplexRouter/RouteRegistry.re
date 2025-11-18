/**
* RouteRegistry is a registry of client-side routes.
* It's used to store the routes path and loader function.
*/

/* TODO: Rename to route virtual tree location history */
/* CurrentRoute */
/* This is how the client knows which route is rendered, and which subroute needs to get rendered as outlet (children) */

type route = {
  path: string,
  loader: React.element => unit /* TODO: Rename loader to an actual name */
};

let routes = ref([]);

/* TODO: visit */
let register = (~path, ~loader) => {
  let filteredRoutes = List.filter(route => route.path != path, routes^);

  routes :=
    filteredRoutes
    @ [
      {
        path,
        loader,
      },
    ];
};

let find = (path: string) => {
  List.find_opt(route => route.path == path, routes^);
};

let clear = () => {
  routes := [];
};

let cleanup = path => {
  routes :=
    List.filter(
      route => route.path |> String.length <= (path |> String.length),
      routes^,
    );
};

let getAllRoutes = () => {
  routes^;
};
