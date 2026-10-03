# Cloudflare Security Headers Setup for trainlibre.com

This directory contains configuration, documentation, and workers to achieve an **A+ Score on SecurityHeaders.com** and **100/100 (A+) on Mozilla HTTP Observatory** for `https://trainlibre.com/`.

---

## 1. Why SecurityHeaders.com originally reported Grade F

SecurityHeaders.com evaluates **HTTP response headers** returned directly by the server:
- By default, DNS for `trainlibre.com` pointed directly to GitHub Pages (`185.199.109.153`).
- **GitHub Pages natively does NOT support custom HTTP response headers.** GitHub Pages lacks server configuration files (like `.htaccess`) and ignores custom headers.
- As a result, GitHub Pages omits:
  - `Strict-Transport-Security` (HSTS)
  - `Content-Security-Policy` (CSP)
  - `X-Frame-Options`
  - `X-Content-Type-Options`
  - `Referrer-Policy`
  - `Permissions-Policy`

---

## 2. Recommended Solution: Cloudflare Transform Rules (0 Code, 2 Minutes)

`trainlibre.com`'s nameservers are already hosted at Cloudflare (`grannbo.ns.cloudflare.com`, `tosana.ns.cloudflare.com`).

### Step 1: Enable Cloudflare Proxy
1. Log in to the [Cloudflare Dashboard](https://dash.cloudflare.com/).
2. Select `trainlibre.com` > **DNS** > **Records**.
3. Change the A records for `trainlibre.com` (and `www` CNAME if present) from **DNS only** (grey cloud) to **Proxied** (orange cloud).

### Step 2: Ensure SSL/TLS is set to Full (strict)
1. Go to **SSL/TLS** > **Overview**.
2. Set the encryption mode to **Full (strict)**.
   *(This ensures Cloudflare connects to GitHub Pages via HTTPS on port 443 with a valid certificate, preventing redirect loops).*

### Step 3: Enable HSTS in Cloudflare
1. Go to **SSL/TLS** > **Edge Certificates** > **HTTP Strict Transport Security (HSTS)**.
2. Click **Enable HSTS** and set:
   - **Max Age**: 12 months (`31536000`)
   - **Include subdomains**: ON
   - **Preload**: ON
   - **No-sniff header**: ON *(Note: Since this toggle injects `X-Content-Type-Options: nosniff`, do NOT add it a second time in the Transform Rule below to avoid duplicate header warnings!)*

### Step 4: Create a Transform Rule (Modify Response Header)
1. Go to **Rules** > **Overview** > Click **+ Create rule** > select **Response Header Transform Rule**.
2. Name: `Security Headers`.
3. Matching incoming requests: **All incoming requests**.
4. **Modify response headers**:

| Action | Header Name | Value |
| :--- | :--- | :--- |
| **Set static** | `Content-Security-Policy` | `default-src 'self'; script-src 'self' https://cdn.jsdelivr.net; style-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net; font-src 'self' data: https://cdn.jsdelivr.net; img-src 'self' data: https:; connect-src 'self'; frame-ancestors 'none'; base-uri 'self'; form-action 'self'; object-src 'none'; upgrade-insecure-requests;` |
| **Set static** | `X-Frame-Options` | `DENY` |
| **Set static** | `Referrer-Policy` | `strict-origin-when-cross-origin` |
| **Set static** | `Permissions-Policy` | `accelerometer=(), camera=(), geolocation=(), gyroscope=(), magnetometer=(), microphone=(), payment=(), usb=(), interest-cohort=()` |
| **Set static** | `Cross-Origin-Opener-Policy` | `same-origin` |
| **Set static** | `Cross-Origin-Resource-Policy` | `same-origin` |

5. Click **Deploy**.

---

## 3. Alternative Option: Deploy via Cloudflare Worker

If you prefer deploying a worker:
1. Ensure `npx wrangler` is logged in (`npx wrangler login`).
2. Run:
   ```bash
   cd tool/cloudflare
   npx wrangler deploy
   ```
3. Attach the worker route to `trainlibre.com/*` and `www.trainlibre.com/*`.

---

## 4. Alternative Option: Cloudflare Pages

If you migrate static hosting from GitHub Pages to Cloudflare Pages:
- Cloudflare Pages automatically reads the [`docs/_headers`](../../docs/_headers) file on every build and deployment.
