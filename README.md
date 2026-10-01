FEZZY G.I.JOE · V12.0

```
   ___ ___ __________   __   ___ ___      _  ___  ___   ___  ___  ___ 
  | __| __|_  /_  /\ \ / /  / __|_ _|  _ | |/ _ \| __|  / _ \/ _ \/ _ \
  | _|| _| / / / /  \ V /  | (_ || |  | || | (_) | _|   \_, /\_, /\_, /
  |_| |___/___/___|  |_|    \___|___|  \__/ \___/|___|  /_/  /_/  /_/ 
```

Mobile-Optimised Nmap & Web Recon Arsenal · Built for Termux

Strategy Over Impulse · 999

https://img.shields.io/badge/version-12.0-ff2d78?style=flat-square
https://img.shields.io/badge/platform-Termux%20%7C%20Linux-00ffff?style=flat-square
https://img.shields.io/badge/license-Educational%20Use-c6007e?style=flat-square

---

⚠️ LEGAL DISCLAIMER — READ FIRST

This tool is strictly for authorised security testing.

· ✅ Use on systems you own or have explicit written permission to test
· ❌ Unauthorised scanning is a criminal offence (CFAA, Computer Misuse Act, ECPA)
· 🚫 The author accepts zero liability for misuse, damage, or legal consequences

You deploy it — you own the outcome. Strategy over impulse. 999.

---

📖 What Is This?

FEZZY G.I.JOE is a full-arsenal network reconnaissance and web security toolkit built specifically for Termux on Android. It wraps Nmap, ProjectDiscovery tools, OSINT frameworks, and 80+ modules into a single neon-themed interactive menu system.

Written by Grant "Fezzy" Festers — Ravensmead, Cape Town.

Highlights

· 📱 Mobile-first — designed for Termux, rootless-friendly
· 🎨 Neon TUI — colour-coded, dot indicators, Poetry Engine synopsis
· 🧠 Session Reports — build TXT + styled HTML recon reports
· 🔧 80+ Tools — Nmap variants, web arsenal, V8/V10/V11/V12 modules
· 🚀 Self-Update — pulls latest version from GitHub
· 🩺 Rootless — most tools work without root via Go/Python

---

🚀 Installation

Quick Clone (Termux / Linux)

```bash
git clone https://github.com/philfesters/nmap.git
cd nmap
chmod +x nmap.sh
bash nmap.sh
```

One-Liner (Run Directly)

```bash
bash <(curl -s https://raw.githubusercontent.com/philfesters/nmap/main/nmap.sh)
```

Clone via HTTPS vs SSH

HTTPS (recommended for most):

```bash
git clone https://github.com/philfesters/nmap.git
```

SSH (if you have keys set up):

```bash
git clone git@github.com:philfesters/nmap.git
```

Required Dependencies

Install these first for the best experience:

```bash
pkg update && pkg upgrade -y
pkg install -y nmap curl git wget python golang
```

Then inside the script, choose [I] Install Deps for the full toolkit.

---

🎯 Feature Overview

🛰️ Network Scanning (Options 1–34)

Option Feature Description
1 Quick Scan Top 100 ports, fast recon
3 Full Port Scan All 65535 TCP ports
4 Intense Scan OS + version + aggressive NSE
5 Stealth SYN Low & slow, IDS evasion
6 UDP Scan UDP layer enumeration
7 Vuln Script NSE vulnerability category
11 Evasion & Stealth Decoys, Fragmentation, Port Spoof
17 Timing T0–T5 Paranoid to Insane templates
19–34 Advanced Nmap IPv6, Packet Trace, Traceroute, DNS, Parallelism, Proxy, SCTP, etc.

📡 WiFi Elite · Diagnostics (W1–W4)

· Nearby network scan (SSID, channel, signal)
· Gateway discovery
· Local device sweep
· Network latency benchmark

🌐 Web Arsenal · G.I.JOE (Options 35–49)

# Tool Purpose
35 Domain Intel dig + whois + DNS brute + reverse IP
36 Web Fingerprint whatweb · tech stack ID
37 SSL Check Cert expiry, chain, ciphers, HSTS
38 Vulnerability Scan nikto · full web audit
39 Directory Hunter gobuster dir/dns/vhost
40 Web Crawler photon · emails, links, JS
41 Fuzzing Engine wfuzz · params, headers, cookies
42 Netcat Raw TCP/UDP banner grabbing
43 JQ Parser JSON API response parsing
44 theHarvester Passive OSINT · emails/subdomains
46 Httprobe Live HTTP/S host confirmation
47 SQLMap SQL injection detection
48 WAF Detect wafw00f · WAF fingerprinting
49 FFUF Fast fuzzer · dir/param/vhost

