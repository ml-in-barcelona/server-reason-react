(** Ported from Melange's test suite: jscomp/test/js_global_test.ml (melange 6.0.1-54).

    The setTimeout/setInterval cases are pure existence/sanity checks (create an id, clear it) which are safe to run
    synchronously: native timer callbacks only fire under a running Lwt loop, and the Lwt-based behavioural timer suite
    already lives in js_global_timers.ml, so it is not duplicated here. *)

open Helpers
open Js.Global

let ok cond = assert_true "expected true" cond

let tests =
  [
    test "setTimeout/clearTimeout sanity check" (fun () ->
        let handle = setTimeout ~f:(fun () -> ()) 0 in
        clearTimeout handle;
        ok true);
    test "setInerval/clearInterval sanity check" (fun () ->
        let handle = setInterval ~f:(fun () -> ()) 0 in
        clearInterval handle;
        ok true);
    test "encodeURI" (fun () -> assert_string (encodeURI "[-=-]") "%5B-=-%5D");
    test "decodeURI" (fun () -> assert_string (decodeURI "%5B-=-%5D") "[-=-]");
    test "encodeURIComponent" (fun () -> assert_string (encodeURIComponent "[-=-]") "%5B-%3D-%5D");
    test "decodeURIComponent" (fun () -> assert_string (decodeURIComponent "%5B-%3D-%5D") "[-=-]");
  ]
