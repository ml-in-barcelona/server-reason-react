# native-react-dom

## References

- [ReactDOM tests](https://github.com/facebook/react/tree/main/packages/react-dom/src/__tests__)
- [react-wasm-dom](https://github.com/MaibornWolff/react-wasm-dom/)
- [jsoo-react/html.ml](https://github.com/ml-in-barcelona/jsoo-react/blob/main/ppx/html.ml)
- [StaticReactExperiment](https://github.com/reasonml/reason-react/compare/StaticReactExperiment)
- [TyXML](https://github.com/ocsigen/tyxml)
- [html.spec.whatwg](https://html.spec.whatwg.org/#attr-input-checked)

### Reconcilier

- [https://github.com/briskml/brisk](https://github.com/briskml/brisk)
- [https://github.com/briskml/brisk-reconciler](https://github.com/briskml/brisk-reconciler)
- [https://github.com/aidenybai/tiny-vdom](https://github.com/aidenybai/tiny-vdom)
- [https://reactjs.org/docs/reconciliation.html](https://reactjs.org/docs/reconciliation.html)
- [https://github.com/ms-jpq/Noact/blob/noact/src/noact.ts](https://github.com/ms-jpq/Noact/blob/noact/src/noact.ts)

## TODOs

- [x] Create a basic reason project with alcotest
- [x] Take a look at a [Rust implementation](https://github.com/MaibornWolff/react-wasm-dom)
- [x] Try to render a string given a React Tree
- [x] Define the React Tree using React.createElement (not the JSX ppx)
- [x] Allow attributes to be strings or booleans
- [x] Handle ReasonReact APIS. React.null, React.string, React.int
- [x] Handle fragments
- [x] Add data-reactroot="" to the root element
  - [x] Abstract renderToStringRec to handle internal state (ref is_root)
- [x] Handle value/defaultValue logic and similars
- [x] Handle [style attribute](https://github.com/MaibornWolff/react-wasm-dom/blob/main/src/__tests__/CSSPropertyOperations-test.jsx)
- [x] Implement React.Context (https://github.com/preactjs/preact-render-to-string/blob/master/test/context.test.js)
- [x] Does the order of attributes matter on cloneElement
- [x] React.cloneElement
  - How does it work for Fragments/Texts/Empty?
- [x] [Scape text with HTML](https://github.com/MaibornWolff/react-wasm-dom/blob/main/src/__tests__/escapeTextForBrowser-test.jsx) [entities](https://stackoverflow.com/questions/7381974/which-characters-need-to-be-escaped-in-html)
  - Should we handle every html entity?
- [x] Handle refs
- [x] Handle useContext
- [x] Run useState
- [x] Handle React.memoN
- [x] Handle React.useCallbackN
- [x] Ignore useEffect
- [x] Handle React dengerouslySetInnerHTML
- [x] Add test for hooks
- [ ] Implement renderToString
  - What are the differences?
- [ ] Handle unicode. Add Uutfs?
- [ ] Implement the rest of the React API
  - forwardRef

- [ ] (ppx) Transform attributes to JSX or do it in "runtime" ?
- [ ] (ppx) Handle synthetic events. Maybe it needs to be done in the ppx?
- [ ] (ppx) A way to trigger warnings for invalid attributes (probably better to do it in the ppx?)
  - https://github.com/facebook/react/blob/main/packages/react-dom/src/__tests__/ReactDOMTextarea-test.js
  - https://github.com/facebook/react/blob/main/packages/react-dom/src/__tests__/ReactDOMSelect-test.js

### Org
- [ ] Create interface for React and ReactDOMServe
- [ ] Create a module called "JSX" with all the HTML-like stuff: https://facebook.github.io/jsx/
- [ ] Add Pretty print with [fmt](https://github.com/dbuenzli/fmt)

## Questions

- How should we handle errors from: createElement or renderToString
- Suspense?
  "ReactDOMServer does not yet support Suspense - server/node_modules/react-dom/cjs/react-dom-server.node.development.js:3518"
<!-- - UseEffect should not run -->
- How does SSR handle component runtime?
  - If there is a function call such as setState inside a component?
  - Lists with keys, why SSR complains?
    - Because there's re-rendering inside SSR. Reconciling? Commiting? What?
- How difficult would be to support Server components?
- Do we need CSSOperations?
  - Add the units (adding `px` when matters and other cases from [CSSPropertyOperations-test](https://github.com/MaibornWolff/react-wasm-dom/blob/main/src/__tests__/CSSPropertyOperations-test.jsx))?
- Do we need to support React.Children API from reason-react? (https://github.com/reasonml/reason-react/blob/master/src/React.re#L58-L76)

### Not native-react-dom related
- How we are going to mock the DOM Api?
- Do we have any way to ensure bs.obj/similars to compile in native?
  - Probably only doing melange?
- Can we use Belly/Belt in native?
