Printf.printf("Rendering app to stdout");
print_endline("");
let start = Unix.gettimeofday();
print_endline(ReactDOM.renderToStaticMarkup(<HelloWorld />));
print_endline("");

let end_time = Unix.gettimeofday();
Printf.printf("Execution time: %.6f ms\n", (end_time -. start) *. 1000.0);
