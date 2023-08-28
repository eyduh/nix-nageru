{
  description = "A flake for bmusb by Sesse";

  inputs = {       
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    flake-utils.url = "github:numtide/flake-utils";    
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    }; 
  };

  outputs = { self, nixpkgs, flake-utils, flake-compat }: 
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
        qtCustomPlot = fetchurl {
          src = "https://www.qcustomplot.com/release/2.1.1/QCustomPlot-sharedlib.tar.gz"
        };
        baseDependencies = with pkgs; [
          movit
          qt5
          libmicrohttpd
          x264.dev
          ffmpeg.dev
          mesa.dev
          luajit
          sqlite.dev
          zita-resampler
          libjpeg.dev
          protobuf
          meson
          libcef
        ];
        nageru = (with pkgs; stdenv.mkDerivation {
          pname = "nageru";
          version = "2.2.3-dev";
          src = fetchgit {
            url = "http://git.sesse.net/nageru";
            rev = "1ea13d66da4aca375505b550bd207ad1c14d298f";
            sha256 = "";
          };
          buildInputs = [
            baseDependencies
            qtCustomPlot
            libzita-resampler
          ];
          nativeBuildInputs = [
            autoPatchelfHook
          ];
          buildPhase = "meson obj && cd obj && ninja";
          installFlags = [ 
            "PREFIX=$(out)"
          ];
#          installPhase = "";
        }
      );
      in rec {
        apps.default = flake-utils.lib.mkApp {
          drv = packages.default;
        };
        packages.default = nageru;
        devShells.default = pkgs.mkShell {
          buildInputs = [
            baseDependencies
          ];
        };
      }
    );
}
