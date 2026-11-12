  $ ../ppx.sh --output re input.re
  let text = s =>
    React.Writer({
      emit: (__buf, ~separators as _) => {
        Buffer.add_string(__buf, "<span>");
        ReactDOM.escape_to_buffer(__buf, s);
        Buffer.add_string(__buf, "</span>");
        ();
      },
      original: () => React.createElement("span", [], [React.string(s)]),
    });
  let string = s =>
    React.Writer({
      emit: (__buf, ~separators as _) => {
        Buffer.add_string(__buf, "<b>");
        ReactDOM.escape_to_buffer(__buf, s);
        Buffer.add_string(__buf, "</b>");
        ();
      },
      original: () => React.createElement("b", [], [React.string(s)]),
    });
  let int = n =>
    React.Writer({
      emit: (__buf, ~separators as _) => {
        Buffer.add_string(__buf, "<i>");
        ReactDOM.write_int_to_buffer(__buf, n);
        Buffer.add_string(__buf, "</i>");
        ();
      },
      original: () => React.createElement("i", [], [React.int(n)]),
    });
  let user_text_literal =
    React.Writer({
      emit: (__buf, ~separators as __separators) => {
        Buffer.add_string(__buf, "<div>");
        {
          let (_: bool) =
            ReactDOM.write_element_to_buffer_internal(
              __buf,
              ~separators=__separators,
              ~prev_text=false,
              text("hi"),
            );
          ();
        };
        Buffer.add_string(__buf, "</div>");
        ();
      },
      original: () => React.createElement("div", [], [text("hi")]),
    });
  let user_text_dynamic = x =>
    React.Writer({
      emit: (__buf, ~separators as __separators) => {
        Buffer.add_string(__buf, "<div>");
        {
          let (_: bool) =
            ReactDOM.write_element_to_buffer_internal(
              __buf,
              ~separators=__separators,
              ~prev_text=false,
              text(x),
            );
          ();
        };
        Buffer.add_string(__buf, "</div>");
        ();
      },
      original: () => React.createElement("div", [], [text(x)]),
    });
  let user_string_literal =
    React.Writer({
      emit: (__buf, ~separators as __separators) => {
        Buffer.add_string(__buf, "<div>");
        {
          let (_: bool) =
            ReactDOM.write_element_to_buffer_internal(
              __buf,
              ~separators=__separators,
              ~prev_text=false,
              string("hi"),
            );
          ();
        };
        Buffer.add_string(__buf, "</div>");
        ();
      },
      original: () => React.createElement("div", [], [string("hi")]),
    });
  let user_string_dynamic = x =>
    React.Writer({
      emit: (__buf, ~separators as __separators) => {
        Buffer.add_string(__buf, "<div>");
        {
          let (_: bool) =
            ReactDOM.write_element_to_buffer_internal(
              __buf,
              ~separators=__separators,
              ~prev_text=false,
              string(x),
            );
          ();
        };
        Buffer.add_string(__buf, "</div>");
        ();
      },
      original: () => React.createElement("div", [], [string(x)]),
    });
  let user_int_literal =
    React.Writer({
      emit: (__buf, ~separators as __separators) => {
        Buffer.add_string(__buf, "<div>");
        {
          let (_: bool) =
            ReactDOM.write_element_to_buffer_internal(
              __buf,
              ~separators=__separators,
              ~prev_text=false,
              int(1),
            );
          ();
        };
        Buffer.add_string(__buf, "</div>");
        ();
      },
      original: () => React.createElement("div", [], [int(1)]),
    });
  let user_int_dynamic = n =>
    React.Writer({
      emit: (__buf, ~separators as __separators) => {
        Buffer.add_string(__buf, "<div>");
        {
          let (_: bool) =
            ReactDOM.write_element_to_buffer_internal(
              __buf,
              ~separators=__separators,
              ~prev_text=false,
              int(n),
            );
          ();
        };
        Buffer.add_string(__buf, "</div>");
        ();
      },
      original: () => React.createElement("div", [], [int(n)]),
    });
  let react_string_literal =
    React.Static({
      prerendered: "<div>hi</div>",
      original: React.createElement("div", [], [React.string("hi")]),
    });
  let react_string_dynamic = x =>
    React.Writer({
      emit: (__buf, ~separators as _) => {
        Buffer.add_string(__buf, "<div>");
        ReactDOM.escape_to_buffer(__buf, x);
        Buffer.add_string(__buf, "</div>");
        ();
      },
      original: () => React.createElement("div", [], [React.string(x)]),
    });
  let react_int_literal =
    React.Static({
      prerendered: "<div>1</div>",
      original: React.createElement("div", [], [React.int(1)]),
    });
  let react_int_dynamic = n =>
    React.Writer({
      emit: (__buf, ~separators as _) => {
        Buffer.add_string(__buf, "<div>");
        ReactDOM.write_int_to_buffer(__buf, n);
        Buffer.add_string(__buf, "</div>");
        ();
      },
      original: () => React.createElement("div", [], [React.int(n)]),
    });
