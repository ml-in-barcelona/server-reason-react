# native-react-dom

## References

- [ReactDOM tests](https://github.com/facebook/react/tree/main/packages/react-dom/src/__tests__)
- [react-wasm-dom](https://github.com/MaibornWolff/react-wasm-dom/)
- [jsoo-react/html.ml](https://github.com/ml-in-barcelona/jsoo-react/blob/main/ppx/html.ml)
- [StaticReactExperiment](https://github.com/reasonml/reason-react/compare/StaticReactExperiment)
- [TyXML](https://github.com/ocsigen/tyxml)

### Reconcilier

- [https://github.com/briskml/brisk](https://github.com/briskml/brisk)
- [https://github.com/aidenybai/tiny-vdom](https://github.com/aidenybai/tiny-vdom)
- [https://reactjs.org/docs/reconciliation.html](https://reactjs.org/docs/reconciliation.html)
- [https://github.com/briskml/brisk-reconciler](https://github.com/briskml/brisk-reconciler)
- [https://github.com/ms-jpq/Noact/blob/noact/src/noact.ts](https://github.com/ms-jpq/Noact/blob/noact/src/noact.ts)

## TODOs

- [x] Create a basic reason project with alcotest
- [x] Take a look at a Rust implementation https://github.com/MaibornWolff/react-wasm-dom/
- [x] Try to render a string given a React Tree
- [x] Define the React Tree without jsx ppx, using React.createElement
- [ ] Allow attributes to be strings or booleans
- [ ] Handle html entities https://github.com/MaibornWolff/react-wasm-dom/blob/main/src/__tests__/escapeTextForBrowser-test.jsx
- [ ] Handle fragments
- [ ] Handle syntetic events
- [ ] Handle refs
- [ ] Handle lists with keys
- [ ] Transform attributes to JSX
- [ ] Handle style attribute https://github.com/MaibornWolff/react-wasm-dom/blob/main/src/__tests__/CSSPropertyOperations-test.jsx
- [ ] Pretty print with Fmt https://github.com/dbuenzli/fmt
