type request = {
  id: int,
  target: string,
  action: RouterTypes.Navigation.historyAction,
  resume: unit => unit,
  drop: unit => unit,
};

type t = {
  mutable active: int,
  mutable nextId: int,
  mutable pending: option(request),
  mutable notify: option(request) => unit,
  mutable ignorePop: bool,
  mutable bypassPop: bool,
};

let make = () => {
  active: 0,
  nextId: 0,
  pending: None,
  notify: _ => (),
  ignorePop: false,
  bypassPop: false,
};

let blocking = blocker => blocker.active > 0;

let settle = (blocker, id, run) =>
  switch (blocker.pending) {
  | Some(request) when request.id == id =>
    blocker.pending = None;
    blocker.notify(None);
    run(request);
  | Some(_)
  | None => ()
  };

let proceed = (blocker, id) =>
  settle(blocker, id, request => request.resume());
let cancel = (blocker, id) => settle(blocker, id, request => request.drop());

let hold = (blocker, ~target, ~action, ~resume, ~drop) => {
  switch (blocker.pending) {
  | Some(previous) => cancel(blocker, previous.id)
  | None => ()
  };
  let request = {
    id: blocker.nextId,
    target,
    action,
    resume,
    drop,
  };
  blocker.nextId = blocker.nextId + 1;
  blocker.pending = Some(request);
  blocker.notify(Some(request));
};

let guard = (blocker, ~target, ~action, ~resume, ~drop) =>
  if (blocking(blocker)) {
    hold(blocker, ~target, ~action, ~resume, ~drop);
  } else {
    resume();
  };

let retain = blocker => {
  blocker.active = blocker.active + 1;
  let released = ref(false);
  () =>
    if (! released^) {
      released := true;
      blocker.active = blocker.active - 1;
      switch (blocker.pending) {
      | Some(request) when blocker.active == 0 => cancel(blocker, request.id)
      | Some(_)
      | None => ()
      };
    };
};

let pop = (blocker, ~current, ~target, ~content, ~url, ~traverse, ~handle) =>
  if (blocker.ignorePop) {
    blocker.ignorePop = false;
  } else if (blocker.bypassPop) {
    blocker.bypassPop = false;
    handle();
  } else {
    switch (current, target) {
    | (Some(current), Some(target))
        when content && blocking(blocker) && current != target =>
      blocker.ignorePop = true;
      traverse(current - target);
      hold(
        blocker,
        ~target=url,
        ~action=RouterTypes.Navigation.Pop,
        ~resume=
          () => {
            blocker.bypassPop = true;
            traverse(target - current);
          },
        ~drop=() => (),
      );
    | _ => handle()
    };
  };
