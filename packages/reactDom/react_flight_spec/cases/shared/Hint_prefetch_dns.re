/* prefetchDNS(href) emits `:HD"<href>"`. */
module App = {
  [@react.component]
  let make = () => {
    Spec.prefetch_dns(~href="https://dns.example.com");
    <div> {React.string("resolved")} </div>;
  };
};

let app = () => <App />;
