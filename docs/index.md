# Introduction

Nixible is a Nix-based tool for managing Ansible playbooks with type safety and reproducibility.

## What is Nixible?

Nixible bridges the Nix and Ansible ecosystems by allowing you to define Ansible playbooks, inventories, and collections as Nix expressions. It provides:

- **Type-safe playbook definitions** using Nix's module system
- **Reproducible Ansible environments** with locked dependencies
- **Automatic collection management** from Ansible Galaxy

## Quick Start

### 1. Define your configuration

Create a `some-playbook.nix` file:

```nix title="some-playbook.nix"
{pkgs, ...}: {
  collections = {
    "community-general" = {
      version = "8.0.0";
      hash = "sha256-...";
    };
  };
  
  inventory = {}; # can also be omitted, we only use localhost
  
  playbook = [{
    name = "Hello World";
    hosts = "localhost";
    tasks = [{
      name = "Say hello";
      debug.msg = "Hello from Nixible!";
    }];
  }];
}
```

### 2. Run with Nix

```nix title="flake.nix"
{
  inputs.nixible.url = "gitlab:TECHNOFAB/nixible?dir=lib";
  # outputs = ...
  # nixible_lib = inputs.nixible.lib { inherit pkgs lib; };
  packages.some-playbook = nixible_lib.mkNixibleCli ./some-playbook.nix;
}
```

```bash
nix run .#some-playbook
```

## Getting Started

1. **[Usage](usage.md)** - Learn how to build and run Nixible configurations
1. **[Examples](examples.md)** - See real-world usage patterns
1. **[Reference](reference.md)** - Detailed API and configuration reference
