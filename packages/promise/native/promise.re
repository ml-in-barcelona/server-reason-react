type t(+'a) = Lwt.t('a);
type error = exn;

let make =
    (fn: (~resolve: 'a => unit, ~reject: exn => unit) => unit): Lwt.t('a) => {
  let (promise, resolver) = Lwt.task();
  let resolve = value => Lwt.wakeup_later(resolver, value);
  let reject = exn => Lwt.wakeup_later_exn(resolver, exn);
  fn(~resolve, ~reject);
  promise;
};

let resolve = Lwt.return;
let reject = Lwt.fail;

let all = (promises: array(Lwt.t('a))): Lwt.t(array('a)) =>
  Lwt.map(Array.of_list, Lwt.all(Array.to_list(promises)));

let all2 = ((a, b)) => {
  let%lwt res_a = a;
  let%lwt res_b = b;
  Lwt.return((res_a, res_b));
};

let all3 = ((a, b, c)) => {
  let%lwt res_a = a;
  let%lwt res_b = b;
  let%lwt res_c = c;
  Lwt.return((res_a, res_b, res_c));
};

let all4 = ((a, b, c, d)) => {
  let%lwt res_a = a;
  let%lwt res_b = b;
  let%lwt res_c = c;
  let%lwt res_d = d;
  Lwt.return((res_a, res_b, res_c, res_d));
};

let all5 = ((a, b, c, d, e)) => {
  let%lwt res_a = a;
  let%lwt res_b = b;
  let%lwt res_c = c;
  let%lwt res_d = d;
  let%lwt res_e = e;
  Lwt.return((res_a, res_b, res_c, res_d, res_e));
};

let all6 = ((a, b, c, d, e, f)) => {
  let%lwt res_a = a;
  let%lwt res_b = b;
  let%lwt res_c = c;
  let%lwt res_d = d;
  let%lwt res_e = e;
  let%lwt res_f = f;
  Lwt.return((res_a, res_b, res_c, res_d, res_e, res_f));
};

let race = (promises: array(Lwt.t('a))): Lwt.t('a) =>
  Lwt.pick(Array.to_list(promises));

let then_ = (p, fn) => Lwt.bind(fn, p);
let catch = (handler: exn => Lwt.t('a), promise: Lwt.t('a)): Lwt.t('a) => {
  Lwt.catch(() => promise, handler);
};
