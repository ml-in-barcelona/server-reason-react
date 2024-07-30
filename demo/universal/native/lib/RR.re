let useStateValue = initialState => {
  let (state, setState) = React.useState(_ => initialState);
  let setValueStatic = newState => setState(_ => newState);
  (state, setValueStatic);
};
