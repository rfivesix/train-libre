/**
 * Cloudflare Worker: Security Headers for trainlibre.com
 *
 * Intercepts requests, proxies them to GitHub Pages (or upstream origin),
 * and injects all required security headers to achieve an A+ score on SecurityHeaders.com.
 */

export default {
  async fetch(request, env, ctx) {
    const response = await fetch(request);

    // Clone headers so we can modify them
    const headers = new Headers(response.headers);

    // 1. Strict-Transport-Security (HSTS) - 1 year, includes subdomains, preload
    headers.set("Strict-Transport-Security", "max-age=31536000; includeSubDomains; preload");

    // 2. Content-Security-Policy (CSP) - Clean policy without 'unsafe-inline' in script-src
    headers.set(
      "Content-Security-Policy",
      "default-src 'self'; script-src 'self' https://cdn.jsdelivr.net; style-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net; font-src 'self' data: https://cdn.jsdelivr.net; img-src 'self' data: https:; connect-src 'self'; frame-ancestors 'none'; base-uri 'self'; form-action 'self'; object-src 'none'; upgrade-insecure-requests;"
    );

    // 3. X-Frame-Options (Clickjacking defense)
    headers.set("X-Frame-Options", "DENY");

    // 4. X-Content-Type-Options (MIME-sniffing defense)
    headers.set("X-Content-Type-Options", "nosniff");

    // 5. Referrer-Policy
    headers.set("Referrer-Policy", "strict-origin-when-cross-origin");

    // 6. Permissions-Policy (Feature Policy)
    headers.set(
      "Permissions-Policy",
      "accelerometer=(), camera=(), geolocation=(), gyroscope=(), magnetometer=(), microphone=(), payment=(), usb=(), interest-cohort=()"
    );

    // 7. Cross-Origin-Opener-Policy & Cross-Origin-Resource-Policy
    headers.set("Cross-Origin-Opener-Policy", "same-origin");
    headers.set("Cross-Origin-Resource-Policy", "same-origin");

    // 8. Clean up GitHub Pages' overly permissive Access-Control-Allow-Origin: * on HTML pages
    const contentType = headers.get("content-type") || "";
    if (contentType.includes("text/html")) {
      headers.delete("access-control-allow-origin");
    }

    return new Response(response.body, {
      status: response.status,
      statusText: response.statusText,
      headers: headers,
    });
  },
};
