/* TODO: Add useState in reason-react 19's PR */
[@mel.module "react"]
external useState:
  (unit => 'state) => ('state, (. ('state => 'state)) => unit) =
  "useState";

let useStateValue = initialState => {
  let (state, setState) = useState(_ => initialState);
  let setValueStatic = newState => setState(. _ => newState);
  (state, setValueStatic);
};
