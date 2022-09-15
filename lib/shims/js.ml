module Js : sig
  type 'a nullable

  module Nullable : sig
    type 'a t = 'a nullable

    val null : 'a nullable
    val return : 'a -> 'a nullable
  end
end = struct
  type 'a nullable =
    | Null
    | Something of 'a

  module Nullable = struct
    type +'a t = 'a nullable

    let null = Null
    let return a = Something a
  end
end

include Js
