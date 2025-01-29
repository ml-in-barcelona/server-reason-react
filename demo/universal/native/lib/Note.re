type t = {
  id: int,
  title: string,
  content: string,
  updated_at: float,
};

let pp = note => {
  Dream.log("%s", "Note");
  Dream.log("  title: %s", note.title);
  Dream.log("  content: %s", note.content);
  Dream.log("  updated_at: %f", note.updated_at);
};
