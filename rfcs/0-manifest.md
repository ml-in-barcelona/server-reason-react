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
```js
register("Counter", React.lazy(() => import("./app/demo/universal/js/Counter.js")));
register("Note_editor", React.lazy(() => import("./app/demo/universal/js/Note_editor.js")));
register("Promise_renderer", React.lazy(() => import("./app/demo/universal/js/Promise_renderer.js")));
```

```js
register("Promise_renderer", React.lazy(() => import("./app/demo/universal/js/Promise_renderer.js")));
//       ^^^^^^^^^^^^^^^^^^
```
The "name" is currently the file name without the extension ("Counter"). In reason-react, it handles nested modules and adds $ on each level, but that's not a problem. In the RSC model, we are free to specify this name with whatever we want, both using __FILE__ (which is the relative path to the file: "./demo/universal/native/lib/Counter.re") or have the same logic as reason-react-ppx.

```js
register("Promise_renderer", React.lazy(() => import("./app/demo/universal/js/Promise_renderer.js")));
//                                                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
```
The resultant JS file is the one that we need to know about, and don't have a good mechanism.


### What I have tried

Running a program after the compilation, but before the bundle to generate a manifest with all the map. So during the bundling, I can generate the registration.

```
["Counter", "./app/demo/universal/js/Counter.js"]
["Note_editor", "./app/demo/universal/js/Note_editor.js"]
["Promise_renderer", "./app/demo/universal/js/Promise_renderer.js"]
```

1) Try to get the rules from a particular file `dune rules demo/universal/js/Counter.re` gives me the copy files action, which is expected. But it doesn't even give me a parsable sexp.
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

2) Try to get the rules from a melange.emit alias with `dune rules -r @melange-app`, gives [./melange-emit.rules](./melange-emit.rules) which contains references to `_build/default/demo/client/app/demo/universal/js/Counter.js`, and also to `counter.cmj`. It looked very promising, since parsing the sexp is possible, but I stopped when I was parsing actions and rebuilding the map "backwards" in [packages/melange-file-mapper/Melange_file_mapper.ml](./packages/melange-file-mapper/Melange_file_mapper.ml).
Aside, my script runs when the build is done, so I'm not sure if running `dune rules` during the build would work ok.

3) Randomly, trying to get the rules for a makefile `dune rules -m @melange-app` and gives me [./melange-makefile.rules](./melange-makefile.rules) which contains a the list of melange files that are part of the target, but only the JavaScript files.

4) Unsure if there's more ways to gather the dune rules.

### Looking at melange_rules.ml

There seems to be a place where we generate all rules for a melange.emit, and have access to all information needed: https://github.com/ocaml/dune/blob/5b695d66de4471e6df6268b715de9aabbad51d5b/src/dune_rules/melange/melange_rules.ml#L156

### Similar issue

In https://github.com/davesnx/meleange, I have a similar issue. Where the build needs to know all dependencies of a melange file. Adding it here, just in case we design a manfiest and can expand with this use-case in the future and not break hard.
