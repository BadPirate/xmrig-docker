## XMRig Ubuntu 24.04 CUDA Docker

### Overview
Run the latest XMRig in Docker with CUDA support on Ubuntu 24.04.

### Why
- [Metal3D XMRig Docker](https://github.com/metal3d/docker-xmrig): great project, but didn’t work for my RTX 5090 setup.
- [XMRig CUDA Binary](https://xmrig.com/download/cuda): expects you to manually build the CUDA plugin; docs are sparse.
- No easy way to live-switch to newer versions by bumping version numbers.

So I made this.

### Usage

#### Clone

- Clone the repo
- Run: `./xmrig-docker.sh <arguments>`

#### Run directly

Note: CUDA_VERSION=12.9.0 for prebuilt, for a different version / automatic detection use clone

- Run: `docker run --rm -it --privileged --security-opt seccomp=unconfined --security-opt apparmor=unconfined --gpus all ghcr.io/badpirate/xmrig-docker:latest <arguments>`

#### Arguments

Arguments are passed directly to XMRig. If no arguments are provided, the default will be used:

```bash
--donate-level 50 --cuda -o pool.supportxmr.com:443 -u 857wrDAs1cf2K6iekP3JuWeCAzCLbC8U6DJE7osGhZ8UVBqzCNa6Cu9iiNsH4MaUvje56yaT851rihEWvGuvcpqrGoXhRQB -k --tls -p xmrig-docker
```

Default splits any harvest between supportxmr and myself.

### Environment Values

Set these values before building / running 

- CUDA_VERSION: Specify a cuda version to use, if left blank will attempt auto-detect
- XMRIG_VERSION: Specify XMRig version to use, default 6.24.0 (latest 9/2025)
- XMRIG_CUDA_VERSION: Specify XMRig Cuda version to use, default 6.22.1 (latest 9/2025)

### Worth it?

Depends a lot on your hardware, home CPU mining ([at least for my napkin math and testing](benchmarks.md)) isn't profitable unless your electric rates are less than 0.11 kWH, and GPU mining isn't profitable unless your electricity is less than 0.01 kWH -- And that is assuming your equipment is free. That being said, mining does help improve transaction speeds as well as helps avoid the very real threat of 51% [takeover](https://www.google.com/url?sa=t&source=web&rct=j&opi=89978449&url=https://www.coindesk.com/business/2025/08/12/monero-s-51-attack-problem-inside-qubic-s-controversial-network-takeover&ved=2ahUKEwjhxt6c-uKPAxUTEDQIHVmhDkYQFnoECBgQAQ&usg=AOvVaw0UtglHtaRMl2mPVeMjsnK3) plaguing the XMR coin at the moment. And the electricity isn't wasted if you are using it to heat your space :) 

### License

This project is released under the Unlicense (public domain). See `LICENSE`.