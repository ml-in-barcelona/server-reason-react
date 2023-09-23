let () =
  Ppxlib.Driver.register_transformation "native-react-ppx"
    ~impl:Jsx_ppx.rewrite_implementation ~intf:Jsx_ppx.rewrite_interface
