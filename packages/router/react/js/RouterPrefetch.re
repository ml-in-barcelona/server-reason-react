module Level = RouterRuntime.PrefetchLevel;

type request = {
  url: string,
  trigger: Level.t,
};

type t = {
  limit: int,
  mutable inFlight: list(string),
  mutable queued: list(request),
  mutable refused: list((string, Level.t)),
};

let refusedLimit = 200;

let make = (~limit) => {
  limit,
  inFlight: [],
  queued: [],
  refused: [],
};

let attribute = "data-router-prefetch";

let levelOfAttribute = value =>
  switch (Option.bind(value, Level.fromString)) {
  | Some(level) => level
  | None => Level.Intent
  };

let rec take = (count, values) =>
  switch (values) {
  | [value, ...values] when count > 0 => [value, ...take(count - 1, values)]
  | _ => []
  };

let refuse = (state, ~url, level) =>
  state.refused =
    take(
      refusedLimit,
      [(url, level), ...List.remove_assoc(url, state.refused)],
    );

let allowed = (state, ~url, ~level, ~trigger) => {
  let level =
    switch (List.assoc_opt(url, state.refused)) {
    | Some(refused) when Level.compare(refused, level) < 0 => refused
    | Some(_)
    | None => level
    };
  Level.compare(trigger, level) <= 0
  && !List.mem(url, state.inFlight)
  && !List.exists(request => String.equal(request.url, url), state.queued);
};

let rec pump = (state, ~run) =>
  switch (state.queued) {
  | [request, ...rest] when List.length(state.inFlight) < state.limit =>
    state.queued = rest;
    start(state, ~run, request);
  | _ => ()
  }
and start = (state, ~run, request) => {
  state.inFlight = [request.url, ...state.inFlight];
  run(
    request,
    () => {
      state.inFlight = List.filter(url => url != request.url, state.inFlight);
      pump(state, ~run);
    },
  );
};

let request = (state, ~run, ~url, ~level, ~trigger) =>
  if (allowed(state, ~url, ~level, ~trigger)) {
    if (List.length(state.inFlight) < state.limit) {
      start(
        state,
        ~run,
        {
          url,
          trigger,
        },
      );
    } else {
      state.queued =
        trigger == Level.Intent
          ? [
            {
              url,
              trigger,
            },
            ...state.queued,
          ]
          : state.queued
            @ [
              {
                url,
                trigger,
              },
            ];
    };
  };

let clear = state => state.queued = [];
