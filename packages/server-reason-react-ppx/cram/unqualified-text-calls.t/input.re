let text = s => <span> {React.string(s)} </span>;
let string = s => <b> {React.string(s)} </b>;
let int = n => <i> {React.int(n)} </i>;

let user_text_literal = <div> {text("hi")} </div>;
let user_text_dynamic = x => <div> {text(x)} </div>;
let user_string_literal = <div> {string("hi")} </div>;
let user_string_dynamic = x => <div> {string(x)} </div>;
let user_int_literal = <div> {int(1)} </div>;
let user_int_dynamic = n => <div> {int(n)} </div>;

let react_string_literal = <div> {React.string("hi")} </div>;
let react_string_dynamic = x => <div> {React.string(x)} </div>;
let react_int_literal = <div> {React.int(1)} </div>;
let react_int_dynamic = n => <div> {React.int(n)} </div>;
