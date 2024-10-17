# ROCm

ROCm container for linux

> [!NOTE]
> More than 30GB when built. So you have to build it locally as it would not fit a regular runner.
> Hence why there is no built package in the repo.
> This container image could be considered bloated, but it should not miss anything in it.
> If you have access to larger github runners the `publish.yaml` is functional with a few simple modifications like the `runs-on:`.
> It works right now, but it runs out of space.
> You would also need to generate a new key pair with `skopeo` and add a new github secret with the private key to the repo or remove signing altogether.

## Building

Minimal build command

```shell
podman build --tag=localhost/rocm:latest rocm.Containerfile .
```

## Running

Example run command

```shell
podman --runtime=/usr/bin/crun run \
    --env=PYTORCH_HIP_ALLOC_CONF=backend:native,max_split_size_mb:128,expandable_segments:False,garbage_collection_threshold:0.5 \
    --rm \
    --interactive \
    --tty \
    --group-add=keep-groups \
    --device=/dev/dri:rwm \
    --device=/dev/kfd:rwm \
    localhost/rocm:latest
```

`--env=PYTORCH_HIP_ALLOC_CONF=...`

Pytorch settings that will reduce the amount of crashes with big AI models.
[More info](https://pytorch.org/docs/stable/notes/cuda.html)

`--env=HSA_OVERRIDE_GFX_VERSION=10.3.0`

This specific to your gpu and only necessary for older gpus (6700XT and under I believe).

`-runtime=/usr/bin/crun` `--group-add=keep-groups` `--device=/dev/dri:rwm` `--device=/dev/kfd:rwm`

Required device permissions.
You will need to add yourself in the `video` and `render` groups on your host machine and create them if they don't exist.
If SELinux is running on your host machine, you will need to enable the `container_use_devices` boolean for rootless containers.

`--ipc=host` `--cap-add=SYS_PTRACE`

AMD documentation specifies to use these, but I have never needed them for any AI applications.

> [!NOTE]
> This command will only bring up a ROCMm container bash command line interface.
> You will need to attach a `--volume=` and run a custom `entrypoint.sh` to make it useful.
