exception Not_implemented of string

let notImplemented module_ function_ =
  let msg =
    Printf.sprintf
      "'%s.%s' is not implemented in native on `server-reason-react.js`. You are running code that depends on the \
       browser, this is not supported. If this case should run on native and there's no browser dependency, please \
       open an issue at %s"
      module_ function_ "https://github.com/ml-in-barcelona/server-reason-react/issues"
  in
  raise (Not_implemented msg)

type 'a null = 'a option
type 'a undefined = 'a option
type 'a nullable = 'a option
