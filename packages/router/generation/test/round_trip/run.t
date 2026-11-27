Generated path helpers and the server agree on typed path parameters.
round_trip.exe uses RouterDefinition.ml (base path /base). `href` builds an
href from typed values with tryHref, checks that href agrees, and serves it.
`serve` decodes a pathname into page props and builds the href again.

  $ alias rt=./round_trip.exe

Built-in scalars and a custom codec:

  $ rt href Scalars i=1 s=a b=true c=7
  href: /base/s/1/a/true/7
  props: Scalars i=1 s="a" b=true c=7
  $ rt href Scalars i=-42 s=x b=false c=0
  href: /base/s/-42/x/false/0
  props: Scalars i=-42 s="x" b=false c=0

String parameters are percent-encoded and decode to the same bytes:

  $ rt href Scalars i=1 s='a b' b=true c=7
  href: /base/s/1/a%20b/true/7
  props: Scalars i=1 s="a b" b=true c=7
  $ rt href Scalars i=1 s='日本' b=true c=7
  href: /base/s/1/%E6%97%A5%E6%9C%AC/true/7
  props: Scalars i=1 s="\230\151\165\230\156\172" b=true c=7
  $ rt href Scalars i=1 s='\xf0\x9f\x98\x80' b=true c=7
  href: /base/s/1/%F0%9F%98%80/true/7
  props: Scalars i=1 s="\240\159\152\128" b=true c=7
  $ rt href Scalars i=1 s='%2F' b=true c=7
  href: /base/s/1/%252F/true/7
  props: Scalars i=1 s="%2F" b=true c=7
  $ rt href Scalars i=1 s='+?#;=&' b=true c=7
  href: /base/s/1/%2B%3F%23%3B%3D%26/true/7
  props: Scalars i=1 s="+?#;=&" b=true c=7
  $ rt href Scalars i=1 s="!'()*~-_." b=true c=7
  href: /base/s/1/!'()*~-_./true/7
  props: Scalars i=1 s="!'()*~-_." b=true c=7
  $ rt href Scalars i=1 s='...' b=true c=7
  href: /base/s/1/.../true/7
  props: Scalars i=1 s="..." b=true c=7

Values that are not one valid segment are rejected by tryHref, and href raises:

  $ rt href Scalars i=1 s= b=true c=7
  tryHref: route parameters must be valid non-empty path segments
  $ rt href Scalars i=1 s=. b=true c=7
  tryHref: route parameters must be valid non-empty path segments
  $ rt href Scalars i=1 s=.. b=true c=7
  tryHref: route parameters must be valid non-empty path segments
  $ rt href Scalars i=1 s=a/b b=true c=7
  tryHref: route parameters must be valid non-empty path segments
  $ rt href Scalars i=1 s='\x00' b=true c=7
  tryHref: route parameters must be valid non-empty path segments
  $ rt href Scalars i=1 s='a\nb' b=true c=7
  tryHref: route parameters must be valid non-empty path segments
  $ rt href Scalars i=1 s='\x7f' b=true c=7
  tryHref: route parameters must be valid non-empty path segments
  $ rt href Scalars i=1 s='\xff' b=true c=7
  tryHref: route parameters must be valid non-empty path segments
  $ rt href Scalars i=1 s='\xc3' b=true c=7
  tryHref: route parameters must be valid non-empty path segments
  $ rt href Scalars i=1 s='\xed\xa0\x80' b=true c=7
  tryHref: route parameters must be valid non-empty path segments

int is a 32-bit signed integer on the server. The bounds round trip:

  $ rt href Scalars i=2147483647 s=a b=true c=7
  href: /base/s/2147483647/a/true/7
  props: Scalars i=2147483647 s="a" b=true c=7
  $ rt href Scalars i=-2147483648 s=a b=true c=7
  href: /base/s/-2147483648/a/true/7
  props: Scalars i=-2147483648 s="a" b=true c=7

A native int outside that range still produces an href, which its own route
then rejects:

  $ rt href Scalars i=2147483648 s=a b=true c=7
  href: /base/s/2147483648/a/true/7
  serve: invalid path parameter i
  $ rt href Scalars i=-2147483649 s=a b=true c=7
  href: /base/s/-2147483649/a/true/7
  serve: invalid path parameter i
  $ rt href OptRest lead=4611686018427387903
  href: /base/q/4611686018427387903
  serve: invalid path parameter lead

The int and bool codecs accept one spelling. A segment that matches the route
shape but fails its codec is an invalid parameter; matching does not fall back
to another route:

  $ rt serve /base/s/-0/a/true/7
  props: Scalars i=0 s="a" b=true c=7
  href: /base/s/0/a/true/7
  $ rt serve /base/s/+5/a/true/7
  serve: invalid path parameter i
  $ rt serve /base/s/0x10/a/true/7
  serve: invalid path parameter i
  $ rt serve /base/s/1_000/a/true/7
  serve: invalid path parameter i
  $ rt serve /base/s/2147483648/a/true/7
  serve: invalid path parameter i
  $ rt serve /base/s/1/a/True/7
  serve: invalid path parameter b
  $ rt serve /base/s/1/a/1/7
  serve: invalid path parameter b

