{
  description = "Piq's blog";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/22.11";

  outputs = { self, nixpkgs }:
    let
      forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
      nixpkgsFor = forAllSystems (system: import nixpkgs {
        inherit system;
        overlays = [ self.overlay ];
      });
    in
    {
      overlay = self: super: {
        hsPkgs = super.haskell.packages.ghc943.override {
          overrides = hself: hsuper: {
            hspec-contrib = super.haskell.lib.dontCheck (super.haskell.lib.doJailbreak hsuper.hspec-contrib);
            string-qq = super.haskell.lib.doJailbreak hsuper.string-qq;
            hslua-aeson = super.haskell.lib.doJailbreak hsuper.hslua-aeson;
            pandoc = super.haskell.lib.doJailbreak hsuper.pandoc;
            hakyll = super.haskell.lib.doJailbreak hsuper.hakyll;
          };
        };
      };
      devShells = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
          libs = with pkgs; [
            zlib
          ];
        in
        {
          default = pkgs.hsPkgs.shellFor {
            packages = hsPkgs: [ ];
            buildInputs = with pkgs; [
              hsPkgs.cabal-install
              hsPkgs.cabal-fmt
              hsPkgs.ghcid
              hsPkgs.ghc
              hsPkgs.hakyll
              treefmt
              ormolu
            ] ++ libs;
            shellHook = "export PS1='[$PWD]\n❄ '";
            LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath libs;
          };
        });
    };
}
