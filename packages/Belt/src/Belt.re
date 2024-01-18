/** The stdlib shipped with Melange, but working on native */;

/** {!Belt.Id}

    Provide utilities to create identified comparators or hashes for
    data structures used below.

    It create a unique identifier per module of
    functions so that different data structures with slightly different
    comparison functions won't mix
*/
module Id = Belt_Id;

/** {!Belt.Array}

    {b mutable array}: Utilities functions
*/
module Array = Belt_Array;

/** {!Belt.SortArray}

    The top level provides some generic sort related utilities.

    It also has two specialized inner modules
    {!Belt.SortArray.Int} and {!Belt.SortArray.String}
*/
module SortArray = Belt_SortArray;

/** {!Belt.MutableQueue}

    An FIFO(first in first out) queue data structure
*/
module MutableQueue = Belt_MutableQueue;

/** {!Belt.MutableStack}

    An FILO(first in last out) stack data structure
*/
module MutableStack = Belt_MutableStack;

/** {!Belt.List}

    Utilities for List data type
*/
module List = Belt_List;

/** {!Belt.Range}

    Utilities for a closed range [(from, start)]
*/
module Range = Belt_Range;

/** {!Belt.Set}

    The top level provides generic {b immutable} set operations.

    It also has three specialized inner modules
    {!Belt.Set.Int}, {!Belt.Set.String} and

    {!Belt.Set.Dict}: This module separates data from function
    which is more verbose but slightly more efficient

*/
module Set = Belt_Set;

/** {!Belt.Map},

    The top level provides generic {b immutable} map operations.

    It also has three specialized inner modules
    {!Belt.Map.Int}, {!Belt.Map.String} and

    {!Belt.Map.Dict}: This module separates data from function
    which  is more verbose but slightly more efficient
*/
module Map = Belt_Map;

/** {!Belt.MutableSet}

    The top level provides generic {b mutable} set operations.

    It also has two specialized inner modules
    {!Belt.MutableSet.Int} and {!Belt.MutableSet.String}
*/
module MutableSet = Belt_MutableSet;

/** {!Belt.MutableMap}

    The top level provides generic {b mutable} map operations.

    It also has two specialized inner modules
    {!Belt.MutableMap.Int} and {!Belt.MutableMap.String}

*/
module MutableMap = Belt_MutableMap;

/** {!Belt.HashSet}

    The top level provides generic {b mutable} hash set operations.

    It also has two specialized inner modules
    {!Belt.HashSet.Int} and {!Belt.HashSet.String}
*/
module HashSet = Belt_HashSet;

/** {!Belt.HashMap}

    The top level provides generic {b mutable} hash map operations.

    It also has two specialized inner modules
    {!Belt.HashMap.Int} and {!Belt.HashMap.String}
*/
module HashMap = Belt_HashMap;

/** {!Belt.Option}

    Utilities for option data type.
*/
module Option = Belt_Option;

/** {!Belt.Result}

    Utilities for result data type.
*/;

module Result = Belt_Result;

/** {!Belt.Int}
    Utilities for Int.
*/;

module Int = Belt_Int;

/** {!Belt.Float}
    Utilities for Float.
*/;

module Float = Belt_Float;
