## XMRig Ubuntu 24.04 CUDA Docker

### Overview
Run the latest XMRig in Docker with CUDA support on Ubuntu 24.04.

### Why
- [Metal3D XMRig Docker](https://github.com/metal3d/docker-xmrig): great project, but didn’t work for my RTX 5090 setup.
- [XMRig CUDA Binary](https://xmrig.com/download/cuda): expects you to manually build the CUDA plugin; docs are sparse.
- No easy way to live-switch to newer versions by bumping version numbers.

So I made this.

### Usage
- Clone the repo
- Run: `./xmrig-docker.sh <arguments>`

Arguments are passed directly to XMRig. If no arguments are provided, the default will be used:

```bash
--donate-level 50 --cuda -o pool.supportxmr.com:443 -u 857wrDAs1cf2K6iekP3JuWeCAzCLbC8U6DJE7osGhZ8UVBqzCNa6Cu9iiNsH4MaUvje56yaT851rihEWvGuvcpqrGoXhRQB -k --tls -p xmrig-docker
```

Default splits any harvest between supportxmr and myself.

### Environment Values

- CUDA_VERSION: Specify a cuda version to use, if left blank will attempt auto-detect
- XMRIG_VERSION: Specify XMRig version to use, default 6.24.0 (latest 9/2025)
- XMRIG_CUDA_VERSION: Specify XMRig Cuda version to use, default 6.22.1 (latest 9/2025)

### License

This project is released under the Unlicense (public domain). See `LICENSE`.