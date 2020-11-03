{ callPackage, protobuf, ... }:

callPackage ./java-v3.nix {
  version = "3.13.0";
  sha256 = "1nqsvi2yfr93kiwlinz8z7c68ilg1j75b2vcpzxzvripxx5h6xhd";
  dependencies-sha256 = "15is15qxsfax5cq3wii32rx3cr223jfrq6w9kql47mkg58sjjy5n";
  inherit protobuf;
}
