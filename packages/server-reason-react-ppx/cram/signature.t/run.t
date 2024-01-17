  $ refmt --parse re --interface true --print ml ./input.rei > output.mli
  $ ./../standalone.exe --intf output.mli -o temp.mli
  $ ocamlformat --enable-outside-detected-project --intf temp.mli -o temp.mli
  $ cat temp.mli
  module Greeting : sig
    val make : ?key:string option -> ?mockup:string -> React.element
  end
