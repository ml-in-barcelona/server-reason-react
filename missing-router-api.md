# Missing router APIs

## Server-rendered links

Generated route components rendered by server components become plain anchors
because the native router cannot attach a browser click handler. Applications
currently need a client layout that delegates same-origin anchor clicks back to
`Router.useNavigation` through `Router.unsafeDestination`.

The router provider should own this delegated navigation. Generated native
links should serialize their history and revalidation intent as data attributes
so the client provider can preserve modifier keys, targets, downloads, hashes,
and full-document opt-outs without application-specific click effects.

## Page cache controls

The first visited-page cache only stores bounded full RSC responses and uses
`revalidate=true` as its bypass. The public router interface still needs:

- `prefetch(destination)`
- `invalidate(destination)` and tag-based invalidation
- current-route revalidation
- cache status for pending, hit, miss, and stale states
- separate freshness and full-response policies
- memory limits based on retained Flight bytes as well as entry count

Patch responses cannot be cached safely while `RouterOutlet` owns grafted
subtrees in local state. Supporting cached patches requires one immutable render
frame that owns the base element and all active grafts.

## Flight lifecycle

The router can commit after a Flight root resolves while nested promised rows
are still streaming. Cache eviction and request cancellation need separate
root-ready and stream-complete signals before pending promised content can be
managed safely.
