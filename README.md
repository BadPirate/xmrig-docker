## XMRig Ubuntu 24.04 CUDA Docker

### Overview

Goal was to have something to make it easy to spin up a monero miner to help with takeovers, or mining for fun.

Full stack XMRig (Monero Mining) for headless linux server with:

- Support for CUDA / NVidia on latest cards (like Nvidia 5090)
- Support to enable huge pages
- Docker: for launching just XMRig and pointing at existing pool
- Docker Compose: For launching full stack required for p2pool, monerod, p2pool, xmrig, tor (bonus so you can reach
  monero wallet and p2pool anonymously over tor service)

### Why

- [Metal3D XMRig Docker](https://github.com/metal3d/docker-xmrig): great project, but didn’t work for my RTX 5090 setup.
- [XMRig CUDA Binary](https://xmrig.com/download/cuda): expects you to manually build the CUDA plugin; docs are sparse.
- No easy way to live-switch to newer versions by bumping version numbers.

So I made this.

### Usage

1. Install docker

#### Quick XMRig (Pre-built XMRig docker)

Launch using pre-built docker image (Trusting aren't you?), note that this will help against qbit (probably) but
contributes to whatever pool you choose instead (likely large).

`docker run --rm -it --privileged --security-opt seccomp=unconfined --security-opt apparmor=unconfined --gpus all ghcr.io/badpirate/xmrig-docker:latest <arguments>`


##### Arguments

If arguments left blank, the defaults will use supportxmr pool, give 50% to that project, and give 50% to me, will
enable cuda (wasteful compared to CPU mining, but if you just want to maximize hash rate) and huge pages. Setting any
other arguments will clear the default values in favor of your own.

`--donate-level 50 -o pool.supportxmr.com:443 -u 857wrDAs1cf2K6iekP3JuWeCAzCLbC8U6DJE7osGhZ8UVBqzCNa6Cu9iiNsH4MaUvje56yaT851rihEWvGuvcpqrGoXhRQB -k --tl -p xmrig-cuda-docker --cuda --huge-pages`

#### P2Pool docker compose full stack

Best way to contribute to concensus without allowing takeovers is to use p2pool, this requires running your own
monerod node, as well as p2pool endpoint that you point xmrig at. This docker compose flag puts all those services, as
well as a few bonus services together in a single stack.

1. Install docker compose if needed on host system
2. Download this repo using git, and cd xmrig-docker
3. Rename .env.EXAMPLE to .env and replace with your values
4. `docker compose up <services> -d`

##### Services

If left blank, will launch all services, otherwise specify services by name:

- monerod: If you already have monerod sync'd somewhere (needed for p2pool) then you can leave this off service list
  but you must set `MONEROD_HOST` `MONEROD_RPC_PORT` in .env, note if you haven't synchoronized monerod this can
  take a long time (days), and the other dependent services will time out, you'll want to run `docker compose up monerod`
  and wait for it to sync, before bringing up the larger service `docker compose up` everything.
- tor: This will create tor services for your monerod RPC and your p2pool instance (in case you want to anonymously
  use them from elsewhere), the addresses will show at the end of `docker logs tor`, leaving this off if you want to
  use locally or don't need
- p2pool: Required for the compose setup
- xmrig: Required if you want to mine, doesn't take arguments as above, but instead uses the .env values and hard code
  if you need custom arguments edit docker-compose to include those as well.

Quick start:

1. Set the following environment variables (e.g., in your shell or a `.env` next to the compose file):
   - `XMR_ADDRESS` (required for P2Pool): your Monero wallet address
   - `XMR_DONATE_LEVEL` (optional): defaults to `50` in the compose
2. Copy the example compose to your working file:
   ```bash
   cp docker-compose.example.yml docker-compose.yml
   ```
3. Ensure you have NVIDIA drivers and `nvidia-container-toolkit` installed so Compose can access your GPU.
4. Bring the stack up:
   ```bash
   docker compose up -d
   ```
5. Check logs:
   ```bash
   docker compose logs -f monerod p2pool xmrig-gpu-cpu
   ```

What the stack exposes:

- Monerod: `18080`, `18084` (ZMQ), `18089` (restricted RPC)
- P2Pool: `3333` (stratum), `37889` (p2p)
- Tor: publishes onion services for Monerod and P2Pool; data stored in `/data/tor`

Volumes (edit as needed):

- Monerod data: `/data/monerod`
- P2Pool data: `/data/p2pool`
- Hugepages: `/dev/hugepages` (passed through)

Notes:

- In this setup, XMRig does not need `-u <wallet>` because P2Pool is started with `--wallet ${XMR_ADDRESS}` and the miner connects to `p2pool:3333`.
- The XMRig service requests all GPUs via the NVIDIA runtime and runs privileged to access necessary devices.

#### Clone

- Clone the repo
- Run: `./xmrig-docker.sh <arguments>`

#### Docker

Note: CUDA_VERSION=12.9.0 for prebuilt, for a different version / automatic detection use clone

- Run: `docker run --rm -it --privileged --security-opt seccomp=unconfined --security-opt apparmor=unconfined --gpus all ghcr.io/badpirate/xmrig-docker:latest <arguments>`

#### Arguments

Arguments are passed directly to XMRig. If no arguments are provided, the default will be used:

```bash
--donate-level 50 --cuda -o pool.supportxmr.com:443 -u 857wrDAs1cf2K6iekP3JuWeCAzCLbC8U6DJE7osGhZ8UVBqzCNa6Cu9iiNsH4MaUvje56yaT851rihEWvGuvcpqrGoXhRQB -k --tls -p xmrig-docker
```

Default splits any harvest between supportxmr and myself.

### Optional ENV Values

- CUDA_VERSION: Specify a cuda version to use, if left blank will attempt auto-detect
- XMRIG_VERSION: Specify XMRig version to use, default 6.24.0 (latest 9/2025)
- XMRIG_CUDA_VERSION: Specify XMRig Cuda version to use, default 6.22.1 (latest 9/2025)

### Worth it?

Depends a lot on your hardware, home CPU mining ([at least for my napkin math and testing](benchmarks.md)) isn't profitable unless your electric rates are less than 0.11 kWH, and GPU mining isn't profitable unless your electricity is less than 0.01 kWH -- And that is assuming your equipment is free. That being said, mining does help improve transaction speeds as well as helps avoid the very real threat of 51% [takeover](https://www.google.com/url?sa=t&source=web&rct=j&opi=89978449&url=https://www.coindesk.com/business/2025/08/12/monero-s-51-attack-problem-inside-qubic-s-controversial-network-takeover&ved=2ahUKEwjhxt6c-uKPAxUTEDQIHVmhDkYQFnoECBgQAQ&usg=AOvVaw0UtglHtaRMl2mPVeMjsnK3) plaguing the XMR coin at the moment. And the electricity isn't wasted if you are using it to heat your space :) 

### License

This project is released under the Unlicense (public domain). See `LICENSE`.

### Huge pages helper script

`hugepages.sh` helps you view, enable, and disable HugeTLB pages (1G or 2M) on the host. Huge pages can improve XMRig performance by reducing TLB misses.

Prerequisites:

- Run with sufficient privileges (use `sudo` for enable/disable)
- Kernel support for the requested size (1G requires `pdpe1gb` CPU support and kernel config)
- Optional: mount hugepages fs (most systems expose `/dev/hugepages` already)

Quick usage:

```bash
# Show current huge pages and memory status
./hugepages.sh status

# Enable N pages, auto-select size (prefers 1G if supported)
sudo ./hugepages.sh enable 2

# Explicit sizes
sudo ./hugepages.sh enable 4 -s 2M
sudo ./hugepages.sh enable 1 -s 1G

# Disable by size
sudo ./hugepages.sh disable -s 2M
sudo ./hugepages.sh disable -s 1G
```

Notes and troubleshooting:

- 1G pages often need boot-time reservation. Example GRUB setting:
  ```bash
  GRUB_CMDLINE_LINUX="... default_hugepagesz=1G hugepagesz=1G hugepages=4"
  ```
  Then update GRUB and reboot.
- 2M pages can usually be allocated at runtime, but fragmentation may prevent full allocation. Check kernel logs:
  ```bash
  dmesg | grep -i huge | tail -n 50
  ```
- If using containers, pass huge pages through to the container (example Compose volume):
  ```yaml
  volumes:
    - /dev/hugepages:/dev/hugepages:rw
  ```

Manual: `./hugepages.sh --help`