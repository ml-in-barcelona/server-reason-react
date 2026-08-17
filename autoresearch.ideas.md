# Ideas Backlog

- Serialize `Html.element` directly into the subscriber buffer instead of allocating a fresh 1KB `Buffer.t` and intermediate string for each chunk.
- Replace per-row `Printf.sprintf` calls for Flight row IDs with allocation-light hexadecimal writes.
- Reuse or right-size Flight row buffers instead of allocating 4KB for every model and debug row.
- Add a direct Flight writer that avoids building a full `Yojson.Basic.t` tree before serialization.
- Avoid building both `Html.element` and JSON trees in `render_html` when a subtree has a PPX `Writer` fast path.
- Measure queue and Lwt callback allocation before changing `Push_stream`.
