{
  description = "server-reason-react";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs = {
      url = "github:nix-ocaml/nix-overlays";
      inputs.flake-utils.follows = "flake-utils";
    };
    melange = {
      # this should match the pinned version in the Makefile
      url = "github:melange-re/melange?rev=a01735398b5df5b90f0a567dd660847ae0e9da48";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };
  outputs =
    { self
    , nixpkgs
    , flake-utils
    , melange
    }:
    (flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages."${system}".appendOverlays [
        melange.overlays.default
        (self: super: {
          ocamlPackages = super.ocaml-ng.ocamlPackages_5_1;
        })
      ];
      inherit (pkgs) ocamlPackages;
    in
    with ocamlPackages;
    rec {
      devShells.default = pkgs.mkShell {
        buildInputs = [
          lwt
          lwt_ppx
          ocamlPackages.melange
          ocaml_pcre
          alcotest
          alcotest-lwt
          fmt
          ppxlib
          reason-react
        ];
        nativeBuildInputs = [
          findlib
          ocaml
          ocaml-lsp
          reason
          dune_3
          reason-native.refmterr
          ocamlformat
        ];
        OCAMLRUNPARAM = "b";
      };
    }));
}
