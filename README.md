# cloudflare-ddns
A dynamic DNS updater script for CloudFlare API v4 using bearer tokens, with OpenWRT ddns-scripts in mind. Requires curl and jq.

This script expects an environment variable named domain, which contains the FQDN of the domain you want to update. It assumes that everything after the first dot is the zone name, so this likely won't work for deeply nested subdomains, but that could be fixed easily.

This script also expects an environment variable named password, which contains the bearer token exactly as CloudFlare provides it. It requires Zone:Read and DNS:Edit permissions to apply to that token.

OpenWRT ddns-scripts provides a logging function called write_log. If this is present, we make use of it. If it isn't, it falls back to echo.
