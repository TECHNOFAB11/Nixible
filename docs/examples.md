# Examples

See the `examples` directory in the repo.

## Task Examples

### File Operations

```nix
{
  name = "Create configuration";
  template = {
    src = "nginx.conf.j2";
    dest = "/etc/nginx/nginx.conf";
    backup = true;
  };
  notify = "restart nginx";
}
```

### Service Management

```nix
{
  name = "Start services";
  service = {
    name = "{{ item }}";
    state = "started";
    enabled = true;
  };
  loop = ["nginx" "postgresql"];
}
```

### Conditional Tasks

```nix
{
  name = "Install SSL certificate";
  copy = {
    src = "ssl/cert.pem";
    dest = "/etc/ssl/certs/";
  };
  when = "ssl_enabled | default(false)";
}
```

### Block Tasks

```nix
{
  block = [
    {
      name = "Create user";
      user = {
        name = "deploy";
        state = "present";
      };
    }
    {
      name = "Set up SSH key";
      authorized_key = {
        user = "deploy";
        key = "{{ ssh_public_key }}";
      };
    }
  ];
  rescue = [
    {
      name = "Log error";
      debug.msg = "Failed to create user";
    }
  ];
  always = [
    {
      name = "Cleanup";
      file = {
        path = "/tmp/setup";
        state = "absent";
      };
    }
  ];
}
```
