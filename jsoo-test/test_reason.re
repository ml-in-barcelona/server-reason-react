open Webtest.Suite;
module Js = Js_of_ocaml.Js;
module Dom_html = Js_of_ocaml.Dom_html;
module Dom = Js_of_ocaml.Dom;
open React.Dom.Dsl;
open Html;
let act = ReactDOMTestUtils.act;

let jsdom = Jsdom.make(~html="<!doctype html><html><body></body></html>");

let doc = jsdom |> Jsdom.window |> Jsdom.document;

// React.js reads from global `window` and `document`
let () = Js.Unsafe.global##.document := doc;

let () = Js.Unsafe.global##.window := jsdom |> Jsdom.window;

let printTextContent = container =>
  print_endline(
    Js.to_string(
      Js.Opt.get(container##.textContent, () => Js.string("missing")),
    ),
  );
let printInnerHTML = (container: Js.t(Dom_html.divElement)) =>
  print_endline(Js.to_string(container##.innerHTML));

let withContainer = f => {
  let container = Dom_html.createDiv(doc);
  Dom.appendChild(doc##.body, container);
  let result = f(container);
  ignore(React.Dom.unmount_component_at_node(container));
  Dom.removeChild(doc##.body, container);
  result;
};

let testDom = () => {
  doc##.title := Js.string("Testing");
  let p = Dom_html.createP(doc);
  p##.innerHTML := Js.string("Loading graph...");
  Dom.appendChild(doc##.body, p);
  assert_equal(doc##.title, Js.string("Testing"));
  assert_equal(p##.innerHTML, Js.string("Loading graph..."));
};

let testReact = () =>
  withContainer(c => {
    act(() => {
      React.Dom.render(
        <div> {"Hello world!" |> React.string} </div>,
        Dom_html.element(c),
      )
    });
    assert_equal(c##.textContent, Js.Opt.return(Js.string("Hello world!")));
  });

let testKeys = () =>
  withContainer(c => {
    act(() => {
      React.Dom.render(
        <div>
          ...{List.map(
            str => <div key=str> {str |> React.string} </div>,
            ["a", "b"],
          )}
        </div>,
        Dom_html.element(c),
      )
    });
    assert_equal(
      c##.innerHTML,
      Js.string("<div><div>a</div><div>b</div></div>"),
    );
  });

let testOptionalPropsUppercase = () => {
  module OptProps = {
    [@react.component]
    let make = (~name="joe") => {
      <div> {Printf.sprintf("`name` is %s", name) |> React.string} </div>;
    };
  };
  withContainer(c => {
    act(() => {React.Dom.render(<OptProps />, Dom_html.element(c))});
    assert_equal(
      c##.textContent,
      Js.Opt.return(Js.string("`name` is joe")),
    );
    act(() => {
      React.Dom.render(<OptProps name="jane" />, Dom_html.element(c))
    });
    assert_equal(
      c##.textContent,
      Js.Opt.return(Js.string("`name` is jane")),
    );
  });
};

let testOptionalPropsLowercase = () => {
  module LinkWithMaybeHref = {
    [@react.component]
    let make = (~href) => <a ?href />;
  };

  withContainer(c => {
    act(() =>
      React.Dom.render(<LinkWithMaybeHref href=None />, Dom_html.element(c))
    );
    assert_equal(c##.innerHTML, Js.string("<a></a>"));
    act(() =>
      React.Dom.render(
        <LinkWithMaybeHref href={Some("https://google.es")} />,
        Dom_html.element(c),
      )
    );
    assert_equal(
      c##.innerHTML,
      Js.string({|<a href="https://google.es"></a>|}),
    );
  });
};

let testContext = () => {
  module DummyContext = {
    let context = React.Context.make("foo");
    module Provider = {
      let make = React.Context.Provider.make(context);
    };
    module Consumer = {
      [@react.component]
      let make = () => {
        let value = React.use_context(context);
        <div> {value |> React.string} </div>;
      };
    };
  };
  withContainer(c => {
    act(() => {
      React.Dom.render(
        <DummyContext.Provider value="bar">
          <DummyContext.Consumer />
        </DummyContext.Provider>,
        Dom_html.element(c),
      )
    });
    assert_equal(c##.textContent, Js.Opt.return(Js.string("bar")));
  });
};

let testUseCallback1 = () => {
  module UseCallback = {
    [@react.component]
    let make = (~a) => {
      let ((count, str), setCountStr) =
        React.use_state(() => (0, "init and"));
      let f = React.use_callback1(input => {input ++ " " ++ a ++ " and"}, a);
      React.use_effect1(
        () => {
          setCountStr(((count, str)) => (count + 1, f(str)));
          None;
        },
        f,
      );
      <div>
        {Printf.sprintf("`count` is %d, `str` is %s", count, str)
         |> React.string}
      </div>;
    };
  };
  withContainer(c => {
    let fooString = "foo"; /* strings in OCaml are boxed, and we want to keep same reference across renders */
    act(() => {
      React.Dom.render(<UseCallback a=fooString />, Dom_html.element(c))
    });
    assert_equal(
      c##.textContent,
      Js.Opt.return(Js.string("`count` is 1, `str` is init and foo and")),
    );
    act(() => {
      React.Dom.render(<UseCallback a=fooString />, Dom_html.element(c))
    });
    assert_equal(
      c##.textContent,
      Js.Opt.return(Js.string("`count` is 1, `str` is init and foo and")),
    );
    act(() => {
      React.Dom.render(<UseCallback a="bar" />, Dom_html.element(c))
    });
    assert_equal(
      c##.textContent,
      Js.Opt.return(
        Js.string("`count` is 2, `str` is init and foo and bar and"),
      ),
    );
  });
};

let testUseCallback4 = () => {
  module UseCallback = {
    [@react.component]
    let make = (~a, ~b, ~d, ~e) => {
      let ((count, str), setCountStr) = React.use_state(() => (0, "init"));
      let f =
        React.use_callback4(
          _input => {
            Printf.sprintf(
              "a: %s, b: %d, d: [%d], e: [|%d|]",
              a,
              b,
              List.nth(d, 0),
              e[0],
            )
          },
          (a, b, d, e),
        );
      React.use_effect1(
        () => {
          setCountStr(((count, str)) => (count + 1, f(str)));
          None;
        },
        f,
      );
      <div>
        {Printf.sprintf("`count` is %d, `str` is %s", count, str)
         |> React.string}
      </div>;
    };
  };
  withContainer(c => {
    let a = "foo"; /* strings in OCaml are boxed, and we want to keep same reference across renders */
    let a2 = "bar"; /* strings in OCaml are boxed, and we want to keep same reference across renders */
    let b = 2;
    let d = [3];
    let e = [|4|];
    act(() => {
      React.Dom.render(<UseCallback a b d e />, Dom_html.element(c))
    });
    assert_equal(
      c##.textContent,
      Js.Opt.return(
        Js.string("`count` is 1, `str` is a: foo, b: 2, d: [3], e: [|4|]"),
      ),
    );
    act(() => {
      React.Dom.render(<UseCallback a b d e />, Dom_html.element(c))
    });
    assert_equal(
      c##.textContent,
      Js.Opt.return(
        Js.string("`count` is 1, `str` is a: foo, b: 2, d: [3], e: [|4|]"),
      ),
    );
    act(() => {
      React.Dom.render(<UseCallback a=a2 b d e />, Dom_html.element(c))
    });
    assert_equal(
      c##.textContent,
      Js.Opt.return(
        Js.string("`count` is 2, `str` is a: bar, b: 2, d: [3], e: [|4|]"),
      ),
    );
    act(() => {
      React.Dom.render(<UseCallback a=a2 b d e />, Dom_html.element(c))
    });
    assert_equal(
      c##.textContent,
      Js.Opt.return(
        Js.string("`count` is 2, `str` is a: bar, b: 2, d: [3], e: [|4|]"),
      ),
    );
    act(() => {
      React.Dom.render(<UseCallback a=a2 b=3 d e />, Dom_html.element(c))
    });
    assert_equal(
      c##.textContent,
      Js.Opt.return(
        Js.string("`count` is 3, `str` is a: bar, b: 3, d: [3], e: [|4|]"),
      ),
    );
    act(() => {
      React.Dom.render(
        <UseCallback a=a2 b=3 d=[4] e />,
        Dom_html.element(c),
      )
    });
    assert_equal(
      c##.textContent,
      Js.Opt.return(
        Js.string("`count` is 4, `str` is a: bar, b: 3, d: [4], e: [|4|]"),
      ),
    );
  });
};

let testUseState = () => {
  module DummyStateComponent = {
    [@react.component]
    let make = (~initialValue=0, ()) => {
      let (counter, setCounter) = React.use_state(() => initialValue);
      <>
        <div className="value"> {React.int(counter)} </div>
        <button onClick={_ => setCounter(counter => counter + 1)}>
          {React.string("Increment")}
        </button>
        <button onClick={_ => setCounter(counter => counter - 1)}>
          {React.string("Decrement")}
        </button>
      </>;
    };
  };
  withContainer(c => {
    open ReactDOMTestUtils;
    act(() => {
      React.Dom.render(<DummyStateComponent />, Dom_html.element(c))
    });
    assert_equal(
      c##.innerHTML,
      Js.string(
        "<div class=\"value\">0</div><button>Increment</button><button>Decrement</button>",
      ),
    );
    let button =
      DOM.findBySelectorAndPartialTextContent(
        unsafe_to_element(c),
        "button",
        "Increment",
      );
    act(() => {Simulate.click(button)});
    assert_equal(
      c##.innerHTML,
      Js.string(
        "<div class=\"value\">1</div><button>Increment</button><button>Decrement</button>",
      ),
    );
    let button =
      DOM.findBySelectorAndPartialTextContent(
        unsafe_to_element(c),
        "button",
        "Decrement",
      );
    act(() => {Simulate.click(button)});
    assert_equal(
      c##.innerHTML,
      Js.string(
        "<div class=\"value\">0</div><button>Increment</button><button>Decrement</button>",
      ),
    );
  });
};

let testUseStateUpdaterReference = () => {
  module UseState = {
    let prevSetCount = ref(None);
    [@react.component]
    let make = () => {
      let (_count, setCount) = React.use_state(() => 0);
      let equal =
        switch (setCount, prevSetCount^) {
        | (r1, Some(r2)) when r1 === r2 => "true"
        | _ => "false"
        };
      prevSetCount := Some(setCount);
      <div> {equal |> React.string} </div>;
    };
  };
  withContainer(c => {
    act(() => {React.Dom.render(<UseState />, Dom_html.element(c))});
    assert_equal(c##.textContent, Js.Opt.return(Js.string("false")));
    act(() => {React.Dom.render(<UseState />, Dom_html.element(c))});
    assert_equal(c##.textContent, Js.Opt.return(Js.string("true")));
  });
};

let testUseReducer = () => {
  module DummyReducerComponent = {
    type action =
      | Increment
      | Decrement;
    [@react.component]
    let make = (~initialValue=0, ()) => {
      let (state, send) =
        React.use_reducer(
          ~init=() => initialValue,
          (state, action) =>
            switch (action) {
            | Increment => state + 1
            | Decrement => state - 1
            },
        );

      <>
        <div className="value"> {React.int(state)} </div>
        <button onClick={_ => send(Increment)}>
          {React.string("Increment")}
        </button>
        <button onClick={_ => send(Decrement)}>
          {React.string("Decrement")}
        </button>
      </>;
    };
  };
  withContainer(c => {
    open ReactDOMTestUtils;
    act(() => {
      React.Dom.render(<DummyReducerComponent />, Dom_html.element(c))
    });
    assert_equal(
      c##.innerHTML,
      Js.string(
        "<div class=\"value\">0</div><button>Increment</button><button>Decrement</button>",
      ),
    );
    let button =
      DOM.findBySelectorAndPartialTextContent(
        unsafe_to_element(c),
        "button",
        "Increment",
      );
    act(() => {Simulate.click(button)});
    assert_equal(
      c##.innerHTML,
      Js.string(
        "<div class=\"value\">1</div><button>Increment</button><button>Decrement</button>",
      ),
    );
    let button =
      DOM.findBySelectorAndPartialTextContent(
        unsafe_to_element(c),
        "button",
        "Decrement",
      );
    act(() => {Simulate.click(button)});
    assert_equal(
      c##.innerHTML,
      Js.string(
        "<div class=\"value\">0</div><button>Increment</button><button>Decrement</button>",
      ),
    );
  });
};

let testUseReducerWithMapState = () => {
  module DummyReducerWithMapStateComponent = {
    type action =
      | Increment
      | Decrement;
    [@react.component]
    let make = (~initialValue=0, ()) => {
      let (state, send) =
        React.use_reducer(
          ~init=() => initialValue + 1,
          (state, action) =>
            switch (action) {
            | Increment => state + 1
            | Decrement => state - 1
            },
        );

      <>
        <div className="value"> {React.int(state)} </div>
        <button onClick={_ => send(Increment)}>
          {React.string("Increment")}
        </button>
        <button onClick={_ => send(Decrement)}>
          {React.string("Decrement")}
        </button>
      </>;
    };
  };
  withContainer(c => {
    open ReactDOMTestUtils;
    act(() => {
      React.Dom.render(
        <DummyReducerWithMapStateComponent />,
        Dom_html.element(c),
      )
    });
    assert_equal(
      c##.innerHTML,
      Js.string(
        "<div class=\"value\">1</div><button>Increment</button><button>Decrement</button>",
      ),
    );
    let button =
      DOM.findBySelectorAndPartialTextContent(
        unsafe_to_element(c),
        "button",
        "Increment",
      );
    act(() => {Simulate.click(button)});
    assert_equal(
      c##.innerHTML,
      Js.string(
        "<div class=\"value\">2</div><button>Increment</button><button>Decrement</button>",
      ),
    );
    let button =
      DOM.findBySelectorAndPartialTextContent(
        unsafe_to_element(c),
        "button",
        "Decrement",
      );
    act(() => {Simulate.click(button)});
    assert_equal(
      c##.innerHTML,
      Js.string(
        "<div class=\"value\">1</div><button>Increment</button><button>Decrement</button>",
      ),
    );
  });
};

let testUseReducerDispatchReference = () => {
  module UseReducer = {
    let prevDispatch = ref(None);
    [@react.component]
    let make = () => {
      let (_, dispatch) = React.use_reducer(~init=() => 2, (_, _) => 2);
      let equal =
        switch (dispatch, prevDispatch^) {
        | (r1, Some(r2)) when r1 === r2 => "true"
        | _ => "false"
        };
      prevDispatch := Some(dispatch);
      <div> {equal |> React.string} </div>;
    };
  };
  withContainer(c => {
    act(() => {React.Dom.render(<UseReducer />, Dom_html.element(c))});
    assert_equal(c##.textContent, Js.Opt.return(Js.string("false")));
    act(() => {React.Dom.render(<UseReducer />, Dom_html.element(c))});
    assert_equal(c##.textContent, Js.Opt.return(Js.string("true")));
  });
};

let testUseMemo1 = () => {
  module UseMemo = {
    [@react.component]
    let make = (~a) => {
      let (count, setCount) = React.use_state(() => 0);
      let result = React.use_memo1(() => {a ++ "2"}, a);
      React.use_effect1(
        () => {
          setCount(count => count + 1);
          None;
        },
        result,
      );
      <div> {Printf.sprintf("`count` is %d", count) |> React.string} </div>;
    };
  };
  withContainer(c => {
    let fooString = "foo"; /* strings in OCaml are boxed, and we want to keep same reference across renders */
    act(() => {
      React.Dom.render(<UseMemo a=fooString />, Dom_html.element(c))
    });
    assert_equal(c##.textContent, Js.Opt.return(Js.string("`count` is 1")));
    act(() => {
      React.Dom.render(<UseMemo a=fooString />, Dom_html.element(c))
    });
    assert_equal(c##.textContent, Js.Opt.return(Js.string("`count` is 1")));
    act(() => {React.Dom.render(<UseMemo a="foo" />, Dom_html.element(c))});
    assert_equal(c##.textContent, Js.Opt.return(Js.string("`count` is 2")));
  });
};

let testMemo = () => {
  let numRenders = ref(0);
  module Memoized = {
    [@react.component]
    let make =
      React.memo((~a) => {
        numRenders := numRenders^ + 1;
        <div>
          {Printf.sprintf("`a` is %s, `numRenders` is %d", a, numRenders^)
           |> React.string}
        </div>;
      });
  };
  withContainer(c => {
    let fooString = "foo"; /* strings in OCaml are boxed, and we want to keep same reference across renders */
    act(() => {
      React.Dom.render(<Memoized a=fooString />, Dom_html.element(c))
    });
    assert_equal(
      c##.textContent,
      Js.Opt.return(Js.string("`a` is foo, `numRenders` is 1")),
    );
    act(() => {
      React.Dom.render(<Memoized a=fooString />, Dom_html.element(c))
    });
    assert_equal(
      c##.textContent,
      Js.Opt.return(Js.string("`a` is foo, `numRenders` is 1")),
    );
    act(() => {React.Dom.render(<Memoized a="bar" />, Dom_html.element(c))});
    assert_equal(
      c##.textContent,
      Js.Opt.return(Js.string("`a` is bar, `numRenders` is 2")),
    );
  });
};

let testMemoCustomCompareProps = () => {
  let numRenders = ref(0);
  module Memoized = {
    [@react.component]
    let make =
      React.memo(
        ~compare=(_prevPros, _nextProps) => true,
        (~a) => {
          numRenders := numRenders^ + 1;
          <div>
            {Printf.sprintf("`a` is %s, `numRenders` is %d", a, numRenders^)
             |> React.string}
          </div>;
        },
      );
  };
  withContainer(c => {
    let fooString = "foo"; /* strings in OCaml are boxed, and we want to keep same reference across renders */
    act(() => {
      React.Dom.render(<Memoized a=fooString />, Dom_html.element(c))
    });
    assert_equal(
      c##.textContent,
      Js.Opt.return(Js.string("`a` is foo, `numRenders` is 1")),
    );
    act(() => {
      React.Dom.render(<Memoized a=fooString />, Dom_html.element(c))
    });
    assert_equal(
      c##.textContent,
      Js.Opt.return(Js.string("`a` is foo, `numRenders` is 1")),
    );
    act(() => {React.Dom.render(<Memoized a="bar" />, Dom_html.element(c))});
    assert_equal(
      c##.textContent,
      Js.Opt.return(Js.string("`a` is foo, `numRenders` is 1")),
    );
  });
};

let testCreateRef = () => {
  let reactRef = React.Ref.make();
  assert_equal(React.Ref.current(reactRef), Js_of_ocaml.Js.null);
  React.Ref.set_current(reactRef, Js_of_ocaml.Js.Opt.return(1));
  assert_equal(React.Ref.current(reactRef), Js_of_ocaml.Js.Opt.return(1));
};

let testForwardRef = () => {
  module FancyButton = {
    [@react.component]
    let make =
      React.Dom.forward_ref((~children, ref_) => {
        <button ref_ className="FancyButton"> ...children </button>
      });
  };

  withContainer(c => {
    let count = ref(0);
    let buttonRef =
      React.Dom.Ref.callback_dom_ref(_ref => {count := count^ + 1});
    act(() => {
      React.Dom.render(
        <FancyButton ref=buttonRef> <div /> </FancyButton>,
        Dom_html.element(c),
      )
    });
    assert_equal(count^, 1);
  });
};

let testUseRef = () => {
  module DummyComponentWithRefAndEffect = {
    [@react.component]
    let make = (~cb, ()) => {
      let myRef = React.use_ref(1);
      React.use_effect_once(() => {
        React.Ref.(set_current(myRef, current(myRef) + 1));
        cb(myRef);
        None;
      });
      <div />;
    };
  };
  withContainer(c => {
    let myRef = ref(None);
    let cb = reactRef => {
      myRef := Some(reactRef);
    };

    act(() => {
      React.Dom.render(
        <DummyComponentWithRefAndEffect cb />,
        Dom_html.element(c),
      )
    });
    assert_equal(
      myRef.contents |> Option.map(item => {item |> React.Ref.current}),
      Some(2),
    );
  });
};

let testChildrenMapWithIndex = () => {
  module DummyComponentThatMapsChildren = {
    [@react.component]
    let make = (~children, ()) => {
      <div>
        {React.Children.mapi(children, (element, index) => {
           React.clone_element(
             element,
             Js_of_ocaml.Js.Unsafe.(
               obj([|
                 ("key", inject(index)),
                 ("data-index", inject(index)),
               |])
             ),
           )
         })}
      </div>;
    };
  };
  withContainer(c => {
    act(() => {
      React.Dom.render(
        <DummyComponentThatMapsChildren>
          <div> {React.int(1)} </div>
          <div> {React.int(2)} </div>
          <div> {React.int(3)} </div>
        </DummyComponentThatMapsChildren>,
        Dom_html.element(c),
      )
    });
    assert_equal(
      c##.innerHTML,
      Js.string(
        "<div><div data-index=\"0\">1</div><div data-index=\"1\">2</div><div data-index=\"2\">3</div></div>",
      ),
    );
  });
};

let testFragmentModule = () => {
  withContainer(c => {
    act(() => {
      React.Dom.render(
        <React.Fragment>
          <div> {React.string("Hello")} </div>
          <div> {React.string("World")} </div>
        </React.Fragment>,
        Dom_html.element(c),
      )
    });
    assert_equal(
      c##.innerHTML,
      Js.string("<div>Hello</div><div>World</div>"),
    );
  });
};

let testFragmentSyntax = () => {
  withContainer(c => {
    act(() => {
      React.Dom.render(
        <>
          <div> {React.string("Hello")} </div>
          <div> {React.string("World")} </div>
        </>,
        Dom_html.element(c),
      )
    });
    assert_equal(
      c##.innerHTML,
      Js.string("<div>Hello</div><div>World</div>"),
    );
  });
};

let testNonListChildren = () => {
  module NonListChildrenComponent = {
    [@react.component]
    let make = (~children as (first, second), ()) => {
      <div> first second </div>;
    };
  };
  withContainer(c => {
    act(() => {
      React.Dom.render(
        <NonListChildrenComponent>
          ...(<div> {React.int(1)} </div>, <div> {React.int(3)} </div>)
        </NonListChildrenComponent>,
        Dom_html.element(c),
      )
    });
    assert_equal(
      c##.innerHTML,
      Js.string("<div><div>1</div><div>3</div></div>"),
    );
  });
};

let testDangerouslySetInnerHTML = () => {
  withContainer(c => {
    act(() => {
      React.Dom.render(
        <div
          dangerouslySetInnerHTML={React.Dom.SafeString.make_unchecked(
            "<lol></lol>",
          )}
        />,
        Dom_html.element(c),
      )
    });
    assert_equal(c##.innerHTML, Js.string("<div><lol></lol></div>"));
  });
};

let testExternals = () => {
  module JsComp = {
    [@react.component]
    external make: (~name: Js.t(Js.js_string)) => React.element =
      {|require("./external").Greeting|};
  };
  withContainer(c => {
    act(() => {
      React.Dom.render(
        <JsComp name={Js.string("John")} />,
        Dom_html.element(c),
      )
    });
    assert_equal(c##.innerHTML, Js.string("<span>Hey John</span>"));
  });
};

let testExternalChildren = () => {
  module JsComp = {
    [@react.component]
    external make: (~children: list(React.element)) => React.element =
      {|require("./external").GreetingChildren|};
  };
  withContainer(c => {
    act(() => {
      React.Dom.render(
        <JsComp> <em key="one"> {React.string("John")} </em> </JsComp>,
        Dom_html.element(c),
      )
    });
    assert_equal(c##.innerHTML, Js.string("<span>Hey <em>John</em></span>"));
  });
};

let testExternalNonFunction = () => {
  module JsComp = {
    [@react.component]
    external make: (~name: string) => React.element =
      {|require("./external").NonFunctionGreeting|};
  };
  withContainer(c => {
    act(() => {
      React.Dom.render(<JsComp name="John" />, Dom_html.element(c))
    });
    assert_equal(c##.innerHTML, Js.string("<span>Hey John</span>"));
  });
};

let testExternalOptionalArg = () => {
  module JsComp = {
    [@react.component]
    external make: (~name: Js.t(Js.js_string)=?) => React.element =
      {|require("./external").Greeting|};
  };
  withContainer(c => {
    act(() => {
      React.Dom.render(
        <JsComp name={Js.string("John")} />,
        Dom_html.element(c),
      )
    });
    assert_equal(c##.innerHTML, Js.string("<span>Hey John</span>"));
  });
};

let testExternalStringArg = () => {
  module JsComp = {
    [@react.component]
    external make: (~name: string) => React.element =
      {|require("./external").Greeting|};
  };
  withContainer(c => {
    act(() => {
      React.Dom.render(<JsComp name="John" />, Dom_html.element(c))
    });
    assert_equal(c##.innerHTML, Js.string("<span>Hey John</span>"));
  });
};

let testExternalOptionalStringArg = () => {
  module JsComp = {
    [@react.component]
    external make: (~name: string=?) => React.element =
      {|require("./external").Greeting|};
  };
  withContainer(c => {
    act(() => {
      React.Dom.render(<JsComp name="John" />, Dom_html.element(c))
    });
    assert_equal(c##.innerHTML, Js.string("<span>Hey John</span>"));
  });
};

let testExternalBoolArg = () => {
  module JsComp = {
    [@react.component]
    external make: (~name: string, ~strong: bool) => React.element =
      {|require("./external").Greeting|};
  };
  withContainer(c => {
    act(() => {
      React.Dom.render(
        <JsComp name="John" strong=false />,
        Dom_html.element(c),
      )
    });
    assert_equal(c##.innerHTML, Js.string("<span>Hey John</span>"));
  });
};

let testExternalOptionalBoolArg = () => {
  module JsComp = {
    [@react.component]
    external make: (~name: string=?, ~strong: bool=?) => React.element =
      {|require("./external").Greeting|};
  };
  withContainer(c => {
    act(() => {
      React.Dom.render(
        <JsComp name="John" strong=true />,
        Dom_html.element(c),
      )
    });
    assert_equal(
      c##.innerHTML,
      Js.string("<span>Hey <strong>John</strong></span>"),
    );
  });
};

let testExternalArrayArg = () => {
  module JsComp = {
    [@react.component]
    external make: (~children: array(React.element)) => React.element =
      {|require("./external").GreetingChildren|};
  };
  withContainer(c => {
    act(() => {
      React.Dom.render(
        <JsComp>
          ...[|<em key="one"> {React.string("John")} </em>|]
        </JsComp>,
        Dom_html.element(c),
      )
    });
    assert_equal(c##.innerHTML, Js.string("<span>Hey <em>John</em></span>"));
  });
};

let testExternalOptionalArrayArg = () => {
  module JsComp = {
    [@react.component]
    external make: (~children: array(React.element)=?) => React.element =
      {|require("./external").GreetingChildren|};
  };
  withContainer(c => {
    act(() => {
      React.Dom.render(
        <JsComp>
          ...[|<em key="one"> {React.string("John")} </em>|]
        </JsComp>,
        Dom_html.element(c),
      )
    });
    assert_equal(c##.innerHTML, Js.string("<span>Hey <em>John</em></span>"));
  });
};

let testExternalSecondOrderArgConversion = () => {
  module JsComp = {
    [@react.component]
    external make: (~names: array(string)=?) => React.element =
      {|require("./external").Greetings|};
  };
  withContainer(c => {
    act(() => {
      React.Dom.render(
        <JsComp names=[|"John", "Jerry", "Fred"|] />,
        Dom_html.element(c),
      )
    });
    assert_equal(
      c##.innerHTML,
      Js.string("<span>Hey John, Jerry, Fred</span>"),
    );
  });
};

let testAliasedChildren = () => {
  module AliasedChildrenComponent = {
    [@react.component]
    let make = (~children as kids, ()) => {
      <div> ...kids </div>;
    };
  };
  withContainer(c => {
    act(() => {
      React.Dom.render(
        <AliasedChildrenComponent>
          <div> {React.int(1)} </div>
          <div> {React.int(3)} </div>
        </AliasedChildrenComponent>,
        Dom_html.element(c),
      )
    });
    assert_equal(
      c##.innerHTML,
      Js.string("<div><div>1</div><div>3</div></div>"),
    );
  });
};

let testWithId = () => {
  module WithTestId = {
    [@react.component]
    let make = (~id, ~children, ()) =>
      React.Children.map(children, child =>
        React.clone_element(
          child,
          Js.Unsafe.obj([|
            ("data-testid", Js.Unsafe.inject(Js.string(id))),
          |]),
        )
      );
  };
  withContainer(c => {
    act(() => {
      React.Dom.render(
        WithTestId.make(~id="feed-toggle", ~children=[<div />], ()),
        Dom_html.element(c),
      )
    });
    assert_equal(
      c##.innerHTML,
      Js.string("<div data-testid=\"feed-toggle\"></div>"),
    );
  });
};

let testPropMaybeNone = () =>
  withContainer(c => {
    act(() =>
      React.Dom.render(<div className=?None />, Dom_html.element(c))
    );
    assert_equal(c##.innerHTML, Js.string("<div></div>"));
  });

let testPropMaybeSome = () =>
  withContainer(c => {
    act(() =>
      React.Dom.render(
        <div className=?{Some("foo")} />,
        Dom_html.element(c),
      )
    );
    assert_equal(c##.innerHTML, Js.string("<div class=\"foo\"></div>"));
  });

let testPropCustomString = () =>
  withContainer(c => {
    module Prop = {
      let foo = Prop.string("foo");
    };
    act(() => React.Dom.render(<div foo="bar" />, Dom_html.element(c)));
    assert_equal(c##.innerHTML, Js.string("<div foo=\"bar\"></div>"));
  });

let testPropCustomBool = () =>
  withContainer(c => {
    module Prop = {
      let disabled = Prop.bool("disabled");
    };
    act(() => React.Dom.render(<div disabled=true />, Dom_html.element(c)));
    assert_equal(c##.innerHTML, Js.string("<div disabled=\"\"></div>"));
  });

let testPropCustomInt = () =>
  withContainer(c => {
    module Prop = {
      let foo = Prop.int("foo");
    };
    act(() => React.Dom.render(<div foo=42 />, Dom_html.element(c)));
    assert_equal(c##.innerHTML, Js.string("<div foo=\"42\"></div>"));
  });

let testPropCustomFloat = () =>
  withContainer(c => {
    module Prop = {
      let foo = Prop.float_("foo");
    };
    act(() => React.Dom.render(<div foo=42.5 />, Dom_html.element(c)));
    assert_equal(c##.innerHTML, Js.string("<div foo=\"42.5\"></div>"));
  });

let testPropCustomAny = () =>
  withContainer(c => {
    module Prop = {
      let foo: Js.t(Js.js_array(string)) => Prop.t = Prop.any("foo");
    };
    act(() =>
      React.Dom.render(
        <div foo={Js.array([|"bar", "baz"|])} />,
        Dom_html.element(c),
      )
    );
    assert_equal(c##.innerHTML, Js.string("<div foo=\"bar,baz\"></div>"));
  });

let testCustomElement = () =>
  withContainer(c => {
    let cool_element = h("cool-element");
    let chill = h("chill");
    module Prop = {
      let coolness = Prop.string("coolness");
      let data_out = Prop.bool("data-out");
    };
    act(() =>
      React.Dom.render(
        <cool_element coolness="max"> <chill data_out=true /> </cool_element>,
        Dom_html.element(c),
      )
    );
    assert_equal(
      c##.innerHTML,
      Js.string(
        "<cool-element coolness=\"max\"><chill data-out=\"true\"></chill></cool-element>",
      ),
    );
  });

let testSvg = () =>
  withContainer(c => {
    open Svg;
    module Prop = {
      include Html.Prop;
      include Svg.Prop;
    };
    act(() =>
      React.Dom.render(
        <svg width="100" height="100">
          <circle
            cx="50"
            cy="50"
            strokeWidth="2"
            stroke="magenta"
            fill="pink"
          />
        </svg>,
        Dom_html.element(c),
      )
    );
    assert_equal(
      c##.innerHTML,
      Js.string(
        "<svg width=\"100\" height=\"100\"><circle cx=\"50\" cy=\"50\" stroke-width=\"2\" stroke=\"magenta\" fill=\"pink\"></circle></svg>",
      ),
    );
  });

let basic =
  "basic"
  >::: [
    "testDom" >:: testDom,
    "testReact" >:: testReact,
    "testKey" >:: testKeys,
    "testOptionalPropsUppercase" >:: testOptionalPropsUppercase,
    "testOptionalPropsLowercase" >:: testOptionalPropsLowercase,
  ];

let context = "context" >::: ["testContext" >:: testContext];

let use_callback =
  "use_callback"
  >::: [
    "use_callback1" >:: testUseCallback1,
    "use_callback4" >:: testUseCallback4,
  ];

let use_state =
  "useState"
  >::: [
    "use_state" >:: testUseState,
    "useStateUpdaterReference" >:: testUseStateUpdaterReference,
  ];

let use_reducer =
  "use_reducer"
  >::: [
    "use_reducer" >:: testUseReducer,
    "use_reducer_with_map_state" >:: testUseReducerWithMapState,
    "use_reducer_dispatch_reference" >:: testUseReducerDispatchReference,
  ];

let memoization =
  "memo"
  >::: [
    "use_memo1" >:: testUseMemo1,
    "memo" >:: testMemo,
    "memoCustomCompareProps" >:: testMemoCustomCompareProps,
  ];

let refs =
  "refs"
  >::: [
    "create_ref" >:: testCreateRef,
    "forward_ref" >:: testForwardRef,
    "use_ref" >:: testUseRef,
  ];

let children =
  "children"
  >::: [
    "mapWithIndex" >:: testChildrenMapWithIndex,
    "nonListChildren" >:: testNonListChildren,
    "aliasedChildren" >:: testAliasedChildren,
    "testWithId" >:: testWithId,
  ];

let fragments =
  "fragments"
  >::: [
    "fragmentModule" >:: testFragmentModule,
    "fragmentSyntax" >:: testFragmentSyntax,
  ];

let dangerouslySetInnerHTML =
  "dangerouslySetInnerHTML" >::: ["basic" >:: testDangerouslySetInnerHTML];

let externals =
  "externals"
  >::: [
    "basic" >:: testExternals,
    "children" >:: testExternalChildren,
    "non-function" >:: testExternalNonFunction,
    "optional-arg" >:: testExternalOptionalArg,
    "string-arg" >:: testExternalStringArg,
    "optional-string-arg" >:: testExternalOptionalStringArg,
    "bool-arg" >:: testExternalBoolArg,
    "optional-bool-arg" >:: testExternalOptionalBoolArg,
    "array-arg" >:: testExternalArrayArg,
    "optional-array-arg" >:: testExternalOptionalArrayArg,
    "second-order-arg-conversion" >:: testExternalSecondOrderArgConversion,
  ];

let props =
  "props"
  >::: [
    "maybe-none" >:: testPropMaybeNone,
    "maybe-some" >:: testPropMaybeSome,
    "custom-string" >:: testPropCustomString,
    "custom-bool" >:: testPropCustomBool,
    "custom-int" >:: testPropCustomInt,
    "custom-float" >:: testPropCustomFloat,
    "custom-any" >:: testPropCustomAny,
  ];

let elements = "elements" >::: ["custom" >:: testCustomElement];

let svg = "svg" >::: ["basic" >:: testSvg];

let suite =
  "reason"
  >::: [
    basic,
    context,
    use_callback,
    use_state,
    use_reducer,
    memoization,
    refs,
    children,
    fragments,
    dangerouslySetInnerHTML,
    externals,
    props,
    elements,
    svg,
  ];
