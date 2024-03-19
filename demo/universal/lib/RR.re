let useStateValue = a => {
  let (value, setValue) = React.useState(_ => a);
  let setValueStatic = value => setValue(_ => value);
  (value, setValueStatic);
};
