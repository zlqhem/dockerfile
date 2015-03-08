(* $Id: topfind.ml.in 239 2014-10-14 09:39:42Z gerd $
 * ----------------------------------------------------------------------
 *
 *)

let predicates = ref [];;
let forbidden = ref [];;
let loaded = ref [];;
let directories = ref [ Findlib.ocaml_stdlib() ];;


(* Note: Sys.interactive is always _true_ during toploop startup.
 * When a script is executed, it is set to false just before the
 * script starts. This is important for ocamlmktop-generated toploops:
 * For initialization code linked into the toploop, Sys.interactive
 * is _true_. It is set to false just before the script starts.
 *)

let real_toploop =
  !Sys.interactive;;

let log = ref (if real_toploop then prerr_endline else ignore)

let rec remove_dups l =
  match l with
    x :: l' ->
      if List.mem x l' then remove_dups l' else x::remove_dups l'
  | [] -> []
;;

let add_predicates pl =
  predicates := remove_dups (pl @ !predicates);;

let syntax s =
  add_predicates [ "syntax"; s ];;

let standard_syntax () = syntax "camlp4o";;
let revised_syntax () = syntax "camlp4r";;


let add_dir d =
  let d = Fl_split.norm_dir d in
  if not (List.mem d !directories) then begin
    Topdirs.dir_directory d;
    directories := d :: !directories;
    !log (d ^ ": added to search path")
  end
;;

let exec_string s =
  let l = Lexing.from_string s in
  let ph = !Toploop.parse_toplevel_phrase l in
  let fmt = Format.make_formatter (fun _ _ _ -> ()) (fun _ -> ()) in
  try
    Toploop.execute_phrase false fmt ph
  with
      _ -> false
;;

