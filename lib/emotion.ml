module Hash = struct
  let make str = Murmur3.hash32 str |> Int32.abs |> Int32.to_string

  (* let make str =
     (* Initialize the hash *)
     let h = ref 0 in

     (* Mix 4 bytes at a time into the hash *)
     let k = ref 0 in
     let i = 0 in
     let len = String.length str in

     for i = 0 to (len / 4) - 1 do
       let or_0xff = ( land ) 0xff in
       let first = String.get str i |> Char.code |> or_0xff in
       let second = String.get str (i + 1) |> Char.code |> or_0xff |> ( lsl ) 8 in
       let third = String.get str (i + 2) |> Char.code |> or_0xff |> ( lsl ) 16 in
       let forth = String.get str (i + 3) |> Char.code |> or_0xff |> ( lsl ) 24 in
       k := first lor (second lor (third lor forth));
       k := (k.contents land 0xffff * 0x5bd1e995) + (k.contents lsr 16);
       k := k.contents lxor (k.contents lsr 24) land 0xffffffff;
       h := h.contents * 0x5bd1e995 lxor !k;
       h := h.contents lxor (h.contents lsr 24)
     done;

     (* Handle the last few bytes of the input array *)
     (h :=
        match len with
        | 3 ->
            h.contents
            lxor (String.get str (i + 2)
                 |> Char.code |> ( land ) 0xff |> ( lsl ) 16)
        | 2 ->
            h.contents
            lxor (String.get str (i + 1) |> Char.code |> ( land ) 0xff |> ( lsl ) 8)
        | 1 -> h.contents lxor (String.get str i |> Char.code |> ( land ) 0xff)
        | _ -> h.contents);

     (* Do a few final mixes of the hash to ensure the last few *)
     (* bytes are well-incorporated. *)
     h := h.contents lxor (h.contents lsr 13);
     h := h.contents * 0x5bd1e995;
     h := h.contents lxor (h.contents lsr 15);

     h.contents |> Int.to_string
  *)
end
