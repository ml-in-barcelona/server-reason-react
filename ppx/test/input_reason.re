module Joe = {
  [@react.component]
  let make = (~name="joe") => {
    <div> {"`name` " ++ name |> React.string} </div>;
  };
};

