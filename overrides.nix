{ pkgs, lib, ... }:

let
  addNvidia = self: super: packages: (lib.listToAttrs (map
    (pkg: {
      name = pkg;
      value = super.${pkg}.overridePythonAttrs (attrs: {
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
  "torchvision"
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
]) // {
  wheel = super.wheel.override { preferWheel = false; };

  clipseg = super.clipseg.overridePythonAttrs (old: {
    buildInputs = (old.buildInputs or [ ]) ++ (with super; [
      setuptools
    ]);
    propagatedBuildInputs = (old.propagatedBuildInputs or [ ]) ++ (with self; [
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

  clip = super.clip.overridePythonAttrs (old: {
    buildInputs = (old.buildInputs or [ ]) ++ (with super; [
      setuptools
    ]);
    propagatedBuildInputs = (old.propagatedBuildInputs or [ ]) ++ (with self; [
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
    propagatedBuildInputs = (attrs.propagatedBuildInputs or [ ]) ++ (with super; [
      cython

      self.nvidia-cudnn-cu11
      self.nvidia-cuda-nvrtc-cu11
      self.nvidia-cuda-runtime-cu11
    ]);
  });

  pypatchmatch = super.pypatchmatch.overridePythonAttrs (old: {
    buildInputs = (old.buildInputs or [ ]) ++ (with super; [
      setuptools
    ]);
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

  numba = super.numba.overridePythonAttrs (attrs: {
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
    propagatedBuildInputs = (attrs.propagatedBuildInputs or [ ]) ++ (with super; [
      opencv-python-headless
    ]);
  });

  albumentations = super.albumentations.overridePythonAttrs (attrs: {
    propagatedBuildInputs = (attrs.propagatedBuildInputs or [ ]) ++ (with super; [
      opencv-python-headless
    ]);
  });

  llvmlite = super.llvmlite.override {
    preferWheel = false;
  };

  nvidia-cudnn-cu11 = super.nvidia-cudnn-cu11.overridePythonAttrs (attrs: {
    nativeBuildInputs = attrs.nativeBuildInputs or [ ] ++ [ pkgs.autoPatchelfHook ];
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

  torch = super.torch.overridePythonAttrs (attrs: {
    nativeBuildInputs = attrs.nativeBuildInputs or [ ] ++ [
      pkgs.autoPatchelfHook
      pkgs.cudaPackages.autoAddOpenGLRunpathHook
    ];
    buildInputs = attrs.buildInputs or [ ] ++ [
      self.nvidia-cudnn-cu11
      self.nvidia-cuda-nvrtc-cu11
      self.nvidia-cuda-runtime-cu11
    ];
    propagatedBuildInputs = attrs.propagatedBuildInputs or [ ] ++ [
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
