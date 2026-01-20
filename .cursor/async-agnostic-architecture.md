# Async-Agnostic Architecture Plan

## Goal

Decouple `react` and `react-dom` from any specific async runtime (LWT, Picos, etc.) by using OCaml functors. This enables:

1. A core `react` library with no async dependencies
2. Backend-specific libraries (`react-lwt`, `react-picos`) that instantiate the core with their async implementation
3. Users choose their async runtime at compile time
4. Full type safety and exhaustiveness checking preserved

## Current State

LWT is deeply embedded in the codebase:

| Location | LWT Usage |
|----------|-----------|
| `React.element` | `Async_component of string * (unit -> element Lwt.t)` |
| `React.Model.t` | `Promise : 'a Lwt.t * ('a -> json) -> 'element t` |
| `React.any_promise` | `Any_promise : 'a Lwt.t -> any_promise` |
| `ReactServerDOM.ml` | `Lwt.state`, `Lwt.async`, `let%lwt`, `Lwt_list.map_p` |
| `Push_stream.ml` | `Lwt_stream.create`, `Lwt_stream.iter_s` |
| Tests | `Alcotest_lwt`, `Lwt_unix.sleep`, `Lwt.pick` |

## Proposed Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         User Code                                │
└─────────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              ▼                               ▼
┌─────────────────────────┐     ┌─────────────────────────┐
│     react-lwt           │     │     react-picos         │
│  React.Make(Lwt_async)  │     │  React.Make(Picos_async)│
└─────────────────────────┘     └─────────────────────────┘
              │                               │
              ▼                               ▼
