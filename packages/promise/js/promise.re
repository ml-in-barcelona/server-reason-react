/* Copyright (C) 2015-2016 Bloomberg Finance L.P.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * In addition to the permissions granted to you by the LGPL, you may combine
 * or link a "work that uses the Library" with a publicly distributed version
 * of this file to produce a combined library or application, then distribute
 * that combined work under the terms of your choosing, with no requirement
 * to comply with the obligations normally placed on you by section 4 of the
 * LGPL version 3 (or the corresponding section of a later version of the LGPL
 * should you choose to use a later version).
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA. */

/** Specialized bindings to Promise. Note: For simplicity,
    this binding does not track the error type, it treat it as an opaque type
    {[

    ]}
*/;

type t(+'a);
type error;

[@bs.new]
external make:
  (
  [@bs.uncurry]
  ((~resolve: (. 'a) => unit, ~reject: (. exn) => unit) => unit)
  ) =>
  t('a) =
  "Promise";

/* [make (fun resolve reject -> .. )] */
[@bs.val] [@bs.scope "Promise"] external resolve: 'a => t('a) = "resolve";
[@bs.val] [@bs.scope "Promise"] external reject: exn => t('a) = "reject";

[@bs.val] [@bs.scope "Promise"]
external all: array(t('a)) => t(array('a)) = "all";

[@bs.val] [@bs.scope "Promise"]
external all2: ((t('a0), t('a1))) => t(('a0, 'a1)) = "all";

[@bs.val] [@bs.scope "Promise"]
external all3: ((t('a0), t('a1), t('a2))) => t(('a0, 'a1, 'a2)) = "all";

[@bs.val] [@bs.scope "Promise"]
external all4:
  ((t('a0), t('a1), t('a2), t('a3))) => t(('a0, 'a1, 'a2, 'a3)) =
  "all";

[@bs.val] [@bs.scope "Promise"]
external all5:
  ((t('a0), t('a1), t('a2), t('a3), t('a4))) =>
  t(('a0, 'a1, 'a2, 'a3, 'a4)) =
  "all";

[@bs.val] [@bs.scope "Promise"]
external all6:
  ((t('a0), t('a1), t('a2), t('a3), t('a4), t('a5))) =>
  t(('a0, 'a1, 'a2, 'a3, 'a4, 'a5)) =
  "all";

[@bs.val] [@bs.scope "Promise"]
external race: array(t('a)) => t('a) = "race";

[@bs.send.pipe: t('a)]
external then_: ([@bs.uncurry] ('a => t('b))) => t('b) = "then";

[@bs.send.pipe: t('a)]
external catch: ([@bs.uncurry] (error => t('a))) => t('a) = "catch";
/* [ p|> catch handler]
       Note in JS the returned promise type is actually runtime dependent,
       if promise is rejected, it will pick the [handler] otherwise the original promise,
       to make it strict we enforce reject handler
       https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/catch
   */

/*
 let errorAsExn (x :  error) (e  : (exn ->'a option))=
   if Caml_exceptions.isCamlExceptionOrOpenVariant (Obj.magic x ) then
      e (Obj.magic x)
   else None
 [%bs.error?  ]
 */
