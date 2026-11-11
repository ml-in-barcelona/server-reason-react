type +'a t = 'a Lwt.t
type error = exn

let on_settle p k = Lwt.on_any p (fun v -> k (Ok v)) (fun exn -> k (Error exn))
let settle promise wakeup result = if Lwt.is_sleeping promise then wakeup result

let make (fn : resolve:('a -> unit) -> reject:(exn -> unit) -> unit) : 'a t =
  let promise, resolver = Lwt.task () in
  let settle = settle promise (Lwt.wakeup_later_result resolver) in
  let resolve value = settle (Ok value) in
  let reject exn = settle (Error exn) in
  (try fn ~resolve ~reject with exn -> reject exn);
  promise

let resolve = Lwt.return
let reject = Lwt.fail

let both a b =
  let promise, resolver = Lwt.wait () in
  let settle = settle promise (Lwt.wakeup_result resolver) in
  let reject_on_error = function Ok _ -> () | Error exn -> settle (Error exn) in
  on_settle a (function
    | Ok va -> on_settle b (function Ok vb -> settle (Ok (va, vb)) | error -> reject_on_error error)
    | error -> reject_on_error error);
  on_settle b reject_on_error;
  promise

let all (promises : 'a t array) : 'a array t =
  Stdlib.Array.fold_right (fun p acc -> Lwt.map (fun (v, vs) -> v :: vs) (both p acc)) promises (Lwt.return [])
  |> Lwt.map Stdlib.Array.of_list

let all2 (a, b) = both a b
let all3 (a, b, c) = Lwt.map (fun (a, (b, c)) -> (a, b, c)) (both a (both b c))
let all4 (a, b, c, d) = Lwt.map (fun (a, (b, c, d)) -> (a, b, c, d)) (both a (all3 (b, c, d)))
let all5 (a, b, c, d, e) = Lwt.map (fun (a, (b, c, d, e)) -> (a, b, c, d, e)) (both a (all4 (b, c, d, e)))
let all6 (a, b, c, d, e, f) = Lwt.map (fun (a, (b, c, d, e, f)) -> (a, b, c, d, e, f)) (both a (all5 (b, c, d, e, f)))

let race (promises : 'a t array) : 'a t =
  let promise, resolver = Lwt.wait () in
  Stdlib.Array.iter (fun p -> on_settle p (settle promise (Lwt.wakeup_result resolver))) promises;
  promise

let then_ fn p = Lwt.bind p (Lwt.apply fn)
let catch (handler : exn -> 'a t) (promise : 'a t) : 'a t = Lwt.catch (fun () -> promise) (Lwt.apply handler)
