  $ cat > dune-project << EOF
  > (lang dune 3.10)
  > EOF

  $ cat > dune << EOF
  > (include_subdirs unqualified)
  > (executable
  >  (name input)
  >  (libraries server-reason-react.react server-reason-react.runtime server-reason-react.reactDom melange-json)
  >  (preprocess (pps server-reason-react.ppx -shared-folder-prefix=native/ server-reason-react.melange_ppx melange-json-native.ppx)))
  > EOF

  $ ../dune-describe-pp.sh native/input.ml
  include
    struct
      let makeProps () =
        let __js_obj = object  end in
        (Js.Obj.Internal.register_abstract __js_obj [] : <  >  Js.t)
      let make ?key:(key : string option) () =
        React.Client_component
          {
            key;
            import_module = "input.ml";
            import_name = "";
            props = [];
            client =
              (React.Upper_case_component
                 (Stdlib.__FUNCTION__, (fun () -> React.null)))
          }
      let make ?key:(key : string option) (_Props : <  >  Js.t) = make ?key ()
    end
