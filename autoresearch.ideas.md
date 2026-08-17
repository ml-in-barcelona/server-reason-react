# Ideas Backlog

- Reuse or right-size Flight row buffers instead of allocating 4KB for every model and debug row.
- Add a direct Flight writer that avoids building a full `Yojson.Basic.t` tree before serialization.
- Avoid building both `Html.element` and JSON trees in `render_html` when a subtree has a PPX `Writer` fast path.
- Measure queue and Lwt callback allocation before changing `Push_stream`.
- Revisit recursive JSON list and association traversal with a larger sample count.
