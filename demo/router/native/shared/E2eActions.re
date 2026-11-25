[@react.server.function]
let countVisit = (_formData: Js.FormData.t): Js.Promise.t(unit) => {
  E2eState.visits := E2eState.visits^ + 1;
  Lwt.return();
};

[@react.server.function]
let redirectToLong = (): Js.Promise.t(unit) =>
  RouterServer.redirect(Router.E2eLong.destination());