A custom codec can accept several spellings. Its to_string picks the href:

  $ rt serve /base/s/1/a/true/007
  props: Scalars i=1 s="a" b=true c=7
  href: /base/s/1/a/true/7
  $ rt serve /base/s/1/a/true/-7
  serve: invalid path parameter c

The server decodes escapes in either case, and the href uses one encoding:

  $ rt serve /base/s/1/%61/true/7
  props: Scalars i=1 s="a" b=true c=7
  href: /base/s/1/a/true/7
  $ rt serve /base/s/1/%c3%a9/true/7
  props: Scalars i=1 s="\195\169" b=true c=7
  href: /base/s/1/%C3%A9/true/7
  $ rt serve /base/s/1/%C3%A9/true/7
  props: Scalars i=1 s="\195\169" b=true c=7
  href: /base/s/1/%C3%A9/true/7
  $ rt serve /base/s/1/é/true/7
  props: Scalars i=1 s="\195\169" b=true c=7
  href: /base/s/1/%C3%A9/true/7
  $ rt serve /base/s/1/a+b/true/7
  props: Scalars i=1 s="a+b" b=true c=7
  href: /base/s/1/a%2Bb/true/7
  $ rt serve /base/s/1/%2B/true/7
  props: Scalars i=1 s="+" b=true c=7
  href: /base/s/1/%2B/true/7
  $ rt serve /base/s/1/%2E/true/7
  serve: invalid path
  $ rt serve /base/s/1/a%2Fb/true/7
  serve: encoded slash
  $ rt serve /base/s/1/a%2fb/true/7
  serve: encoded slash
  $ rt serve /base/s/1/%FF/true/7
  serve: invalid path
  $ rt serve /base/s/1/%00/true/7
  serve: invalid path
  $ rt serve /base/s/1/%/true/7
  serve: malformed escape
  $ rt serve /base/s/1/%4/true/7
  serve: malformed escape

Optional parameters: /o/:i?<int>/x/y/:s?<string>.

  $ rt href Optional
  href: /base/o/x/y
  props: Optional i=None s=None
  $ rt href Optional i=5
  href: /base/o/5/x/y
  props: Optional i=5 s=None
  $ rt href Optional s=z
  href: /base/o/x/y/z
  props: Optional i=None s="z"
  $ rt href Optional i=5 s=z
  href: /base/o/5/x/y/z
  props: Optional i=5 s="z"
  $ rt href Optional s=
  tryHref: route parameters must be valid non-empty path segments
  $ rt href Optional s=x
  href: /base/o/x/y/x
  props: Optional i=None s="x"
  $ rt serve /base/o/x/y
  props: Optional i=None s=None
  href: /base/o/x/y
  $ rt serve /base/o/5/x/y/z
  props: Optional i=5 s="z"
  href: /base/o/5/x/y/z
  $ rt serve /base/o/x/y/x
  props: Optional i=None s="x"
  href: /base/o/x/y/x
  $ rt serve /base/o/abc/x/y
  serve: invalid path parameter i
  $ rt serve /base/o/x/x/y
  serve: invalid path parameter i

A catch-all /r/:parts<string...> takes one or more segments:

  $ rt href Rest parts=a
  href: /base/r/a
  props: Rest parts=["a"]
  $ rt href Rest parts=a parts='b c' parts='日本'
  href: /base/r/a/b%20c/%E6%97%A5%E6%9C%AC
  props: Rest parts=["a"; "b c"; "\230\151\165\230\156\172"]
  $ rt href Rest
  tryHref: catch-all route parameters require at least one segment
  $ rt href Rest parts=a parts=
  tryHref: catch-all route parameters must be non-empty path segments
  $ rt href Rest parts=a/b
  tryHref: catch-all route parameters must be non-empty path segments
  $ rt href Rest parts=..
  tryHref: catch-all route parameters must be non-empty path segments
  $ rt serve /base/r
  serve: no matching route
  $ rt serve /base/r/a/b%2Fc
  serve: encoded slash
  $ rt serve /base/r/a/%2E%2E
  serve: invalid path
  $ rt serve /base/r/a//b
  serve: invalid path

An optional catch-all /q/:lead<int>/:rest?<string...> takes zero or more:

  $ rt href OptRest lead=1
  href: /base/q/1
  props: OptRest lead=1 rest=[]
  $ rt href OptRest lead=1 rest=a rest=b
  href: /base/q/1/a/b
  props: OptRest lead=1 rest=["a"; "b"]
  $ rt href OptRest lead=1 rest=
  tryHref: catch-all route parameters must be non-empty path segments
  $ rt serve /base/q/1
  props: OptRest lead=1 rest=[]
  href: /base/q/1
  $ rt serve /base/q/1/a/b/c
  props: OptRest lead=1 rest=["a"; "b"; "c"]
  href: /base/q/1/a/b/c
  $ rt serve /base/q/x
  serve: invalid path parameter lead

The base path is compared after decoding:

  $ rt serve /%62ase/q/1
  props: OptRest lead=1 rest=[]
  href: /base/q/1
  $ rt serve /basement/q/1
  serve: outside the base path
  $ rt serve /q/1
  serve: outside the base path
