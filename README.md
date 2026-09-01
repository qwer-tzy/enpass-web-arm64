# Docker Enpass ARM64 (KasmVNC + Box64)

Run the official **amd64 Enpass Password Manager** on **ARM64 devices** (such as Raspberry Pi 4/5, Apple Silicon VMs, or ARM Cloud Instances) inside a browser-accessible Docker container using KasmVNC and Box64 emulation.

> **Note:** Enpass does not natively provide a web-based client or web interface for accessing vaults. This project bridges that gap by providing a fully self-hosted, browser-accessible Enpass desktop environment on ARM64 architectures.

![Architecture](https://img.shields.io/badge/Architecture-ARM64-blue)
![Emulation](https://img.shields.io/badge/Emulation-Box64-orange)
![UI](https://img.shields.io/badge/UI-KasmVNC-green)

---

## Why Use This? (Motivation)

This setup provides a self-hosted, web-based Enpass interface accessible from any device with a web browser. It is ideal for situations where installing desktop/mobile apps is restricted or undesirable:

* **Restricted / Corporate Workstations:** Use your Enpass vault on work PCs where installing third-party applications or browser extensions is locked down by IT policies.
* **Public or Shared Computers:** Securely access passwords on temporary or shared machines without leaving local traces or installing software.
* **Seamless Copy-Paste:** Avoid manually typing long, complex passwords—full clipboard support allows seamless copying directly into your browser or target apps.
* **Zero Desktop Footprint:** Access your passwords anywhere via browser while keeping vault files securely hosted on your personal ARM server.

---

## Key Features

* **ARM64 Emulation:** Compiles `Box64` with dynamic recompilation (`-DARM_DYNAREC=ON`) to run x86_64 Enpass natively on ARM architectures with solid performance.
* **Modern Web GUI:** Uses KasmVNC for responsive, touch-friendly browser access on both Desktop and Mobile.
* **Full Clipboard Integration:** Pre-configured with `xclip` and `xsel` for copy-paste workflows.
* **Smart Window Management:** Auto-restore script (`wmctrl`) brings the Enpass window back into focus upon browser connection/reconnect.
* **Persistent Storage:** Vaults and settings are safely stored in `/config`.

---

## Quick Start & Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/qwer-tzy/enpass-web-arm64.git
   cd enpass-web-arm64
   ```

2. **Create your .env file and fill in your values:**
   ```bash
   mv .env.example .env
   $EDITOR .env
   ```

3. **Build and start the container:**
   ```bash
   docker compose up -d --build
   ```
   *(Note: The initial build compiles Box64 from source and may take 5–15 minutes depending on your CPU).*

4. **Access & Initial Enpass Setup:**
   * Open your browser and navigate to:
     * **HTTP:** `http://:3000`
     * **HTTPS:** `https://:3001`
   * **Set up Enpass normally:** Enter your registered Enpass email address and restore/sync your vault(s) from your preferred cloud storage (e.g., Nextcloud, OneDrive, Google Drive, Dropbox) or local backup just as you would in the regular desktop application.

---

## Updating Enpass

Because Enpass and its dependencies are fetched during the build process, updating the application to the latest version simply requires rebuilding the container image without altering your cached compilation steps:

1. **Rebuild the image:**
   ```bash
   docker compose build
   ```
   *(Docker will reuse the cached Box64 layer, so updating Enpass usually takes only 15–30 seconds).*

2. **Restart the container:**
   ```bash
   docker compose up -d
   ```

---

## Configuration & Security Recommendations

### Recommended Enpass Setting
To prevent the application window from minimizing into a hidden state when clicking the **X** button:
1. Open Enpass inside the container.
2. Go to **Settings -> General**.
3. **Uncheck** *"Minimize to System Tray on Close"*.

### Reverse Proxy & Access Control Lists (ACLs)
For enhanced security and maximum clipboard compatibility, it is **strongly recommended** to place this container behind a Reverse Proxy (e.g., Nginx Proxy Manager, Traefik, Caddy, or Cloudflare Tunnels) equipped with Access Control Lists (ACLs):

* **IP / Location Restrictions:** Limit access exclusively to trusted static IPs or local VPN ranges (e.g., WireGuard/Tailscale).
* **Additional Authentication Layer:** Implement HTTP Basic Auth, Authelia, or Authentik in front of KasmVNC for double authentication before even reaching the Enpass login screen.
* **Automatic SSL (HTTPS):** Ensures a secure context required for native browser clipboard integration (`Ctrl+C` / `Ctrl+V`).

### HTTPS & Clipboard Permissions
Modern web browsers require a **secure context (HTTPS)** to allow direct access to the system clipboard (`Ctrl+C` / `Ctrl+V`).

* Access the web interface via **HTTPS (`https://:3001`)** or place the container behind a Reverse Proxy with SSL enabled.
* Grant **Clipboard Access** permissions when prompted by your browser.
* Mobile users can utilize the side-panel clipboard drawer built into KasmVNC.

### Custom SSL Certificates
If you want to use custom certificates (e.g., Let's Encrypt / Certbot) without a reverse proxy, mount your certificate files into the `./config` directory and set the following environment variables in `docker-compose.yml`:

```bash
   environment:
      - SSL_CERTIFICATE_FILE=/config/certs/fullchain.pem
      - SSL_KEY_FILE=/config/certs/privkey.pem
```

---

## Troubleshooting

* **Blank Black Screen:** If the window was accidentally closed or minimized, simply refresh the browser tab (**F5**). The autostart hook will automatically restore or launch Enpass.
* **Force Window Restore (CLI):** If Enpass is running in the background but invisible, run:
  ```bash
  docker exec -d -e DISPLAY=:1 enpass-web /usr/local/bin/start-enpass.sh
  ```
* **Restart Process:** To kill and re-launch Enpass without restarting the entire container:
  ```bash
  docker exec enpass-web pkill -f Enpass
  ```

---

## Disclaimer & Responsibility

**Use at your own risk.** This project is an unofficial community effort and is neither affiliated with, endorsed by, nor supported by Sinew Software Systems (the creators of Enpass). 

* Neither the maintainer of this repository nor Enpass / Sinew Software Systems shall be held liable for any data loss, security breaches, unauthorized access, or credential leaks resulting from the deployment or usage of this setup.
* **Security Notice:** You are solely responsible for securing your deployment. If you expose this container publicly without proper protection, use weak master passwords, set insecure PIN codes, or fail to implement basic network security measures (such as Reverse Proxies with HTTPS, SSL, ACLs, or VPNs), you risk exposing your vault to malicious actors.

---

## License

MIT License. Feel free to modify and adapt for your own homelab setup.

