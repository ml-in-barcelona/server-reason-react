let valid value =
  Uutf.String.fold_utf_8 (fun valid _ -> function `Uchar _ -> valid | `Malformed _ -> false) true value
