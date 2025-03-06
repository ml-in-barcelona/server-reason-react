// Defines a custom base route for the actions
let baseRoute = Some("/api/actions/");

// Defines the functions to adapt the server actions to the server
[@platform native]
include {
          let actionRoutes = ref([]);

          let register_action = (~handler, ~route) => {
            actionRoutes :=
              [
                Dream.post(
                  route,
                  req => {
                    let%lwt body = Dream.body(req);
                    let%lwt json_string = handler(body);
                    Dream.json(json_string);
                  },
                ),
                ...actionRoutes^,
              ];
          };

          let get_action_routes = () => actionRoutes^;
        };
