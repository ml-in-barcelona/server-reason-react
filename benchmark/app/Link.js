const React = require("react");

function Link(props) {
  return React.createElement(
    "a",
    {
      className: "text-blue-500 hover:text-blue-800",
      href: props.url,
      onClick: function (e) {
        e.preventDefault();
      },
    },
    props.txt
  );
}

exports.default = Link;
