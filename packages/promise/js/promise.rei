type t(+'a);
type error;

let make:
  ((~resolve: (. 'a) => unit, ~reject: (. exn) => unit) => unit) => t('a);

let resolve: 'a => t('a);
let reject: exn => t('a);

let all: array(t('a)) => t(array('a));

let all2: ((t('a0), t('a1))) => t(('a0, 'a1));

let all3: ((t('a0), t('a1), t('a2))) => t(('a0, 'a1, 'a2));

let all4: ((t('a0), t('a1), t('a2), t('a3))) => t(('a0, 'a1, 'a2, 'a3));

let all5:
  ((t('a0), t('a1), t('a2), t('a3), t('a4))) =>
  t(('a0, 'a1, 'a2, 'a3, 'a4));

let all6:
  ((t('a0), t('a1), t('a2), t('a3), t('a4), t('a5))) =>
  t(('a0, 'a1, 'a2, 'a3, 'a4, 'a5));

let race: array(t('a)) => t('a);

let then_: ('a => t('b), t('a)) => t('b);
let catch: (error => t('a), t('a)) => t('a);
