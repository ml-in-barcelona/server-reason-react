let continuation value length index = index < length && Char.code (String.unsafe_get value index) land 0xc0 = 0x80

let rec valid_from value length index =
  if index >= length then true
  else
    let first = Char.code (String.unsafe_get value index) in
    if first < 0x80 then valid_from value length (index + 1)
    else if first < 0xc2 then false
    else if first < 0xe0 then continuation value length (index + 1) && valid_from value length (index + 2)
    else if index + 1 >= length then false
    else
      let second = Char.code (String.unsafe_get value (index + 1)) in
      if first < 0xf0 then
        (match first with 0xe0 -> second >= 0xa0 | 0xed -> second < 0xa0 | _ -> true)
        && continuation value length (index + 1)
        && continuation value length (index + 2)
        && valid_from value length (index + 3)
      else if first < 0xf5 then
        (match first with 0xf0 -> second >= 0x90 | 0xf4 -> second < 0x90 | _ -> true)
        && continuation value length (index + 1)
        && continuation value length (index + 2)
        && continuation value length (index + 3)
        && valid_from value length (index + 4)
      else false

let valid value = valid_from value (String.length value) 0
