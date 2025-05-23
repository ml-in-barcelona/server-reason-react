[@platform native]
include {
          let useStateValue = initialState => {
            let setValueStatic = _newState => ();
            (initialState, setValueStatic);
          };
        };

[@platform js]
include {
          [@mel.module "react"]
          external useState:
            (unit => 'state) => ('state, (. ('state => 'state)) => unit) =
            "useState";

          let useStateValue = initialState => {
            let (state, setState) = useState(_ => initialState);
            let setValueStatic = newState => setState(. _ => newState);
            (state, setValueStatic);
          };
        };
