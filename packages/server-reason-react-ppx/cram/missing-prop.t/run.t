
  $ ../ppx.sh --output re input.re
  File "output.ml", line 1, characters 21-60:
  1 | let almostItemProp = ((div ~itemPro ~children:[] ())[@JSX ])
                           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  Error: prop 'itemPro' isn't valid on a 'div' element.
  Hint: Maybe you mean 'itemProp'?
  
  If this isn't correct, please open an issue at https://github.com/ml-in-barcelona/server-reason-react/issues. Meanwhile you could use `React.createElement`.
  [1]
