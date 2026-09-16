val project_row : string -> string
(** Check native production element tuples and remove their three-field validation suffix. All retained bytes are copied
    unchanged. Malformed JSON, row headers, or element tuples raise [Invalid_argument]. *)
