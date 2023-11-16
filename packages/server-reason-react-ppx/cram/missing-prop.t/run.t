
  $ ../ppx.sh --output re input.re
  let almostItemProp = [%ocaml.error
    "jsx: prop 'itemPro' isn't valid on a 'div' element.\nHint: Maybe you mean 'itemProp'?\n\nIf this isn't correct, please open an issue at https://github.com/ml-in-barcelona/server-reason-react/issues."
  ];

  $ ../ppx.sh --output re wrong-prop.re
  [%ocaml.error
    "jsx: prop 'asdf' isn't valid on a 'div' element.\nIf this isn't correct, please open an issue at https://github.com/ml-in-barcelona/server-reason-react/issues."
  ];
