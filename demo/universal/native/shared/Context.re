module Provider = {
  include React.Context;
  let context = React.createContext(23);
  let make = React.Context.provider(context);
};
