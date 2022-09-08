const React = require("react");

function Greeting({
  name,
  strong,
}) {
  var name = strong === true
    ? React.createElement("strong", null, name)
    : name;

  return React.createElement("span", null, "Hey ", name);
}

exports.Greeting = Greeting;

function GreetingChildren({
  children
}) {
  return React.createElement("span", null, "Hey ", children);
}

exports.GreetingChildren = GreetingChildren;

function Greetings({
  names
}) {
  return React.createElement("span", null, "Hey ", names.join(", "));
}

exports.Greetings = Greetings;

// React.forwardRef is a non-function wrapper component, at least at time of writing
exports.NonFunctionGreeting = React.forwardRef(function Greeting({
  name,
  strong,
}, ref) {
  var name = strong === true
    ? React.createElement("strong", null, name)
    : name;

  return React.createElement("span", { ref: ref }, "Hey ", name);
});
