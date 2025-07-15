# Nixible

[![built with nix](https://img.shields.io/static/v1?logo=nixos&logoColor=white&label=&message=Built%20with%20Nix&color=41439a)](https://builtwithnix.org)
[![pipeline status](https://gitlab.com/TECHNOFAB/nixible/badges/main/pipeline.svg)](https://gitlab.com/TECHNOFAB/nixible/-/commits/main)
![License: MIT](https://img.shields.io/gitlab/license/technofab/nixible)
[![Latest Release](https://gitlab.com/TECHNOFAB/nixible/-/badges/release.svg)](https://gitlab.com/TECHNOFAB/nixible/-/releases)
[![Support me](https://img.shields.io/badge/Support-me-black)](https://tec.tf/#support)
[![Docs](https://img.shields.io/badge/Read-Docs-black)](https://nixible.projects.tf)

A Nix-based tool for managing Ansible playbooks with type safety and reproducibility.

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

## Documentation

Check the [docs](https://nixible.projects.tf).
