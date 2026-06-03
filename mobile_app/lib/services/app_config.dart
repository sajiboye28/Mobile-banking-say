/// Central configuration for backend URLs.
///
/// Update [kApiBase] and [kPbUrl] to match your environment:
///   - Local dev (real device on WiFi): use your machine's LAN IP
///   - Android emulator:               replace the IP with 10.0.2.2
///   - Production:                     replace with your Vercel domain

/// LAN IP of the machine running PocketBase + Next.js admin panel
const String _kHostIp = '192.168.1.3';

/// PocketBase server URL
const String kPbUrl = 'http://$_kHostIp:8091';

/// Next.js admin-panel API base URL (no trailing slash)
const String kApiBase = 'http://$_kHostIp:3040/api';
