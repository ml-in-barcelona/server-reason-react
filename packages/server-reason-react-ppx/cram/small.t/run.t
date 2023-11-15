Since we generate invalid syntax for the argument of the make fn `(Props : <>)`
We need to output ML syntax here, otherwise refmt could not parse it.
  $ ../ppx.sh --output ml input.re
  React.Upper_case_component
    (fun () ->
      Component.make
        ~children:
          (React.list
             [
               React.createElement "div" [] [ React.createElement "span" [] [] ];
               React.createElement "span" [] [];
             ])
        ~cosas:false ())
