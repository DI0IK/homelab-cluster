```bash
talosctl gen secrets
```

```bash
talosctl gen config capi https://192.168.179.170:6443
```

```yaml patch.yaml
machine:
  network:
    hostname: management
    interfaces:
      - deviceSelector:
          busPath: "0*"
        dhcp: false
        addresses:
          - 192.168.179.170/23
        routes:
          - network: 0.0.0.0/0
            metric: 1024
            mtu: 1500
            gateway: "192.168.178.1"

    nameservers:
      - 192.168.178.1
cluster:
  allowSchedulingOnControlPlanes: true
```

```bash
talosctl gen config test https://192.168.179.170:6443 --config-patch-control-plane @patch.yaml --force
```

```bash
talosctl apply-config -n 192.168.178.42 -e 192.168.178.42 --file controlplane.yaml --insecure
```

```bash
talosctl bootstrap -n 192.168.179.170 -e 192.168.179.170 --talosconfig ./talosconfig
```

```bash
talosctl kubeconfig -n 192.168.179.170 -e 192.168.179.170 --talosconfig ./talosconfig --merge=false
```

```bash in proxmox
pveum user add capmox@pve
pveum aclmod / -user capmox@pve -role PVEVMAdmin
pveum user token add capmox@pve capi -privsep
```

```yaml
providers:
  - name: "talos"
    url: "https://github.com/siderolabs/cluster-api-bootstrap-provider-talos/releases/latest/bootstrap-components.yaml"
    type: "BootstrapProvider"
  - name: "talos"
    url: "https://github.com/siderolabs/cluster-api-control-plane-provider-talos/releases/latest/control-plane-components.yaml"
    type: "ControlPlaneProvider"
  - name: "proxmox"
    url: "https://github.com/ionos-cloud/cluster-api-provider-proxmox/releases/latest/infrastructure-components.yaml"
    type: "InfrastructureProvider"
PROXMOX_URL: "https://192.168.179.171:8006"
PROXMOX_TOKEN: "capmox@pve!capi"
PROXMOX_SECRET: "<secret>"
```

```bash
KUBECONFIG=./kubeconfig clusterctl init --infrastructure proxmox --ipam in-cluster --control-plane talos --bootstrap talos
```

```bash
GITHUB_TOKEN=PAT_WITH_ADMINISTRATOR flux bootstrap github --token-auth --owner=<USERNAME> --repository=<REPO_NAME> --branch=main --path=clusters/management --personal
```
