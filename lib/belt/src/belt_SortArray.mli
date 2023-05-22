(** A module for Array sort relevant utiliites *)

module Int = Belt_SortArrayInt
(** Specalized when key type is [int], more efficient
    than the generic type *)

module String = Belt_SortArrayString
(** Specalized when key type is [string], more efficient
    than the generic type *)

val strictlySortedLengthU : 'a array -> (('a -> 'a -> bool)[@bs]) -> int

val strictlySortedLength : 'a array -> ('a -> 'a -> bool) -> int
(**
  [strictlySortedLenght xs cmp]
  return [+n] means increasing order
  [-n] means negative order

  @example{[
     strictlySortedLength [|1;2;3;4;3|] (fun x y -> x < y) = 4;;
     strictlySortedLength [||] (fun x y -> x < y) = 0;;
     strictlySortedLength [|1|] (fun x y -> x < y) = 1;;
     strictlySortedLength [|4;3;2;1|] (fun x y -> x < y) = -4;;
  ]}
*)

val isSortedU : 'a array -> (('a -> 'a -> int)[@bs]) -> bool

val isSorted : 'a array -> ('a -> 'a -> int) -> bool
(** [isSorted arr cmp]
    @return true if array is increasingly sorted (equal is okay )
    @example {[
     isSorted [|1;1;2;3;4|] (fun x y -> compare x y) = true
   ]}
*)

val stableSortInPlaceByU : 'a array -> (('a -> 'a -> int)[@bs]) -> unit

val stableSortInPlaceBy : 'a array -> ('a -> 'a -> int) -> unit
(** [stableSortBy xs cmp]

    Sort xs in place using comparator [cmp], the stable means if the elements
    are equal, their order will be preserved
*)

val stableSortByU : 'a array -> (('a -> 'a -> int)[@bs]) -> 'a array

val stableSortBy : 'a array -> ('a -> 'a -> int) -> 'a array
(** [stableSort xs cmp]
    @return a fresh array

    The same as {!stableSortInPlaceBy} except that [xs] is  not modified
*)

val binarySearchByU : 'a array -> 'a -> (('a -> 'a -> int)[@bs]) -> int

val binarySearchBy : 'a array -> 'a -> ('a -> 'a -> int) -> int
(**

  If value is not found and value is less than one or more elements in array,
  the negative number returned is the bitwise complement of the index of the first element
  that is larger than value.

  If value is not found and value is greater than all elements in array,
  the negative number returned is the bitwise complement of
  (the index of the last element plus 1)

  for example, if [key] is smaller than all elements return [-1] since [lnot (-1) = 0]
  if [key] is larger than all elements return [- (len + 1)] since [lnot (-(len+1)) = len]

   @example {[
     binarySearchBy [|1;2;3;4;33;35;36|] 33 = 4;;
     lnot (binarySearchBy [|1;3;5;7|] 4) = 2;;
   ]}
*)

(**/**)

val unionU :
  'a array ->
  int ->
  int ->
  'a array ->
  int ->
  int ->
  'a array ->
  int ->
  (('a -> 'a -> int)[@bs]) ->
  int

val union :
  'a array ->
  int ->
  int ->
  'a array ->
  int ->
  int ->
  'a array ->
  int ->
  ('a -> 'a -> int) ->
  int
(**
  [union src src1ofs src1len src2 src2ofs src2len dst dstofs cmp]
  assume [src] and [src2] is strictly sorted.
  for equivalent elements, it is picked from [src]
  also assume that [dst] is large enough to store all elements
*)

val intersectU :
  'a array ->
  int ->
  int ->
  'a array ->
  int ->
  int ->
  'a array ->
  int ->
  (('a -> 'a -> int)[@bs]) ->
  int

val intersect :
  'a array ->
  int ->
  int ->
  'a array ->
  int ->
  int ->
  'a array ->
  int ->
  ('a -> 'a -> int) ->
  int
(** [union src src1ofs src1len src2 src2ofs src2len dst dstofs cmp]
  return the [offset] in the output array
*)

val diffU :
  'a array ->
  int ->
  int ->
  'a array ->
  int ->
  int ->
  'a array ->
  int ->
  (('a -> 'a -> int)[@bs]) ->
  int

val diff :
  'a array ->
  int ->
  int ->
  'a array ->
  int ->
  int ->
  'a array ->
  int ->
  ('a -> 'a -> int) ->
  int

(**/**)
