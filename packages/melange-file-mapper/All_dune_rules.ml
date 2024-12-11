let counter =
  {|
((deps
  ((File
    (External
     /Users/davesnx/Code/github/ml-in-barcelona/server-reason-react/_opam/bin/melc))
   (File
    (In_build_dir
     _build/default/demo/universal/js/.demo_shared_js.objs/melange/cx.cmi))
   (File
    (In_build_dir
     _build/default/demo/universal/js/.demo_shared_js.objs/melange/cx.cmj))
   (File
    (In_build_dir
     _build/default/demo/universal/js/.demo_shared_js.objs/melange/rR.cmi))
   (File
    (In_build_dir
     _build/default/demo/universal/js/.demo_shared_js.objs/melange/rR.cmj))
   (File
    (In_build_dir
     _build/default/demo/universal/js/.demo_shared_js.objs/melange/spacer.cmi))
   (File
    (In_build_dir
     _build/default/demo/universal/js/.demo_shared_js.objs/melange/spacer.cmj))
   (File
    (In_build_dir
     _build/default/demo/universal/js/.demo_shared_js.objs/melange/theme.cmi))
   (File
    (In_build_dir
     _build/default/demo/universal/js/.demo_shared_js.objs/melange/theme.cmj))
   (File (In_build_dir _build/default/demo/universal/js/Counter.re.pp.ml))
   (glob
    ((dir
      (External
       /Users/davesnx/Code/github/ml-in-barcelona/server-reason-react/_opam/lib/melange-webapi/melange))
     (predicate *.cmi)
     (only_generated_files false)))
   (glob
    ((dir
      (External
       /Users/davesnx/Code/github/ml-in-barcelona/server-reason-react/_opam/lib/melange-webapi/melange))
     (predicate *.cmj)
     (only_generated_files false)))
   (glob
    ((dir
      (External
       /Users/davesnx/Code/github/ml-in-barcelona/server-reason-react/_opam/lib/melange/belt/melange))
     (predicate *.cmi)
     (only_generated_files false)))
   (glob
    ((dir
      (External
       /Users/davesnx/Code/github/ml-in-barcelona/server-reason-react/_opam/lib/melange/belt/melange))
     (predicate *.cmj)
     (only_generated_files false)))
   (glob
    ((dir
      (External
       /Users/davesnx/Code/github/ml-in-barcelona/server-reason-react/_opam/lib/melange/dom/melange))
     (predicate *.cmi)
     (only_generated_files false)))
   (glob
    ((dir
      (External
       /Users/davesnx/Code/github/ml-in-barcelona/server-reason-react/_opam/lib/melange/dom/melange))
     (predicate *.cmj)
     (only_generated_files false)))
   (glob
    ((dir
      (External
       /Users/davesnx/Code/github/ml-in-barcelona/server-reason-react/_opam/lib/melange/js/melange))
     (predicate *.cmi)
     (only_generated_files false)))
   (glob
    ((dir
      (External
       /Users/davesnx/Code/github/ml-in-barcelona/server-reason-react/_opam/lib/melange/js/melange))
     (predicate *.cmj)
     (only_generated_files false)))
   (glob
    ((dir
      (External
       /Users/davesnx/Code/github/ml-in-barcelona/server-reason-react/_opam/lib/reason-react/melange))
     (predicate *.cmi)
     (only_generated_files false)))
   (glob
    ((dir
      (External
       /Users/davesnx/Code/github/ml-in-barcelona/server-reason-react/_opam/lib/reason-react/melange))
     (predicate *.cmj)
     (only_generated_files false)))
   (glob
    ((dir
      (In_build_dir _build/default/packages/runtime/.runtime.objs/melange))
     (predicate *.cmi)
     (only_generated_files false)))
   (glob
    ((dir
      (In_build_dir _build/default/packages/runtime/.runtime.objs/melange))
     (predicate *.cmj)
     (only_generated_files false)))))
 (targets
  ((files
    (_build/default/demo/universal/js/.demo_shared_js.objs/melange/counter.cmi
     _build/default/demo/universal/js/.demo_shared_js.objs/melange/counter.cmj
     _build/default/demo/universal/js/.demo_shared_js.objs/melange/counter.cmt))
   (directories ())))
 (context default)
 (action
  (chdir
   _build/default
   (run
    /Users/davesnx/Code/github/ml-in-barcelona/server-reason-react/_opam/bin/melc
    -w
    @1..3@5..28@30..39@43@46..47@49..57@61..62@67@69-40
    -strict-sequence
    -strict-formats
    -short-paths
    -keep-locs
    -g
    -bin-annot
    -I
    demo/universal/js/.demo_shared_js.objs/melange
    -I
    /Users/davesnx/Code/github/ml-in-barcelona/server-reason-react/_opam/lib/melange-webapi/melange
    -I
    /Users/davesnx/Code/github/ml-in-barcelona/server-reason-react/_opam/lib/melange/belt/melange
    -I
    /Users/davesnx/Code/github/ml-in-barcelona/server-reason-react/_opam/lib/melange/dom/melange
    -I
    /Users/davesnx/Code/github/ml-in-barcelona/server-reason-react/_opam/lib/melange/js/melange
    -I
    /Users/davesnx/Code/github/ml-in-barcelona/server-reason-react/_opam/lib/reason-react/melange
    -I
    packages/runtime/.runtime.objs/melange
    --bs-stop-after-cmj
    --bs-package-output
    demo/universal/js
    --bs-module-name
    Counter
    -no-alias-deps
    -opaque
    -o
    demo/universal/js/.demo_shared_js.objs/melange/counter.cmj
    -c
    -impl
    demo/universal/js/Counter.re.pp.ml))))

((deps
  ((File
    (External
     /Users/davesnx/Code/github/ml-in-barcelona/server-reason-react/_opam/bin/melc))
   (File
    (In_build_dir
     _build/default/demo/universal/js/.demo_shared_js.objs/melange/counter.cmj))
   (File
    (In_build_dir
     _build/default/demo/universal/js/.demo_shared_js.objs/melange/cx.cmj))
   (File
    (In_build_dir
     _build/default/demo/universal/js/.demo_shared_js.objs/melange/rR.cmj))
   (File
    (In_build_dir
     _build/default/demo/universal/js/.demo_shared_js.objs/melange/spacer.cmj))
   (File
    (In_build_dir
     _build/default/demo/universal/js/.demo_shared_js.objs/melange/theme.cmj))
   (glob
    ((dir
      (External
       /Users/davesnx/Code/github/ml-in-barcelona/server-reason-react/_opam/lib/melange-fetch/melange))
     (predicate *.cmj)
     (only_generated_files false)))
   (glob
    ((dir
      (External
       /Users/davesnx/Code/github/ml-in-barcelona/server-reason-react/_opam/lib/melange-webapi/melange))
     (predicate *.cmj)
     (only_generated_files false)))
   (glob
    ((dir
      (External
       /Users/davesnx/Code/github/ml-in-barcelona/server-reason-react/_opam/lib/melange/__private__/melange_mini_stdlib/melange))
     (predicate *.cmj)
     (only_generated_files false)))
   (glob
    ((dir
      (External
       /Users/davesnx/Code/github/ml-in-barcelona/server-reason-react/_opam/lib/melange/belt/melange))
     (predicate *.cmj)
     (only_generated_files false)))
   (glob
    ((dir
      (External
       /Users/davesnx/Code/github/ml-in-barcelona/server-reason-react/_opam/lib/melange/dom/melange))
     (predicate *.cmj)
     (only_generated_files false)))
   (glob
    ((dir
      (External
       /Users/davesnx/Code/github/ml-in-barcelona/server-reason-react/_opam/lib/melange/js/melange))
     (predicate *.cmj)
     (only_generated_files false)))
   (glob
    ((dir
      (External
       /Users/davesnx/Code/github/ml-in-barcelona/server-reason-react/_opam/lib/melange/melange))
     (predicate *.cmj)
     (only_generated_files false)))
   (glob
    ((dir
      (External
       /Users/davesnx/Code/github/ml-in-barcelona/server-reason-react/_opam/lib/reason-react/melange))
     (predicate *.cmj)
     (only_generated_files false)))
   (glob
    ((dir
      (In_build_dir _build/default/packages/runtime/.runtime.objs/melange))
     (predicate *.cmj)
     (only_generated_files false)))))
 (targets
  ((files (_build/default/demo/client/app/demo/universal/js/Counter.js))
   (directories ())))
 (context default)
 (action
  (chdir
   _build/default
   (run
    /Users/davesnx/Code/github/ml-in-barcelona/server-reason-react/_opam/bin/melc
    -I
    demo/universal/js/.demo_shared_js.objs/melange
    -I
    /Users/davesnx/Code/github/ml-in-barcelona/server-reason-react/_opam/lib/melange-fetch/melange
    -I
    /Users/davesnx/Code/github/ml-in-barcelona/server-reason-react/_opam/lib/melange-webapi/melange
    -I
    /Users/davesnx/Code/github/ml-in-barcelona/server-reason-react/_opam/lib/melange/belt/melange
    -I
    /Users/davesnx/Code/github/ml-in-barcelona/server-reason-react/_opam/lib/melange/dom/melange
    -I
    /Users/davesnx/Code/github/ml-in-barcelona/server-reason-react/_opam/lib/melange/js/melange
    -I
    /Users/davesnx/Code/github/ml-in-barcelona/server-reason-react/_opam/lib/melange/melange
    -I
    /Users/davesnx/Code/github/ml-in-barcelona/server-reason-react/_opam/lib/reason-react/melange
    -I
    packages/runtime/.runtime.objs/melange
    --bs-module-type
    es6
    -o
    demo/client/app/demo/universal/js/Counter.js
    demo/universal/js/.demo_shared_js.objs/melange/counter.cmj))))

((deps
  ((File (In_build_dir _build/default/demo/universal/native/lib/Counter.re))))
 (targets
  ((files (_build/default/demo/universal/js/Counter.re)) (directories ())))
 (context default)
 (action
  (chdir
   _build/default
   (copy demo/universal/native/lib/Counter.re demo/universal/js/Counter.re))))

((deps
  ((File
    (External
     /Users/davesnx/Code/github/ml-in-barcelona/server-reason-react/_opam/bin/refmt))
   (File (In_build_dir _build/default/demo/universal/js/Counter.re))))
 (targets
  ((files (_build/default/demo/universal/js/Counter.re.ml)) (directories ())))
 (context default)
 (action
  (chdir
   _build/default
   (with-stdout-to
    demo/universal/js/Counter.re.ml
    (chdir
     .
     (run
      /Users/davesnx/Code/github/ml-in-barcelona/server-reason-react/_opam/bin/refmt
      --print
      binary
      demo/universal/js/Counter.re))))))

((deps
  ((File
    (In_build_dir
     _build/default/.ppx/eac557cf765cce331d33b8e4f4dc295b/ppx.exe))
   (File (In_build_dir _build/default/demo/universal/js/Counter.re))
   (File (In_build_dir _build/default/demo/universal/js/Counter.re.ml))))
 (targets
  ((files (_build/default/demo/universal/js/Counter.re.pp.ml))
   (directories ())))
 (context default)
 (action
  (chdir
   _build/default
   (progn
    (chdir
     .
     (run
      .ppx/eac557cf765cce331d33b8e4f4dc295b/ppx.exe
      -js
      --cookie
      "library-name=\"demo_shared_js\""
      -o
      demo/universal/js/Counter.re.pp.ml
      --impl
      demo/universal/js/Counter.re.ml
      -corrected-suffix
      .ppx-corrected
      -diff-cmd
      -
      -dump-ast))
    (diff?
     demo/universal/js/Counter.re
     demo/universal/js/Counter.re.ppx-corrected)))))

((deps ((File (In_source_tree demo/universal/native/lib/Counter.re))))
 (targets
  ((files (_build/default/demo/universal/native/lib/Counter.re))
   (directories ())))
 (context default)
 (action
  (copy
   demo/universal/native/lib/Counter.re
   _build/default/demo/universal/native/lib/Counter.re)))

((deps
  ((File
    (External
     /Users/davesnx/Code/github/ml-in-barcelona/server-reason-react/_opam/bin/refmt))
   (File (In_build_dir _build/default/demo/universal/native/lib/Counter.re))))
 (targets
  ((files (_build/default/demo/universal/native/lib/Counter.re.ml))
   (directories ())))
 (context default)
 (action
  (chdir
   _build/default
   (with-stdout-to
    demo/universal/native/lib/Counter.re.ml
    (chdir
     .
     (run
      /Users/davesnx/Code/github/ml-in-barcelona/server-reason-react/_opam/bin/refmt
      --print
      binary
      demo/universal/native/lib/Counter.re))))))

((deps
  ((File
    (In_build_dir
     _build/default/.ppx/a0fdff921d377242b3321f7490a43612/ppx.exe))
   (File (In_build_dir _build/default/demo/universal/native/lib/Counter.re))
   (File
    (In_build_dir _build/default/demo/universal/native/lib/Counter.re.ml))))
 (targets
  ((files (_build/default/demo/universal/native/lib/Counter.re.pp.ml))
   (directories ())))
 (context default)
 (action
  (chdir
   _build/default
   (progn
    (chdir
     .
     (run
      .ppx/a0fdff921d377242b3321f7490a43612/ppx.exe
      --cookie
      "library-name=\"demo_shared_native\""
      -o
      demo/universal/native/lib/Counter.re.pp.ml
      --impl
      demo/universal/native/lib/Counter.re.ml
      -corrected-suffix
      .ppx-corrected
      -diff-cmd
      -
      -dump-ast))
    (diff?
     demo/universal/native/lib/Counter.re
     demo/universal/native/lib/Counter.re.ppx-corrected)))))|}
