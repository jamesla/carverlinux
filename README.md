# Carverlinux

## Getting started

1. Ensure darwin-nix is installed

2. Configure darwin linux builder (ensure following snippet is added to your darwin-configuration.nix)
```nix
...
nix.linux-builder = {
  enable = true;
  ephemeral = true;
  maxJobs = 4;
  config = {
    virtualisation = {
      darwin-builder = {
        diskSize = 200 * 1024;
        memorySize = 8 * 1024;
      };
      cores = 6;
    };
  };
};

nix.settings.trusted-users = [ "@admin" ];
...
```

3. Build builder
```bash
darwin-rebuild switch
```

4. Provision vm
```bash
make provision
```

5. Can rebuild vm from inside itself with
```bash
make rebuild
```
