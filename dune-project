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
  (dune (= dev))
  (reason (>= 3.10.0))
  (melange (>= 3.0.0))

  ; Library dependencies
  (ppxlib (> 0.23.0))
  (quickjs (>= 0.1.1))
  (promise (>= 1.1.2))
  (lwt (>= 5.6.0))
  (lwt_ppx (>= 2.1.0))
  (uri (>= 4.2.0))

  ; Test dependencies
  (alcotest :with-test)
  (alcotest-lwt :with-test)
  (fmt :with-test)
  (merlin :with-test)

  ; Documentation
  (odoc :with-doc)

  ; Dev dependencies, using with-test so that consumers don't install them (until package is released in opam)
  (ocamlformat
   (and
    (= 0.26.1)
    :with-test))
  (ocaml-lsp-server :with-test)

  ; Demo deps
  ; :with-dev-setup when opam 2.2 is used everywhere
  (tiny_httpd :with-test)
  (melange-webapi :with-test)
  (reason-react :with-test)
  (melange-webapi :with-test)
  (reason-react-ppx :with-test)
))
