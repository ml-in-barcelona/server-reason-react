module Provider = {
  let context = React.createContext(23);
  include React.Context;
  let make = React.Context.provider(context);
};
