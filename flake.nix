{
  nixConfig = {
    substituters = [
      "https://cache.nixos.org/"
      "https://nix-community.cachix.org"
      "https://cuda-maintainers.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
    ];
  };

  inputs = {
    utils.url = "github:numtide/flake-utils";

    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "utils";
      };
    };

    invokeai = {
      url = "github:invoke-ai/InvokeAI";
      flake = false;
    };

    automatic1111 = {
      url = "github:AUTOMATIC1111/stable-diffusion-webui";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, utils, poetry2nix, invokeai, automatic1111 }:
    with nixpkgs.lib;
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            cudaSupport = true;
          };
          overlay = [ poetry2nix.overlay ];
        };

        overrides = import ./overrides.nix {
          inherit pkgs;
          inherit (nixpkgs) lib;
        };
      in
      {
        packages = {
          automatic1111 = pkgs.poetry2nix.mkPoetryApplication {
            projectDir = ./automatic1111;
            src = automatic1111;
            python = pkgs.python310;
            pyproject = ./automatic1111/pyproject.toml;
            poetrylock = ./automatic1111/poetry.lock;
            preferWheels = true;

            dontUseWheelUnpack = true;

            overrides = [ overrides pkgs.poetry2nix.defaultPoetryOverrides ];
          };
          invoke-ai = pkgs.poetry2nix.mkPoetryApplication {
            projectDir = ./invoke-ai;
            src = invokeai;
            python = pkgs.python310;
            pyproject = ./invoke-ai/pyproject.toml;
            poetrylock = ./invoke-ai/poetry.lock;
            preferWheels = true;

            patches = [ ./invoke-ai/pyreadline3.patch ];

            dontUseWheelUnpack = true;

            overrides = [ overrides pkgs.poetry2nix.defaultPoetryOverrides ];
          };
        };

        apps = {
          invoke-ai-configure = {
            type = "app";
            program = "${pkgs.writeShellScriptBin "configure.sh" ''
              cd ${invokeai}
              ${self.packages.${system}.invoke-ai}/bin/configure_invokeai.py $@
            ''}/bin/configure.sh";
          };

          invoke-ai = {
            type = "app";
            program = "${pkgs.buildFHSUserEnv {
              name = "invoke-ai-fhs";
              targetPkgs = pkgs: (with pkgs; [
                cudatoolkit
                cudaPackages.cudnn
              ]);
              runScript = "${self.packages.${system}.invoke-ai}/bin/invoke.py";
            }}/bin/invoke-ai-fhs";
          };
        };

        devShells.default = pkgs.mkShell {
          buildInputs = [ pkgs.poetry ];
        };
      });
}
