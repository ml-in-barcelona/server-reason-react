[@@@ocaml.text
" A stdlib shipped with BuckleScript\n\n\
\    This stdlib is still in {i beta} but we encourage you to try it out and\n\
\    give us feedback.\n\n\
\    {b Motivation }\n\n\
\    The motivation for creating such library is to provide BuckleScript users a\n\
\    better end-to-end user experience, since the original OCaml stdlib was not\n\
\    written with JS in mind. Below is a list of areas this lib aims to\n\
\    improve: \n\
\    {ol\n\
\    {- Consistency in name convention: camlCase, and arguments order}\n\
\    {- Exception thrown functions are all suffixed with {i Exn}, e.g, {i \
 getExn}}\n\
\    {- Better performance and smaller code size running on JS platform}\n\
\    }\n\n\
\    {b Name Convention}\n\n\
\    For higher order functions, it will be suffixed {b U} if it takes uncurried\n\
\    callback.\n\n\
\    {[\n\
\        val forEach  : 'a t -> ('a -> unit) -> unit\n\
\        val forEachU : 'a t -> ('a -> unit [@bs]) -> unit \n\
\    ]}\n\n\
\    In general, uncurried version will be faster, but it may be less familiar \
 to\n\
\    people who have a background in functional programming.\n\n\
\   {b A special encoding for collection safety}\n\n\
\   When we create a collection library for a custom data type we need a way \
 to provide a comparator\n\
\   function. Take {i Set} for example, suppose its element type is a pair of \
 ints,\n\
\    it needs a custom {i compare} function that takes two tuples and returns \
 their order.\n\
\    The {i Set} could not just be typed as [ Set.t (int * int) ], its \
 customized {i compare} function \n\
\    needs to manifest itself in the signature, otherwise, if the user creates \
 another\n\
\    customized {i compare} function, the two collection could mix which would \
 result in runtime error.\n\n\
\    The original OCaml stdlib solved the problem using {i functor} which \
 creates a big\n\
\    closure at runtime and makes dead code elimination much harder.\n\
\    We use a phantom type to solve the problem:\n\n\
\    {[\n\
\    module Comparable1 = Belt.Id.MakeComparable(struct\n\
\        type t = int * int\n\
\        let cmp (a0, a1) (b0, b1) =\n\
\          match Stdlib.compare a0 b0 with\n\
\          | 0 -> Stdlib.compare a1 b1\n\
\          | c -> c\n\
\    end)\n\n\
\    let mySet1 = Belt.Set.make ~id:(module Comparable1)\n\n\
\    module Comparable2 = Belt.Id.MakeComparable(struct\n\
\      type t = int * int\n\
\      let cmp (a0, a1) (b0, b1) =\n\
\        match Stdlib.compare a0 b0 with\n\
\        | 0 -> Stdlib.compare a1 b1\n\
\        | c -> c\n\
\    end)\n\n\
\    let mySet2 = Belt.Set.make ~id:(module Comparable2)\n\
\    ]}\n\n\
\    Here, the compiler would infer [mySet1] and [mySet2] having different \
 type, so\n\
\    e.g. a `merge` operation that tries to merge these two sets will \
 correctly fail.\n\n\
\    {[\n\
\        val mySet1 : ((int * int), Comparable1.identity) t\n\
\        val mySet2 : ((int * int), Comparable2.identity) t\n\
\    ]}\n\n\
\    [Comparable1.identity] and [Comparable2.identity] are not the same using \
 our encoding scheme.\n\n\
\    {b Collection Hierarchy}\n\n\
\    In general, we provide a generic collection module, but also create \
 specialized\n\
\    modules for commonly used data type. Take {i Belt.Set} for example, we \
 provide:\n\n\
\    {[\n\
\        Belt.Set\n\
\        Belt.Set.Int\n\
\        Belt.Set.String \n\
\    ]}\n\n\
\    The specialized modules {i Belt.Set.Int}, {i Belt.Set.String} are in \
 general more\n\
\    efficient.\n\n\
\    Currently, both {i Belt_Set} and {i Belt.Set} are accessible to users for \
 some\n\
\    technical reasons,\n\
\    we {b strongly recommend} users stick to qualified import, {i Belt.Set}, \
 we may hide\n\
\    the internal, {i i.e}, {i Belt_Set} in the future\n\n"]

