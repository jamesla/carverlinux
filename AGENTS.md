# Carverlinux Agent Guidelines

## Build Commands
- `make build` - Build system image from macOS
- `make rebuild` - Rebuild system from NixOS  
- `make run` - Run carverlinux VM
- `make clean` - Clean nix garbage
- `make update` - Update flake lock file
- `make test` - Test CI validation workflows
- `make validate` - Run CI validation checks locally

## Code Style Guidelines
- Use Nix functional style with proper indentation (2 spaces)
- Follow NixOS module patterns with imports and config sections
- Use descriptive variable names (snake_case for packages, camelCase for functions)
- Keep configuration modular - separate concerns into individual .nix files
- Use overlays for package customization
- Include proper SHA256 hashes for fetchurl
- Use `inherit` for passing arguments between modules
- Maintain consistent ordering: inputs, overlays, pkgs, configurations
- Use comments sparingly - Nix should be self-documenting
- Follow Nixpkgs conventions for package definitions