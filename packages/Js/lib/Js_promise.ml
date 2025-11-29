type +'a t = 'a Lwt.t
type error = exn

let make (fn : resolve:('a -> unit) -> reject:(exn -> unit) -> unit) : 'a t =
  let promise, resolver = Lwt.task () in
  let resolve value = Lwt.wakeup_later resolver value in
  let reject exn = Lwt.wakeup_later_exn resolver exn in
  fn ~resolve ~reject;
  promise

let resolve = Lwt.return
let reject = Lwt.fail
let all (promises : 'a t array) : 'a array t = Lwt.map Stdlib.Array.of_list (Lwt.all (Stdlib.Array.to_list promises))

let all2 (a, b) =
  let%lwt res_a = a in
  let%lwt res_b = b in
  Lwt.return (res_a, res_b)

let all3 (a, b, c) =
  let%lwt res_a = a in
  let%lwt res_b = b in
  let%lwt res_c = c in
  Lwt.return (res_a, res_b, res_c)

let all4 (a, b, c, d) =
  let%lwt res_a = a in
  let%lwt res_b = b in
  let%lwt res_c = c in
  let%lwt res_d = d in
  Lwt.return (res_a, res_b, res_c, res_d)

let all5 (a, b, c, d, e) =
  let%lwt res_a = a in
  let%lwt res_b = b in
  let%lwt res_c = c in
  let%lwt res_d = d in
  let%lwt res_e = e in
  Lwt.return (res_a, res_b, res_c, res_d, res_e)

let all6 (a, b, c, d, e, f) =
  let%lwt res_a = a in
  let%lwt res_b = b in
  let%lwt res_c = c in
  let%lwt res_d = d in
  let%lwt res_e = e in
  let%lwt res_f = f in
  Lwt.return (res_a, res_b, res_c, res_d, res_e, res_f)

let race (promises : 'a t array) : 'a t = Lwt.pick (Stdlib.Array.to_list promises)
let then_ p fn = Lwt.bind fn p
let catch (handler : exn -> 'a t) (promise : 'a t) : 'a t = Lwt.catch (fun () -> promise) handler
