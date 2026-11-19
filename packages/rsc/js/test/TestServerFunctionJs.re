let expect = (message, condition) =>
  if (!condition) {
    failwith(message);
  };

let calls: ref(array(string)) = ref([||]);

let serverReference: (string => unit, RSC.t) => RSC.t = [%mel.raw
  {|(record, response) => function () {
  record(JSON.stringify(Array.from(arguments, (value) => value === undefined ? "undefined" : value)));
  return Promise.resolve(response);
}|}
];

let record = call => calls := Js.Array.concat(~other=[|call|], calls^);

let decode = rsc =>
  [%of_rsc:
    Runtime.server_function(
      (~name: string, ~age: int, ~greeting: string=?, unit) =>
      Js.Promise.t(int64),
    )
  ](
    rsc,
  );

let reference = serverReference(record, Obj.magic("42"));
let greet = decode(reference);

expect(
  "decoding the same reference twice gave two records",
  decode(reference) === greet,
);

let rejected =
  switch (decode(Obj.magic("not a function"))) {
  | _ => false
  | exception (RSC.Of_rsc_error(_)) => true
  };
expect("a non-function decoded as a server function", rejected);

let _ =
  greet.call(~name="Lola", ~age=20, ())
  |> Js.Promise.then_(response => {
       expect("the response was not decoded", response == 42L);
       greet.call(~name="Lola", ~age=20, ~greeting="Hola", ());
     })
  |> Js.Promise.then_(_ => {
       expect(
         "the reference got other arguments: "
         ++ Js.Array.join(~sep=" ", calls^),
         calls^
         == [|
              {|["Lola",20,"undefined","undefined"]|},
              {|["Lola",20,"Hola","undefined"]|},
            |],
       );
       Js.Promise.resolve();
     })
  |> Js.Promise.catch(error => {
       Js.log(error);
       [%raw {|process.exit(1)|}];
     });
