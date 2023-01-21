{ lib, pkgs, ... }:

{
  BLIP = pkgs.fetchgit {
    url = "https://github.com/salesforce/BLIP.git";
    rev = "48211a1594f1321b00f14c9f7a5b4813144b2fb9";
    sha256 = "sha256-0IO+3M/Gy4VrNBFYYgZB2CzWhT3PTGBXNKPad61px5k=";
  };

  CodeFormer = pkgs.fetchgit {
    url = "https://github.com/sczhou/CodeFormer.git";
    rev = "c5b4593074ba6214284d6acd5f1719b6c5d739af";
    sha256 = "sha256-JyyJe+VBeNK5rRaPJ4jYdKZqLnRfayHWkTwFNrSfseY=";
  };

  k-diffusion = pkgs.fetchgit {
    url = "https://github.com/Birch-san/k-diffusion.git";
    rev = "5b3af030dd83e0297272d861c19477735d0317ec";
    sha256 = "sha256-lnjYsMVjL6rVbWVvAjVQRcK3CSs2CGOEsN3nw6pS3rk=";
  };

  taming-transformers = pkgs.fetchgit {
    url = "https://github.com/CompVis/taming-transformers.git";
    rev = "24268930bf1dce879235a7fddd0b2355b84d7ea6";
    sha256 = "sha256-kDChiuNh/lYO4M1Vj7fW3130kNl5wh+Os4MPBcaw1tM=";
  };

  stable-diffusion = pkgs.fetchgit {
    url = "https://github.com/Stability-AI/stablediffusion.git";
    rev = "47b6b607fdd31875c9279cd2f4f16b92e4ea958e";
    sha256 = "sha256-F0B6h/+Ji/E821KyylcLQb2e8W4LctByGMa88feADtU=";
  };
}
