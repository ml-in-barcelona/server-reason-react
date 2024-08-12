Printf.printf("Rendering app to stdout\n");
let start = Unix.gettimeofday();
print_endline(ReactDOM.renderToStaticMarkup(<HelloWorld />));
let end_time = Unix.gettimeofday();
Printf.printf("\nExecution time: %.6f ms\n", (end_time -. start) *. 1000.0);
