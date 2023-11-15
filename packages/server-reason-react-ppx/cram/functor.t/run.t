Since we generate invalid syntax for the argument of the make fn `(Props : <>)`
We need to output ML syntax here, otherwise refmt could not parse it.
  $ ../ppx.sh --output ml input.re
  module type X_int = sig
    val x : int
  end
  
  module Func (M : X_int) = struct
    let x = M.x + 1
  
    let make ?key ~a =
     fun [@warning "-16"] ~b () ->
      print_endline "This function should be named `Test$Func`" M.x;
      React.createElement "div" [] []
  end
