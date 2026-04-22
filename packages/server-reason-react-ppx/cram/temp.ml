let test ~name =
 fun ~active ->
  fun ~tab ->
   React.Writer
     {
       emit =
         (fun b ->
           Buffer.add_string b "<div";
           Buffer.add_char b ' ';
           Buffer.add_string b "class";
           Buffer.add_string b "=\"";
           ReactDOM.escape_to_buffer b (Cx.make [ "base"; Cx.ifTrue "active" active ] : string);
           Buffer.add_char b '"';
           Buffer.add_char b ' ';
           Buffer.add_string b "id";
           Buffer.add_string b "=\"";
           ReactDOM.escape_to_buffer b (name : string);
           Buffer.add_char b '"';
           Buffer.add_char b ' ';
           Buffer.add_string b "tabindex";
           Buffer.add_string b "=\"";
           Printf.bprintf b "%d" (tab : int);
           Buffer.add_char b '"';
           (match title with
           | None -> ()
           | Some v ->
               Buffer.add_char b ' ';
               Buffer.add_string b "title";
               Buffer.add_string b "=\"";
               ReactDOM.escape_to_buffer b (v : string);
               Buffer.add_char b '"');
           Buffer.add_string b ">";
           ReactDOM.write_to_buffer b
             (React.Static
                { prerendered = "<span>hi</span>"; original = React.createElement "span" [] [ React.string "hi" ] });
           Buffer.add_string b "</div>";
           ());
       original =
         (fun () ->
           React.createElement "div"
             (Stdlib.List.filter_map Stdlib.Fun.id
                [
                  Some
                    (React.JSX.String ("class", "className", (Cx.make [ "base"; Cx.ifTrue "active" active ] : string)));
                  Some (React.JSX.String ("id", "id", (name : string)));
                  Some (React.JSX.String ("tabindex", "tabIndex", Stdlib.Int.to_string (tab : int)));
                  (match (title : string option) with
                  | None -> None
                  | Some v -> Some (React.JSX.String ("title", "title", v)));
                ])
             [
               React.Static
                 { prerendered = "<span>hi</span>"; original = React.createElement "span" [] [ React.string "hi" ] };
             ]);
     }
