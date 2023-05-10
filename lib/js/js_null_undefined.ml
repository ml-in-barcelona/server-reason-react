type 'a nullable = Null | Something of 'a
type +'a t = 'a nullable

let null = Null
let return a = Something a
