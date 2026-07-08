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

  (* Object registration is on the hot path: every [makeProps] (one per
     component instantiation) and every [%mel.obj] literal registers its
     entries. Materializing [metadata] eagerly costs a [Hashtbl.create]
     plus one [Hashtbl.replace] and one list cons per field — and building
     an [entry] costs a record plus two boxing closures per field — yet the
     metadata is only ever consulted by [keys]/[assign]/[merge], which
     almost never run on these objects. So the generated code registers a
     single [Deferred] thunk that builds all entries on demand instead of
     paying that cost per object construction. *)
  type state = Built of metadata | Deferred of (unit -> entry list)
  type slot = { mutable state : state }

  let registry : slot Registry.t = Registry.create 16
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

  let register_entry metadata entry =
    let was_present =
      match Hashtbl.find_opt metadata.entries entry.js_name with Some existing -> existing.present | None -> false
    in
    Hashtbl.replace metadata.entries entry.js_name entry;
    if entry.present && not was_present then add_key_in_order metadata entry.js_name

  let build_metadata slot entries =
    let metadata = empty_metadata () in
    List.iter (register_entry metadata) entries;
    slot.state <- Built metadata;
    metadata

  let force slot = match slot.state with Built metadata -> metadata | Deferred thunk -> build_metadata slot (thunk ())

  let get_metadata object_ =
    match Registry.find_opt registry (Obj.repr object_) with None -> None | Some slot -> Some (force slot)

  let ensure_metadata object_ =
    match Registry.find_opt registry (Obj.repr object_) with
    | Some slot -> force slot
    | None ->
        let metadata = empty_metadata () in
        Registry.add registry (Obj.repr object_) { state = Built metadata };
        metadata

  (* Builds the [entry] for a field cell on demand; only ever called from a
     [Deferred] thunk, so the record and its two boxing closures are not
     allocated on the object-construction hot path. *)
  let deferred_entry ~method_name ~js_name ~present cell =
    {
      method_name;
      js_name;
      present;
      get_boxed = (fun () -> Obj.repr !cell);
      set_boxed = (fun next -> cell := Obj.obj next);
    }

  let register_deferred object_ thunk =
    Registry.replace registry (Obj.repr object_) { state = Deferred thunk };
    object_

  let clone_entry entry =
    let cell = ref (entry.get_boxed ()) in
    {
      method_name = entry.method_name;
      js_name = entry.js_name;
      present = entry.present;
      get_boxed = (fun () -> !cell);
      set_boxed = (fun next -> cell := next);
    }

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
    Registry.replace registry (Obj.repr object_) { state = Built metadata };
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

  let register_deferred_abstract object_ thunk = Obj.obj (Obj.repr (register_deferred object_ thunk))
end

let empty () : < .. > = Internal.register_deferred_abstract ((object end : < >) :> < .. >) (fun () -> [])
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
