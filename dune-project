(lang dune 3.1)

(name native-react)

(license MIT)

(maintainers "Javier Chávarri <javier.chavarri@gmail.com>")

(authors "Javier Chávarri <javier.chavarri@gmail.com>")

(source
 (github ml-in-barcelona/native-react))

(generate_opam_files false)

(implicit_transitive_deps false)

(package
 (name native-react)
 (synopsis "Bindings to ReactJS for js_of_ocaml, including JSX ppx")
 (depends
  ;; General system dependencies
  (dune (and (>= 2) (< 4)))
  (ocaml (and (>= 4.12.0) (< 5.0.0)))

  (ppxlib (>= 0.23.0))

  (reason (= 3.8.1))

  ;; Test dependencies
  (alcotest :with-test)

  ;; Dev dependencies, using with-test so that consumers don't install them (until package is released in opam)
  (ocamlformat (and (= 0.21.0) :with-test))
  (ocaml-lsp-server :with-test)
))
