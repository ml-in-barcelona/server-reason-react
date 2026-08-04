let () =
  if (Client.noteHref
      != "/fixture/workspaces/7/notes/42?filter=active%2F%C3%BC") {
    failwith("generated Melange href did not use the typed parameter");
  };
if (Client.quoteHref != "/fixture/workspaces/7/notes/42?filter=it's") {
  failwith("generated Melange href did not match encodeURIComponent");
};
