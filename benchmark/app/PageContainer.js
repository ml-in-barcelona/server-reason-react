const React = require("react");

function PageContainer(props) {
  return React.createElement(
    "div",
    {
      className: "flex xs:justify-center overflow-hidden",
    },
    React.createElement(
      "div",
      {
        className:
          "mt-8 md:mt-32 mx-8 md:mx-32 min-w-md lg:align-center w-full px-4 md:px-8 max-w-2xl",
      },
      props.children
    )
  );
}

exports.default = PageContainer;
