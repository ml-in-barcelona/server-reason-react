let context: React.context(option(string)) = React.createContext(None);
include React.Context;
let make = React.Context.provider(context);
