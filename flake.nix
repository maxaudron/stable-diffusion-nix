{
  nixConfig = {
    substituters = [
      "https://cache.nixos.org/"
      "https://nix-community.cachix.org"
      "https://cuda-maintainers.cachix.org"
      "https://nix.cache.vapor.systems"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
      "nix.cache.vapor.systems-1:OjV+eZuOK+im1n8tuwHdT+9hkQVoJORdX96FvWcMABk="
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
    utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
              cudaSupport = true;
            };
          };

          inherit (poetry2nix.legacyPackages.${system}) mkPoetryApplication defaultPoetryOverrides;

          overrides = import ./overrides.nix {
            inherit pkgs;
            inherit (nixpkgs) lib;
          };

          userDir = "$HOME/stable-diffusion";
        in
        {
          packages = {
            automatic1111 =
              let
                packages = import ./automatic1111/packages.nix {
                  inherit (nixpkgs) lib;
                  inherit pkgs;
                };

                outDir = "$out/${pkgs.python310Packages.python.sitePackages}";
              in
              mkPoetryApplication {
                projectDir = ./automatic1111;
                src = automatic1111;
                python = pkgs.python310;
                pyproject = ./automatic1111/pyproject.toml;
                poetrylock = ./automatic1111/poetry.lock;
                preferWheels = true;

                dontUseWheelUnpack = true;

                # patchFlags = [
                #   "--strip=1"
                #   "--binary"
                # ];
                # patches = [
                #   ./automatic1111/gradio_file_directories.patch
                # ];

                postPatch = ''
                  sed -i 's/stored_commit_hash = None/stored_commit_hash = "${automatic1111.shortRev}"/' launch.py
                '';

                nativeBuildInputs = [
                  pkgs.autoPatchelfHook
                ];

                preBuild = ''
                  cp ${./automatic1111/pyproject.toml} ./pyproject.toml
                  cp ${./automatic1111/poetry.lock} ./poetry.lock
                '';

                pipInstallFlags = "--no-deps";

                postInstall = ''
                  mkdir -p ${outDir}/localizations

                  mkdir -p ${outDir}/repositories/BLIP
                  mkdir -p ${outDir}/repositories/CodeFormer
                  mkdir -p ${outDir}/repositories/k-diffusion
                  mkdir -p ${outDir}/repositories/taming-transformers
                  mkdir -p ${outDir}/repositories/stable-diffusion-stability-ai

                  cp -r ${packages.BLIP}/* ${outDir}/repositories/BLIP/
                  cp -r ${packages.CodeFormer}/* ${outDir}/repositories/CodeFormer/
                  cp -r ${packages.k-diffusion}/* ${outDir}/repositories/k-diffusion/
                  cp -r ${packages.taming-transformers}/* ${outDir}/repositories/taming-transformers/
                  cp -r ${packages.stable-diffusion}/* ${outDir}/repositories/stable-diffusion-stability-ai/

                  chmod +w -R ${outDir}/repositories

                  pushd ${outDir}/repositories/CodeFormer
                  patch --strip=1 < ${./automatic1111/codeformer_weights_dir.patch}
                  popd
                '';

                overrides = [ overrides defaultPoetryOverrides ];
              };

            invoke-ai = mkPoetryApplication {
              projectDir = ./invoke-ai;
              src = invokeai;
              python = pkgs.python310;
              pyproject = ./invoke-ai/pyproject.toml;
              poetrylock = ./invoke-ai/poetry.lock;
              preferWheels = true;

              patches = [ ./invoke-ai/pyreadline3.patch ];

              dontUseWheelUnpack = true;

              overrides = [ overridesdefaultPoetryOverrides ];
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

            automatic1111 = {
              type = "app";
              program = "${pkgs.buildFHSUserEnv {
                name = "automatic1111-fhs";
                targetPkgs = pkgs: (with pkgs; [
                  cudatoolkit
                  cudaPackages.cudnn
                ]);
                runScript = "${pkgs.writeShellScriptBin "run.sh" ''
                  export CODEFORMER_WEIGHTS="${userDir}/models/Codeformer"

                  [ ! -d "${userDir}/outputs" ] && mkdir -p "${userDir}/outputs"
                  [ ! -d "${userDir}/configs" ] && mkdir -p "${userDir}/configs"
                  [ ! -d "${userDir}/extensions" ] && mkdir -p "${userDir}/extensions"
                  [ ! -d "${userDir}/embeddings" ] && mkdir -p "${userDir}/embeddings"

                  [ ! -d "${userDir}/models/VAE" ] && mkdir -p "${userDir}/models/VAE"
                  [ ! -d "${userDir}/models/VAE-approx" ] && mkdir -p "${userDir}/models/VAE-approx"

                  if [ ! -f "${userDir}/models/VAE-approx/model.pt" ]; then
                    cp "${automatic1111}/models/VAE-approx/model.pt" "${userDir}/models/VAE-approx/model.pt"
                  fi

                  cd ${self.packages.${system}.automatic1111}/${pkgs.python310Packages.python.sitePackages}

                  ${self.packages.${system}.automatic1111}/bin/run \
                    --data-dir=${userDir} \
                    --ui-config-file=${userDir}/configs/ui_config.json \
                    --ui-settings-file=${userDir}/configs/ui_settings.json \
                    --disable-console-progressbars \
                    --xformers \
                    $@
                ''}/bin/run.sh";
              }}/bin/automatic1111-fhs";
            };
          };

          devShells.default = pkgs.mkShell {
            buildInputs = [ pkgs.poetry ];
          };
        });
}
