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
- [https://github.com/aidenybai/tiny-vdom](https://github.com/aidenybai/tiny-vdom)
- [https://reactjs.org/docs/reconciliation.html](https://reactjs.org/docs/reconciliation.html)
- [https://github.com/briskml/brisk-reconciler](https://github.com/briskml/brisk-reconciler)
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
  - [ ] Do we need to add the units (adding `px` when matters and other cases from [CSSPropertyOperations-test](https://github.com/MaibornWolff/react-wasm-dom/blob/main/src/__tests__/CSSPropertyOperations-test.jsx)) ?
- [ ] Implement React.Context (https://github.com/preactjs/preact-render-to-string/blob/master/test/context.test.js)
- [ ] Handle React dengerouslySetInnerHtml
  - Not sure how it works, tbh
- [ ] React.cloneElement
  - It's implemented a silly cloneElement that doesn't clone attributes/childrens
  - Aside from attr/childs, how does it work?
  - How does it work for Fragments/Texts/Empty?
- [x] [Scape text with HTML](https://github.com/MaibornWolff/react-wasm-dom/blob/main/src/__tests__/escapeTextForBrowser-test.jsx) [entities](https://stackoverflow.com/questions/7381974/which-characters-need-to-be-escaped-in-html)
  - Should we handle every html entity?
- [ ] Handle refs
- [ ] Pretty print with [fmt](https://github.com/dbuenzli/fmt)
- [ ] Create a module called "JSX" with all the HTML-like stuff: https://facebook.github.io/jsx/
- [ ] React.Children API (https://github.com/reasonml/reason-react/blob/master/src/React.re#L58-L76)
- [ ] Handle React portals
- [ ] Handle emojis?
- [ ] Handle SVGs
- [ ] Handle textarea (value prop should be the children? Link? Can't find other cases)

## PPX TODO
- [ ] Transform attributes to JSX?
- [ ] Handle synthetic events. Maybe it needs to be done in the ppx?
- [ ] A way to trigger warnings for invalid attributes (probably better to do it in the ppx?)
  - https://github.com/facebook/react/blob/main/packages/react-dom/src/__tests__/ReactDOMTextarea-test.js
  - https://github.com/facebook/react/blob/main/packages/react-dom/src/__tests__/ReactDOMSelect-test.js
- [ ] Bring logic from ppx/html.ml into React.Element
- [ ] Handle lists with keys

## Questions

- Should `children` be a List or a custom type with polymoprhic constructors?
- What to do with React.Components
  - static getDerivedStateFromError(error)
- Suspense?
- Hooks should be mocked
  - UseState should "work"?
  - UseEffect should not run
- Hooks and other callbacks should be untouched
- Should we support shallowRenderer? (Render only one level of the component tree, leaving the rest as Capital leters and not recursively render them)
- Components runtime? If there is a function call such as setState inside a component?
- (Smoking idea) When Server components, can we transform React.node into json?
