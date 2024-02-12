pkgs: let
  utils = import ./utils.nix pkgs;
in {
  cacheFromProjectDepsJson = projectDepsJson: let
    # Parse the PklProject.deps.json and validate the schema version
    lockfile = let parsed = pkgs.lib.importJSON projectDepsJson; in assert parsed.schemaVersion == 1; parsed;
    # Download a package by its url and sha256 digest, returning the name, version, path, and derivations
    # for the metadata .json and the package .zip
    downloadPackage = packageUrl: digest: let 
      path = builtins.head (pkgs.lib.lists.drop 1 (builtins.match "(project)?package://(.*)" packageUrl));
      metadata = utils.fetchurlHexDigest {
        url = "https://" + path;
        inherit digest;
      };
      metadataParsed = pkgs.lib.importJSON metadata;
      package = utils.fetchurlHexDigest {
        url = metadataParsed.packageZipUrl;
        digest = metadataParsed.packageZipChecksums.sha256;
      };
    in {
      inherit path metadata package;
      name = metadataParsed.name;
      version = metadataParsed.version;
    };
    # Build a list of all remote deps in the deps file
    packages = builtins.map (p: downloadPackage p.uri p.checksums.sha256) (
      builtins.filter (p: p.type == "remote") (builtins.attrValues lockfile.resolvedDependencies)
    );
  in (pkgs.stdenv.mkDerivation {
    name = "pkl-cache";
    dontUnpack = true;
    # Copy all files into the the cache directory format
    buildPhase = ''
    ${
      pkgs.lib.strings.concatStringsSep "\n" (builtins.map (p: ''
        mkdir -p "$out/package-1/${p.path}"
        cp ${p.metadata} "$out/package-1/${p.path}/${p.name}@${p.version}.json"
        cp ${p.package} "$out/package-1/${p.path}/${p.name}@${p.version}.zip"
      '') packages)
    }
    '';
  });
}
