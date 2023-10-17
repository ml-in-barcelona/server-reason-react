[@react.component]
let make = () => {
  <div>
    <form method="get">
      <label>
        {React.string("Name:")}
        <input type_="text" name="name" />
      </label>
      <input type_="submit" value="Submit" />
    </form>
  </div>;
};
