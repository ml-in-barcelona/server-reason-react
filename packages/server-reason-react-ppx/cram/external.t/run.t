  $ ../ppx.sh --output re input.re
  module MyPropIsOptionOptionBoolWithSig = {
    [%ocaml.error
      "externals aren't supported on server-reason-react. externals are used to bind to React components defined in JavaScript, in the server, that doesn't make sense. If you need to render this on the server, implement a placeholder or an empty element"
    ];
  };
