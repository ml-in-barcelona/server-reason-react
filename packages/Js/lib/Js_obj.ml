(** Provide utilities for {!Js.t} *)

module Internal = struct
  module Registry = Ephemeron.K1.Make (struct
    type t = Obj.t

    let equal (left : t) (right : t) = left == right
    let hash = Hashtbl.hash
  end)

  type entry = {
    method_name : string;
    js_name : string;
    mutable present : bool;
    get_boxed : unit -> Obj.t;
    set_boxed : Obj.t -> unit;
  }

  type metadata = {
    mutable order_rev : string list;
    mutable cached_keys : string array option;
    entries : (string, entry) Hashtbl.t;
  }

  let registry : metadata Registry.t = Registry.create 16
  let empty_metadata () = { order_rev = []; cached_keys = Some [||]; entries = Hashtbl.create 8 }

  let add_key_in_order metadata js_name =
    metadata.order_rev <- js_name :: metadata.order_rev;
    metadata.cached_keys <- None

  let keys_in_order metadata =
    match metadata.cached_keys with
    | Some keys -> keys
    | None ->
        let keys = Array.of_list (List.rev metadata.order_rev) in
        metadata.cached_keys <- Some keys;
        keys

  let raw_entry ~method_name ~js_name ~present value =
    let cell = ref value in
    { method_name; js_name; present; get_boxed = (fun () -> !cell); set_boxed = (fun next -> cell := next) }

  let slot_ref ~method_name ~js_name ~present initial =
    let cell = ref initial in
    let entry =
      {
        method_name;
        js_name;
        present;
        get_boxed = (fun () -> Obj.repr !cell);
        set_boxed = (fun next -> cell := Obj.obj next);
      }
    in
    (cell, entry)

  let get_metadata object_ = Registry.find_opt registry (Obj.repr object_)

  let ensure_metadata object_ =
    match get_metadata object_ with
    | Some metadata -> metadata
    | None ->
        let metadata = empty_metadata () in
        Registry.add registry (Obj.repr object_) metadata;
        metadata

  let register_entry metadata entry =
    let was_present =
      match Hashtbl.find_opt metadata.entries entry.js_name with Some existing -> existing.present | None -> false
    in
    Hashtbl.replace metadata.entries entry.js_name entry;
    if entry.present && not was_present then add_key_in_order metadata entry.js_name

  let register_structural object_ entries =
    let metadata = empty_metadata () in
    List.iter (register_entry metadata) entries;
    Registry.replace registry (Obj.repr object_) metadata;
    object_

  let clone_entry entry =
    raw_entry ~method_name:entry.method_name ~js_name:entry.js_name ~present:entry.present (entry.get_boxed ())

  let present_entries metadata =
    Array.fold_right
      (fun key acc ->
        match Hashtbl.find_opt metadata.entries key with
        | Some entry when entry.present -> entry :: acc
        | Some _ | None -> acc)
      (keys_in_order metadata) []

  let build metadata =
    let present_entries = present_entries metadata in
    let object_ : < .. > =
      match present_entries with
      | [] -> ((object end : < >) :> < .. >)
      | _ ->
          let table =
            CamlinternalOO.create_table (Array.of_list (List.map (fun entry -> entry.method_name) present_entries))
          in
          CamlinternalOO.init_class table;
          let object_ = CamlinternalOO.create_object table in
          List.iter
            (fun entry ->
              let label = CamlinternalOO.get_method_label table entry.method_name in
              let closure : CamlinternalOO.meth =
                Obj.obj (Obj.repr (fun (_self : CamlinternalOO.obj) -> entry.get_boxed ()))
              in
              CamlinternalOO.set_method table label closure)
            present_entries;
          CamlinternalOO.run_initializers object_ table;
          Obj.obj (Obj.repr object_)
    in
    Registry.replace registry (Obj.repr object_) metadata;
    object_

  let copy_present_entries_into target_metadata source =
    match get_metadata source with
    | None -> ()
    | Some source_metadata ->
        Array.iter
          (fun key ->
            match Hashtbl.find_opt source_metadata.entries key with
            | None -> ()
            | Some source_entry -> (
                match Hashtbl.find_opt target_metadata.entries key with
                | Some target_entry ->
                    target_entry.set_boxed (source_entry.get_boxed ());
                    if not target_entry.present then add_key_in_order target_metadata key;
                    target_entry.present <- true
                | None ->
                    let cloned_entry = clone_entry source_entry in
                    Hashtbl.add target_metadata.entries key cloned_entry;
                    if cloned_entry.present then add_key_in_order target_metadata key))
          (keys_in_order source_metadata)

  let assign_into target source =
    let target_metadata = ensure_metadata target in
    copy_present_entries_into target_metadata source;
    target

  let register_abstract object_ entries = Obj.obj (Obj.repr (register_structural object_ entries))
end

let empty () : < .. > = Internal.register_abstract ((object end : < >) :> < .. >) []
let assign target source = Internal.assign_into target source

let merge () left right : < .. > =
  let metadata = Internal.empty_metadata () in
  Internal.copy_present_entries_into metadata left;
  Internal.copy_present_entries_into metadata right;
  let object_ : < .. > = Internal.build metadata in
  Obj.obj (Obj.repr object_)

let keys object_ =
  match Internal.get_metadata object_ with
  | None -> [||]
  | Some metadata -> Array.copy (Internal.keys_in_order metadata)
