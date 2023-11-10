{
  # A "type" representing the method that a registry is specified in a
  # spago.yaml file.
  registrySpecified = {
    registryVersion = 0;
    remoteURLHash = 1;
    localFile = 2;
  };

  # A "type" representing the style of registry.
  registry = {
    modern = 0;
    legacy = 1;
  };

  # A "type" representing the style of registry entry.
  registryEntry = {
    modern = 0;
    remoteGit = 1;
    legacy = 2;
  };

  # A "type" representing the method used to build a .spago
  # directory.
  buildMethod = {
    spago = 0;
    spagoLock = 1;
  };
}
