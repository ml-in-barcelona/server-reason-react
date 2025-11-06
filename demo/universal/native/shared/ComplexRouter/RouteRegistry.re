/**
* RouteRegistry is a registry of client-side routes.
* It's used to store the routes path and loader function.
*/

type route = {
  path: string,
  loader: React.element => unit,
};

let routes = ref([]);

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
