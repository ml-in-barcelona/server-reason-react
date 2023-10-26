let () =
  Ppxlib.Driver.register_transformation "server-reason-react.ppx"
    ~impl:Jsx.rewrite_implementation ~intf:Jsx.rewrite_interface
