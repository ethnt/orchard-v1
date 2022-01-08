{ lib, buildGoModule, fetchFromGitHub }:

buildGoModule rec {
  pname = "blocky";
  version = "0.16";

  src = fetchFromGitHub {
    owner = "0xERR0R";
    repo = "blocky";
    rev = "v${version}";
    sha256 = "049cawkhs7jh54ppbmk97rjd9x02h0lyjikiqlh8a4y7p50s407c";
  };

  vendorSha256 = "02dbhqnd0j4853lyy35j9zj5rvlkdap6dm59c626zy9j6ym95zzc";

  proxyVendor = true;

  doCheck = false;

  ldflags = "-w -s -X github.com/0xERR0R/blocky/util.Version=${version}";
}
