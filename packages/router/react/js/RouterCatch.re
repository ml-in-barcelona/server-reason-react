type componentClass;
type props = {
  .
  "fallback": React.element,
  "resetKey": RouterOutlet.operation,
  "children": React.element,
};

[@mel.module "react"] external component: componentClass = "Component";

let define: componentClass => React.component(props) = [%mel.raw
  {|function (Component) {
  class RouterErrorBoundary extends Component {
    constructor(props) {
      super(props);
      this.state = { failed: false, resetKey: props.resetKey };
    }
    static getDerivedStateFromProps(props, state) {
      return state.resetKey === props.resetKey
        ? null
        : { failed: false, resetKey: props.resetKey };
    }
    static getDerivedStateFromError() {
      return { failed: true };
    }
    render() {
      return this.state.failed ? this.props.fallback : this.props.children;
    }
  }
  return RouterErrorBoundary;
}|}
];

let boundary = define(component);

let make = (~fallback, ~children) =>
  React.createElement(
    boundary,
    {
      "fallback": fallback,
      "resetKey": React.useContext(RouterOutlet.context),
      "children": children,
    },
  );
