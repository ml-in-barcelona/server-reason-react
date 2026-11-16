  $ ../ppx.sh --output re input.re
  let text = s =>
    (
      __jsx_value__001_ =>
        React.Writer({
          emit: (__buf, ~separators as _) => {
            Buffer.add_string(__buf, "<span>");
            ReactDOM.escape_to_buffer(__buf, __jsx_value__001_);
            Buffer.add_string(__buf, "</span>");
            ();
          },
          original: () =>
            React.createElement(
              "span",
              [],
              [React.string(__jsx_value__001_)],
            ),
        })
    )(
      s,
    );
  let string = s =>
    (
      __jsx_value__002_ =>
        React.Writer({
          emit: (__buf, ~separators as _) => {
            Buffer.add_string(__buf, "<b>");
            ReactDOM.escape_to_buffer(__buf, __jsx_value__002_);
            Buffer.add_string(__buf, "</b>");
            ();
          },
          original: () =>
            React.createElement("b", [], [React.string(__jsx_value__002_)]),
        })
    )(
      s,
    );
  let int = n =>
    (
      __jsx_value__003_ =>
        React.Writer({
          emit: (__buf, ~separators as _) => {
            Buffer.add_string(__buf, "<i>");
            ReactDOM.write_int_to_buffer(__buf, __jsx_value__003_);
            Buffer.add_string(__buf, "</i>");
            ();
          },
          original: () =>
            React.createElement("i", [], [React.int(__jsx_value__003_)]),
        })
    )(
      n,
    );
  let user_text_literal =
    (
      __jsx_value__004_ =>
        React.Writer({
          emit: (__buf, ~separators as __separators) => {
            Buffer.add_string(__buf, "<div>");
            {
              let (_: bool) =
                ReactDOM.write_element_to_buffer_internal(
                  __buf,
                  ~separators=__separators,
                  ~prev_text=false,
                  __jsx_value__004_,
                );
              ();
            };
            Buffer.add_string(__buf, "</div>");
            ();
          },
          original: () => React.createElement("div", [], [__jsx_value__004_]),
        })
    )(
      text("hi"),
    );
  let user_text_dynamic = x =>
    (
      __jsx_value__005_ =>
        React.Writer({
          emit: (__buf, ~separators as __separators) => {
            Buffer.add_string(__buf, "<div>");
            {
              let (_: bool) =
                ReactDOM.write_element_to_buffer_internal(
                  __buf,
                  ~separators=__separators,
                  ~prev_text=false,
                  __jsx_value__005_,
                );
              ();
            };
            Buffer.add_string(__buf, "</div>");
            ();
          },
          original: () => React.createElement("div", [], [__jsx_value__005_]),
        })
    )(
      text(x),
    );
  let user_string_literal =
    (
      __jsx_value__006_ =>
        React.Writer({
          emit: (__buf, ~separators as __separators) => {
            Buffer.add_string(__buf, "<div>");
            {
              let (_: bool) =
                ReactDOM.write_element_to_buffer_internal(
                  __buf,
                  ~separators=__separators,
                  ~prev_text=false,
                  __jsx_value__006_,
                );
              ();
            };
            Buffer.add_string(__buf, "</div>");
            ();
          },
          original: () => React.createElement("div", [], [__jsx_value__006_]),
        })
    )(
      string("hi"),
    );
  let user_string_dynamic = x =>
    (
      __jsx_value__007_ =>
        React.Writer({
          emit: (__buf, ~separators as __separators) => {
            Buffer.add_string(__buf, "<div>");
            {
              let (_: bool) =
                ReactDOM.write_element_to_buffer_internal(
                  __buf,
                  ~separators=__separators,
                  ~prev_text=false,
                  __jsx_value__007_,
                );
              ();
            };
            Buffer.add_string(__buf, "</div>");
            ();
          },
          original: () => React.createElement("div", [], [__jsx_value__007_]),
        })
    )(
      string(x),
    );
  let user_int_literal =
    (
      __jsx_value__008_ =>
        React.Writer({
          emit: (__buf, ~separators as __separators) => {
            Buffer.add_string(__buf, "<div>");
            {
              let (_: bool) =
                ReactDOM.write_element_to_buffer_internal(
                  __buf,
                  ~separators=__separators,
                  ~prev_text=false,
                  __jsx_value__008_,
                );
              ();
            };
            Buffer.add_string(__buf, "</div>");
            ();
          },
          original: () => React.createElement("div", [], [__jsx_value__008_]),
        })
    )(
      int(1),
    );
  let user_int_dynamic = n =>
    (
      __jsx_value__009_ =>
        React.Writer({
          emit: (__buf, ~separators as __separators) => {
            Buffer.add_string(__buf, "<div>");
            {
              let (_: bool) =
                ReactDOM.write_element_to_buffer_internal(
                  __buf,
                  ~separators=__separators,
                  ~prev_text=false,
                  __jsx_value__009_,
                );
              ();
            };
            Buffer.add_string(__buf, "</div>");
            ();
          },
          original: () => React.createElement("div", [], [__jsx_value__009_]),
        })
    )(
      int(n),
    );
  let react_string_literal =
    React.Static({
      prerendered: "<div>hi</div>",
      original: React.createElement("div", [], [React.string("hi")]),
    });
  let react_string_dynamic = x =>
    (
      __jsx_value__010_ =>
        React.Writer({
          emit: (__buf, ~separators as _) => {
            Buffer.add_string(__buf, "<div>");
            ReactDOM.escape_to_buffer(__buf, __jsx_value__010_);
            Buffer.add_string(__buf, "</div>");
            ();
          },
          original: () =>
            React.createElement("div", [], [React.string(__jsx_value__010_)]),
        })
    )(
      x,
    );
  let react_int_literal =
    React.Static({
      prerendered: "<div>1</div>",
      original: React.createElement("div", [], [React.int(1)]),
    });
  let react_int_dynamic = n =>
    (
      __jsx_value__011_ =>
        React.Writer({
          emit: (__buf, ~separators as _) => {
            Buffer.add_string(__buf, "<div>");
            ReactDOM.write_int_to_buffer(__buf, __jsx_value__011_);
            Buffer.add_string(__buf, "</div>");
            ();
          },
          original: () =>
            React.createElement("div", [], [React.int(__jsx_value__011_)]),
        })
    )(
      n,
    );