let load pkglist =
  List.iter
    (fun pkg ->
      let _stdlibdir = Findlib.ocaml_stdlib() in
      if not (List.mem pkg !loaded) then begin
        (* Determine the package directory: *)
	let d = Findlib.package_directory pkg in
	add_dir d;
        (* Leave pkg out if mentioned in !forbidden *)
	if not (List.mem pkg !forbidden) then begin
	  (* Determine the 'archive' property: *)
	  let archive =
	    try Findlib.package_property !predicates pkg "archive"
	    with
	      Not_found -> ""
	  in
	  (* Split the 'archive' property and load the files: *)
	  let archives = Fl_split.in_words archive in
	  List.iter
	    (fun arch ->
	       let arch' = Findlib.resolve_path ~base:d arch in
	       !log (arch' ^ ": loaded");
	       Topdirs.dir_load
		 Format.std_formatter arch')
	    archives;
          (* Determine the 'ppx' property: *)
          let ppx =
            try  
              Some(Findlib.resolve_path
                     ~base:d ~explicit:true
                     (Findlib.package_property !predicates pkg "ppx")
                  )
            with Not_found -> None
          and ppxopts =
            try
              List.map
                (fun opt ->
                   match Fl_split.in_words opt with
                     | pkg :: opts ->
                          pkg, 
                          List.map
                            (Findlib.resolve_path ~base:d ~explicit:true) opts
                     | _ -> assert false)
                (Fl_split.in_words_ws
                   (Findlib.package_property !predicates pkg "ppxopt"))
            with Not_found -> []          in
          (* Feed the 'ppx' property into the toplevel. To remain compatible
             with pre-4.01 OCaml, construct and execute a phrase instead of directly
             altering Clflags. *)
          begin match ppx with
            | Some ppx ->


                 begin try
                     match Hashtbl.find Toploop.directive_table "ppx" with
                       | Toploop.Directive_string fn -> 
                            fn ppx; !log (ppx ^ ": activated")
                       | _ -> assert false
                   with Not_found ->
                     failwith "Package defines a ppx preprocessor, but OCaml is too old. \
                               Use OCaml >= 4.02.0 for ppx support."
                 end
            | None -> ()
          end;
          (* Feed the 'ppxopt' property into the toplevel. *)
          match ppxopts with
            | [] -> ()
            | _ ->
                failwith "Package defines a ppx preprocessor option, but OCaml is too old. \
                          Use OCaml >=4.02.1 for ppxopt support."
        end;
	(* The package is loaded: *)
	loaded := pkg :: !loaded
      end)
    pkglist
;;


let load_deeply pkglist =
  (* Get the sorted list of ancestors *)
  let eff_pkglist =
    Findlib.package_deep_ancestors !predicates pkglist in
  (* Load the packages in turn: *)
  load eff_pkglist
;;


let don't_load pkglist =
  forbidden := remove_dups (pkglist @ !forbidden);
  List.iter
    (fun pkg ->
       let _d = Findlib.package_directory pkg in
       ()
    )
    pkglist
;;


let don't_load_deeply pkglist =
  (* Check if packages exist: *)
  List.iter
    (fun pkg ->
       let _ = Findlib.package_directory pkg in ()
    )
    pkglist;
  (* Get the sorted list of ancestors *)
  let eff_pkglist =
    Findlib.package_deep_ancestors !predicates pkglist in
  (* Add this to the list of forbidden packages: *)
  don't_load eff_pkglist
;;


let reset() =
  loaded := []
;;


let have_mt_support() =
  Findlib.package_property [] "threads" "type_of_threads" = "posix"
;;


let load_mt_support() =
  (* Load only if package "threads" is not yet loaded. *)
  if not(List.mem "threads" !loaded) then (
    (* This works only for POSIX threads. *)
    if have_mt_support() then (
      add_predicates ["mt"; "mt_posix"];
      add_dir (Filename.concat (Findlib.ocaml_stdlib()) "threads");
      load_deeply ["unix"];
      load_deeply ["threads"];
    )
    else (
      failwith "It is not possible to load support for vmthreads dynamically. Use\n
'ocamlfind ocamlmktop -o vmtop -package threads,findlib -linkpkg -vmthread'\n
to create a toploop with integrated vmthreads library."
    )
  )
;;


let list_packages() =
  Findlib.list_packages stdout;
  flush stdout
;;


let protect f arg =
  try
    let _ = f arg in ()
  with
      Failure s ->
	print_endline s
    | Fl_package_base.No_such_package(pkg, reason) ->
	print_endline ("No such package: " ^ pkg ^
		       (if reason <> "" then " - " ^ reason else ""))
    | Fl_package_base.Package_loop pkg ->
	print_endline ("Package requires itself: " ^ pkg)
;;


(* Add "#require" directive: *)

Hashtbl.add
    Toploop.directive_table
    "require"
    (Toploop.Directive_string
       (fun s ->
	  protect load_deeply (Fl_split.in_words s)
       ))
;;

(* Add "#predicates" directive: *)
Hashtbl.add
    Toploop.directive_table
    "predicates"
    (Toploop.Directive_string
       (fun s ->
	  protect add_predicates (Fl_split.in_words s)
       ))
;;


(* Add "#camlp4o" directive: *)

Hashtbl.add
    Toploop.directive_table
    "camlp4o"
    (Toploop.Directive_none
       (fun () ->
	  protect (fun () ->
		     standard_syntax();
		     load_deeply ["camlp4"]) ()
       ))
;;

(* Add "#camlp4r" directive: *)

Hashtbl.add
    Toploop.directive_table
    "camlp4r"
    (Toploop.Directive_none
       (fun () ->
	  protect (fun () ->
		     revised_syntax();
		     load_deeply ["camlp4"]) ()
       ))
;;


(* Add "#list" directive: *)

Hashtbl.add
    Toploop.directive_table
    "list"
    (Toploop.Directive_none
       (fun () ->
	  protect list_packages ()
       ))
;;


(* Add "#thread" directive: *)

Hashtbl.add
    Toploop.directive_table
    "thread"
    (Toploop.Directive_none
       (fun () ->
	  protect load_mt_support ()
       ))
;;


let announce() =
  if real_toploop then begin
    (* Assume we are in a toploop and not a script *)
    let msg_thread =
      "  #thread;;                 to enable threads\n" in
    print_endline
      ("Findlib has been successfully loaded. Additional directives:\n" ^
       "  #require \"package\";;      to load a package\n" ^
       "  #list;;                   to list the available packages\n" ^
       "  #camlp4o;;                to load camlp4 (standard syntax)\n" ^
       "  #camlp4r;;                to load camlp4 (revised syntax)\n" ^
       "  #predicates \"p,q,...\";;   to set these predicates\n" ^
       "  Topfind.reset();;         to force that packages will be reloaded\n" ^
       (if have_mt_support() then msg_thread else ""))
  end ;;