┌─────────────────────────┐     ┌─────────────────────────┐
│   react-dom-lwt         │     │   react-dom-picos       │
│ ReactDOM.Make(Lwt_async)│     │ReactDOM.Make(Picos_async│
└─────────────────────────┘     └─────────────────────────┘
              │                               │
              └───────────────┬───────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    react (core, no async)                        │
│                    react-dom (core, no async)                    │
│                    Async_intf (module signature)                 │
└─────────────────────────────────────────────────────────────────┘
```

## Module Design

### 1. Async Interface (`packages/async-intf/Async_intf.ml`)

```ocaml
module type S = sig
  type 'a t

  (* Monad operations *)
  val return : 'a -> 'a t
  val bind : 'a t -> ('a -> 'b t) -> 'b t
  val map : ('a -> 'b) -> 'a t -> 'b t

  (* Non-blocking state inspection *)
  type 'a state =
    | Resolved of 'a
    | Failed of exn
    | Pending
  val state : 'a t -> 'a state

  (* Background execution *)
  val async : (unit -> unit t) -> unit

  (* Parallel operations *)
  val all : 'a t list -> 'a list t
  val all_unit : unit t list -> unit t

  (* Streams for SSR *)
  module Stream : sig
    type 'a t
    val create : unit -> 'a t * ('a option -> unit)
    val iter : ('a -> unit) -> 'a t -> unit
  end
end
```

### 2. React Core (`packages/react/React.ml`)

```ocaml
module type ASYNC = Async_intf.S

module Make (Async : ASYNC) = struct
  type 'a async = 'a Async.t

  type element =
    | Lower_case_element of lower_case_element
    | Upper_case_component of string * (unit -> element)
    | Async_component of string * (unit -> element async)
    | Text of string
    | Empty
    | Fragment of element
    | List of element list
    | Array of element array
    | Suspense of { key : string option; children : element; fallback : element }
    | Provider of element
    | Consumer of element
    | Client_component of client_component

  (* ... rest of React API ... *)
end

(* Sync-only version for simple cases *)
module Sync = struct
  module Identity = struct
    type 'a t = 'a
    let return x = x
    let bind x f = f x
    let map f x = f x
    type 'a state = Resolved of 'a | Failed of exn | Pending
    let state x = Resolved x
    let async f = ignore (f ())
    let all = Fun.id
    let all_unit _ = ()
    module Stream = struct
      type 'a t = 'a Queue.t
      let create () = let q = Queue.create () in (q, function Some x -> Queue.push x q | None -> ())
      let iter f q = Queue.iter f q
    end
  end

  include Make(Identity)
end
```

### 3. LWT Backend (`packages/react-lwt/Lwt_async.ml`)

```ocaml
module Lwt_async : Async_intf.S with type 'a t = 'a Lwt.t = struct
  type 'a t = 'a Lwt.t

  let return = Lwt.return
  let bind = Lwt.bind
  let map f p = Lwt.map f p

  type 'a state = Resolved of 'a | Failed of exn | Pending

  let state p =
    match Lwt.state p with
    | Lwt.Return v -> Resolved v
    | Lwt.Fail e -> Failed e
    | Lwt.Sleep -> Pending

  let async = Lwt.async
  let all = Lwt.all
  let all_unit ps = Lwt.join ps

  module Stream = struct
    type 'a t = 'a Lwt_stream.t
    let create () = Lwt_stream.create ()
    let iter f s = Lwt.async (fun () -> Lwt_stream.iter f s; Lwt.return ())
  end
end
```

### 4. Picos Backend (`packages/react-picos/Picos_async.ml`)

```ocaml
module Picos_async : Async_intf.S = struct
  open Picos_std_sync
  open Picos_std_structured

  type 'a promise_result = Value of 'a | Error of exn | Pending

  type 'a t = 'a promise_result Ivar.t

  let return x =
    let ivar = Ivar.create () in
    Ivar.fill ivar (Value x);
    ivar

  let bind p f =
    let result = Ivar.create () in
    Flock.fork (fun () ->
      match Ivar.read p with
      | Value v ->
          (match Ivar.read (f v) with
          | r -> Ivar.fill result r)
      | Error e -> Ivar.fill result (Error e)
      | Pending -> assert false
    );
    result

  let map f p = bind p (fun x -> return (f x))

  type 'a state = Resolved of 'a | Failed of exn | Pending

  let state p =
    match Ivar.try_read p with
    | Some (Value v) -> Resolved v
    | Some (Error e) -> Failed e
    | Some Pending | None -> Pending

  let async f =
    Flock.fork (fun () -> ignore (Ivar.read (f ())))

  let all ps =
    let result = Ivar.create () in
    Flock.fork (fun () ->
      try
        let values = List.map (fun p ->
          match Ivar.read p with
          | Value v -> v
          | Error e -> raise e
          | Pending -> assert false
        ) ps in
        Ivar.fill result (Value values)
      with e -> Ivar.fill result (Error e)
    );
    result

  let all_unit ps = map (fun _ -> ()) (all ps)

  module Stream = struct
    type 'a t = {
      queue : 'a Queue.t;
      mutex : Mutex.t;
      mutable closed : bool;
      condition : Condition.t;
    }

    let create () =
      let s = {
        queue = Queue.create ();
        mutex = Mutex.create ();
        closed = false;
        condition = Condition.create ();
      } in
      let push = function
        | Some v ->
            Mutex.lock s.mutex;
            Queue.push v s.queue;
            Mutex.unlock s.mutex;
            Condition.signal s.condition
        | None ->
            s.closed <- true;
            Condition.signal s.condition
      in
      (s, push)

    let iter f s =
      let rec loop () =
        Mutex.lock s.mutex;
        let item = if Queue.is_empty s.queue then None else Some (Queue.pop s.queue) in
        Mutex.unlock s.mutex;
        match item with
        | Some v -> f v; loop ()
        | None when s.closed -> ()
        | None -> Condition.wait s.condition s.mutex; loop ()
      in
      loop ()
  end
end
```

## Package Structure

```
packages/
├── async-intf/           # NEW: Module signature only
│   ├── dune
│   └── Async_intf.ml
│
├── react/                # MODIFIED: Functor-based, no async deps
│   ├── src/
│   │   ├── React.ml      # module Make(Async : ASYNC) = struct ... end
│   │   └── React.mli
│   └── dune              # No lwt dependency
│
├── react-lwt/            # NEW: LWT instantiation
│   ├── dune              # depends on react, lwt
│   ├── Lwt_async.ml
│   └── React_lwt.ml      # include React.Make(Lwt_async)
│
├── react-picos/          # NEW: Picos instantiation
│   ├── dune              # depends on react, picos, picos_std
│   ├── Picos_async.ml
│   └── React_picos.ml    # include React.Make(Picos_async)
│
├── reactDom/             # MODIFIED: Functor-based, no async deps
│   ├── src/
│   │   ├── ReactServerDOM.ml   # module Make(Async)(React) = struct ... end
│   │   └── ReactDOM.ml
│   └── dune              # No lwt dependency
│
├── react-dom-lwt/        # NEW: LWT instantiation
│   ├── dune              # depends on reactDom, react-lwt, lwt
│   └── ReactServerDOM_lwt.ml
│
└── react-dom-picos/      # NEW: Picos instantiation
    ├── dune              # depends on reactDom, react-picos, picos
    └── ReactServerDOM_picos.ml
