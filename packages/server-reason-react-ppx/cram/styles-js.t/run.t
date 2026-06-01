Styles expansion should run in Melange mode before JSX is passed through.
  $ ../ppx.sh --output ml -js input.re
  div ~className:(fst x) ~style:(snd x) ~children:[] () [@JSX]