module Id = Belt_Id
[@@ocaml.doc
  " {!Belt.Id}\n\n\
  \    Provide utilities to create identified comparators or hashes for\n\
  \    data structures used below.\n\n\
  \    It create a unique identifier per module of\n\
  \    functions so that different data structures with slightly different\n\
  \    comparison functions won't mix\n"]

module Array = Belt_Array
[@@ocaml.doc " {!Belt.Array}\n\n    {b mutable array}: Utilities functions\n"]

module SortArray = Belt_SortArray
[@@ocaml.doc
  " {!Belt.SortArray}\n\n\
  \    The top level provides some generic sort related utilities.\n\n\
  \    It also has two specialized inner modules\n\
  \    {!Belt.SortArray.Int} and {!Belt.SortArray.String}\n"]

module MutableQueue = Belt_MutableQueue
[@@ocaml.doc
  " {!Belt.MutableQueue}\n\n\
  \    An FIFO(first in first out) queue data structure\n"]

module MutableStack = Belt_MutableStack
[@@ocaml.doc
  " {!Belt.MutableStack}\n\n\
  \    An FILO(first in last out) stack data structure\n"]

module List = Belt_List
[@@ocaml.doc " {!Belt.List}\n\n    Utilities for List data type\n"]

module Range = Belt_Range
[@@ocaml.doc
  " {!Belt.Range}\n\n    Utilities for a closed range [(from, start)]\n"]

module Set = Belt_Set
[@@ocaml.doc
  " {!Belt.Set}\n\n\
  \    The top level provides generic {b immutable} set operations.\n\n\
  \    It also has three specialized inner modules\n\
  \    {!Belt.Set.Int}, {!Belt.Set.String} and\n\n\
  \    {!Belt.Set.Dict}: This module separates data from function\n\
  \    which is more verbose but slightly more efficient\n\n"]

module Map = Belt_Map
[@@ocaml.doc
  " {!Belt.Map},\n\n\
  \    The top level provides generic {b immutable} map operations.\n\n\
  \    It also has three specialized inner modules\n\
  \    {!Belt.Map.Int}, {!Belt.Map.String} and\n\n\
  \    {!Belt.Map.Dict}: This module separates data from function\n\
  \    which  is more verbose but slightly more efficient\n"]

module MutableSet = Belt_MutableSet
[@@ocaml.doc
  " {!Belt.MutableSet}\n\n\
  \    The top level provides generic {b mutable} set operations.\n\n\
  \    It also has two specialized inner modules\n\
  \    {!Belt.MutableSet.Int} and {!Belt.MutableSet.String}\n"]

module MutableMap = Belt_MutableMap
[@@ocaml.doc
  " {!Belt.MutableMap}\n\n\
  \    The top level provides generic {b mutable} map operations.\n\n\
  \    It also has two specialized inner modules\n\
  \    {!Belt.MutableMap.Int} and {!Belt.MutableMap.String}\n\n"]

module HashSet = Belt_HashSet
[@@ocaml.doc
  " {!Belt.HashSet}\n\n\
  \    The top level provides generic {b mutable} hash set operations.\n\n\
  \    It also has two specialized inner modules\n\
  \    {!Belt.HashSet.Int} and {!Belt.HashSet.String}\n"]

module HashMap = Belt_HashMap
[@@ocaml.doc
  " {!Belt.HashMap}\n\n\
  \    The top level provides generic {b mutable} hash map operations.\n\n\
  \    It also has two specialized inner modules\n\
  \    {!Belt.HashMap.Int} and {!Belt.HashMap.String}\n"]

module Option = Belt_Option
[@@ocaml.doc " {!Belt.Option}\n\n    Utilities for option data type.\n"]

[@@@ocaml.text " {!Belt.Result}\n\n    Utilities for result data type.\n"]

module Result = Belt_Result

(** {!Belt.Int}
    Utilities for Int.
*)

module Int = Belt_Int

(** {!Belt.Float}
    Utilities for Float.
*)

module Float = Belt_Float
