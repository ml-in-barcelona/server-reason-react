module React_component_with_props = {
  [@react.component]
  let make = (~lola) => {
    <div> {React.string(lola)} </div>;
  };
};
let react_component_with_props = <React_component_with_props lola="flores" />;

/* module Using_React_memo = {
     [@react.component]
     let make =
       React.memo((~a) =>
         <div> {Printf.sprintf("`a` is %s", a) |> React.string} </div>
       );
   };

   module Using_memo_custom_compare_Props = {
     [@react.component]
     let make =
       React.memoCustomCompareProps(
         (~a) => <div> {Printf.sprintf("`a` is %d", a) |> React.string} </div>,
         (prevPros, nextProps) => false,
       );
   }; */

module Forward_Ref = {
  [@react.component]
  let make =
    React.forwardRef((~children, ~buttonRef) => {
      <button ref=buttonRef className="FancyButton"> children </button>
    });
};

module Onclick_handler_button = {
  [@react.component]
  let make = (~name, ~isDisabled=?) => {
    let onClick = event => Js.log(event);
    <button name onClick disabled=isDisabled />;
  };
};

module Children_as_string = {
  [@react.component]
  let make = (~name="joe") =>
    <div> {Printf.sprintf("`name` is %s", name) |> React.string} </div>;
};

/* It shoudn't remove this :/ */
let () = Dream.run();
let l = 33;

module Uppercase_with_SSR_components = {
  [@react.component]
  let make = (~children, ~moreProps) =>
    <html>
      <head>
        <title> {React.string("SSR React " ++ moreProps)} </title>
      </head>
      <body>
        <div id="root"> children </div>
        <script src="/static/client.js" />
      </body>
    </html>;
};

module Upper_with_aria = {
  [@react.component]
  let make = (~children) => <div ariaHidden="true"> children </div>;
};

// As the ppx does not runs as preprocessor, using method will break, like the error below:
// +  File "output.ml", line 62, characters 33-41:
// +  62 |     let make ~children  = ((form ~method:"GET" ~children:[children] ())
// So I commented this for know and added a test at ../test.re
// module Form_with_method = {
//   [@react.component]
//   let make = (~children) => <form method="GET"> children </form>;
// };

module Form_with_action = {
  [@react.component]
  let make = (~children) => <form actionFn="action_id"> children </form>;
};

let a = <Uppercase> <div /> </Uppercase>;

module Async_component = {
  [@react.async.component]
  let make = (~children) => <div className="async-component"> children </div>;
};

let a = <Async_component> <div /> </Async_component>;

module Sequence = {
  [@react.component]
  let make = (~lola) => {
    let (state, setState) = React.useState(lola);

    React.useEffect(() => {
      setState(lola);
      None;
    });

    <div> {React.string(state)} </div>;
  };
};

module Use_context = {
  [@react.component]
  let make = () => {
    let captured = React.useContext(Context.value);
    <div> {React.string(captured)} </div>;
  };
};
