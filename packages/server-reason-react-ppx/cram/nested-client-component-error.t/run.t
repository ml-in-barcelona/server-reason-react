
  $ cat > dune-project << EOF
  > (lang dune 3.10)
  > (using melange 0.1)
  > (using directory-targets 0.1)
  > EOF

  $ cat > dune << EOF
  > (melange.emit
  >  (target js)
  >  (preprocess (pps server-reason-react.ppx -melange)))
  > EOF

  $ dune build
  File "input.re", lines 1-18, characters 16-1:
   1 | ................{
   2 |   [@react.client.component]
   3 |   let make =
   4 |       (
   5 |         ~initial: int,
  ...
  15 |       {React.string(value)}
  16 |     </div>;
  17 |   };
  18 | }.
  Error: can't use [@react.client.component] inside a module, only on the
         toplevel. Please move the make function outside of the module.
  [1]
