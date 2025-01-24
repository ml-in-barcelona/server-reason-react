let is_today = date => {
  let now = Unix.localtime(Unix.time());
  let d = Unix.localtime(date);
  now.tm_year == d.tm_year
  && now.tm_mon == d.tm_mon
  && now.tm_mday == d.tm_mday;
};

let format_time = date => {
  let t = Unix.localtime(date);
  let hour = t.tm_hour mod 12;
  let hour =
    if (hour == 0) {
      12;
    } else {
      hour;
    };
  let ampm =
    if (t.tm_hour >= 12) {
      "pm";
    } else {
      "am";
    };
  Printf.sprintf("%d:%02d %s", hour, t.tm_min, ampm);
};

let format_date = date => {
  let t = Unix.localtime(date);
  Printf.sprintf("%d/%d/%02d", t.tm_mon + 1, t.tm_mday, t.tm_year mod 100);
};