⚙️ V8 · Rootless Recon Arsenal (Options 50–60)

Powered by ProjectDiscovery — all rootless:

· Amass — Passive subdomain enum (30+ sources)
· Nuclei — 9000+ YAML templates (CVE, misconfig, exposure)
· Katana — JS-aware crawler
· ShuffleDNS — High-speed DNS resolver
· HTTPX — Status/title/tech probe
· Subfinder — Passive sub discovery
· Naabu — Rootless port scanner
· DNSx — Bulk DNS resolution
· MassDNS — 1000x bulk resolver
· Waybackurls + GAU — Historical URL mining

🎯 V10 · Fezzy Station · S.O.I Arsenal (Options 61–63)

· Arjun — Hidden GET/POST/JSON parameter discovery
· Optiva — Multi-module offensive framework
· HiddenURL — Obscured path discovery

💀 V11 · Bounty Arsenal (Options 64–77)

· Dalfox — XSS scanner + PoC generator
· KXSS — Reflected XSS parameter finder
· GF — grep filters (xss/sqli/lfi/ssrf/idor/rce)
· TruffleHog — Secret & API key scanner
· CRLFuzz — CRLF injection fuzzer
· Byp4xx — 403 bypass engine
· Feroxbuster — Recursive content discovery
· Assetfinder, Gospider, Qsreplace, Unfurl
· ParamSpider, SSRFmap, Chaos

🕵️ V12 · OSINT Intel (Options 78–87)

· Holehe — Email → 120+ site account check
· Blackbird — Username footprint (500+ platforms)
· Toutatis — Instagram hidden detail extractor
· Moriarty — Phone intel via AWS + business regs
· DaProfiler — EU/Global identity mapper
· CloudPeler — Real IP behind Cloudflare
· Mosint — Go email profiler
· Photon — High-speed site crawler
· OnionSearch — Dark web scraper
· GitSniff — GitHub commit metadata ripper

---

🛠️ Installation Inside The Script

Once running, use the main menu:

· [I] Install Deps — nmap, curl, git, wget
· [WA] Install Full Suite — installs all Web Arsenal modules
· [U] Self-Update — pulls latest from GitHub
· [R] Report Builder — generate TXT/HTML session reports
· [M] Automatic Scans — AI-strategy recon flows

---

📸 Screenshot Preview

```
═══ FEZZY G.I.JOE · V12.0 · Fezzy Station · 999 ═══

  [ NETWORK SCANNING ]
 [1] Quick Scan           - Fast sweep of common ports
 [3] Full Port Scan       - All 65535 ports
 [4] Intense Scan         - OS + version + aggressive
 [11] Evasion & Stealth   - Decoys, Spoofing, Frag
 ...
```

---

📂 Repository Structure

```
nmap/
├── nmap.sh              # Main script (FEZZY G.I.JOE V12.0)
├── README.md            # This file
└── LICENSE              # Educational Use License
```

---

🧠 Session Reports

After running tools, use [R] Report Builder to compile:

· 📄 TXT Report — Clean, greppable output
· 🌐 HTML Report — Neon dark-theme styled report
· 📊 Session Log — All entries with timestamps

Reports save to ~/storage/downloads/ (falls back to ~/ if storage not set up).

---

🔄 Updating

Via script: Main menu → [U] Update Script

Via git:

```bash
cd nmap
git pull origin main
```

---

🤝 Contributing

Pull requests are welcome. For major changes:

1. Fork the repo
2. Create your feature branch (git checkout -b feature/AmazingFeature)
3. Commit changes (git commit -m 'Add AmazingFeature')
4. Push (git push origin feature/AmazingFeature)
5. Open a Pull Request

---

📜 License

Educational Use Only. See disclaimer above.

---

📬 Connect

· GitHub: @philfesters
· Facebook: Fezzy Arsenal

---

💚 Credits

Built by Grant "Fezzy" Festers · Ravensmead, Cape Town

"Strategy over impulse. Built for the elite. 999."

---

⭐ If this helped you, drop a star on the repo — keeps the 999 alive.
