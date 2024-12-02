# server-reason-react

Re-implementation of `react`, `react-dom` and `react-dom/server` to run on the server and also, a [few related libraries](https://ml-in-barcelona.github.io/server-reason-react/local/server-reason-react/index.html#other-libraries) to enable Server-side rendering for reason-react applications, also contains a [few libraries](https://ml-in-barcelona.github.io/server-reason-react/local/server-reason-react/universal-code.html) and a [ppx](https://ml-in-barcelona.github.io/server-reason-react/local/server-reason-react/browser_only.html) to share code between native (compiled to machine code) and JavaScript (compiled by [Melange](https://melange.re)).

> **Warning**
> This repo contains a few parts that are considered experimental. The stable parts are used in production at [app.ahrefs.com](https://app.ahrefs.com) for all users and [wordcount.com](https://wordcount.com), but `Belt`, `Js` modules have missing APIs, non-implemented functions and unsafe code. Use it at your own risk.

## Why
Explained more details in this blog post [sancho.dev/blog/server-side-rendering-react-in-ocaml](https://sancho.dev/blog/server-side-rendering-react-in-ocaml)

## [Documentation](https://ml-in-barcelona.github.io/server-reason-react/local/server-reason-react/index.html)
