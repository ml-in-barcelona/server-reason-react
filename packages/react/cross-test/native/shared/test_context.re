let context: React.Context.t(option(string)) = React.createContext(None);
include React.Context;
let make = React.Context.provider(context);
