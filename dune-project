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
  (ocaml (>= 4.14.1))
  (reason (>= 3.14.0))
  (melange (>= 3.0.0))

  ; Library dependencies
  (uucp (>= 16.0.0))
  (ppxlib (> 0.23.0))
  (quickjs (>= 0.1.2))
  (lwt (>= 5.6.0))
  (lwt_ppx (>= 2.1.0))
  (uri (>= 4.2.0))
  (yojson (>= 2.2.0))
  (integers (>= 0.7.0))
  (melange-fetch (>= 0.1.0))
  (melange-json (>= 2.0.0))
  (melange-json-native (>= 2.0.0))
  (melange-webapi (>= 0.21.0))
  (reason-react (>= 0.16.0))

  ; Documentation
  (odoc :with-doc)

  (dream
   (and
    (= 1.0.0~alpha8)
    :with-dev-setup)) ; We use dream on the demo

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
