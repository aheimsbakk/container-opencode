---
topic: "ocl libvirt SSH keys must be restricted in authorized_keys"
importance: high
category: warning
tags: [ssh, libvirt, virsh, security, ocl]
created: 2026-11-20T22:22:12Z
model: kompis/qwen3.8-flash-next-iq3_s
---

When documenting or setting up the `ocl` (libvirt) container, the container SSH key
added to the host's `~/.ssh/authorized_keys` must carry the options
`restrict,command="/usr/bin/virt-ssh-helper qemu:///session"` before the key type,
so a leaked key cannot open a host shell. `/usr/bin/virt-ssh-helper` is the Fedora
path (package `libvirt-daemon-common`); verify elsewhere with `command -v virt-ssh-helper`.
Never paste real key material in docs — mask key bodies with placeholders.
