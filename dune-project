(lang dune 3.8)
(using melange 0.1)
(using directory-targets 0.1)

(cram enable)

(name server-reason-react)

(license MIT)

(maintainers "David Sancho <dsnxmoreno@gmail.com>")

(authors "David Sancho <dsnxmoreno@gmail.com>")

(source
 (github ml-in-barcelona/server-reason-react))

(generate_opam_files true)

(implicit_transitive_deps false)

(package
 (name server-reason-react)
 (synopsis "Rendering React components on the server natively")
 (depends
  ;; General system dependencies
  (ocaml (and (>= 4.12.0) (< 5.0.0)))
  (reason (>= 3.8.1))
  melange

  ;; Library dependencies
  (ppxlib (>= 0.23.0))
  (pcre (<= 7.5.0))
  (promise (>= 1.1.2))
  (lwt (>= 5.6.0))
  (lwt_ppx (>= 2.1.0))

  ;; Test dependencies
  (alcotest :with-test)
  (alcotest-lwt :with-test)
  (fmt :with-test)

  ;; Dev dependencies, using with-test so that consumers don't install them (until package is released in opam)
  (ocamlformat (and (= 0.21.0) :with-test))
  (ocaml-lsp-server :with-test)
))
