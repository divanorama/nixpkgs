{ stdenv
, fetchFromGitHub
, autoreconfHook, zlib, gmock, buildPackages
, version, sha256, dependencies-sha256
, maven, protobuf
, ...
}:

let
mkProtobufDerivation = stdenv: stdenv.mkDerivation rec {
  pname = "protobuf-java";
  inherit version;

  # make sure you test also -A pythonPackages.protobuf
  src = fetchFromGitHub {
    owner = "protocolbuffers";
    repo = "protobuf";
    rev = "v${version}";
    inherit sha256;
  };
  mavenFlags = "-Dprotoc2=${protobuf}/bin/protoc -DskipTests -pl core,util,lite";
  fetched-maven-deps = stdenv.mkDerivation {
    name = "hadoop-${version}-maven-deps";
    inherit src patches postPatch nativeBuildInputs buildInputs;
    buildPhase = ''
      cd java
      while mvn package -Dmaven.repo.local=$out/.m2 -Dmaven.wagon.rto=5000 ${mavenFlags}; [ $? = 1 ]; do
        echo "timeout, restart maven to continue downloading"
      done
    '';
    # keep only *.{pom,jar,xml,sha1,so,dll,dylib} and delete all ephemeral files with lastModified timestamps inside
    installPhase = ''find $out/.m2 -type f -regex '.+\(\.lastUpdated\|resolver-status\.properties\|_remote\.repositories\)' -delete'';
    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
    outputHash = dependencies-sha256;
  };

  # mvn -Dprotoc= doesn't override ant runner plugin vars
  patches = [ ./protoc-java.patch ];

  postPatch = ''
    rm -rf gmock
    cp -r ${gmock.src}/googlemock gmock
    cp -r ${gmock.src}/googletest googletest
    chmod -R a+w gmock
    chmod -R a+w googletest
    ln -s ../googletest gmock/gtest
  '' + stdenv.lib.optionalString stdenv.isDarwin ''
    substituteInPlace src/google/protobuf/testing/googletest.cc \
      --replace 'tmpnam(b)' '"'$TMPDIR'/foo"'
  '';

  buildPhase = ''
    cd java
    mkdir $TMPDIR/.m2
    cp -dpR ${fetched-maven-deps}/.m2 $TMPDIR/
    chmod +w -R $TMPDIR/.m2
    mvn --offline -Dmaven.repo.local=$TMPDIR/.m2 ${mavenFlags} package
  '';
  installPhase = ''
    mkdir $out
     find . -name "*.jar" -exec cp '{}' $out/ \;
  '';

  nativeBuildInputs = [ maven protobuf ];

  buildInputs = [ zlib ];

  enableParallelBuilding = true;

  doCheck = true;

  dontDisableStatic = true;

  meta = {
    description = "Google's data interchange format";
    longDescription =
      ''Protocol Buffers are a way of encoding structured data in an efficient
        yet extensible format. Google uses Protocol Buffers for almost all of
        its internal RPC protocols and file formats.
      '';
    license = stdenv.lib.licenses.bsd3;
    platforms = stdenv.lib.platforms.unix;
    homepage = "https://developers.google.com/protocol-buffers/";
  };

  passthru.version = version;
};
in mkProtobufDerivation stdenv
