{ pkgs, lib, ... }:

let
  addNvidia = self: super: packages: (lib.listToAttrs (map
    (pkg: {
      name = pkg;
      value = super.${pkg}.overridePythonAttrs (attrs: {
        buildInputs = (attrs.buildInputs or [ ]) ++ (with super; [
          setuptools
        ]);

        propagatedBuildInputs = (attrs.propagatedBuildInputs or [ ]) ++ (with super; [
          self.nvidia-cudnn-cu11
          self.nvidia-cuda-nvrtc-cu11
          self.nvidia-cuda-runtime-cu11
        ]);
      });
    })
    packages));
in
self: super: (addNvidia self super [
  "kornia"
  "accelerate"
  "torchmetrics"
  "torch-fidelity"
  "taming-transformers-rom1504"
  "facexlib"
  "gfpgan"
  "realesrgan"
  "clean-fid"
  "torchdiffeq"
  "torchsde"
  "clip-anytorch"
  "k-diffusion"
  "fairscale"
  "timm"
  "lpips"
  "invisible-watermark"
  "stable-diffusion"
  "taming-transformers"
  "open-clip-torch"
  "triton"
]) // {
  wheel = super.wheel.override { preferWheel = false; };

  gradio = (super.gradio.override { preferWheel = true; }).overridePythonAttrs (attrs: {
    buildInputs = (attrs.buildInputs or [ ]) ++ (with super; [
      setuptools
      pip
    ]);

    # installPhase = ''
    #   echo "Executing pipInstallPhase"

    #   mkdir -p "$out/${self.python.sitePackages}"
    #   export PYTHONPATH="$out/${self.python.sitePackages}:$PYTHONPATH"

    #   pushd dist || return 1
    #   ${super.pip}/bin/pip install ./*.whl --no-index --no-warn-script-location --prefix="$out" --no-cache --no-deps
    #   popd || return 1

    #   echo "Finished executing pipInstallPhase"
    # '';
  });

  lit = super.lit.overridePythonAttrs (attrs: {
    buildInputs = (attrs.buildInputs or [ ]) ++ (with super; [
      setuptools
    ]);
  });

  font-roboto = super.font-roboto.overridePythonAttrs (attrs: {
    buildInputs = (attrs.buildInputs or [ ]) ++ (with super; [
      setuptools
    ]);
  });

  ffmpy = super.ffmpy.overridePythonAttrs (attrs: {
    buildInputs = (attrs.buildInputs or [ ]) ++ (with super; [
      setuptools
    ]);
  });

  mdit-py-plugins = super.mdit-py-plugins.overridePythonAttrs (attrs: {
    pipInstallFlags = "--no-deps";
    propagatedBuildInputs = [ ];
  });

  blendmodes = super.blendmodes.overridePythonAttrs (attrs: {
    buildInputs = (attrs.buildInputs or [ ]) ++ (with super; [
      poetry
    ]);
  });

  orjson = pkgs.python310Packages.orjson;
  pybind11 = pkgs.python310Packages.pybind11;

  xformers = (super.xformers.override {
    preferWheel = true;
  }).overridePythonAttrs (attrs: rec {
    autoPatchelfIgnoreMissingDeps = [
      "libcudart.so.11.0"
    ];

    nativeBuildInputs = (attrs.nativeBuildInputs or [ ]) ++ (with pkgs; [
      autoPatchelfHook
      cudaPackages.autoAddOpenGLRunpathHook
      cudatoolkit
    ]);

    propagatedBuildInputs = (attrs.propagatedBuildInputs or [ ]) ++ (with self; [
      nvidia-cudnn-cu11
      nvidia-cuda-nvrtc-cu11
      nvidia-cuda-runtime-cu11

      torch
      numpy
    ]);

    postInstall = ''
      addAutoPatchelfSearchPath "${self.nvidia-cublas-cu11}/${self.python.sitePackages}/nvidia/cublas/lib"
      addAutoPatchelfSearchPath "${self.nvidia-cudnn-cu11}/${self.python.sitePackages}/nvidia/cudnn/lib"
      addAutoPatchelfSearchPath "${self.nvidia-cuda-nvrtc-cu11}/${self.python.sitePackages}/nvidia/cuda_nvrtc/lib"
      addAutoPatchelfSearchPath "${self.torch}/${self.python.sitePackages}/torch/lib"
    '';
  });

  clipseg = super.clipseg.overridePythonAttrs (attrs: {
    buildInputs = (attrs.buildInputs or [ ]) ++ (with super; [
      setuptools
    ]);

    propagatedBuildInputs = (attrs.propagatedBuildInputs or [ ]) ++ (with self; [
      numpy
      scipy
      torch
      torchvision
      matplotlib
      opencv-python
      regex
      ftfy
      tqdm

      nvidia-cudnn-cu11
      nvidia-cuda-nvrtc-cu11
      nvidia-cuda-runtime-cu11
    ]);
  });

  clip = super.clip.overridePythonAttrs (attrs: {
    buildInputs = (attrs.buildInputs or [ ]) ++ (with super; [
      setuptools
    ]);

    propagatedBuildInputs = (attrs.propagatedBuildInputs or [ ]) ++ (with self; [
      ftfy
      regex
      tqdm
      torch
      torchvision

      nvidia-cudnn-cu11
      nvidia-cuda-nvrtc-cu11
      nvidia-cuda-runtime-cu11
    ]);
  });

  basicsr = super.basicsr.overridePythonAttrs (attrs: {
    propagatedBuildInputs = (attrs.propagatedBuildInputs or [ ]) ++ (with self; [
      cython

      nvidia-cudnn-cu11
      nvidia-cuda-nvrtc-cu11
      nvidia-cuda-runtime-cu11
    ]);
  });

  pypatchmatch = (super.pypatchmatch.override { preferWheel = false; }).overridePythonAttrs (attrs: {
    buildInputs = (attrs.buildInputs or [ ]) ++ (with super; [
      setuptools
      self.opencv-python
      pkgs.opencv
    ]);

    nativeBuildInputs = (attrs.nativeBuildInputs or [ ]) ++ (with super; [
      pkgs.pkg-config
    ]);

    preBuild = ''
      pushd patchmatch
      export NIX_CFLAGS_COMPILE="$NIX_CFLAGS_COMPILE -isystem ${pkgs.opencv}/include/opencv4 -Wl,-z,defs"
      make
      popd
    '';

    postInstall = ''
      cp patchmatch/libpatchmatch.so $out/${self.python.sitePackages}/patchmatch/
    '';

    preFixup = let
      # we prepare our library path in the let clause to avoid it become part of the input of mkDerivation
      libPath = lib.makeLibraryPath [
        pkgs.opencv
        pkgs.stdenv.cc.cc.lib
      ];
    in ''
      patchelf \
        --set-rpath "${libPath}" \
        $out/${self.python.sitePackages}/patchmatch/libpatchmatch.so
    '';

  });

  pytorch-lightning = (super.pytorch-lightning.override {
    preferWheel = false;
  }).overridePythonAttrs (attrs: {
    configurePhase = ''
      # rm -rf .
      tar --strip-components=1 -xvf $src
    '';

    propagatedBuildInputs = attrs.propagatedBuildInputs or [ ] ++ [
      self.nvidia-cudnn-cu11
      self.nvidia-cuda-nvrtc-cu11
      self.nvidia-cuda-runtime-cu11
    ];
  });

  numba = (super.numba.override { preferWheel = true; }).overridePythonAttrs (attrs: {
    autoPatchelfIgnoreMissingDeps = true;
  });

  test-tube = super.test-tube.overridePythonAttrs (attrs: {
    preferWheel = false;

    propagatedBuildInputs = attrs.propagatedBuildInputs or [ ] ++ [
      self.nvidia-cudnn-cu11
      self.nvidia-cuda-nvrtc-cu11
      self.nvidia-cuda-runtime-cu11
    ];

    preBuild = ''
      tar --strip-components=1 -xvf $src
    '';
  });

  qudida = super.qudida.overridePythonAttrs (attrs: {
    # propagatedBuildInputs = (attrs.propagatedBuildInputs or [ ]) ++ (with super; [
    #   opencv-python-headless
    # ]);
  });

  albumentations = super.albumentations.overridePythonAttrs (attrs: {
    # propagatedBuildInputs = (attrs.propagatedBuildInputs or [ ]) ++ (with super; [
    #   opencv-python-headless
    # ]);
  });

  llvmlite = super.llvmlite.override {
    preferWheel = false;
  };

  nvidia-cudnn-cu11 = super.nvidia-cudnn-cu11.overridePythonAttrs (attrs: {
    nativeBuildInputs = (attrs.nativeBuildInputs or [ ]) ++ [
      pkgs.autoPatchelfHook
    ];

    preFixup = ''
      addAutoPatchelfSearchPath "${self.nvidia-cublas-cu11}/${self.python.sitePackages}/nvidia/cublas/lib"
    '';

    postFixup = ''
      rm -r $out/${self.python.sitePackages}/nvidia/{__pycache__,__init__.py}
    '';

    propagatedBuildInputs = attrs.propagatedBuildInputs or [ ] ++ [
      self.nvidia-cublas-cu11
    ];
  });

  nvidia-cuda-nvrtc-cu11 = super.nvidia-cuda-nvrtc-cu11.overridePythonAttrs (_: {
    postFixup = ''
      rm -r $out/${self.python.sitePackages}/nvidia/{__pycache__,__init__.py}
    '';
  });

  torch = (super.torch.override {
    enableCuda = true;
    cudatoolkit = pkgs.cudatoolkit;
    preferWheel = false;
  }).overridePythonAttrs (attrs: {
    nativeBuildInputs = (attrs.nativeBuildInputs or [ ]) ++ [
      pkgs.autoPatchelfHook
      pkgs.cudaPackages.autoAddOpenGLRunpathHook
    ];

    buildInputs = (attrs.buildInputs or [ ]) ++ [
      self.nvidia-cudnn-cu11
      self.nvidia-cuda-nvrtc-cu11
      self.nvidia-cuda-runtime-cu11
    ];

    postInstall = ''
      addAutoPatchelfSearchPath "${self.nvidia-cublas-cu11}/${self.python.sitePackages}/nvidia/cublas/lib"
      addAutoPatchelfSearchPath "${self.nvidia-cudnn-cu11}/${self.python.sitePackages}/nvidia/cudnn/lib"
      addAutoPatchelfSearchPath "${self.nvidia-cuda-nvrtc-cu11}/${self.python.sitePackages}/nvidia/cuda_nvrtc/lib"
    '';
  });

  torchvision = (super.torchvision.override {
    enableCuda = true;
    cudatoolkit = pkgs.cudatoolkit;
    preferWheel = false;
  }).overridePythonAttrs (attrs: {
    nativeBuildInputs = (attrs.nativeBuildInputs or [ ]) ++ [
      pkgs.autoPatchelfHook
      pkgs.cudaPackages.autoAddOpenGLRunpathHook
    ];

    buildInputs = (attrs.buildInputs or [ ]) ++ [
      self.nvidia-cudnn-cu11
      self.nvidia-cuda-nvrtc-cu11
      self.nvidia-cuda-runtime-cu11
    ];

    postInstall = ''
      addAutoPatchelfSearchPath "${self.nvidia-cublas-cu11}/${self.python.sitePackages}/nvidia/cublas/lib"
      addAutoPatchelfSearchPath "${self.nvidia-cudnn-cu11}/${self.python.sitePackages}/nvidia/cudnn/lib"
      addAutoPatchelfSearchPath "${self.nvidia-cuda-nvrtc-cu11}/${self.python.sitePackages}/nvidia/cuda_nvrtc/lib"
    '';
  });
}
