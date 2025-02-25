let measure_alloc title f =
  let before = Gc.stat () in
  let result = f () in
  let after = Gc.stat () in
  Printf.printf "\n=== %s ===\n" title;
  Printf.printf "Minor words: %f\n" (after.minor_words -. before.minor_words);
  Printf.printf "Major words: %f\n" (after.major_words -. before.major_words);
  Printf.printf "Minor collections: %d\n" (after.minor_collections - before.minor_collections);
  result

let loop n f =
  for _ = 1 to n do
    f ()
  done

let main () =
  let filter_map_style () =
    let element =
      React.createElement "div"
        (Stdlib.List.filter_map Fun.id
           (List.init 50 (fun i ->
                Some
                  (React.JSX.String (Printf.sprintf "prop%d" i, Printf.sprintf "prop%d" i, Printf.sprintf "value%d" i)))))
        []
    in
    let _ = ReactDOM.renderToStaticMarkup element in
    ()
  in

  let direct_style () =
    let props =
      List.init 50 (fun i ->
          React.JSX.String (Printf.sprintf "prop%d" i, Printf.sprintf "prop%d" i, Printf.sprintf "value%d" i))
    in
    let element = React.createElement "div" props [] in
    let _ = ReactDOM.renderToStaticMarkup element in
    ()
  in

  let render_hello_world () =
    let _ = ReactDOM.renderToStaticMarkup (Static_small.make ()) in
    ()
  in

  let render_app () =
    let _ = ReactDOM.renderToStaticMarkup (App.make ()) in
    ()
  in

  let render_React_list ~num () =
    let list = React.list (List.init num (fun i -> React.string (Printf.sprintf "index: %d" i))) in
    let _ = ReactDOM.renderToStaticMarkup (React.createElement "div" [] [ list ]) in
    ()
  in

  let render_React_array ~num () =
    let array = React.array (Array.init num (fun i -> React.string (Printf.sprintf "index: %d" i))) in
    let _ = ReactDOM.renderToStaticMarkup (React.createElement "div" [] [ array ]) in
    ()
  in

  measure_alloc "Use filter_map" (fun () -> loop 10000 filter_map_style);
  measure_alloc "Use list direct style" (fun () -> loop 10000 direct_style);
  measure_alloc "Render <HelloWorld />" (fun () -> loop 10000 render_hello_world);
  measure_alloc "Render <App />" (fun () -> loop 10000 render_app);
  measure_alloc "Render React.list 10" (fun () -> loop 10000 (render_React_list ~num:10));
  measure_alloc "Render React.array 10" (fun () -> loop 10000 (render_React_array ~num:10));
  measure_alloc "Render React.list 100" (fun () -> loop 10000 (render_React_list ~num:100));
  measure_alloc "Render React.array 100" (fun () -> loop 10000 (render_React_array ~num:100));
  (* measure_alloc "Render React.list 1000" (fun () -> loop 10000 (render_React_list ~num:1000)); *)
  (* measure_alloc "Render React.array 1000" (fun () -> loop 10000 (render_React_array ~num:1000)); *)
  Lwt.return ()

let () = Lwt_main.run (main ())
