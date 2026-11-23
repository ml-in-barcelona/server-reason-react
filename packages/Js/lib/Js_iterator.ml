type 'a t = { mutable seq : 'a Seq.t }
type 'a value = { done_ : bool option; value : 'a option }

let make seq = { seq }

let next t =
  match t.seq () with
  | Seq.Nil ->
      t.seq <- Seq.empty;
      { done_ = Some true; value = None }
  | Seq.Cons (v, rest) ->
      t.seq <- rest;
      { done_ = Some false; value = Some v }

let toArray t =
  let arr = Stdlib.Array.of_seq t.seq in
  t.seq <- Seq.empty;
  arr

let toArrayWithMapper t ~f =
  let arr = Stdlib.Array.of_seq (Seq.map f t.seq) in
  t.seq <- Seq.empty;
  arr
