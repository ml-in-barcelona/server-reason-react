Given a client component like [Counter.re](./demo/universal/native/lib/Counter.re), the server needs to know the JavaSript file where the component exists. Why? Because it will SSR the component as a Server reason react component, and also, render the "use client" boundary.

This is probably a good approximation: The model contains `I[\"./client-without-props.js\",[],\"ClientWithoutProps\"]` for the client component:

```ocaml
let client_without_props () =
  let app () =
    React.Upper_case_component
      (fun () ->
        React.List
          [|
            React.createElement "div" [] [ React.string "Server Content" ];
            React.Client_component
              {
                props = [];
                client = React.string "Client without Props";
                import_module = "./client-without-props.js";
                import_name = "ClientWithoutProps";
              };
          |])
  in
  let%lwt stream = ReactServerDOM.render_to_model (app ()) in
  assert_stream stream
    [
      "2:I[\"./client-without-props.js\",[],\"ClientWithoutProps\"]\n";
      "1:[[\"$\",\"div\",null,{\"children\":\"Server Content\"}],[\"$\",\"$2\",null,{}]]\n";
      "0:\"$1\"\n";
    ]
```

### What I need

I need to generate a JS file that contains the client component registration:
```
register("Counter", React.lazy(() => import("./app/demo/universal/js/Counter.js")));
register("Note_editor", React.lazy(() => import("./app/demo/universal/js/Note_editor.js")));
register("Promise_renderer", React.lazy(() => import("./app/demo/universal/js/Promise_renderer.js")));
```

```
register("Promise_renderer", React.lazy(() => import("./app/demo/universal/js/Promise_renderer.js")));
          ^^^^^^^^^^^^^^^^
```
The "name" is currently the file name. In reason-react, the name is the module name (and some $ in the name for nested modules), but that's not a problem. In the RSC model, we can specify the exported name and this logic is already implemented in reason-react-ppx.

```
register("Promise_renderer", React.lazy(() => import("./app/demo/universal/js/Promise_renderer.js")));
                                                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
```
The resultant JS file is the one that we need to know about, and don't have a good mechanism.


### What I have tried

1) Try to get the rules from a particular file: `dune rules demo/universal/js/Counter.re` gives me the copy files action
```clojure
  ((File (In_build_dir _build/default/demo/universal/native/lib/Counter.re))))
 (targets
  ((files (_build/default/demo/universal/js/Counter.re)) (directories ())))
 (context default)
 (action
  (chdir
   _build/default
   (copy demo/universal/native/lib/Counter.re demo/universal/js/Counter.re))))
```

2) Try to get the rules from a particular melange.emit and gives me [./melange.rules](./melange.rules) which contains references to `_build/default/demo/client/app/demo/universal/js/Counter.js` but no clear way to know if those JS files are the ones that contain the client components, or are the same files as

3) Try to get the rules from a particular alias (?) `dune rules -m @melange-app` and gives me [./melange-target.rules](./melange-target.rules) which contains a the list of melange files that are part of the target, as JavaScript files.

### Similar issue

In https://github.com/davesnx/meleange, I have a similar issue. Where the build needs to know all dependencies of a melange file. Adding it here, just in case we design a manfiest and can expand with this use-case in the future and not break hard.
