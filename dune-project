(lang dune 3.9)
(using melange 0.1)
(using directory-targets 0.1)
(using mdx 0.4)

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
  ; General system dependencies
  (ocaml (>= 5.0.0))
  (reason (>= 3.10.0))
  (melange (>= 3.0.0))

  ; Library dependencies
  (camomile (>= 2.0.0))
  (ppxlib (> 0.23.0))
  (quickjs (>= 0.1.2))
  (promise (>= 1.1.2))
  (lwt (>= 5.6.0))
  (lwt_ppx (>= 2.1.0))
  (uri (>= 4.2.0))
  integers

  ; Documentation
  (odoc :with-doc)

  ; Dev dependencies
  (ocamlformat
   (and
    (= 0.26.1)
    :with-test)) ; We use ocamlformat on the tests
  (ocaml-lsp-server :with-dev-setup)

  ; Demo deps
  (dream :with-dev-setup)
  (melange-webapi :with-dev-setup)
  (reason-react :with-dev-setup)
  (melange-webapi :with-dev-setup)
  (reason-react-ppx :with-dev-setup)

  ; Test dependencies
  (alcotest :with-test)
  (alcotest-lwt :with-test)
  (fmt :with-test)
  (merlin :with-test)

  ; Benchmark dependencies
  (core_unix :with-test)
  (core_bench :with-test)
))
