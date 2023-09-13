type t;

[@mel.get] external valueMissing: t => bool = "valueMissing";
[@mel.get] external typeMismatch: t => bool = "typeMismatch";
[@mel.get] external patternMismatch: t => bool = "patternMismatch";
[@mel.get] external tooLong: t => bool = "tooLong";
[@mel.get] external tooShort: t => bool = "tooShort";
[@mel.get] external rangeUnderflow: t => bool = "rangeUnderflow";
[@mel.get] external rangeOverflow: t => bool = "rangeOverflow";
[@mel.get] external stepMismatch: t => bool = "stepMismatch";
[@mel.get] external badInput: t => bool = "badInput";
[@mel.get] external customError: t => bool = "customError";
[@mel.get] external valid: t => bool = "valid";