```

## Implementation Phases

### Phase 1: Create Async Interface
- [ ] Create `packages/async-intf` with `Async_intf.ml`
- [ ] Define the minimal interface needed by React and ReactDOM
- [ ] Write tests for the interface contract

### Phase 2: Refactor React Core
- [ ] Convert `React.ml` to `module Make(Async : ASYNC)`
- [ ] Replace all `Lwt.t` with `Async.t`
- [ ] Replace `Lwt.state` with `Async.state`
- [ ] Update `React.mli` with functor signature
- [ ] Ensure no LWT imports remain in core

### Phase 3: Create react-lwt
- [ ] Implement `Lwt_async` module
- [ ] Create `React_lwt.ml` that instantiates the functor
- [ ] Verify existing tests pass with new structure

### Phase 4: Refactor ReactServerDOM Core
- [ ] Convert `ReactServerDOM.ml` to functor
- [ ] Convert `Push_stream.ml` to use `Async.Stream`
- [ ] Replace `let%lwt` with explicit `Async.bind`
- [ ] Replace `Lwt.async` with `Async.async`
- [ ] Replace `Lwt_list.map_p` with custom parallel map

### Phase 5: Create react-dom-lwt
- [ ] Implement `ReactServerDOM_lwt.ml`
- [ ] Migrate existing tests to use `react-dom-lwt`
- [ ] Verify all tests pass

### Phase 6: Create Picos Backend
- [ ] Implement `Picos_async` module
- [ ] Create `React_picos.ml`
- [ ] Create `ReactServerDOM_picos.ml`
- [ ] Write Picos-specific tests
- [ ] Benchmark against LWT implementation

### Phase 7: Update Downstream
- [ ] Update demo applications
- [ ] Update documentation
- [ ] Create migration guide for users

## Test Strategy

### Unit Tests for Async Interface
```ocaml
(* Test that any ASYNC implementation satisfies the laws *)
module Test_async (A : Async_intf.S) = struct
  let test_return_bind () =
    (* return x >>= f  ≡  f x *)
    let x = 42 in
    let f n = A.return (n + 1) in
    assert (A.state (A.bind (A.return x) f) = A.state (f x))

  let test_state_resolved () =
    assert (A.state (A.return 42) = A.Resolved 42)
end
```

### Integration Tests
- Run existing test suite against both `react-dom-lwt` and `react-dom-picos`
- Compare output for identical inputs
- Benchmark streaming performance

## Migration Guide for Users

### Before (LWT-coupled)
```ocaml
open React
open ReactServerDOM

let app = Async_component ("app", fun () ->
  let%lwt data = fetch_data () in
  Lwt.return (createElement "div" [] [string data]))
```

### After (with react-lwt)
```ocaml
open React_lwt
open ReactServerDOM_lwt

let app = Async_component ("app", fun () ->
  let%lwt data = fetch_data () in
  Lwt.return (createElement "div" [] [string data]))
```

The change is minimal - just update the imports.

## Trade-offs

### Pros
- Clean separation of concerns
- Can add new async backends without changing core
- Full type safety preserved
- Exhaustiveness checking works
- Each backend optimized for its runtime

### Cons
- `React_lwt.element` ≠ `React_picos.element` (incompatible types)
- Cannot mix backends in same application
- Slightly more complex module structure
- Functor application has minimal overhead

## Open Questions

1. **PPX compatibility**: Does `lwt_ppx` work when `let%lwt` is inside a functor? Need to verify.

2. **Reason syntax**: How does this affect `.re` files that use JSX?

3. **Client components**: Do client components need async awareness, or are they always sync?

4. **Melange compatibility**: Does this architecture work for the browser build?

5. **Error handling**: Should `Async.t` be `('a, exn) result t` or handle errors via exceptions?

## Timeline Estimate

| Phase | Effort |
|-------|--------|
| Phase 1: Async Interface | Small |
| Phase 2: React Core | Medium |
| Phase 3: react-lwt | Small |
| Phase 4: ReactServerDOM Core | Large |
| Phase 5: react-dom-lwt | Small |
| Phase 6: Picos Backend | Medium |
| Phase 7: Downstream | Medium |

The largest effort is Phase 4 (ReactServerDOM) due to the extensive use of `let%lwt` syntax and stream handling.
