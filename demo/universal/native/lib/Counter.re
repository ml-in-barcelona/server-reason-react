type lola =
  | Mucha
  | Tela({
      name: string,
      age: int,
    })
  | Data;

let lola_to_json = lola => {
  switch (lola) {
  | Mucha => `String("Mucha")
  | Data => `String("Data")
  | Tela({name, age}) =>
    `Assoc([("name", `String(name)), ("age", `Int(age))])
  };
};

let json_to_lola = json => {
  switch (json) {
  | `String("Mucha") => Mucha
  | `String("Data") => Data
  | `Assoc([("name", `String(name)), ("age", `Int(age))]) =>
    Tela({name, age})
  | _ => Mucha
  };
};

[@client]
[@react.component]
let make = (~initial: int, ~lola: lola) => {
  Js.log(Obj.magic(lola));

  let (state, setCount) = RR.useStateValue(initial);

  let onClick = _event => {
    setCount(state + 1);
  };

  <div className={Theme.text(Theme.Color.white)}>
    <Spacer bottom=0>
      <div
        className={Cx.make([
          "flex",
          "justify-items-end",
          "items-center",
          "gap-4",
        ])}>
        <p className={Cx.make(["m-0", "text-3xl", "font-bold"])}>
          {React.string("Counter")}
          {React.string(" ")}
          {switch (lola) {
           | Mucha => React.string("Mucha")
           | Data => React.string("Data")
           | Tela({name, age}) =>
             <span>
               {React.string(name)}
               <br />
               {React.string(Int.to_string(age))}
             </span>
           }}
        </p>
        <button
          onClick
          className="font-mono border-2 py-1 px-2 rounded-lg bg-yellow-950 border-yellow-700 text-yellow-200">
          {React.string(Int.to_string(state))}
        </button>
      </div>
    </Spacer>
  </div>;
};
