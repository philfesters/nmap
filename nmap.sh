#!/bin/bash
# fezzy-nmap.sh
# Version: V6.0 - G.I.JOE Full Arsenal Edition
# Mobile Optimised – Dot indicators, Alias as Option 2
# Author: Grant "Fezzy" Festers · Ravensmead, CPT
# FEZZY ARSENAL · Strategy Over Impulse · 999

# --- Colour palette ---
HOT=$'\033[38;5;198m'
GRN=$'\033[0;32m'
CYN=$'\033[0;36m'
YLW=$'\033[0;33m'
RED=$'\033[0;31m'
RST=$'\033[0m'
BLD=$'\033[1m'
DESC=$'\033[0;35m'
PNK=$'\033[38;5;162m'
PUR=$'\033[38;5;91m'
NEON_BLU=$'\033[38;5;51m'
DK_BLU=$'\033[38;5;18m'
DK_PUR=$'\033[38;5;54m'

# --- Variables ---
SCRIPT_VERSION="12.0"
SCRIPT_PATH="$(realpath "$0")"
REPO_URL="https://raw.githubusercontent.com/philfesters/fezzy-arsenal/main/fezzy-nmap.sh"
FB_LINK="https://www.facebook.com/share/1GcuwSgant/"
# LOG: prefer Termux downloads, fall back to home dir if storage not set up
if [ -d "${HOME}/storage/downloads" ]; then
    LOG="${HOME}/storage/downloads/fezzy_gijoe_log.txt"
else
    LOG="${HOME}/fezzy_gijoe_log.txt"
fi
TOOL_DIR="${HOME}/.fezzy-gijoe"
CONFIG_FILE="${TOOL_DIR}/config"
_FEZZY_TARGET=""
LIVE_HOSTS=()
SESSION_TARGET=""
SESSION_ID=""
SESSION_FILE=""
REPORT_ENTRIES=()
REPORT_COUNTER=0

# --- Module Flags ---
NMAP_INSTALLED=false; CURL_INSTALLED=false
GIT_INSTALLED=false;  TAPI_INSTALLED=false
ALIAS_INSTALLED=false
DOMAIN_INTEL_INSTALLED=false; WEB_FINGERPRINT_INSTALLED=false
SSL_CHECK_INSTALLED=false;    DIRECTORY_HUNTER_INSTALLED=false
WEB_CRAWLER_INSTALLED=false;  FUZZING_ENGINE_INSTALLED=false
VULN_SCAN_INSTALLED=false
# V5 new tool flags
NETCAT_INSTALLED=false; JQ_INSTALLED=false
HARVESTER_INSTALLED=false;
HTTPROBE_INSTALLED=false; SQLMAP_INSTALLED=false
WAFW00F_INSTALLED=false; FFUF_INSTALLED=false
# V8 rootless toolkit flags
AMASS_INSTALLED=false; NUCLEI_INSTALLED=false; KATANA_INSTALLED=false
SHUFFLEDNS_INSTALLED=false; HTTPX_T_INSTALLED=false; SUBFINDER_INSTALLED=false
NAABU_INSTALLED=false; DNSX_INSTALLED=false; MASSDNS_INSTALLED=false
WAYBACKURLS_INSTALLED=false; GAU_INSTALLED=false
# V9 new rootless tools
HAKRAWLER_INSTALLED=false; ANEW_INSTALLED=false; TLSX_INSTALLED=false
CDNCHECK_INSTALLED=false; NOTIFY_INSTALLED=false; INTERACTSH_INSTALLED=false
# V10 · Fezzy Station tools
ARJUN_INSTALLED=false; OPTIVA_INSTALLED=false; HIDDENURL_INSTALLED=false
# V11 · Bounty Arsenal flags
DALFOX_INSTALLED=false; KXSS_INSTALLED=false; GF_INSTALLED=false
TRUFFLEHOG_INSTALLED=false; CRLFUZZ_INSTALLED=false
BYP4XX_INSTALLED=false; FEROXBUSTER_INSTALLED=false
ASSETFINDER_INSTALLED=false; GOSPIDER_INSTALLED=false
QSREPLACE_INSTALLED=false;   UNFURL_INSTALLED=false
PARAMSPIDER_INSTALLED=false;  SSRFMAP_INSTALLED=false
CHAOS_INSTALLED=false
# V12 · OSINT Intel flags
HOLEHE_INSTALLED=false; BLACKBIRD_INSTALLED=false
TOUTATIS_INSTALLED=false; MORIARTY_INSTALLED=false
DAPROFILER_INSTALLED=false; CLOUDPELER_INSTALLED=false
MOSINT_INSTALLED=false; PHOTON_INSTALLED=false
ONIONSEARCH_INSTALLED=false; GITSNIFF_INSTALLED=false

# --- Utility functions ---
spinner() {
    local pid=$1 delay=0.1 spinstr='|/-\'
    while ps -p $pid > /dev/null 2>&1; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay; printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

install_package() {
    local pkg="$1" msg="$2"
    printf "%s  [*] Installing %s...%s\n" "${CYN}" "$pkg" "${RST}"
    (pkg install -y "$pkg" 2>/dev/null) &
    local pid=$!; spinner $pid; wait $pid
    command -v "$pkg" >/dev/null 2>&1 \
        && { printf "%s  [+] %s%s\n" "${GRN}" "$msg" "${RST}"; return 0; } \
        || { printf "%s  [!!] Failed: %s%s\n" "${RED}" "$pkg" "${RST}"; return 1; }
}

install_pip_package() {
    local pkg="$1" msg="$2"
    printf "%s  [*] Installing %s (pip)...%s\n" "${CYN}" "$pkg" "${RST}"
    (pip install "$pkg" 2>/dev/null) &
    local pid=$!; spinner $pid; wait $pid
    pip list 2>/dev/null | grep -qi "$pkg" \
        && { printf "%s  [+] %s%s\n" "${GRN}" "$msg" "${RST}"; return 0; } \
        || { printf "%s  [!!] Failed: %s%s\n" "${RED}" "$pkg" "${RST}"; return 1; }
}

get_wifi_info() {
    local ssid="N/A" ip="N/A" gateway="N/A"
    command -v termux-wifi-connectioninfo >/dev/null 2>&1 && {
        ssid=$(termux-wifi-connectioninfo 2>/dev/null | grep '"ssid"' | cut -d'"' -f4)
        ip=$(termux-wifi-connectioninfo 2>/dev/null   | grep '"ip"'   | cut -d'"' -f4)
    }
    [ -z "$ip" ] || [ "$ip" = "N/A" ] && \
        ip=$(ip addr show 2>/dev/null | grep "inet " | grep -v "127.0.0.1" | awk '{print $2}' | cut -d/ -f1 | head -n1)
    gateway=$(ip route show 2>/dev/null | grep "default" | awk '{print $3}' | head -n1)
    printf "  %sSSID: %s%s | %sIP: %s%s | %sGW: %s%s\n" \
        "${CYN}" "${ssid:-None}" "${RST}" "${GRN}" "${ip:-None}" "${RST}" "${YLW}" "${gateway:-None}" "${RST}"
}

new_neon_line() {
    local w; w=$(tput cols 2>/dev/null || echo 60)
    for ((i=0; i<w; i++)); do
        (( i % 2 == 0 )) && printf "${DK_BLU}═" || printf "${DK_PUR}═"
    done
    printf "${RST}\n"
}

new_short_line() {
    local len="$1"
    for ((i=0; i<len; i++)); do
        (( i % 2 == 0 )) && printf "${DK_BLU}═" || printf "${DK_PUR}═"
    done
    printf "${RST}\n"
}

center_in_box() {
    local text="$1" w pad
    w=$(tput cols 2>/dev/null || echo 60)
    pad=$(( (w - ${#text}) / 2 )); [ $pad -lt 0 ] && pad=0
    printf "%${pad}s%s\n" "" "$text"
}

pink_line()       { new_neon_line; }
short_pink_line() { new_short_line "$1"; }


# ============================================================
#  V9 PULSE BAR
# ============================================================
pulse_bar() {
    local label="${1:-Working}" duration="${2:-2}"
    local w; w=$(tput cols 2>/dev/null || echo 60)
    local bar_w=$(( w - 20 ))
    [ "$bar_w" -lt 10 ] && bar_w=10
    local steps=$((bar_w))
    local delay; delay=$(echo "scale=3; $duration / $steps" | bc 2>/dev/null || echo "0.05")
    printf "  %s%s%s " "${CYN}" "$label" "${RST}"
    printf "${HOT}["
    for ((i=0; i<steps; i++)); do
        printf "\u2588"
        sleep "$delay"
    done
    printf "]${RST}\n"
}

pulse_bar_bg() {
    local label="${1:-Scanning}" pid="$2"
    local chars=("\u258f" "\u258e" "\u258d" "\u258c" "\u258b" "\u258a" "\u2589" "\u2588")
    local i=0
    printf "  %s%s%s " "${CYN}" "$label" "${RST}"
    printf "${HOT}["
    while ps -p "$pid" >/dev/null 2>&1; do
        printf "%s" "${chars[$((i % 8))]}"
        sleep 0.12
        printf "\b"
        i=$((i+1))
    done
    printf "]${RST}\n"
}

# ============================================================
#  V9 DASHBOARD PANEL
# ============================================================
dashboard_panel() {
    local _GB="${HOME}/go/bin"
    local _ok="${GRN}\u25cf${RST}" _no="${RED}\u25cb${RST}"

    _chk() { command -v "$1" >/dev/null 2>&1 || [[ -x "${_GB}/$1" ]] && printf "%s" "${_ok}" || printf "%s" "${_no}"; }

    new_neon_line
    printf "${HOT}${BLD}"
    center_in_box "ARSENAL STATUS · V12.0"
    printf "${RST}"
    new_neon_line
    echo ""
    printf "  ${BLD}${CYN}CORE          WEB           ROOTLESS GO       V9 NEW${RST}\n"
    printf "  $(_chk nmap)    nmap        $(_chk gobuster)  gobuster     $(_chk subfinder) subfinder   $(_chk hakrawler) hakrawler\n"
    printf "  $(_chk curl)    curl        $(_chk nikto)     nikto        $(_chk nuclei)    nuclei      $(_chk anew) anew\n"
    printf "  $(_chk git)     git         $(_chk ffuf)      ffuf         $(_chk katana)    katana      $(_chk tlsx) tlsx\n"
    printf "  $(_chk jq)      jq          $(_chk sqlmap)    sqlmap       $(_chk naabu)     naabu       $(_chk cdncheck) cdncheck\n"
    printf "  $(_chk nc)      netcat      $(_chk wafw00f)   wafw00f      $(_chk httpx)     httpx       $(_chk notify) notify\n"
    printf "  $(_chk openssl) openssl     $(_chk whatweb)   whatweb      $(_chk amass)     amass       $(_chk interactsh-client) interactsh\n"
    printf "  $(_chk dig)     dig         $(_chk wfuzz)     wfuzz        $(_chk dnsx)      dnsx\n"
    printf "  $(_chk whois)   whois                         $(_chk waybackurls) waybackurls\n"
    printf "  $(_chk massdns) massdns                       $(_chk gau) gau              $(_chk shuffledns) shuffledns\n"
    echo ""
    new_neon_line
    echo ""
}

banner() {
    clear
    printf "\n"
    printf "${HOT}   ___ ___ __________   __   ___ ___      _  ___  ___   ___  ___  ___ ${RST}\n"
    printf "${PNK}  | __| __|_  /_  /\ \ / /  / __|_ _|  _ | |/ _ \\| __|  / _ \\/ _ \\/ _ \\${RST}\n"
    printf "${PUR}  | _|| _| / / / /  \ V /  | (_ || |  | || | (_) | _|   \\_, /\\_, /\\_, /${RST}\n"
    printf "${NEON_BLU}  |_| |___/___/___|  |_|    \___|___|  \\__/ \\___/|___|  /_/  /_/  /_/${RST}\n"
    printf "\n"
    new_neon_line
    printf "${HOT}${BLD}"
    center_in_box "FEZZY G.I.JOE · V12.0 · Fezzy Station · 999"
    printf "${RST}"
    new_neon_line
    echo ""
}

banner_with_status() {
    banner
}

check_deps() {
    command -v nmap   >/dev/null 2>&1 && NMAP_INSTALLED=true  || NMAP_INSTALLED=false
    command -v curl   >/dev/null 2>&1 && CURL_INSTALLED=true  || CURL_INSTALLED=false
    command -v git    >/dev/null 2>&1 && GIT_INSTALLED=true   || GIT_INSTALLED=false
    command -v termux-wifi-connectioninfo >/dev/null 2>&1 && TAPI_INSTALLED=true || TAPI_INSTALLED=false
    command -v dig    >/dev/null 2>&1 && command -v whois >/dev/null 2>&1 \
        && DOMAIN_INTEL_INSTALLED=true   || DOMAIN_INTEL_INSTALLED=false
    command -v whatweb  >/dev/null 2>&1 && WEB_FINGERPRINT_INSTALLED=true  || WEB_FINGERPRINT_INSTALLED=false
    command -v openssl  >/dev/null 2>&1 && SSL_CHECK_INSTALLED=true        || SSL_CHECK_INSTALLED=false
    command -v nikto    >/dev/null 2>&1 && VULN_SCAN_INSTALLED=true         || VULN_SCAN_INSTALLED=false

    command -v gobuster >/dev/null 2>&1 && DIRECTORY_HUNTER_INSTALLED=true || DIRECTORY_HUNTER_INSTALLED=false
    command -v photon   >/dev/null 2>&1 && WEB_CRAWLER_INSTALLED=true      || WEB_CRAWLER_INSTALLED=false
    command -v wfuzz    >/dev/null 2>&1 && FUZZING_ENGINE_INSTALLED=true   || FUZZING_ENGINE_INSTALLED=false
    grep -q "alias fezzy_gijoe=" ~/.bashrc 2>/dev/null && ALIAS_INSTALLED=true || ALIAS_INSTALLED=false
    # V5 checks
    command -v nc       >/dev/null 2>&1 && NETCAT_INSTALLED=true     || NETCAT_INSTALLED=false
    command -v jq       >/dev/null 2>&1 && JQ_INSTALLED=true         || JQ_INSTALLED=false
    command -v theHarvester >/dev/null 2>&1 && HARVESTER_INSTALLED=true || \
        (python3 -c "import theHarvester" 2>/dev/null && HARVESTER_INSTALLED=true || HARVESTER_INSTALLED=false)
    command -v httprobe >/dev/null 2>&1 && HTTPROBE_INSTALLED=true   || HTTPROBE_INSTALLED=false
    command -v sqlmap   >/dev/null 2>&1 && SQLMAP_INSTALLED=true     || SQLMAP_INSTALLED=false
    command -v wafw00f  >/dev/null 2>&1 && WAFW00F_INSTALLED=true    || \
        (pip list 2>/dev/null | grep -qi wafw00f && WAFW00F_INSTALLED=true || WAFW00F_INSTALLED=false)
    command -v ffuf     >/dev/null 2>&1 && FFUF_INSTALLED=true       || FFUF_INSTALLED=false
    # V8 rootless toolkit checks — go bin aware
    local _GB="${HOME}/go/bin"
    { command -v amass       >/dev/null 2>&1 || [[ -x "${_GB}/amass"       ]]; } && AMASS_INSTALLED=true      || AMASS_INSTALLED=false
    { command -v nuclei      >/dev/null 2>&1 || [[ -x "${_GB}/nuclei"      ]]; } && NUCLEI_INSTALLED=true     || NUCLEI_INSTALLED=false
    { command -v katana      >/dev/null 2>&1 || [[ -x "${_GB}/katana"      ]]; } && KATANA_INSTALLED=true     || KATANA_INSTALLED=false
    { command -v shuffledns  >/dev/null 2>&1 || [[ -x "${_GB}/shuffledns"  ]]; } && SHUFFLEDNS_INSTALLED=true || SHUFFLEDNS_INSTALLED=false
    { command -v httpx       >/dev/null 2>&1 || [[ -x "${_GB}/httpx"       ]]; } && HTTPX_T_INSTALLED=true    || HTTPX_T_INSTALLED=false
    { command -v subfinder   >/dev/null 2>&1 || [[ -x "${_GB}/subfinder"   ]]; } && SUBFINDER_INSTALLED=true  || SUBFINDER_INSTALLED=false
    { command -v naabu       >/dev/null 2>&1 || [[ -x "${_GB}/naabu"       ]]; } && NAABU_INSTALLED=true      || NAABU_INSTALLED=false
    { command -v dnsx        >/dev/null 2>&1 || [[ -x "${_GB}/dnsx"        ]]; } && DNSX_INSTALLED=true       || DNSX_INSTALLED=false
    command -v massdns       >/dev/null 2>&1 && MASSDNS_INSTALLED=true    || MASSDNS_INSTALLED=false
    { command -v waybackurls >/dev/null 2>&1 || [[ -x "${_GB}/waybackurls" ]]; } && WAYBACKURLS_INSTALLED=true || WAYBACKURLS_INSTALLED=false
    { command -v gau         >/dev/null 2>&1 || [[ -x "${_GB}/gau"         ]]; } && GAU_INSTALLED=true        || GAU_INSTALLED=false
    # V9 new tool checks
    { command -v hakrawler  >/dev/null 2>&1 || [[ -x "${_GB}/hakrawler"  ]]; } && HAKRAWLER_INSTALLED=true  || HAKRAWLER_INSTALLED=false
    { command -v anew       >/dev/null 2>&1 || [[ -x "${_GB}/anew"       ]]; } && ANEW_INSTALLED=true       || ANEW_INSTALLED=false
    { command -v tlsx       >/dev/null 2>&1 || [[ -x "${_GB}/tlsx"       ]]; } && TLSX_INSTALLED=true       || TLSX_INSTALLED=false
    { command -v cdncheck   >/dev/null 2>&1 || [[ -x "${_GB}/cdncheck"   ]]; } && CDNCHECK_INSTALLED=true   || CDNCHECK_INSTALLED=false
    { command -v notify     >/dev/null 2>&1 || [[ -x "${_GB}/notify"     ]]; } && NOTIFY_INSTALLED=true     || NOTIFY_INSTALLED=false
    { command -v interactsh-client >/dev/null 2>&1 || [[ -x "${_GB}/interactsh-client" ]]; } && INTERACTSH_INSTALLED=true || INTERACTSH_INSTALLED=false
    # V10 · Fezzy Station tool checks
    pip list 2>/dev/null | grep -qi "arjun" && ARJUN_INSTALLED=true || ARJUN_INSTALLED=false
    { [[ -d "${HOME}/Optiva-Framework" ]] || command -v optiva >/dev/null 2>&1; } && OPTIVA_INSTALLED=true || OPTIVA_INSTALLED=false
    { [[ -d "${HOME}/HiddenURL" ]] || command -v HiddenURL >/dev/null 2>&1; } && HIDDENURL_INSTALLED=true || HIDDENURL_INSTALLED=false
    # V11 checks
    local _GB="${HOME}/go/bin"
    { command -v dalfox     >/dev/null 2>&1 || [[ -x "${_GB}/dalfox"     ]]; } && DALFOX_INSTALLED=true     || DALFOX_INSTALLED=false
    { command -v kxss       >/dev/null 2>&1 || [[ -x "${_GB}/kxss"       ]]; } && KXSS_INSTALLED=true       || KXSS_INSTALLED=false
    { command -v gf         >/dev/null 2>&1 || [[ -x "${_GB}/gf"         ]]; } && GF_INSTALLED=true         || GF_INSTALLED=false
    { command -v trufflehog >/dev/null 2>&1 || [[ -x "${_GB}/trufflehog" ]]; } && TRUFFLEHOG_INSTALLED=true || TRUFFLEHOG_INSTALLED=false
    { command -v crlfuzz    >/dev/null 2>&1 || [[ -x "${_GB}/crlfuzz"    ]]; } && CRLFUZZ_INSTALLED=true    || CRLFUZZ_INSTALLED=false
    { command -v byp4xx     >/dev/null 2>&1 || [[ -x "${_GB}/byp4xx"     ]]; } && BYP4XX_INSTALLED=true     || BYP4XX_INSTALLED=false
    command -v feroxbuster  >/dev/null 2>&1 && FEROXBUSTER_INSTALLED=true || FEROXBUSTER_INSTALLED=false
    { command -v assetfinder  >/dev/null 2>&1 || [[ -x "${_GB}/assetfinder"  ]]; } && ASSETFINDER_INSTALLED=true  || ASSETFINDER_INSTALLED=false
    { command -v gospider     >/dev/null 2>&1 || [[ -x "${_GB}/gospider"     ]]; } && GOSPIDER_INSTALLED=true     || GOSPIDER_INSTALLED=false
    { command -v qsreplace    >/dev/null 2>&1 || [[ -x "${_GB}/qsreplace"    ]]; } && QSREPLACE_INSTALLED=true    || QSREPLACE_INSTALLED=false
    { command -v unfurl       >/dev/null 2>&1 || [[ -x "${_GB}/unfurl"       ]]; } && UNFURL_INSTALLED=true       || UNFURL_INSTALLED=false
    { [[ -d "${HOME}/ParamSpider" ]] || command -v paramspider >/dev/null 2>&1; } && PARAMSPIDER_INSTALLED=true  || PARAMSPIDER_INSTALLED=false
    { [[ -d "${HOME}/ssrfmap"    ]] || command -v ssrfmap     >/dev/null 2>&1; } && SSRFMAP_INSTALLED=true       || SSRFMAP_INSTALLED=false
    { command -v chaos        >/dev/null 2>&1 || [[ -x "${_GB}/chaos"        ]]; } && CHAOS_INSTALLED=true        || CHAOS_INSTALLED=false
    # V12 · OSINT Intel checks
    pip list 2>/dev/null | grep -qi "holehe"       && HOLEHE_INSTALLED=true      || HOLEHE_INSTALLED=false
    [[ -d "${HOME}/blackbird" ]]                    && BLACKBIRD_INSTALLED=true   || BLACKBIRD_INSTALLED=false
    pip list 2>/dev/null | grep -qi "toutatis"      && TOUTATIS_INSTALLED=true    || TOUTATIS_INSTALLED=false
    [[ -d "${HOME}/Moriarty-Project" ]]             && MORIARTY_INSTALLED=true    || MORIARTY_INSTALLED=false
    [[ -d "${HOME}/DaProfiler" ]]                   && DAPROFILER_INSTALLED=true  || DAPROFILER_INSTALLED=false
    [[ -d "${HOME}/CloudPeler" ]]                   && CLOUDPELER_INSTALLED=true  || CLOUDPELER_INSTALLED=false
    { command -v mosint >/dev/null 2>&1 || [[ -x "${HOME}/go/bin/mosint" ]]; } && MOSINT_INSTALLED=true || MOSINT_INSTALLED=false
    [[ -d "${HOME}/Photon" ]]                       && PHOTON_INSTALLED=true      || PHOTON_INSTALLED=false
    pip list 2>/dev/null | grep -qi "onionsearch"   && ONIONSEARCH_INSTALLED=true || ONIONSEARCH_INSTALLED=false
    [[ -d "${HOME}/GitSniff" ]]                     && GITSNIFF_INSTALLED=true    || GITSNIFF_INSTALLED=false
}

dot_status() {
    # Safe boolean check — no eval, no subshell bleed
    [[ "$1" == "true" ]] && printf "${GRN}●${RST}" || printf "${RED}○${RST}"
}

# ============================================================
#  JUICE WRLD 999 POETRY ENGINE (FULL)
# ============================================================

juice_poetry() {
    local label="$1"
    echo ""
    case "$label" in
        "Quick Scan")
            printf "  %sYeah, I'm quick like a ghost, 999 on the coast
" "${GRN}"
            printf "  Scanning all your ports, I ain't playing post
"
            printf "  Common ports in check, I don't need to boast
"
            printf "  Fezzy on the beat, I'm the one you need the most.
"
            printf "  %sLeanin' in the shadows, sippin' on the code
" "${YLW}"
            printf "  No time for the slow, I'm taking every road
"
            printf "  999 forever, that's the Fezzy load — yeah, you know.%s
" "${RST}"
            ;;
        "Full Port Scan")
            printf "  %sAll 65535, I don't miss a single door
" "${GRN}"
            printf "  From port 1 to the end, I'm mapping out the war
"
            printf "  No hidden service safe, no place to hide no more
"
            printf "  Fezzy in your network, I'm breaking down the core.
"
            printf "  %s999 in my veins, I'm scanning every lane
" "${YLW}"
            printf "  You thought you were hidden, but I'm driving in the rain
"
            printf "  Full scan, full pain — Fezzy's always in the game.%s
" "${RST}"
            ;;
        "Intense Scan")
            printf "  %sAggressive like a storm, I'll rip the OS apart
" "${GRN}"
            printf "  Version and script, I'm tearing from the start
"
            printf "  The deeper that I go, the more I'm a work of art
"
            printf "  Fezzy Arsenal running — I'm tearing every heart.
"
            printf "  %s999 on my mind, I'm aggressive by design
" "${YLW}"
            printf "  No box, no line, I'm crossing every sign
"
            printf "  Intense scan, I'm divine — Fezzy's always on the grind.%s
" "${RST}"
            ;;
        "Stealth SYN")
            printf "  %sI'm moving low and slow, the logs won't see my name
" "${GRN}"
            printf "  SYN packets drift, I play the silent game
"
            printf "  No loud alarms, no fire to blame
"
            printf "  Stealth in my veins — that's the Fezzy aim.
"
            printf "  %s999 in the dark, I'm a ghost in the park
" "${YLW}"
            printf "  You won't see me coming, I'm a silent spark
"
            printf "  Stealth SYN, I'm a mark — Fezzy's leaving no mark.%s
" "${RST}"
            ;;
        "UDP Scan")
            printf "  %sUDP, the protocol that don't make a sound
" "${GRN}"
            printf "  But I'll find your open ports — they'll be found
"
            printf "  Like a ghost in the wind, I'm hunting around
"
            printf "  Fezzy's scanning the sky, you're on the ground.
"
            printf "  %s999 UDP flow, I'm moving like a pro
" "${YLW}"
            printf "  No TCP handshake, just a silent blow
"
            printf "  Fezzy's scanning the low — you better let it go.%s
" "${RST}"
            ;;
        "Vuln Script")
            printf "  %sI'm checking for holes, yeah, the cracks in your code
" "${GRN}"
            printf "  NSE scripts run, I'm heavy on the load
"
            printf "  One weak spot, and I'm taking the road
"
            printf "  Fezzy the auditor — you can't hide your abode.
"
            printf "  %s999 vulnerabilities, I'm counting every crack
" "${YLW}"
            printf "  You thought you were secure, but I'm the one who'll attack
"
            printf "  Vuln script, no turning back — Fezzy's on the track.%s
" "${RST}"
            ;;
        "Custom")
            printf "  %sMy flags, my rules, I'm the architect
" "${GRN}"
            printf "  Running whatever I choose — no one can object
"
            printf "  The terminal's my canvas, I don't need to connect
"
            printf "  Fezzy's custom flows — you'd better respect.
"
            printf "  %s999 custom vibes, I'm writing my own ties
" "${YLW}"
            printf "  No preset, no disguise — Fezzy's in the skies
"
            printf "  You can't cap my rise — I'm the one who never dies.%s
" "${RST}"
            ;;
        "Pasted Command")
            printf "  %sPaste your command, I'll run it raw and true
" "${GRN}"
            printf "  No limits, no filters — just me and you
"
            printf "  The terminal's my throne, the output my view
"
            printf "  Fezzy's execution — nobody can sue.
"
            printf "  %s999 pasted in the booth, I'm running every truth
" "${YLW}"
            printf "  No validation, no proof — Fezzy's the roof
"
            printf "  You paste, I move — that's the 999 proof.%s
" "${RST}"
            ;;
        "Connection Info")
            printf "  %sSSID and IP, I'm reading the signal's pulse
" "${GRN}"
            printf "  Link speed and MAC, no room for false
"
            printf "  Fezzy's diagnostics — I'm the network's consul
"
            printf "  Know your connection before the assault.
"
            printf "  %s999 connection check, I'm reading every speck
" "${YLW}"
            printf "  Your IP's on my neck — Fezzy's got you on deck
"
            printf "  Info in check, I'm the one you should expect.%s
" "${RST}"
            ;;
        "Scan Nearby Networks")
            printf "  %sI see every SSID, every channel, every shout
" "${GRN}"
            printf "  Signal strength in dBm, I'm mapping the route
"
            printf "  No network hidden, no router to flout
"
            printf "  Fezzy's WiFi scan — I leave no doubt.
"
            printf "  %s999 nearby, I'm scanning every eye
" "${YLW}"
            printf "  SSID in the sky, Fezzy's gonna fly
"
            printf "  You can't hide, I'm the guy — 999, goodbye.%s
" "${RST}"
            ;;
        "Gateway Discovery")
            printf "  %sDefault gateway, where the packets flow
" "${GRN}"
            printf "  I'll find your router, the path you'll know
"
            printf "  IP and details, I'm putting on a show
"
            printf "  Fezzy's discovery — the way to go.
"
            printf "  %s999 gateway, I'm finding every route
" "${YLW}"
            printf "  No hiding, no doubt — Fezzy's the scout
"
            printf "  You can't keep me out — 999, I'm about.%s
" "${RST}"
            ;;
        "Local Device Scan")
            printf "  %sHosts on my subnet, I'll find every one
" "${GRN}"
            printf "  Connected devices, no place to run
"
            printf "  Quick ping sweep — the job gets done
"
            printf "  Fezzy's local hunt, under the sun.
"
            printf "  %s999 local scan, I'm every living man
" "${YLW}"
            printf "  Device in my hand, Fezzy's the plan
"
            printf "  You can't escape the clan — 999, I'm the man.%s
" "${RST}"
            ;;
        "Network Bench")
            printf "  %sPing latency, I'm testing the connection's heart
" "${GRN}"
            printf "  Gateway or Google, I'll measure the art
"
            printf "  Five packets sent, then I depart
"
            printf "  Fezzy's benchmark — that's the smart part.
"
            printf "  %s999 bench, I'm measuring every tench
" "${YLW}"
            printf "  No flinch, no inch — Fezzy's the winch
"
            printf "  Latency in sync — 999, I'm the link.%s
" "${RST}"
            ;;
        "WiFi Local Discovery")
            printf "  %sSubnet scan, I'm sniffing every host alive
" "${GRN}"
            printf "  Living devices — I'll make them thrive
"
            printf "  No port scan, just a ping to drive
"
            printf "  Fezzy's discovery — the truth arrives.
"
            printf "  %s999 WiFi discovery, I'm moving with the glory
" "${YLW}"
            printf "  Every host a story, Fezzy's never boring
"
            printf "  You can't ignore me — 999, I'm soaring.%s
" "${RST}"
            ;;
        "XML Output")
            printf "  %sStructured data, I'm logging every breath
" "${GRN}"
            printf "  XML results, I'm cheating every death
"
            printf "  No detail lost, I'm the master of the depth
"
            printf "  Fezzy's reports — keeping secrets in the stealth.
"
            printf "  %s999 reporting, I'm writing every page
" "${YLW}"
            printf "  The data's the truth, I'm the one on the stage
"
            printf "  Output locked in, I'm breaking every cage.%s
" "${RST}"
            ;;
        "Grepable Output")
            printf "  %sOne line per host, I'm keeping it concise
" "${GRN}"
            printf "  Grepable flows, yeah, the data's looking nice
"
            printf "  Searching for the patterns, I don't need to ask twice
"
            printf "  Fezzy on the grep — I'm paying the price.
"
            printf "  %s999 in the line, I'm finding every port
" "${YLW}"
            printf "  Concise and clean, I'm the one in the court
"
            printf "  Grepable logic — that's the Fezzy resort.%s
" "${RST}"
            ;;
        "All Formats")
            printf "  %sEvery format known, I'm covering the base
" "${GRN}"
            printf "  XML, Grep, and Text — I'm leading the race
"
            printf "  Data everywhere, I'm setting up the pace
"
            printf "  Fezzy's archive — I'm leaving a trace.
"
            printf "  %s999 in the files, I'm logging every move
" "${YLW}"
            printf "  Full documentation, I've got nothing to prove
"
            printf "  All formats locked — that's the Fezzy groove.%s
" "${RST}"
            ;;
        "IPv6 Scan")
            printf "  %sIPv6, the new age, I'm mapping every byte\n" "${GRN}"
            printf "  No IPv4, just the future, shining bright\n"
            printf "  Fezzy's 128 bits, I'm scanning through the night\n"
            printf "  999 forever, IPv6 is the light.%s\n" "${RST}"
            ;;
        "Packet Trace")
            printf "  %sPacket trace, I'm watching every hop and move\n" "${GRN}"
            printf "  Seeing the data flow, I'm finding the groove\n"
            printf "  Every packet counted, I've got nothing to prove\n"
            printf "  Packet trace, 999, I'm the one who'll improve.%s\n" "${RST}"
            ;;
        "Traceroute")
            printf "  %sTraceroute, mapping the path to your gate\n" "${GRN}"
            printf "  Every router skipped, I'm deciding your fate\n"
            printf "  Fezzy in the network, I'm never gonna wait\n"
            printf "  999, traceroute, I'm the one who's great.%s\n" "${RST}"
            ;;
        "DNS Resolution Control")
            printf "  %sDNS servers, I'm picking where to go\n" "${GRN}"
            printf "  Resolution locked, I'm running the show\n"
            printf "  Fezzy in the lookup, moving fast, moving slow\n"
            printf "  DNS control, 999, let the data flow.%s\n" "${RST}"
            ;;
        "Service Version Intensity")
            printf "  %sVersion intensity, I'm digging down deep\n" "${GRN}"
            printf "  Finding the service while the network's asleep\n"
            printf "  Fezzy's precision, secrets I keep\n"
            printf "  999, version intensity, secrets I reap.%s\n" "${RST}"
            ;;
        "OS Detection Accuracy")
            printf "  %sOS detection, I'm reading your core\n" "${GRN}"
            printf "  Windows or Linux, I know who's at the door\n"
            printf "  Fezzy's mapping, I'm asking for more\n"
            printf "  OS detection, 999, settling the score.%s\n" "${RST}"
            ;;
        "Parallelism Control")
            printf "  %sParallelism, scanning fast as I can\n" "${GRN}"
            printf "  Handling the load, following the plan\n"
            printf "  Fezzy's multi-thread, the fastest in the land\n"
            printf "  999, parallelism, understand.%s\n" "${RST}"
            ;;
        "Packet Rate Control")
            printf "  %sPacket rate, I'm setting the pace\n" "${GRN}"
            printf "  Speeding it up, winning the race\n"
            printf "  Fezzy's control, all over the place\n"
            printf "  999, packet rate, leaving a trace.%s\n" "${RST}"
            ;;
        "Interface Selection")
            printf "  %sInterface selection, choosing my door\n" "${GRN}"
            printf "  Wlan or Ethernet, I'm checking the floor\n"
            printf "  Fezzy's movement, I'm asking for more\n"
            printf "  Interface select, 999, settling the score.%s\n" "${RST}"
            ;;
        "Proxy Support")
            printf "  %sProxy support, I'm hiding my track\n" "${GRN}"
            printf "  Socks5 or HTTP, no looking back\n"
            printf "  Fezzy in the shadows, I'm on the right track\n"
            printf "  Proxy control, 999, I'm leadin' the pack.%s\n" "${RST}"
            ;;
        "NSE Script Args")
            printf "  %sNSE args, I'm changing the game\n" "${GRN}"
            printf "  Sending parameters, I'm claiming my name\n"
            printf "  Fezzy's configuration, no two are the same\n"
            printf "  Script args, 999, I'm dodging the blame.%s\n" "${RST}"
            ;;
        "Host Timeout Control")
            printf "  %sHost timeout, I'm cutting you short\n" "${GRN}"
            printf "  Closing the session, I'm holding the fort\n"
            printf "  Fezzy's decision, the last resort\n"
            printf "  Host timeout, 999, I'm the master of the court.%s\n" "${RST}"
            ;;
        "Scan Delay Control")
            printf "  %sScan delay, I'm pausing the flow\n" "${GRN}"
            printf "  Giving you room, giving you time to grow\n"
            printf "  Fezzy in the pause, I'm moving like a pro\n"
            printf "  Scan delay, 999, just let it go.%s\n" "${RST}"
            ;;
        "Retry Control")
            printf "  %sRetry control, I'm giving it another try\n" "${GRN}"
            printf "  If it fails once, I'll never say goodbye\n"
            printf "  Fezzy's persistence, reachin' for the sky\n"
            printf "  Retry control, 999, never gonna die.%s\n" "${RST}"
            ;;
        "No Ping")
            printf "  %sNo ping, I'm skipping the beat\n" "${GRN}"
            printf "  Firewall is silent, I'm bringing the heat\n"
            printf "  Fezzy in the network, I'm making it complete\n"
            printf "  No ping, 999, I'm never in retreat.%s\n" "${RST}"
            ;;
        "SCTP Scanning")
            printf "  %sSCTP scan, a protocol rare\n" "${GRN}"
            printf "  Finding the services that others don't dare\n"
            printf "  Fezzy's insight, I'm scanning with care\n"
            printf "  SCTP, 999, I'm everywhere.%s\n" "${RST}"
            ;;
        "IPv6 Scan")
            printf "  %sStep 1: Uses the -6 flag to enable IPv6 scanning.\n" "${CYN}"
            printf "  Step 2: Nmap will probe the target using IPv6 protocols.\n"
            printf "  Step 3: Requires target and network to support IPv6.%s\n" "${RST}"
            ;;
        "Packet Trace")
            printf "  %sStep 1: Uses --packet-trace to display every packet Nmap sends and receives.\n" "${CYN}"
            printf "  Step 2: Provides deep insight into network communication.\n"
            printf "  Step 3: Excellent for debugging complex network issues.%s\n" "${RST}"
            ;;
        "Traceroute")
            printf "  %sStep 1: Uses --traceroute to map the path to the target.\n" "${CYN}"
            printf "  Step 2: Shows each hop the traffic takes to reach its destination.\n"
            printf "  Step 3: Helps identify bottlenecks and path configurations.%s\n" "${RST}"
            ;;
        "DNS Resolution Control")
            printf "  %sStep 1: Uses --dns-servers to specify custom DNS for resolution.\n" "${CYN}"
            printf "  Step 2: Can speed up scanning or resolve internal domains.\n"
            printf "  Step 3: Useful for testing DNS-based security filters.%s\n" "${RST}"
            ;;
        "Service Version Intensity")
            printf "  %sStep 1: Uses --version-intensity (0-9) to control service detection effort.\n" "${CYN}"
            printf "  Step 2: Higher intensity means deeper probing, slower speeds.\n"
            printf "  Step 3: Adjust based on your need for speed vs accuracy.%s\n" "${RST}"
            ;;
        "OS Detection Accuracy")
            printf "  %sStep 1: Uses --osscan-limit and --osscan-guess for refined OS matching.\n" "${CYN}"
            printf "  Step 2: Limits scan for OS detection to likely candidates.\n"
            printf "  Step 3: Helps get a closer guess on heavily firewalled systems.%s\n" "${RST}"
            ;;
        "Parallelism Control")
            printf "  %sStep 1: Sets --min-parallelism and --max-parallelism for concurrent scans.\n" "${CYN}"
            printf "  Step 2: Manages how many probes are active simultaneously.\n"
            printf "  Step 3: Crucial for optimizing performance on large network segments.%s\n" "${RST}"
            ;;
        "Packet Rate Control")
            printf "  %sStep 1: Sets --min-rate and --max-rate to control packets per second.\n" "${CYN}"
            printf "  Step 2: Prevents overwhelming targets or tripping rate limits.\n"
            printf "  Step 3: Essential for balancing stealth and performance.%s\n" "${RST}"
            ;;
        "Interface Selection")
            printf "  %sStep 1: Uses -e to force Nmap to use a specific network interface.\n" "${CYN}"
            printf "  Step 2: Ensures packets leave through your desired network path.\n"
            printf "  Step 3: Vital when you have multiple network connections.%s\n" "${RST}"
            ;;
        "Proxy Support")
            printf "  %sStep 1: Uses --proxies to route your traffic through a proxy server.\n" "${CYN}"
            printf "  Step 2: Helps hide your IP or bypass local restrictions.\n"
            printf "  Step 3: Great for distributed or indirect reconnaissance.%s\n" "${RST}"
            ;;
        "NSE Script Args")
            printf "  %sStep 1: Uses --script-args to pass variables to NSE scripts.\n" "${CYN}"
            printf "  Step 2: Allows custom configuration for advanced script execution.\n"
            printf "  Step 3: Essential for leveraging complex NSE script capabilities.%s\n" "${RST}"
            ;;
        "Host Timeout Control")
            printf "  %sStep 1: Uses --host-timeout to set the max time to scan a single host.\n" "${CYN}"
            printf "  Step 2: Prevents slow hosts from hanging your entire scan process.\n"
            printf "  Step 3: Great for keeping large network scans moving quickly.%s\n" "${RST}"
            ;;
        "Scan Delay Control")
            printf "  %sStep 1: Uses --scan-delay to inject a delay between probes.\n" "${CYN}"
            printf "  Step 2: Helpful for avoiding rate limits or IDS detections.\n"
            printf "  Step 3: Can be used to make scans look more "human" and less automated.%s\n" "${RST}"
            ;;
        "Retry Control")
            printf "  %sStep 1: Uses --max-retries to define how many times to probe a failed port.\n" "${CYN}"
            printf "  Step 2: Reduces noise and improves accuracy on unreliable connections.\n"
            printf "  Step 3: Balances speed against thoroughness for sensitive services.%s\n" "${RST}"
            ;;
        "No Ping")
            printf "  %sStep 1: Uses -Pn to skip host discovery (pinging).\n" "${CYN}"
            printf "  Step 2: Forces scan even if the target appears "down" due to firewalls.\n"
            printf "  Step 3: Vital for scanning heavily hardened or non-responsive targets.%s\n" "${RST}"
            ;;
        "SCTP Scanning")
            printf "  %sStep 1: Uses -sZ to enable SCTP initialization scan.\n" "${CYN}"
            printf "  Step 2: Used for probing SCTP-based services (like Telephony/SS7).\n"
            printf "  Step 3: Useful for niche and complex industrial network assessments.%s\n" "${RST}"
            ;;
        "Decoy Scan")
            printf "  %sHidden in the crowd, I'm moving like a ghost
" "${GRN}"
            printf "  Ten fake IPs, I'm the one you need the most
"
            printf "  Which one is me? I'm laughing at the post
"
            printf "  Fezzy's decoys — I'm toast to the coast.
"
            printf "  %s999 in the mist, I'm a shadow in the rain
" "${YLW}"
            printf "  You won't catch a trace, I'm dodging every pain
"
            printf "  Decoy mode active — I'm the master of the game.%s
" "${RST}"
            ;;
        "Fragmented Scan")
            printf "  %sSplit the packets up, I'm slipping through the cracks
" "${GRN}"
            printf "  Fragmented flows, I'm covering my tracks
"
            printf "  IDS won't see me, I'm making no attacks
"
            printf "  Fezzy's shards — I'm filling the lacks.
"
            printf "  %s999 in the pieces, I'm building it back
" "${YLW}"
            printf "  No firewall can stop me, I'm on the right track
"
            printf "  Fragmented logic — I'm leadin' the pack.%s
" "${RST}"
            ;;
        "Source Port Spoof")
            printf "  %sComing from port 53, I'm looking like DNS
" "${GRN}"
            printf "  Spoofing the source, I'm cleaning up the mess
"
            printf "  Bypassing filters, I'm under no stress
"
            printf "  Fezzy's disguise — I'm the one you should bless.
"
            printf "  %s999 in the source, I'm changing the flow
" "${YLW}"
            printf "  Common ports only, that's the way I go
"
            printf "  Source port spoof — you better let it know.%s
" "${RST}"
            ;;
        "Safe Scripts")
            printf "  %sNon-intrusive vibes, I'm keeping it polite
" "${GRN}"
            printf "  Safe NSE scripts, I'm scanning through the night
"
            printf "  No crashes, no alarms, I'm staying out of sight
"
            printf "  Fezzy's kindness — I'm doing it right.
"
            printf "  %s999 in the scripts, I'm loading every core
" "${YLW}"
            printf "  Safe or aggressive, I'm opening every door
"
            printf "  Discovery deep — you couldn't ask for more.%s
" "${RST}"
            ;;
        "Auth Scripts")
            printf "  %sChecking every door, I'm testing every lock
" "${GRN}"
            printf "  Authentication scripts, I'm ready for the shock
"
            printf "  Weak creds found, I'm running round the block
"
            printf "  Fezzy the locksmith — I'm the one who knocks.
"
            printf "  %s999 in the auth, I'm finding every crack
" "${YLW}"
            printf "  You thought you were secure, but I'm the one who'll attack
"
            printf "  Auth scripts running — no turning back.%s
" "${RST}"
            ;;
        "Discovery Scripts")
            printf "  %sService details deep, I'm reading every sign
" "${GRN}"
            printf "  Discovery scripts, I'm making them all mine
"
            printf "  Enumeration flows, I'm feeling so divine
"
            printf "  Fezzy's knowledge — I'm crossing every line.
"
            printf "  %s999 in the facts, I'm building the map
" "${YLW}"
            printf "  No hidden service safe, I'm closing the gap
"
            printf "  Discovery logic — I'm the one on the lap.%s
" "${RST}"
            ;;
        "Target List")
            printf "  %sReading from the file, I'm targeting the scope
" "${GRN}"
            printf "  A list of IPs, I'm giving them no hope
"
            printf "  Bulk scanning flows, I'm handling the rope
"
            printf "  Fezzy's precision — I'm helping you cope.
"
            printf "  %s999 in the list, I'm scanning every name
" "${YLW}"
            printf "  No one left behind, I'm winning every race
"
            printf "  Target file locked — I'm setting up the pace.%s
" "${RST}"
            ;;
        "Exclusion Scan")
            printf "  %sScan the whole range, but skip the ones I choose
" "${GRN}"
            printf "  Exclusion logic, I've got nothing to lose
"
            printf "  Precise and sharp, I'm shaking off the blues
"
            printf "  Fezzy's filter — I'm breaking the news.
"
            printf "  %s999 excluded, I'm focused on the rest
" "${YLW}"
            printf "  Selective scanning — I'm putting to the test
"
            printf "  Exclusion mode — I'm simply the best.%s
" "${RST}"
            ;;
        "Idle Scan")
            printf "  %sUsing a zombie, I'm hiding my own face
" "${GRN}"
            printf "  A silent partner, leading the whole race
"
            printf "  IPID sequences, I'm moving with the grace
"
            printf "  Fezzy's phantom — I'm leaving no trace.
"
            printf "  %s999 in the zombie, I'm scanning through the host
" "${YLW}"
            printf "  You won't see me coming, I'm a hidden ghost
"
            printf "  Idle scan active — I'm the one you need the most.%s
" "${RST}"
            ;;
        "MAC Spoofing")
            printf "  %sChanging my identity, I'm looking like a phone
" "${GRN}"
            printf "  A Cisco router, or a different zone
"
            printf "  Hardware address shifted, I'm never alone
"
            printf "  Fezzy's masquerade — I'm the one on the throne.
"
            printf "  %s999 in the hardware, I'm spoofing every sign
" "${YLW}"
            printf "  Your filters can't catch me, I'm feeling so divine
"
            printf "  MAC spoofing locked — I'm crossing every line.%s
" "${RST}"
            ;;
        "Bad Checksums")
            printf "  %sSending broken packets, I'm testing every rule
" "${GRN}"
            printf "  Garbage data flow, I'm playing like a fool
"
            printf "  But the firewall's weak, I'm breaking every tool
"
            printf "  Fezzy's corruption — I'm the one in the school.
"
            printf "  %s999 in the garbage, I'm finding every hole
" "${YLW}"
            printf "  Corruption is the truth, I'm taking the control
"
            printf "  Badsum scan running — I'm reaching for the soul.%s
" "${RST}"
            ;;
        "Timing T0-T5")
            printf "  %sSpeeding up the clock, or moving like a snail
" "${GRN}"
            printf "  Timing templates set, I'm never gonna fail
"
            printf "  Paranoid or Insane, I'm riding on the rail
"
            printf "  Fezzy's tempo — I'm the one with the grail.
"
            printf "  %s999 in the rhythm, I'm setting up the pace
" "${YLW}"
            printf "  No matter the speed, I'm winning every race
"
            printf "  Timing locked in — I'm leading the chase.%s
" "${RST}"
            ;;
        "Specific Script")
            printf "  %sOne script, one target, I'm focused on the prize
" "${GRN}"
            printf "  Precision engineering, I'm looking through the eyes
"
            printf "  No wasted energy, I'm cutting all the ties
"
            printf "  Fezzy's laser — I'm the one in the skies.
"
            printf "  %s999 in the script, I'm running every line
" "${YLW}"
            printf "  Targeted exploitation — I'm feeling so divine
"
            printf "  Script mode active — I'm making it mine.%s
" "${RST}"
            ;;
        *)
            printf "  %s999 in the code, I'm scanning every road
" "${GRN}"
            printf "  Fezzy's heavy load — you can't escape the mode
"
            printf "  Strategy over impulse, that's the Fezzy ode
"
            printf "  999 forever — I'm the one you need to know.%s
" "${RST}"
            ;;
    esac
    echo ""
}

# ============================================================
#  DISPLAY HEADER (SYNOPSIS -> PROMPT -> INSTRUCTIONS)
# ============================================================

display_scan_header() {
    local label="$1"
    local flags="$2"
    local need_target="$3"

    clear
    banner
    echo ""

    # Balanced title with underline
    local title="FEZZY NMAP · $label"
    local title_len=${#title}
    printf "%s%s%s
" "${HOT}" "$title" "${RST}"
    short_pink_line $title_len
    echo ""

    # SYNOPSIS section
    printf "${CYN}[ SYNOPSIS — 999 ]${RST}
"
    juice_poetry "$label"

    # COMMAND PROMPT (if needed)
    if [[ "$need_target" == "yes" ]]; then
        printf "${CYN}[ TARGET INPUT ]${RST}
"
        echo ""
        printf "  %sEnter target IP or domain: %s" "${HOT}" "${RST}"
        read -r TARGET
        echo ""
    else
        TARGET=""
    fi

    # INSTRUCTIONS section
    printf "${CYN}[ INSTRUCTIONS ]${RST}
"
    echo ""
    case "$label" in
        "Quick Scan")
            printf "  %sStep 1: Nmap performs a fast TCP SYN scan on the 100 most common ports.
" "${CYN}"
            printf "  Step 2: Results show open ports and services in under 30 seconds.
"
            printf "  Step 3: Use this for rapid reconnaissance on a target you already know.%s
" "${RST}"
            ;;
        "Full Port Scan")
            printf "  %sStep 1: Nmap scans all 65535 TCP ports (slow but thorough).
" "${CYN}"
            printf "  Step 2: Expect 2-5 minutes per host; you'll get every open port.
"
            printf "  Step 3: Use for red team assessments where no service can hide.%s
" "${RST}"
            ;;
        "Intense Scan")
            printf "  %sStep 1: Nmap runs OS detection, version scanning, and aggressive scripts.
" "${CYN}"
            printf "  Step 2: Verbose output shows detailed banners and NSE results.
"
            printf "  Step 3: Best for deep exploitation prep after initial discovery.%s
" "${RST}"
            ;;
        "Stealth SYN")
            printf "  %sStep 1: Nmap uses SYN half-open scanning (requires root for raw packets).
" "${CYN}"
            printf "  Step 2: Slower timing (-T2) reduces log detection chances.
"
            printf "  Step 3: Ideal for evading basic intrusion detection systems.%s
" "${RST}"
            ;;
        "UDP Scan")
            printf "  %sStep 1: Nmap sends UDP packets to common ports (DNS, SNMP, etc).
" "${CYN}"
            printf "  Step 2: Open UDP services reply; closed ones rarely respond.
"
            printf "  Step 3: Run after TCP scan to uncover hidden services.%s
" "${RST}"
            ;;
        "Vuln Script")
            printf "  %sStep 1: Nmap loads the 'vuln' script category from NSE.
" "${CYN}"
            printf "  Step 2: Each script checks a specific known vulnerability.
"
            printf "  Step 3: Review output for CVEs — then exploit or patch.%s
" "${RST}"
            ;;
        "Custom")
            printf "  %sStep 1: Enter your own nmap flags (e.g., -T4 -p 80,443).
" "${CYN}"
            printf "  Step 2: The script will run nmap with exactly what you type.
"
            printf "  Step 3: Full control — no pre-set logic.%s
" "${RST}"
            ;;
        "Pasted Command")
            printf "  %sStep 1: Paste any nmap command (including options and target).
" "${CYN}"
            printf "  Step 2: The script executes it directly, logging output.
"
            printf "  Step 3: For advanced users who know exactly what they want.%s
" "${RST}"
            ;;
        "Connection Info")
            printf "  %sStep 1: Reads SSID, IP address, and link speed from termux-api.
" "${CYN}"
            printf "  Step 2: Falls back to system IP if termux-api is missing.
"
            printf "  Step 3: Use to verify your current network posture.%s
" "${RST}"
            ;;
        "Scan Nearby Networks")
            printf "  %sStep 1: Triggers a WiFi scan via termux-wifi-scaninfo.
" "${CYN}"
            printf "  Step 2: Lists every visible SSID with channel and signal dBm.
"
            printf "  Step 3: Helps choose the strongest network or detect rogue APs.%s
" "${RST}"
            ;;
        "Gateway Discovery")
            printf "  %sStep 1: Reads the default route from 'ip route show'.
" "${CYN}"
            printf "  Step 2: Displays gateway IP and interface details.
"
            printf "  Step 3: Essential for targeting the router in internal tests.%s
" "${RST}"
            ;;
        "Local Device Scan")
            printf "  %sStep 1: Detects your subnet (e.g., 192.168.1.0/24).
" "${CYN}"
            printf "  Step 2: Runs a ping sweep (-sn) to find live hosts.
"
            printf "  Step 3: Outputs IPs of all devices currently connected.%s
" "${RST}"
            ;;
        "Network Bench")
            printf "  %sStep 1: Pings your gateway 5 times, measures latency.
" "${CYN}"
            printf "  Step 2: If gateway unreachable, pings Google DNS (8.8.8.8).
"
            printf "  Step 3: Use to test network stability before scanning.%s
" "${RST}"
            ;;
        "WiFi Local Discovery")
            printf "  %sStep 1: Automatically detects your subnet.
" "${CYN}"
            printf "  Step 2: Runs a ping sweep (-sn) to find live hosts.
"
            printf "  Step 3: Stores discovered IPs for use in later scans.%s
" "${RST}"
            ;;
        "XML Output")
            printf "  %sStep 1: Nmap saves the scan results in XML format.
" "${CYN}"
            printf "  Step 2: File is saved to your downloads folder as fezzy_scan.xml.
"
            printf "  Step 3: Best for importing into Metasploit, Zenmap, or custom tools.%s
" "${RST}"
            ;;
        "Grepable Output")
            printf "  %sStep 1: Nmap saves the scan results in a 'grepable' format.
" "${CYN}"
            printf "  Step 2: File is saved to your downloads folder as fezzy_scan.gnmap.
"
            printf "  Step 3: Ideal for rapid command-line analysis using grep and awk.%s
" "${RST}"
            ;;
        "All Formats")
            printf "  %sStep 1: Nmap saves results in Text, XML, and Grepable formats.
" "${CYN}"
            printf "  Step 2: Files are saved to your downloads folder with 'fezzy_scan_all' prefix.
"
            printf "  Step 3: Complete documentation of your scan for future reference.%s
" "${RST}"
            ;;
        "IPv6 Scan")
            printf "  %sIPv6, the new age, I'm mapping every byte\n" "${GRN}"
            printf "  No IPv4, just the future, shining bright\n"
            printf "  Fezzy's 128 bits, I'm scanning through the night\n"
            printf "  999 forever, IPv6 is the light.%s\n" "${RST}"
            ;;
        "Packet Trace")
            printf "  %sPacket trace, I'm watching every hop and move\n" "${GRN}"
            printf "  Seeing the data flow, I'm finding the groove\n"
            printf "  Every packet counted, I've got nothing to prove\n"
            printf "  Packet trace, 999, I'm the one who'll improve.%s\n" "${RST}"
            ;;
        "Traceroute")
            printf "  %sTraceroute, mapping the path to your gate\n" "${GRN}"
            printf "  Every router skipped, I'm deciding your fate\n"
            printf "  Fezzy in the network, I'm never gonna wait\n"
            printf "  999, traceroute, I'm the one who's great.%s\n" "${RST}"
            ;;
        "DNS Resolution Control")
            printf "  %sDNS servers, I'm picking where to go\n" "${GRN}"
            printf "  Resolution locked, I'm running the show\n"
            printf "  Fezzy in the lookup, moving fast, moving slow\n"
            printf "  DNS control, 999, let the data flow.%s\n" "${RST}"
            ;;
        "Service Version Intensity")
            printf "  %sVersion intensity, I'm digging down deep\n" "${GRN}"
            printf "  Finding the service while the network's asleep\n"
            printf "  Fezzy's precision, secrets I keep\n"
            printf "  999, version intensity, secrets I reap.%s\n" "${RST}"
            ;;
        "OS Detection Accuracy")
            printf "  %sOS detection, I'm reading your core\n" "${GRN}"
            printf "  Windows or Linux, I know who's at the door\n"
            printf "  Fezzy's mapping, I'm asking for more\n"
            printf "  OS detection, 999, settling the score.%s\n" "${RST}"
            ;;
        "Parallelism Control")
            printf "  %sParallelism, scanning fast as I can\n" "${GRN}"
            printf "  Handling the load, following the plan\n"
            printf "  Fezzy's multi-thread, the fastest in the land\n"
            printf "  999, parallelism, understand.%s\n" "${RST}"
            ;;
        "Packet Rate Control")
            printf "  %sPacket rate, I'm setting the pace\n" "${GRN}"
            printf "  Speeding it up, winning the race\n"
            printf "  Fezzy's control, all over the place\n"
            printf "  999, packet rate, leaving a trace.%s\n" "${RST}"
            ;;
        "Interface Selection")
            printf "  %sInterface selection, choosing my door\n" "${GRN}"
            printf "  Wlan or Ethernet, I'm checking the floor\n"
            printf "  Fezzy's movement, I'm asking for more\n"
            printf "  Interface select, 999, settling the score.%s\n" "${RST}"
            ;;
        "Proxy Support")
            printf "  %sProxy support, I'm hiding my track\n" "${GRN}"
            printf "  Socks5 or HTTP, no looking back\n"
            printf "  Fezzy in the shadows, I'm on the right track\n"
            printf "  Proxy control, 999, I'm leadin' the pack.%s\n" "${RST}"
            ;;
        "NSE Script Args")
            printf "  %sNSE args, I'm changing the game\n" "${GRN}"
            printf "  Sending parameters, I'm claiming my name\n"
            printf "  Fezzy's configuration, no two are the same\n"
            printf "  Script args, 999, I'm dodging the blame.%s\n" "${RST}"
            ;;
        "Host Timeout Control")
            printf "  %sHost timeout, I'm cutting you short\n" "${GRN}"
            printf "  Closing the session, I'm holding the fort\n"
            printf "  Fezzy's decision, the last resort\n"
            printf "  Host timeout, 999, I'm the master of the court.%s\n" "${RST}"
            ;;
        "Scan Delay Control")
            printf "  %sScan delay, I'm pausing the flow\n" "${GRN}"
            printf "  Giving you room, giving you time to grow\n"
            printf "  Fezzy in the pause, I'm moving like a pro\n"
            printf "  Scan delay, 999, just let it go.%s\n" "${RST}"
            ;;
        "Retry Control")
            printf "  %sRetry control, I'm giving it another try\n" "${GRN}"
            printf "  If it fails once, I'll never say goodbye\n"
            printf "  Fezzy's persistence, reachin' for the sky\n"
            printf "  Retry control, 999, never gonna die.%s\n" "${RST}"
            ;;
        "No Ping")
            printf "  %sNo ping, I'm skipping the beat\n" "${GRN}"
            printf "  Firewall is silent, I'm bringing the heat\n"
            printf "  Fezzy in the network, I'm making it complete\n"
            printf "  No ping, 999, I'm never in retreat.%s\n" "${RST}"
            ;;
        "SCTP Scanning")
            printf "  %sSCTP scan, a protocol rare\n" "${GRN}"
            printf "  Finding the services that others don't dare\n"
            printf "  Fezzy's insight, I'm scanning with care\n"
            printf "  SCTP, 999, I'm everywhere.%s\n" "${RST}"
            ;;
        "IPv6 Scan")
            printf "  %sStep 1: Uses the -6 flag to enable IPv6 scanning.\n" "${CYN}"
            printf "  Step 2: Nmap will probe the target using IPv6 protocols.\n"
            printf "  Step 3: Requires target and network to support IPv6.%s\n" "${RST}"
            ;;
        "Packet Trace")
            printf "  %sStep 1: Uses --packet-trace to display every packet Nmap sends and receives.\n" "${CYN}"
            printf "  Step 2: Provides deep insight into network communication.\n"
            printf "  Step 3: Excellent for debugging complex network issues.%s\n" "${RST}"
            ;;
        "Traceroute")
            printf "  %sStep 1: Uses --traceroute to map the path to the target.\n" "${CYN}"
            printf "  Step 2: Shows each hop the traffic takes to reach its destination.\n"
            printf "  Step 3: Helps identify bottlenecks and path configurations.%s\n" "${RST}"
            ;;
        "DNS Resolution Control")
            printf "  %sStep 1: Uses --dns-servers to specify custom DNS for resolution.\n" "${CYN}"
            printf "  Step 2: Can speed up scanning or resolve internal domains.\n"
            printf "  Step 3: Useful for testing DNS-based security filters.%s\n" "${RST}"
            ;;
        "Service Version Intensity")
            printf "  %sStep 1: Uses --version-intensity (0-9) to control service detection effort.\n" "${CYN}"
            printf "  Step 2: Higher intensity means deeper probing, slower speeds.\n"
            printf "  Step 3: Adjust based on your need for speed vs accuracy.%s\n" "${RST}"
            ;;
        "OS Detection Accuracy")
            printf "  %sStep 1: Uses --osscan-limit and --osscan-guess for refined OS matching.\n" "${CYN}"
            printf "  Step 2: Limits scan for OS detection to likely candidates.\n"
            printf "  Step 3: Helps get a closer guess on heavily firewalled systems.%s\n" "${RST}"
            ;;
        "Parallelism Control")
            printf "  %sStep 1: Sets --min-parallelism and --max-parallelism for concurrent scans.\n" "${CYN}"
            printf "  Step 2: Manages how many probes are active simultaneously.\n"
            printf "  Step 3: Crucial for optimizing performance on large network segments.%s\n" "${RST}"
            ;;
        "Packet Rate Control")
            printf "  %sStep 1: Sets --min-rate and --max-rate to control packets per second.\n" "${CYN}"
            printf "  Step 2: Prevents overwhelming targets or tripping rate limits.\n"
            printf "  Step 3: Essential for balancing stealth and performance.%s\n" "${RST}"
            ;;
        "Interface Selection")
            printf "  %sStep 1: Uses -e to force Nmap to use a specific network interface.\n" "${CYN}"
            printf "  Step 2: Ensures packets leave through your desired network path.\n"
            printf "  Step 3: Vital when you have multiple network connections.%s\n" "${RST}"
            ;;
        "Proxy Support")
            printf "  %sStep 1: Uses --proxies to route your traffic through a proxy server.\n" "${CYN}"
            printf "  Step 2: Helps hide your IP or bypass local restrictions.\n"
            printf "  Step 3: Great for distributed or indirect reconnaissance.%s\n" "${RST}"
            ;;
        "NSE Script Args")
            printf "  %sStep 1: Uses --script-args to pass variables to NSE scripts.\n" "${CYN}"
            printf "  Step 2: Allows custom configuration for advanced script execution.\n"
            printf "  Step 3: Essential for leveraging complex NSE script capabilities.%s\n" "${RST}"
            ;;
        "Host Timeout Control")
            printf "  %sStep 1: Uses --host-timeout to set the max time to scan a single host.\n" "${CYN}"
            printf "  Step 2: Prevents slow hosts from hanging your entire scan process.\n"
            printf "  Step 3: Great for keeping large network scans moving quickly.%s\n" "${RST}"
            ;;
        "Scan Delay Control")
            printf "  %sStep 1: Uses --scan-delay to inject a delay between probes.\n" "${CYN}"
            printf "  Step 2: Helpful for avoiding rate limits or IDS detections.\n"
            printf "  Step 3: Can be used to make scans look more "human" and less automated.%s\n" "${RST}"
            ;;
        "Retry Control")
            printf "  %sStep 1: Uses --max-retries to define how many times to probe a failed port.\n" "${CYN}"
            printf "  Step 2: Reduces noise and improves accuracy on unreliable connections.\n"
            printf "  Step 3: Balances speed against thoroughness for sensitive services.%s\n" "${RST}"
            ;;
        "No Ping")
            printf "  %sStep 1: Uses -Pn to skip host discovery (pinging).\n" "${CYN}"
            printf "  Step 2: Forces scan even if the target appears "down" due to firewalls.\n"
            printf "  Step 3: Vital for scanning heavily hardened or non-responsive targets.%s\n" "${RST}"
            ;;
        "SCTP Scanning")
            printf "  %sStep 1: Uses -sZ to enable SCTP initialization scan.\n" "${CYN}"
            printf "  Step 2: Used for probing SCTP-based services (like Telephony/SS7).\n"
            printf "  Step 3: Useful for niche and complex industrial network assessments.%s\n" "${RST}"
            ;;
        "Decoy Scan")
            printf "  %sStep 1: Nmap uses 10 random decoy IP addresses to mask your own.
" "${CYN}"
            printf "  Step 2: Makes it difficult for defenders to determine the true source.
"
            printf "  Step 3: Use to evade IP-based rate limiting and detection.%s
" "${RST}"
            ;;
        "Fragmented Scan")
            printf "  %sStep 1: Nmap splits TCP headers into smaller fragments.
" "${CYN}"
            printf "  Step 2: This can bypass simple packet filters and IDS systems.
"
            printf "  Step 3: Effective against older firewalls that don't reassemble fragments.%s
" "${RST}"
            ;;
        "Source Port Spoof")
            printf "  %sStep 1: Nmap sends packets from a specific source port (e.g., 53).
" "${CYN}"
            printf "  Step 2: Many firewalls allow all traffic from common ports like DNS or HTTP.
"
            printf "  Step 3: Use to bypass strict outgoing/incoming firewall rules.%s
" "${RST}"
            ;;
        "Safe Scripts")
            printf "  %sStep 1: Nmap runs scripts that are considered safe and non-intrusive.
" "${CYN}"
            printf "  Step 2: These scripts perform discovery without risking service crashes.
"
            printf "  Step 3: Recommended for initial reconnaissance on production systems.%s
" "${RST}"
            ;;
        "Auth Scripts")
            printf "  %sStep 1: Nmap runs scripts that check for common authentication issues.
" "${CYN}"
            printf "  Step 2: Checks for default passwords, weak creds, and anonymous access.
"
            printf "  Step 3: Essential for identifying easy entry points into a system.%s
" "${RST}"
            ;;
        "Discovery Scripts")
            printf "  %sStep 1: Nmap runs scripts for active service and network discovery.
" "${CYN}"
            printf "  Step 2: Provides much more detail than a standard version scan.
"
            printf "  Step 3: Use for deep enumeration of banners, shares, and versions.%s
" "${RST}"
            ;;
        "Target List")
            printf "  %sStep 1: Nmap reads the list of targets from the specified file.
" "${CYN}"
            printf "  Step 2: Each IP or hostname should be on a new line in the file.
"
            printf "  Step 3: Perfect for scanning large lists generated by other tools.%s
" "${RST}"
            ;;
        "Exclusion Scan")
            printf "  %sStep 1: Nmap scans the target range but skips the excluded IPs.
" "${CYN}"
            printf "  Step 2: Useful for avoiding sensitive devices (like printers or servers).
"
            printf "  Step 3: Enter exclusions as a comma-separated list.%s
" "${RST}"
            ;;
        "Idle Scan")
            printf "  %sStep 1: Nmap uses an 'idle' host to bounce the scan off.
" "${CYN}"
            printf "  Step 2: Requires a host with predictable IPID sequences.
"
            printf "  Step 3: Ultimate stealth — your IP never touches the target.%s
" "${RST}"
            ;;
        "MAC Spoofing")
            printf "  %sStep 1: Nmap changes your MAC address to a random or specific one.
" "${CYN}"
            printf "  Step 2: Bypasses MAC-based filters and makes you look like a different device.
"
            printf "  Step 3: Effective for evading simple network access control (NAC).%s
" "${RST}"
            ;;
        "Bad Checksums")
            printf "  %sStep 1: Nmap sends packets with incorrect TCP/UDP checksums.
" "${CYN}"
            printf "  Step 2: Most systems drop these, but some firewalls let them pass.
"
            printf "  Step 3: Use to discover misconfigured firewalls or IDS rules.%s
" "${RST}"
            ;;
        "Timing T0-T5")
            printf "  %sStep 1: Choose a timing template from T0 (Slowest) to T5 (Fastest).
" "${CYN}"
            printf "  Step 2: T0/T1 are for stealth; T4/T5 are for speed on fast nets.
"
            printf "  Step 3: Adjusts timeouts and parallelism automatically.%s
" "${RST}"
            ;;
        "Specific Script")
            printf "  %sStep 1: Enter the exact name of an NSE script (e.g., http-title).
" "${CYN}"
            printf "  Step 2: Nmap runs only that script against the target.
"
            printf "  Step 3: Best for surgical enumeration of known services.%s
" "${RST}"
            ;;
        *)
            printf "  %sStep 1: Execute the scan as configured.
" "${CYN}"
            printf "  Step 2: Review output in the log file.
"
            printf "  Step 3: Use the post-launch menu to re-run or view logs.%s
" "${RST}"
            ;;
    esac

    # Final separator
    echo ""
    short_pink_line $title_len
    echo ""

    # TARGET already set by read above — no echo needed
    # Callers use the global $TARGET directly
}

# ============================================================
#  RUN SCAN
# ============================================================

run_scan() {
    local flags="$1" label="$2" target_override="$3"

    if [ -n "$target_override" ]; then
        TARGET="$target_override"
        display_scan_header "$label" "$flags" "no"
    else
        # FIXED: call display_scan_header directly (not in $(...))
        # It reads TARGET internally via read -r TARGET and sets the global
        display_scan_header "$label" "$flags" "yes"
        # TARGET is now set by display_scan_header via the global read
    fi

    [ -z "$TARGET" ] && { printf "  %s[!] No target entered.%s\n" "${RED}" "${RST}"; sleep 1; return; }

    printf "\n  %s[*] Launching — %s on %s...%s\n\n" "${CYN}" "$label" "$TARGET" "${RST}"
    mkdir -p "$(dirname "$LOG")"
    {
        echo "=== FEZZY NMAP · $label ==="
        echo "Target  : $TARGET"
        echo "Command : nmap $flags $TARGET"
        echo "Time    : $(date)"
        echo "================================"
        nmap $flags "$TARGET" 2>&1
        echo ""
    } | tee -a "$LOG"

    post_launch "$flags" "$label" "$target_override"
}

post_launch() {
    local flags="$1" label="$2" target_override="$3"
    echo ""
    printf "  %s[+] Done. Log: %s%s
" "${GRN}" "$LOG" "${RST}"
    echo ""
    printf "  ${GRN}[V]${RST} View Log  ${GRN}[R]${RST} Re-run  ${YLW}[B]${RST} Back  ${RED}[Q]${RST} Quit
"
    echo ""
    printf "  %sChoose: %s" "${HOT}" "${RST}"
    read -r POST_CHOICE
    
    case "$POST_CHOICE" in
        v|V) echo ""; cat "$LOG"; echo ""; printf "  %sPress ENTER...%s" "${HOT}" "${RST}"; read -r _; post_launch "$flags" "$label" "$target_override" ;;
        r|R) run_scan "$flags" "$label" "$target_override" ;;
        b|B) return ;;
        q|Q) printf "
  %s999 · Out.%s

" "${HOT}" "${RST}"; exit 0 ;;
        *)   post_launch "$flags" "$label" "$target_override" ;;
    esac
}

run_paste() {
    while true; do
        clear; banner; echo ""
        center_in_box "PASTE · URL FETCH · COMMAND RUNNER"
        short_pink_line 36; echo ""
        printf "  ${GRN}[1]${RST}  Paste & Run Nmap Command   ${DESC}- run any nmap flags directly${RST}\n"
        printf "  ${GRN}[2]${RST}  Fetch URL Headers          ${DESC}- curl -sI <url> header preview${RST}\n"
        printf "  ${GRN}[3]${RST}  Fetch URL Full Response    ${DESC}- curl -s <url> full body dump${RST}\n"
        printf "  ${GRN}[4]${RST}  CDN Check Before Scan      ${DESC}- detect CDN/WAF on target URL${RST}\n"
        printf "  ${YLW}[B]${RST}  Back\n\n"
        printf "  %sChoose: %s" "${HOT}" "${RST}"; read -r PASTE_CHOICE

        case "${PASTE_CHOICE,,}" in
            1)
                display_scan_header "Pasted Command" "" "no"; echo ""
                printf "  %sPaste your Nmap command: %s" "${HOT}" "${RST}"
                read -r PASTED_CMD
                [ -z "$PASTED_CMD" ] && { printf "  %s[!] Nothing entered.%s\n" "${RED}" "${RST}"; sleep 1; continue; }
                # Block clearly dangerous patterns
                if echo "$PASTED_CMD" | grep -qE "rm -rf|mkfs|dd if=|chmod 777 /|> /etc"; then
                    printf "  %s[!!] Blocked: destructive pattern detected.%s\n" "${RED}" "${RST}"
                    sleep 2; continue
                fi
                printf "\n  ${YLW}[!] Pasted commands run unvalidated. Confirm? (y/n): ${RST}"
                read -r CONFIRM_CMD
                [[ "$CONFIRM_CMD" =~ ^[Yy]$ ]] || { printf "  %s[!!] Cancelled.%s\n" "${RED}" "${RST}"; sleep 1; continue; }
                printf "\n  %s[*] Executing...%s\n\n" "${CYN}" "${RST}"
                {
                    echo "=== FEZZY G.I.JOE V9 · PASTED COMMAND ==="
                    echo "Command : $PASTED_CMD"
                    echo "Time    : $(date)"
                    echo "=========================================="
                    eval "$PASTED_CMD" 2>&1
                    echo ""
                } | tee -a "$LOG"
                post_launch "custom" "Pasted Command" "$PASTED_CMD"
                ;;
            2)
                display_scan_header "URL Header Fetch" "" "no"; echo ""
                printf "  %sEnter URL (e.g. https://example.com): %s" "${HOT}" "${RST}"
                read -r FETCH_URL
                [ -z "$FETCH_URL" ] && { printf "  %s[!] No URL entered.%s\n" "${RED}" "${RST}"; sleep 1; continue; }
                echo "$FETCH_URL" | grep -qE "^https?://" || FETCH_URL="https://${FETCH_URL}"
                printf "\n  %s[*] Fetching headers for: %s%s\n\n" "${CYN}" "$FETCH_URL" "${RST}"
                pulse_bar "Fetching" 1
                curl -sI --max-time 10 "$FETCH_URL" 2>/dev/null || printf "  %s[!] Fetch failed — check URL or connection.%s\n" "${RED}" "${RST}"
                ;;
            3)
                display_scan_header "URL Full Response" "" "no"; echo ""
                printf "  %sEnter URL: %s" "${HOT}" "${RST}"
                read -r FETCH_URL
                [ -z "$FETCH_URL" ] && { printf "  %s[!] No URL entered.%s\n" "${RED}" "${RST}"; sleep 1; continue; }
                echo "$FETCH_URL" | grep -qE "^https?://" || FETCH_URL="https://${FETCH_URL}"
                printf "\n  %s[*] Fetching body: %s%s\n\n" "${CYN}" "$FETCH_URL" "${RST}"
                pulse_bar "Fetching" 1
                curl -sL --max-time 15 "$FETCH_URL" 2>/dev/null | head -80                     || printf "  %s[!] Fetch failed.%s\n" "${RED}" "${RST}"
                ;;
            4)
                display_scan_header "CDN Check" "" "no"; echo ""
                printf "  %sEnter domain or URL: %s" "${HOT}" "${RST}"
                read -r CDN_TARGET
                [ -z "$CDN_TARGET" ] && { printf "  %s[!] No target.%s\n" "${RED}" "${RST}"; sleep 1; continue; }
                CDN_TARGET=$(echo "$CDN_TARGET" | sed 's|https\?://||' | cut -d/ -f1)
                printf "\n  %s[*] CDN/WAF check on %s...%s\n\n" "${CYN}" "$CDN_TARGET" "${RST}"
                pulse_bar "Probing" 1
                local _CDN="${HOME}/go/bin/cdncheck"
                command -v cdncheck >/dev/null 2>&1 && _CDN="cdncheck"
                if [[ -x "$_CDN" ]] || command -v cdncheck >/dev/null 2>&1; then
                    echo "$CDN_TARGET" | "$_CDN" -resp 2>/dev/null || printf "  %s[!] cdncheck failed.%s\n" "${RED}" "${RST}"
                else
                    printf "  %s[!] cdncheck not installed.%s\n" "${YLW}" "${RST}"
                    printf "  %sInstall: go install github.com/projectdiscovery/cdncheck/cmd/cdncheck@latest%s\n" "${CYN}" "${RST}"
                    echo ""
                    printf "  %s[*] Fallback: checking headers for CDN signatures...%s\n" "${CYN}" "${RST}"
                    local hdrs; hdrs=$(curl -sI --max-time 8 "https://$CDN_TARGET" 2>/dev/null)
                    echo "$hdrs" | grep -iE "cloudflare|akamai|fastly|cloudfront|sucuri|incapsula|x-cdn"                         && printf "  %s[+] CDN/WAF signature detected in headers.%s\n" "${GRN}" "${RST}"                         || printf "  %s[-] No obvious CDN signature in headers.%s\n" "${YLW}" "${RST}"
                fi
                ;;
            b) return ;;
            *) printf "  %s[!] Invalid.%s\n" "${RED}" "${RST}"; sleep 1 ;;
        esac
        echo ""; printf "  %sPress ENTER...%s" "${HOT}" "${RST}"; read -r _
    done
}

# ============================================================
#  WIFI ELITE
# ============================================================

wifi_elite_menu() {
    while true; do
        clear; banner
        echo ""
        center_in_box "WIFI ELITE · ROOTLESS DIAGNOSTICS"
        pink_line
        echo ""
        printf "  ${GRN}[1]${RST} Scan Nearby Networks  ${DESC}- List SSIDs, Signal, Channels${RST}\n"
        printf "  ${GRN}[2]${RST} Gateway Discovery     ${DESC}- Find router IP & details${RST}\n"
        printf "  ${GRN}[3]${RST} Local Device Scan     ${DESC}- Quick scan of connected hosts${RST}\n"
        printf "  ${GRN}[4]${RST} Network Bench         ${DESC}- Simple ping latency check${RST}\n"
        printf "  ${GRN}[5]${RST} ARP Host Sweep        ${DESC}- Rootless ARP-style subnet sweep${RST}\n"
        printf "  ${GRN}[6]${RST} Interface Inspector   ${DESC}- Show all network interfaces & IPs${RST}\n"
        printf "  ${GRN}[7]${RST} DNS Leak Check        ${DESC}- Query multiple DNS servers for leak detection${RST}\n"
        printf "  ${GRN}[8]${RST} Route Trace           ${DESC}- Traceroute to gateway or custom host${RST}\n"
        printf "  ${YLW}[B]${RST} Back to Main Menu\n"
        echo ""
        printf "  %sChoose: %s" "${HOT}" "${RST}"
        read -r WIFI_CHOICE

        case "$WIFI_CHOICE" in
            1|W1|w1)
                display_scan_header "Scan Nearby Networks" "" "no"
                echo ""
                if $TAPI_INSTALLED; then
                    printf "  %s[*] Scanning... (Wait a few seconds)%s\n" "${CYN}" "${RST}"
                    termux-wifi-scaninfo
                else
                    printf "  %s[!] termux-api not found.%s\n" "${RED}" "${RST}"
                fi
                ;;
            2|W2|w2)
                display_scan_header "Gateway Discovery" "" "no"
                echo ""
                ip route show | grep "default"
                ;;
            3|W3|w3)
                display_scan_header "Local Device Scan" "" "no"
                echo ""
                local subnet
                subnet=$(ip route show | grep "default" | awk '{print $3}' | cut -d'.' -f1-3)".0/24"
                if [ -n "$subnet" ]; then
                    run_scan "-sn" "WiFi Local Discovery" "$subnet"
                    return
                else
                    printf "  %s[!] Could not detect subnet.%s\n" "${RED}" "${RST}"
                fi
                ;;
            4|W4|w4)
                display_scan_header "Network Bench" "" "no"
                echo ""
                local gw
                gw=$(ip route show | grep "default" | awk '{print $3}')
                if [ -n "$gw" ]; then
                    printf "  %s[*] Pinging Gateway: %s%s\n" "${CYN}" "$gw" "${RST}"
                    ping -c 5 "$gw"
                else
                    printf "  %s[*] Pinging Google DNS...%s\n" "${CYN}" "${RST}"
                    ping -c 5 8.8.8.8
                fi
                ;;
            5|W5|w5)
                echo ""
                printf "  %s[*] ARP-style subnet sweep (ping -sn)...%s\n" "${CYN}" "${RST}"
                local subnet
                subnet=$(ip route show | grep "default" | awk '{print $3}' | cut -d'.' -f1-3)".0/24"
                [ -z "$subnet" ] || [ "$subnet" = ".0/24" ] && {
                    printf "  %sEnter subnet (e.g. 192.168.1.0/24): %s" "${HOT}" "${RST}"
                    read -r subnet
                }
                printf "  %s[*] Sweeping %s...%s\n" "${CYN}" "$subnet" "${RST}"
                nmap -sn --send-ip "$subnet" 2>/dev/null | grep -E "Nmap scan report|MAC Address" \
                    || nmap -sn "$subnet" 2>/dev/null | grep "Nmap scan report"
                ;;
            6|W6|w6)
                echo ""
                printf "  %s[*] Network Interfaces & IPs:%s\n" "${CYN}" "${RST}"
                ip -o addr show 2>/dev/null | awk '{printf "  '"${GRN}"'%-12s'"${RST}"'  %s\n", $2, $4}' \
                    || ifconfig 2>/dev/null | grep -E "^[a-z]|inet "
                echo ""
                printf "  %s[*] Routing Table:%s\n" "${CYN}" "${RST}"
                ip route show 2>/dev/null
                ;;
            7|W7|w7)
                echo ""
                printf "  %s[*] DNS Leak Check — querying multiple resolvers...%s\n" "${CYN}" "${RST}"
                local domain="whoami.akamai.net"
                for ns in 8.8.8.8 1.1.1.1 9.9.9.9 208.67.222.222; do
                    local result
                    result=$(nslookup "$domain" "$ns" 2>/dev/null | grep -i "address" | tail -1)
                    printf "  %s%-16s%s → %s\n" "${YLW}" "$ns" "${RST}" "${result:-no response}"
                done
                echo ""
                printf "  %s[*] Current /etc/resolv.conf:%s\n" "${CYN}" "${RST}"
                cat /etc/resolv.conf 2>/dev/null || printf "  %s[!] Not accessible%s\n" "${RED}" "${RST}"
                ;;
            8|W8|w8)
                echo ""
                printf "  %sTrace to gateway or custom host? (g=gateway / enter IP): %s" "${HOT}" "${RST}"
                read -r TRACE_TARGET
                if [ -z "$TRACE_TARGET" ] || [ "$TRACE_TARGET" = "g" ]; then
                    TRACE_TARGET=$(ip route show | grep "default" | awk '{print $3}')
                    [ -z "$TRACE_TARGET" ] && TRACE_TARGET="8.8.8.8"
                fi
                printf "  %s[*] Traceroute to %s...%s\n" "${CYN}" "$TRACE_TARGET" "${RST}"
                traceroute "$TRACE_TARGET" 2>/dev/null \
                    || nmap --traceroute -sn "$TRACE_TARGET" 2>/dev/null \
                    || printf "  %s[!] traceroute not available%s\n" "${RED}" "${RST}"
                ;;
            b|B) return ;;
        esac
        printf "
  %sPress ENTER...%s" "${HOT}" "${RST}"
        read -r _
    done
}


advanced_targets_menu() {
    while true; do
        clear; banner
        echo ""
        center_in_box "ADVANCED TARGETS"
        pink_line
        echo ""
        printf "  ${GRN}[1]${RST} IPv6 Scan\n  ${GRN}[2]${RST} Packet Trace\n  ${GRN}[3]${RST} Traceroute\n  ${GRN}[4]${RST} DNS Servers\n  ${GRN}[5]${RST} Version Intensity\n  ${GRN}[6]${RST} OS Detection Accuracy\n  ${GRN}[7]${RST} Parallelism\n  ${GRN}[8]${RST} Packet Rate\n  ${GRN}[9]${RST} Interface Selection\n  ${GRN}[10]${RST} Proxy Support\n  ${GRN}[11]${RST} NSE Script Args\n  ${GRN}[12]${RST} Host Timeout\n  ${GRN}[13]${RST} Scan Delay\n  ${GRN}[14]${RST} Max Retries\n  ${GRN}[15]${RST} No Ping\n  ${GRN}[16]${RST} SCTP Scan\n  ${YLW}[B]${RST} Back\n"
        echo ""
        printf "  %sChoose: %s" "${HOT}" "${RST}"
        read -r choice
        case "$choice" in
            1) run_scan "-6" "IPv6 Scan" ;;
            2) run_scan "--packet-trace" "Packet Trace" ;;
            3) run_scan "--traceroute" "Traceroute" ;;
            4) printf "  %sEnter DNS servers: %s" "${HOT}" "${RST}"; read -r dns; run_scan "--dns-servers $dns" "DNS Resolution Control" ;;
            5) printf "  %sEnter intensity (0-9): %s" "${HOT}" "${RST}"; read -r int; run_scan "--version-intensity $int" "Service Version Intensity" ;;
            6) run_scan "--osscan-limit --osscan-guess" "OS Detection Accuracy" ;;
            7) printf "  %sEnter min-parallelism: %s" "${HOT}" "${RST}"; read -r min; printf "  %sEnter max-parallelism: %s" "${HOT}" "${RST}"; read -r max; run_scan "--min-parallelism $min --max-parallelism $max" "Parallelism Control" ;;
            8) printf "  %sEnter min-rate: %s" "${HOT}" "${RST}"; read -r min; printf "  %sEnter max-rate: %s" "${HOT}" "${RST}"; read -r max; run_scan "--min-rate $min --max-rate $max" "Packet Rate Control" ;;
            9) printf "  %sEnter interface: %s" "${HOT}" "${RST}"; read -r iface; run_scan "-e $iface" "Interface Selection" ;;
            10) printf "  %sEnter proxy: %s" "${HOT}" "${RST}"; read -r proxy; run_scan "--proxies $proxy" "Proxy Support" ;;
            11) printf "  %sEnter script args: %s" "${HOT}" "${RST}"; read -r args; run_scan "--script-args $args" "NSE Script Args" ;;
            12) printf "  %sEnter host timeout: %s" "${HOT}" "${RST}"; read -r tout; run_scan "--host-timeout $tout" "Host Timeout Control" ;;
            13) printf "  %sEnter scan delay: %s" "${HOT}" "${RST}"; read -r delay; run_scan "--scan-delay $delay" "Scan Delay Control" ;;
            14) printf "  %sEnter max-retries: %s" "${HOT}" "${RST}"; read -r ret; run_scan "--max-retries $ret" "Retry Control" ;;
            15) run_scan "-Pn" "No Ping" ;;
            16) run_scan "-sZ" "SCTP Scanning" ;;
            b|B) return ;;
        esac
    done
}

install_deps() {
    clear; banner
    echo ""
    printf "%s  [*] SYSTEM DIAGNOSTICS & ROBUST INSTALLER...%s
" "${CYN}" "${RST}"
    local pkg_manager=""
    if   command -v pkg  >/dev/null 2>&1; then pkg_manager="pkg"
    elif command -v apt  >/dev/null 2>&1; then pkg_manager="apt"
    elif command -v brew >/dev/null 2>&1; then pkg_manager="brew"
    fi
    echo ""
    [ -n "$pkg_manager" ] && printf "  Detected PM: ${GRN}%s${RST}
" "$pkg_manager" || printf "  Detected PM: ${RED}NONE FOUND (Manual Mode Active)${RST}
"
    echo ""
    printf "  ${GRN}[1]${RST} Standard Install (nmap + curl)          ${DESC}- Recommended${RST}\n"
    printf "  ${GRN}[2]${RST} Full Arsenal Setup (nmap, curl, git, wget) ${DESC}- Robust${RST}\n"
    printf "  ${GRN}[3]${RST} WiFi Elite Support (termux-api)           ${DESC}- Extra features${RST}\n"
    printf "  ${GRN}[4]${RST} Clone Fezzy Arsenal Repo (GitHub)         ${DESC}- Dev version${RST}\n"
    printf "  ${GRN}[5]${RST} Offline/Fallback (Local Registration)      ${DESC}- Manual setup${RST}\n"
    printf "  ${GRN}[6]${RST} Install All Go Rootless Tools (V9)         ${DESC}- nuclei/httpx/subfinder/tlsx/cdncheck/hakrawler/anew${RST}\n"
    printf "  ${GRN}[7]${RST} Install Python Web Tools                   ${DESC}- sqlmap/wafw00f/theHarvester${RST}\n"
    printf "  ${YLW}[B]${RST} Back\n"
    echo ""
    printf "  %sStrategy: %s" "${HOT}" "${RST}"
    read -r DEP_CHOICE

    case "$DEP_CHOICE" in
        1) [ -n "$pkg_manager" ] && install_package "nmap" "$pkg_manager" "nmap ready."
           [ -n "$pkg_manager" ] && install_package "curl" "$pkg_manager" "curl ready." ;;
        2) for p in nmap curl git wget; do [ -n "$pkg_manager" ] && install_package "$p" "$pkg_manager" "$p ready."; done ;;
        3) if [ "$pkg_manager" = "pkg" ]; then install_package "termux-api" "pkg" "termux-api ready."
           printf "  %s[!] Please ensure Termux:API app is installed from Play/F-Droid.%s
" "${YLW}" "${RST}"
           else printf "  %s[!] WiFi Elite features are optimized for Termux.%s
" "${YLW}" "${RST}"; fi ;;
        4)
            if ! command -v git >/dev/null 2>&1; then
                printf "%s  [!] Git missing. Installing...%s
" "${YLW}" "${RST}"
                [ -n "$pkg_manager" ] && install_package "git" "$pkg_manager" "git ready."
            fi
            printf "
  %sChoose clone method:%s
" "${HOT}" "${RST}"
            printf "  ${GRN}[1]${RST} HTTPS (Standard)
"
            printf "  ${GRN}[2]${RST} SSH   (Advanced)
"
            printf "  %sChoose: %s" "${HOT}" "${RST}"
            read -r CLONE_METHOD
            local clone_cmd=""
            case "$CLONE_METHOD" in
                1) clone_cmd="$GIT_CLONE_HTTPS_CMD" ;;
                2) clone_cmd="$GIT_CLONE_SSH_CMD" ;;
                *) return 1 ;;
            esac
            printf "%s  [*] Cloning...%s
" "${CYN}" "${RST}"
            if eval "$clone_cmd "${HOME}/fezzy-arsenal"" 2>&1; then
                printf "%s  [+] Success! Repo at: %s/fezzy-arsenal%s
" "${GRN}" "$HOME" "${RST}"
            else
                printf "%s  [!!] Clone failed. Check internet/SSH keys.%s
" "${RED}" "${RST}"
            fi
            ;;
        5)
            clear; banner
            pink_line
            center_in_box "OFFLINE / MANUAL INSTALLATION"
            pink_line
            echo ""
            printf "  ${YLW}1.${RST} Install 'nmap' manually via your terminal.
"
            printf "  ${YLW}2.${RST} Ensure script permissions are correct: chmod +x %s
" "$(basename "$SCRIPT_PATH")"
            printf "  ${YLW}3.${RST} Run [2] from main menu to register global alias.
"
            printf "  ${YLW}4.${RST} For dashboard integration, move this script to /usr/bin/ or ~/bin/.

"
            printf "  %sPress ENTER to continue...%s" "${HOT}" "${RST}"
            read -r _
            return
            ;;
        6)
            printf "\n  %s[*] Installing Go rootless toolkit — V9...%s\n" "${CYN}" "${RST}"
            if ! command -v go >/dev/null 2>&1; then
                printf "  %s[!] Go not installed. Run: pkg install golang%s\n" "${RED}" "${RST}"
            else
                local _tools=(
                    "github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest"
                    "github.com/projectdiscovery/httpx/cmd/httpx@latest"
                    "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
                    "github.com/projectdiscovery/katana/cmd/katana@latest"
                    "github.com/projectdiscovery/naabu/v2/cmd/naabu@latest"
                    "github.com/projectdiscovery/dnsx/cmd/dnsx@latest"
                    "github.com/projectdiscovery/cdncheck/cmd/cdncheck@latest"
                    "github.com/projectdiscovery/tlsx/cmd/tlsx@latest"
                    "github.com/projectdiscovery/notify/cmd/notify@latest"
                    "github.com/hakluke/hakrawler@latest"
                    "github.com/tomnomnom/anew@latest"
                    "github.com/tomnomnom/waybackurls@latest"
                    "github.com/lc/gau/v2/cmd/gau@latest"
                )
                for t in "${_tools[@]}"; do
                    local tname; tname=$(basename "$t" | sed 's/@.*//')
                    printf "  %s[*] Installing %s...%s\n" "${CYN}" "$tname" "${RST}"
                    pulse_bar "Installing $tname" 3
                    go install "$t" 2>/dev/null                         && printf "  %s[+] %s done%s\n" "${GRN}" "$tname" "${RST}"                         || printf "  %s[!] %s failed%s\n" "${RED}" "$tname" "${RST}"
                done
            fi
            ;;
        7)
            printf "\n  %s[*] Installing Python web tools...%s\n" "${CYN}" "${RST}"
            for p in sqlmap wafw00f theHarvester; do
                printf "  %s[*] pip install %s...%s\n" "${CYN}" "$p" "${RST}"
                pulse_bar "Installing $p" 2
                pip install "$p" --break-system-packages 2>/dev/null                     && printf "  %s[+] %s done%s\n" "${GRN}" "$p" "${RST}"                     || printf "  %s[!] %s failed%s\n" "${RED}" "$p" "${RST}"
            done
            ;;
        b|B) return ;;
    esac
    check_deps
    printf "\n  %s[+] Process finished. Press ENTER...%s" "${GRN}" "${RST}"
    read -r _
}

auto_scan_menu() {
    while true; do
        clear; banner
        echo ""
        center_in_box "AUTOMATIC SCANS · AI STRATEGY"
        pink_line
        echo ""
        printf "  ${GRN}[1]${RST} Subnet Discovery    ${DESC}- Find live hosts on local net & store for later${RST}
"
        printf "  ${GRN}[2]${RST} Range Area Scan     ${DESC}- Scan specific IP range (e.g. .1-100)${RST}
"
        printf "  ${GRN}[3]${RST} IoT/Device Hunter   ${DESC}- Search for cameras, TVs, smart devices${RST}
"
        printf "  ${GRN}[4]${RST} Service Sweep       ${DESC}- Rapid check for SSH, RDP, SMB, VNC${RST}
"
        printf "  ${GRN}[5]${RST} Deep Auto-Recon     ${DESC}- Discover live hosts, then intense scan${RST}
"
        printf "  ${GRN}[6]${RST} Rapid Ping Sweep    ${DESC}- Live hosts only (No ports)${RST}
"
        printf "  ${YLW}[B]${RST} Back to Main Menu
"
        echo ""
        printf "  %sStrategy: %s" "${HOT}" "${RST}"
        read -r AUTO_CHOICE

        case "$AUTO_CHOICE" in
            1)
                local subnet
                subnet=$(ip route show | grep "default" | awk '{print $3}' | cut -d'.' -f1-3)".0/24"
                if [[ "$subnet" == ".0/24" || -z "$subnet" ]]; then
                    printf "  %s[!] Could not auto-detect. Enter subnet (e.g. 192.168.1.0/24): %s" "${RED}" "${RST}"
                    read -r subnet
                fi
                if [ -n "$subnet" ]; then
                    printf "  %s[*] Discovering live hosts on %s...%s
" "${CYN}" "$subnet" "${RST}"
                    local discovered_hosts_output
                    discovered_hosts_output=$(nmap -sn "$subnet" | grep "Nmap scan report for" | awk '{print $5}')
                    LIVE_HOSTS=()
                    if [ -n "$discovered_hosts_output" ]; then
                        for host in $discovered_hosts_output; do
                            LIVE_HOSTS+=("$host")
                        done
                        printf "  %s[+] Discovered %s live hosts. Stored for intelligent scans!%s
" "${GRN}" "${#LIVE_HOSTS[@]}" "${RST}"
                    else
                        printf "  %s[!] No live hosts found on %s.%s
" "${RED}" "$subnet" "${RST}"
                    fi
                fi
                ;;
            2|3|4|5|6)
                local scan_flags=""
                local scan_label=""
                local default_target_prompt=""
                case "$AUTO_CHOICE" in
                    2) scan_flags="-T4 -F"; scan_label="Range Area Scan"; default_target_prompt="Enter Range (e.g. 192.168.1.1-50):" ;;
                    3) scan_flags="-T4 -p 80,443,554,1900,8080,8443 --open"; scan_label="IoT/Device Hunter"; default_target_prompt="Enter Target/Subnet (e.g. 192.168.1.0/24):" ;;
                    4) scan_flags="-T4 -p 21,22,23,445,3389,5900 --open"; scan_label="Service Sweep"; default_target_prompt="Enter Target/Subnet (e.g. 192.168.1.0/24):" ;;
                    5) scan_flags="-T4 -A"; scan_label="Deep Auto-Recon"; default_target_prompt="Enter Target/Subnet (e.g. 192.168.1.0/24):" ;;
                    6) scan_flags="-sn"; scan_label="Rapid Ping Sweep"; default_target_prompt="Enter Target/Subnet (e.g. 192.168.1.0/24):" ;;
                esac

                if [ ${#LIVE_HOSTS[@]} -gt 0 ]; then
                    printf "
  %sDetected %s previously discovered hosts. Options:%s
" "${CYN}" "${#LIVE_HOSTS[@]}" "${RST}"
                    printf "  ${GRN}[A]${RST} Scan ALL Discovered Hosts (${#LIVE_HOSTS[@]} hosts)
"
                    printf "  ${GRN}[M]${RST} Manual Input (Enter new target)
"
                    printf "  %sChoose: %s" "${HOT}" "${RST}"
                    read -r USE_LIVE_HOSTS_CHOICE
                    if [[ "$USE_LIVE_HOSTS_CHOICE" =~ ^[Aa]$ ]]; then
                        printf "
  %s[*] Scanning ALL %s discovered hosts with %s...%s
" "${CYN}" "${#LIVE_HOSTS[@]}" "$scan_label" "${RST}"
                        for host in "${LIVE_HOSTS[@]}"; do
                            run_scan "$scan_flags" "$scan_label: $host" "$host"
                        done
                    elif [[ "$USE_LIVE_HOSTS_CHOICE" =~ ^[Mm]$ ]]; then
                        printf "  %s%s %s" "${HOT}" "$default_target_prompt" "${RST}"
                        read -r TARG
                        [ -n "$TARG" ] && run_scan "$scan_flags" "$scan_label" "$TARG"
                    else
                        printf "  %s[!] Invalid choice. Returning to menu.%s
" "${RED}" "${RST}"
                    fi
                else
                    printf "  %s[!] No hosts discovered yet. Run Subnet Discovery [1] first, or enter target manually.
" "${YLW}" "${RST}"
                    printf "  %s%s %s" "${HOT}" "$default_target_prompt" "${RST}"
                    read -r TARG
                    [ -n "$TARG" ] && run_scan "$scan_flags" "$scan_label" "$TARG"
                fi
                ;;
            b|B) return ;;
            *) continue ;;
        esac
        printf "
  %sPress ENTER...%s" "${HOT}" "${RST}"
        read -r _
    done
}

self_update() {
    clear; banner
    echo ""
    printf "%s  [*] Checking for updates...%s
" "${CYN}" "${RST}"
    if ! command -v curl >/dev/null 2>&1; then
        printf "%s  [!] curl not installed. Use [I] first.%s
" "${RED}" "${RST}"
        sleep 2
        return 1
    fi
    local temp_file="${TMPDIR:-/tmp}/fezzy-nmap-update.sh"
    if curl -s -o "$temp_file" "$REPO_URL"; then
        local new_version
        new_version=$(grep "^SCRIPT_VERSION=" "$temp_file" | cut -d'"' -f2)
        if [ -n "$new_version" ] && [ "$new_version" != "$SCRIPT_VERSION" ]; then
            printf "%s  [+] New: %s -> %s%s
" "${GRN}" "$SCRIPT_VERSION" "$new_version" "${RST}"
            printf "  Update? (y/n): ${HOT}"
            read -r do_update
            printf "${RST}"
            if [[ "$do_update" =~ ^[Yy]$ ]]; then
                cp "$SCRIPT_PATH" "${SCRIPT_PATH}.bak"
                cp "$temp_file" "$SCRIPT_PATH"
                chmod +x "$SCRIPT_PATH"
                printf "%s  [+] Updated. Restarting...%s
" "${GRN}" "${RST}"
                sleep 2
                exec "$SCRIPT_PATH"
            fi
        else
            printf "%s  [+] Latest (%s).%s
" "${GRN}" "$SCRIPT_VERSION" "${RST}"
        fi
    else
        printf "%s  [!!] Failed to fetch.%s
" "${RED}" "${RST}"
    fi
    rm -f "$temp_file"
    sleep 2
}

open_facebook() {
    clear; banner
    echo ""
    pink_line
    center_in_box "FOLLOW FOR MORE SCRIPTS"
    pink_line
    printf "${GRN}
"
    center_in_box "  ${FB_LINK}"
    center_in_box "More tools. More power. Fezzy Arsenal."
    printf "${RST}
"
    echo ""
    echo "  Opening in browser..."
    if   command -v termux-open-url >/dev/null 2>&1; then termux-open-url "$FB_LINK" 2>/dev/null
    elif command -v xdg-open       >/dev/null 2>&1; then xdg-open "$FB_LINK" 2>/dev/null
    elif command -v open           >/dev/null 2>&1; then open "$FB_LINK" 2>/dev/null
    else printf "  %sCopy link and open manually.%s
" "${YLW}" "${RST}"; fi
    echo ""
    printf "  %sPress ENTER...%s" "${HOT}" "${RST}"
    read -r _
}

alias_setup() {
    clear; banner; echo ""
    pink_line
    center_in_box "ADD ALIAS · fezzynmap"
    pink_line
    echo ""
    if grep -q "alias fezzynmap=" ~/.bashrc 2>/dev/null; then
        printf "  %s[+] Alias already set. Run: fezzynmap%s
" "${GRN}" "${RST}"
    else
        cp ~/.bashrc ~/.bashrc.bak
        echo "alias fezzynmap='bash ${SCRIPT_PATH}'" >> ~/.bashrc
        printf "  %s[+] Alias added. Run: source ~/.bashrc then fezzynmap%s
" "${GRN}" "${RST}"
    fi
    echo ""
    printf "  %sPress ENTER...%s" "${HOT}" "${RST}"
    read -r _
}

advanced_output_menu() {
    while true; do
        clear; banner
        echo ""
        center_in_box "ADVANCED OUTPUT · STRUCTURED DATA"
        pink_line
        echo ""
        printf "  ${GRN}[1]${RST} XML Output         ${DESC}- Best for importing to other tools (-oX)${RST}
"
        printf "  ${GRN}[2]${RST} Grepable Output   ${DESC}- Easy to search with grep/awk (-oG)${RST}
"
        printf "  ${GRN}[3]${RST} All Formats       ${DESC}- Text, XML, and Grepable at once (-oA)${RST}
"
        printf "  ${YLW}[B]${RST} Back to Main Menu
"
        echo ""
        printf "  %sChoose: %s" "${HOT}" "${RST}"
        read -r OUT_CHOICE
        case "$OUT_CHOICE" in
            1) run_scan "-oX ${HOME}/storage/downloads/fezzy_scan.xml" "XML Output" ;;
            2) run_scan "-oG ${HOME}/storage/downloads/fezzy_scan.gnmap" "Grepable Output" ;;
            3) run_scan "-oA ${HOME}/storage/downloads/fezzy_scan_all" "All Formats" ;;
            b|B) return ;;
        esac
    done
}

evasion_stealth_menu() {
    while true; do
        clear; banner
        echo ""
        center_in_box "EVASION & STEALTH · BYPASS TECHNIQUES"
        pink_line
        echo ""
        printf "  ${GRN}[1]${RST} Decoy Scan         ${DESC}- Hide your IP with decoys (-D RND:10)${RST}
"
        printf "  ${GRN}[2]${RST} Fragmented Scan    ${DESC}- Split packets to evade IDS (-f)${RST}
"
        printf "  ${GRN}[3]${RST} Source Port Spoof  ${DESC}- Use common ports like 53 or 80 (--source-port)${RST}
"
        printf "  ${YLW}[B]${RST} Back to Main Menu
"
        echo ""
        printf "  %sChoose: %s" "${HOT}" "${RST}"
        read -r EV_CHOICE
        case "$EV_CHOICE" in
            1) run_scan "-D RND:10" "Decoy Scan" ;;
            2) run_scan "-f" "Fragmented Scan" ;;
            3) 
                printf "  %sEnter Source Port (e.g. 53, 80, 443): %s" "${HOT}" "${RST}"
                read -r SPORT
                [ -n "$SPORT" ] && run_scan "--source-port $SPORT" "Source Port Spoof"
                ;;
            b|B) return ;;
        esac
    done
}

script_category_menu() {
    while true; do
        clear; banner
        echo ""
        center_in_box "NSE CATEGORIES · SCRIPT AUTOMATION"
        pink_line
        echo ""
        printf "  ${GRN}[1]${RST} Safe Scripts       ${DESC}- Non-intrusive discovery (--script safe)${RST}
"
        printf "  ${GRN}[2]${RST} Auth Scripts       ${DESC}- Check for weak credentials (--script auth)${RST}
"
        printf "  ${GRN}[3]${RST} Discovery Scripts  ${DESC}- Detailed service enumeration (--script discovery)${RST}
"
        printf "  ${YLW}[B]${RST} Back to Main Menu
"
        echo ""
        printf "  %sChoose: %s" "${HOT}" "${RST}"
        read -r NSE_CHOICE
        case "$NSE_CHOICE" in
            1) run_scan "--script safe" "Safe Scripts" ;;
            2) run_scan "--script auth" "Auth Scripts" ;;
            3) run_scan "--script discovery" "Discovery Scripts" ;;
            b|B) return ;;
        esac
    done
}

advanced_stealth_menu() {
    while true; do
        clear; banner
        echo ""
        center_in_box "ADVANCED STEALTH · IDLE SCAN"
        pink_line
        echo ""
        printf "  ${GRN}[1]${RST} Idle Scan          ${DESC}- Scan using a zombie host (-sI)${RST}
"
        printf "  ${YLW}[B]${RST} Back to Main Menu
"
        echo ""
        printf "  %sChoose: %s" "${HOT}" "${RST}"
        read -r ST_CHOICE
        case "$ST_CHOICE" in
            1) run_scan "-sI" "Idle Scan" "" ;;
            b|B) return ;;
        esac
    done
}

network_spoofing_menu() {
    while true; do
        clear; banner
        echo ""
        center_in_box "NETWORK SPOOFING · IDENTITY"
        pink_line
        echo ""
        printf "  ${GRN}[1]${RST} MAC Spoofing       ${DESC}- Spoof MAC address (--spoof-mac)${RST}
"
        printf "  ${YLW}[B]${RST} Back to Main Menu
"
        echo ""
        printf "  %sChoose: %s" "${HOT}" "${RST}"
        read -r SP_CHOICE
        case "$SP_CHOICE" in
            1) run_scan "--spoof-mac" "MAC Spoofing" "" ;;
            b|B) return ;;
        esac
    done
}

firewall_testing_menu() {
    while true; do
        clear; banner
        echo ""
        center_in_box "FIREWALL TESTING · BAD CHECKSUMS"
        pink_line
        echo ""
        printf "  ${GRN}[1]${RST} Bad Checksums      ${DESC}- Send invalid checksums (--badsum)${RST}
"
        printf "  ${YLW}[B]${RST} Back to Main Menu
"
        echo ""
        printf "  %sChoose: %s" "${HOT}" "${RST}"
        read -r FT_CHOICE
        case "$FT_CHOICE" in
            1) run_scan "--badsum" "Bad Checksums" "" ;;
            b|B) return ;;
        esac
    done
}

timing_performance_menu() {
    while true; do
        clear; banner
        echo ""
        center_in_box "TIMING · PERFORMANCE"
        pink_line
        echo ""
        printf "  ${GRN}[1]${RST} T0 (Paranoid)      ${DESC}- Extremely slow stealth
"
        printf "  ${GRN}[2]${RST} T2 (Polite)        ${DESC}- Slow for reliability
"
        printf "  ${GRN}[3]${RST} T4 (Aggressive)    ${DESC}- Fast for modern nets
"
        printf "  ${GRN}[4]${RST} T5 (Insane)        ${DESC}- Max speed
"
        printf "  ${YLW}[B]${RST} Back to Main Menu
"
        echo ""
        printf "  %sChoose: %s" "${HOT}" "${RST}"
        read -r T_CHOICE
        case "$T_CHOICE" in
            1) run_scan "-T0" "Timing T0-T5" "" ;;
            2) run_scan "-T2" "Timing T0-T5" "" ;;
            3) run_scan "-T4" "Timing T0-T5" ;;
            4) run_scan "-T5" "Timing T0-T5" ;;
            b|B) return ;;
        esac
    done
}

nse_pro_menu() {
    while true; do
        clear; banner
        echo ""
        center_in_box "NSE PRO · SURGICAL EXPLOITATION"
        pink_line
        echo ""
        printf "  ${GRN}[1]${RST} Run Specific Script  ${DESC}- Run one NSE script
"
        printf "  ${YLW}[B]${RST} Back to Main Menu
"
        echo ""
        printf "  %sChoose: %s" "${HOT}" "${RST}"
        read -r NSE_P_CHOICE
        case "$NSE_P_CHOICE" in
            1)
                printf "  %sEnter Script Name (e.g. http-title): %s" "${HOT}" "${RST}"
                read -r SNAME
                run_scan "--script $SNAME" "Specific Script" ""
                ;;
            b|B) return ;;
        esac
    done
}


# ============================================================
#  FEZZY G.I.JOE · WEB ARSENAL FUNCTIONS
# ============================================================

# --- Poetry for each web tool ---
gijoe_poetry() {
    local label="$1"
    echo ""
    case "$label" in
        "Domain Intelligence"*|*"DNS Lookup"*|*"WHOIS Query"*|*"Full"*|*"DNS Brute"*)
            printf "  %sI'm digging through the DNS, finding every hidden name\n" "${GRN}"
            printf "  Whois records tell me who's playing the game\n"
            printf "  No domain hidden, no registrar can hide\n"
            printf "  999 domain intel – I'm the one who's always inside.%s\n" "${RST}"
            ;;
        "Web Fingerprint"*)
            printf "  %sI'm fingerprinting your tech, every server I can see\n" "${GRN}"
            printf "  CMS and frameworks, I know what you're running for me\n"
            printf "  No hidden stack, no WAF can blind my eye\n"
            printf "  999 tech detective – I'm the one who gets it fly.%s\n" "${RST}"
            ;;
        "SSL Check"*)
            printf "  %sI'm checking your certificate, every chain and every sign\n" "${GRN}"
            printf "  TLS and SSL, I'm exposing every line\n"
            printf "  No expired cert, no weak cipher can fool me\n"
            printf "  999 crypto checker – I'm the one who sets you free.%s\n" "${RST}"
            ;;
        "Vulnerability Scan"*)
            printf "  %sI'm scanning your web server, every flaw I'm gonna find\n" "${GRN}"
            printf "  Misconfigurations, outdated software on my mind\n"
            printf "  No hidden vulnerability, no hole can stay\n"
            printf "  999 web auditor – I'm the one who's here to stay.%s\n" "${RST}"
            ;;
        "Directory Hunter"*)
            printf "  %sI'm busting through your directories, every path I'm gonna find\n" "${GRN}"
            printf "  Subdomain brute force, I'm leaving nothing behind\n"
            printf "  No hidden folder, no secret page can hide\n"
            printf "  999 directory hunter – I'm the one who's always inside.%s\n" "${RST}"
            ;;
        "Web Crawler"*)
            printf "  %sI'm crawling through your website, every link I'm gonna take\n" "${GRN}"
            printf "  URLs and emails, I'm gonna make your data shake\n"
            printf "  No hidden endpoint, no script can escape my view\n"
            printf "  999 web crawler – I'm the one who's always true.%s\n" "${RST}"
            ;;
        "Fuzzing Engine"*)
            printf "  %sI'm fuzzing every parameter, every payload I'm gonna send\n" "${GRN}"
            printf "  Hidden endpoints and bugs, I'm gonna find your friend\n"
            printf "  No filter can stop me, no WAF can block my way\n"
            printf "  999 web fuzzer – I'm the one who's here to stay.%s\n" "${RST}"
            ;;
        "Netcat"*)
            printf "  %sBanner coming in, I'm reading every byte\n" "${GRN}"
            printf "  Port probe in the dark, I'm moving through the night\n"
            printf "  Service fingerprint raw – no tool does it tighter\n"
            printf "  999 netcat – I'm the network's ghost writer.%s\n" "${RST}"
            ;;
        "JQ Parser"*)
            printf "  %sJSON responses raw, I'm parsing every key\n" "${GRN}"
            printf "  API recon data, filtering what I need to see\n"
            printf "  No structured data hides, I pull it clean and free\n"
            printf "  999 jq – I'm the one who breaks the tree.%s\n" "${RST}"
            ;;
        "theHarvester"*)
            printf "  %sEmails from the search engine, subdomains from the DNS\n" "${GRN}"
            printf "  IPs and names dropping – passive recon finesse\n"
            printf "  Google, Bing, and HackerTarget – I've got every address\n"
            printf "  999 harvester – leaving nothing to guess.%s\n" "${RST}"
            ;;
        "Httprobe"*)
            printf "  %sDomain list in my hand, I'm confirming who is live\n" "${GRN}"
            printf "  HTTP and HTTPS, I'm testing every drive\n"
            printf "  Dead domains filtered out, only live ones survive\n"
            printf "  999 httprobe – I'm the one who helps you thrive.%s\n" "${RST}"
            ;;
        "SQLMap"*)
            printf "  %sInjection in the parameter, the database is mine\n" "${GRN}"
            printf "  Blind, union, error-based – every attack refined\n"
            printf "  Nikto misses SQL – I go straight to the find\n"
            printf "  999 sqlmap – I'm crossing every line.%s\n" "${RST}"
            ;;
        "WAF Detect"*)
            printf "  %sWAF in the way? I'm naming it before I move\n" "${GRN}"
            printf "  Cloudflare, Akamai, ModSecurity – I know the groove\n"
            printf "  More accurate than http-waf-detect – I'm in the proof\n"
            printf "  999 wafw00f – I'm tearing off the roof.%s\n" "${RST}"
            ;;
        "FFUF"*)
            printf "  %sFaster than wfuzz, filters tighter than the rest\n" "${GRN}"
            printf "  Directories, params, vhosts – I run every test\n"
            printf "  Recursive mode engaged, I'm going deeper in the nest\n"
            printf "  999 ffuf – I'm the fuzzer who's the best.%s\n" "${RST}"
            ;;
        "Arjun"*)
            printf "  %sHidden parameters lurking, I find every one\n" "${GRN}"
            printf "  GET and POST surfaces, no field escapes my run\n"
            printf "  Before you inject – you need to know the gun\n"
            printf "  999 arjun – parameter hunting, never done.%s\n" "${RST}"
            ;;
        "Optiva"*)
            printf "  %sMulti-tool framework, every vector in the mix\n" "${GRN}"
            printf "  Web shells and scanners – Optiva's full of tricks\n"
            printf "  Authorised lab only – no illegal clicks\n"
            printf "  999 optiva – Fezzy Station never quits.%s\n" "${RST}"
            ;;
        "HiddenURL"*)
            printf "  %sObscured endpoints, buried paths, I pull them out\n" "${GRN}"
            printf "  Hidden directories screaming – I hear every shout\n"
            printf "  No cloaked URL survives when I'm about\n"
            printf "  999 HiddenURL – strategy over doubt.%s\n" "${RST}"
            ;;
        *)
            printf "  %sStrategy over impulse – that's the Fezzy code\n" "${GRN}"
            printf "  FEZZY G.I.JOE's arsenal – you're on the heavy load\n"
            printf "  999 forever – I'm the one you need to know.%s\n" "${RST}"
            ;;
    esac
    echo ""
}

# --- Instructional text per tool ---
web_instructional_text() {
    local label="$1"
    echo ""
    printf "${CYN}[ INSTRUCTIONS — 999 ]${RST}\n"
    echo ""
    case "$label" in
        "Domain Intelligence"*|*"DNS Lookup"*|*"WHOIS Query"*|*"Full"*|*"DNS Brute"*)
            printf "  %sStep 1: Digging through DNS records like a ghost in the cloud\n" "${GRN}"
            printf "  Step 2: Pulling WHOIS info, finding who's registered loud\n"
            printf "  Step 3: No domain can hide, no registrar can shroud\n"
            printf "  Step 4: 999 domain intel – that's the Fezzy code.%s\n" "${RST}"
            ;;
        "Web Fingerprint"*)
            printf "  %sStep 1: Fingerprinting tech stack, every server I can find\n" "${GRN}"
            printf "  Step 2: CMS and frameworks, exposing every kind\n"
            printf "  Step 3: No WAF can blind me, no CDN can unwind\n"
            printf "  Step 4: 999 tech detective – that's the Fezzy code.%s\n" "${RST}"
            ;;
        "SSL Check"*)
            printf "  %sStep 1: Checking SSL certificate, every chain and every sign\n" "${GRN}"
            printf "  Step 2: Weak ciphers and expired certs, exposing every line\n"
            printf "  Step 3: No encryption fools me, no protocol can decline\n"
            printf "  Step 4: 999 crypto checker – that's the Fezzy code.%s\n" "${RST}"
            ;;
        "Vulnerability Scan"*)
            printf "  %sStep 1: Scanning web server, every port gonna check\n" "${GRN}"
            printf "  Step 2: Misconfigurations and outdated files, finding your wreck\n"
            printf "  Step 3: No vulnerability hides, no hole can be a deck\n"
            printf "  Step 4: 999 web auditor – that's the Fezzy code.%s\n" "${RST}"
            ;;
        "Directory Hunter"*)
            printf "  %sStep 1: Busting through directories, every path gonna find\n" "${GRN}"
            printf "  Step 2: Subdomain brute force, leaving nothing behind\n"
            printf "  Step 3: No hidden folder, no secret page can unwind\n"
            printf "  Step 4: 999 directory hunter – that's the Fezzy code.%s\n" "${RST}"
            ;;
        "Web Crawler"*)
            printf "  %sStep 1: Crawling through the website, every link gonna take\n" "${GRN}"
            printf "  Step 2: URLs and emails, gonna make your data shake\n"
            printf "  Step 3: No hidden endpoint, no script escapes my view\n"
            printf "  Step 4: 999 web crawler – that's the Fezzy code.%s\n" "${RST}"
            ;;
        "Fuzzing Engine"*)
            printf "  %sStep 1: Fuzzing every parameter, every payload gonna send\n" "${GRN}"
            printf "  Step 2: Hidden endpoints and bugs, gonna find your friend\n"
            printf "  Step 3: No filter stops me, no WAF blocks my way\n"
            printf "  Step 4: 999 web fuzzer – that's the Fezzy code.%s\n" "${RST}"
            ;;
        "Netcat"*)
            printf "  %sStep 1: Connect raw TCP/UDP to target port and read service banner\n" "${GRN}"
            printf "  Step 2: Use nc -v for verbose connection details and probe state\n"
            printf "  Step 3: Chain with grep or tee to log all banner output\n"
            printf "  Step 4: 999 netcat – that's the Fezzy code.%s\n" "${RST}"
            ;;
        "JQ Parser"*)
            printf "  %sStep 1: Pipe JSON API response from recon tool output into jq\n" "${GRN}"
            printf "  Step 2: Use jq keys, .field, .[] to navigate structure\n"
            printf "  Step 3: Export clean fields for use in later scan steps\n"
            printf "  Step 4: 999 jq – that's the Fezzy code.%s\n" "${RST}"
            ;;
        "theHarvester"*)
            printf "  %sStep 1: Runs passive OSINT against search engines and DNS sources\n" "${GRN}"
            printf "  Step 2: Collects emails, subdomains, IPs, hostnames per domain\n"
            printf "  Step 3: No active probing — stealth-safe and rootless-compatible\n"
            printf "  Step 4: 999 harvester – that's the Fezzy code.%s\n" "${RST}"
            ;;
        "Httprobe"*)
            printf "  %sStep 1: Pipe a domain list — httprobe probes HTTP and HTTPS\n" "${GRN}"
            printf "  Step 2: Only returns domains with live web responses\n"
            printf "  Step 3: Output feeds directly into web tool submenus as targets\n"
            printf "  Step 4: 999 httprobe – that's the Fezzy code.%s\n" "${RST}"
            ;;
        "SQLMap"*)
            printf "  %sStep 1: Provide a URL with a parameter — sqlmap tests it for injection\n" "${GRN}"
            printf "  Step 2: Supports GET/POST, blind, union, error-based, and time-based\n"
            printf "  Step 3: Fills the SQL gap nikto doesn't cover — critical for web audits\n"
            printf "  Step 4: 999 sqlmap – that's the Fezzy code.%s\n" "${RST}"
            ;;
        "WAF Detect"*)
            printf "  %sStep 1: wafw00f sends crafted requests to fingerprint WAF signatures\n" "${GRN}"
            printf "  Step 2: More accurate than nmap http-waf-detect for named WAF ID\n"
            printf "  Step 3: Knowing the WAF type informs bypass strategy for later scans\n"
            printf "  Step 4: 999 wafw00f – that's the Fezzy code.%s\n" "${RST}"
            ;;
        "FFUF"*)
            printf "  %sStep 1: Faster than wfuzz — supports dir, param, vhost, and header fuzzing\n" "${GRN}"
            printf "  Step 2: Use -fc to filter status codes, -fs to filter response size\n"
            printf "  Step 3: Recursive mode (-recursion) goes deeper on found directories\n"
            printf "  Step 4: 999 ffuf – that's the Fezzy code.%s\n" "${RST}"
            ;;
        "Arjun"*)
            printf "  %sStep 1: Arjun brute-forces hidden GET/POST/JSON/XML parameters\n" "${GRN}"
            printf "  Step 2: Enter a URL — Arjun tests thousands of param names silently\n"
            printf "  Step 3: Found params feed directly into SQLMap, FFUF, and fuzzing runs\n"
            printf "  Step 4: 999 arjun – map the surface before you attack.%s\n" "${RST}"
            ;;
        "Optiva"*)
            printf "  %sStep 1: Optiva Framework is a multi-module offensive toolkit\n" "${GRN}"
            printf "  Step 2: Runs via Python2 — launch with: cd ~/Optiva-Framework && python2 optiva.py\n"
            printf "  Step 3: Use only on systems you own or have written permission to test\n"
            printf "  Step 4: 999 optiva – authorised environments only.%s\n" "${RST}"
            ;;
        "HiddenURL"*)
            printf "  %sStep 1: HiddenURL discovers obscured and cloaked URL paths on targets\n" "${GRN}"
            printf "  Step 2: Runs as a bash tool — enter domain when prompted\n"
            printf "  Step 3: Combine output with Katana, GAU, and Waybackurls for full coverage\n"
            printf "  Step 4: 999 HiddenURL – no endpoint stays buried.%s\n" "${RST}"
            ;;
        *)
            printf "  %sStep 1: Execute as configured\n" "${GRN}"
            printf "  Step 2: Review output in the log file\n"
            printf "  Step 3: Use the post-launch menu to re-run or view logs\n"
            printf "  Step 4: 999 strategy over impulse – that's the Fezzy code.%s\n" "${RST}"
            ;;
    esac
    echo ""
}

# --- Display tool header (ai.sh pattern — no freeze) ---

alias_check() {
    grep -q "alias fezzynmap=" ~/.bashrc 2>/dev/null && ALIAS_INSTALLED=true || ALIAS_INSTALLED=false
}

# --- Display tool header (renders to terminal, no stdin capture, no freeze) ---
display_web_tool_header() {
    local label="$1" need_target="$2" tool_command="$3"
    clear; banner; echo ""
    local title="FEZZY G.I.JOE · $label"
    local title_len=${#title}
    printf "%s%s%s\n" "${HOT}" "$title" "${RST}"
    short_pink_line $title_len
    echo ""
    printf "${CYN}[ SYNOPSIS — 999 ]${RST}\n"
    gijoe_poetry "$label"
    if [ -n "$tool_command" ]; then
        printf "${CYN}[ COMMAND ]${RST}\n"
        echo ""
        printf "  %s%s%s\n" "${DESC}" "$tool_command" "${RST}"
        echo ""
    fi
    printf "${CYN}[ INSTRUCTIONS ]${RST}\n"
    web_instructional_text "$label"
    echo ""
    short_pink_line $title_len
    echo ""
}

# --- Run Web Tool (freeze-free: target read directly, no $() capture) ---
run_web_tool() {
    local original_command="$1" label="$2" requires_target="$3" tool_command_display="$4"
    while true; do
        local command_to_execute="$original_command" target_input=""
        if [ -n "$requires_target" ] && [[ "$requires_target" == "yes" ]]; then
            display_web_tool_header "$label" "yes" "$tool_command_display"
            printf "  %s[ TARGET INPUT ]%s\n\n" "${CYN}" "${RST}"
            printf "  %sPaste or type target (domain/IP/URL): %s" "${HOT}" "${RST}"
            read -r target_input < /dev/tty
            echo ""
            [ -z "$target_input" ] && {
                printf "  %s[!] No target provided. Returning to menu.%s\n" "${RED}" "${RST}"
                sleep 1; return
            }
            command_to_execute="$(echo "$command_to_execute" | sed "s|TARGET_PLACEHOLDER|${target_input}|g")"
        else
            display_web_tool_header "$label" "no" "$tool_command_display"
        fi
        printf "\n  %s[*] Launching – %s...%s\n\n" "${CYN}" "$label" "${RST}"
        local _tmp_result="${TMPDIR:-/tmp}/fezzy_tool_result_$$.tmp"
        {
            echo "=== FEZZY G.I.JOE · $label ==="
            echo "Target  : ${target_input:-${SESSION_TARGET:-N/A}}"
            echo "Command : $command_to_execute"
            echo "Time    : $(date)"
            echo "================================"
            eval "$command_to_execute" 2>&1
            echo ""
        } | tee -a "$LOG" | tee "$_tmp_result"
        if web_post_scan_menu "$label" "$_tmp_result"; then
            rm -f "$_tmp_result"; continue
        else
            rm -f "$_tmp_result"; return
        fi
    done
}


# --- Post-scan menu ---
web_post_scan_menu() {
    local _label="${1:-Unknown Tool}"
    local _result_file="${2:-}"
    while true; do
        echo ""
        printf "  %s[+] Done. Log: %s%s\n" "${GRN}" "$LOG" "${RST}"
        echo ""
        printf "  ${GRN}[V]${RST} View Log  ${GRN}[R]${RST} Re-run  ${HOT}[S]${RST} Save to Report  ${YLW}[B]${RST} Back  ${RED}[Q]${RST} Quit\n"
        echo ""
        printf "  %sChoose: %s" "${HOT}" "${RST}"; read -r POST_CHOICE
        case "$POST_CHOICE" in
            v|V) echo ""; cat "$LOG"; echo ""; printf "  %sPress ENTER...%s" "${HOT}" "${RST}"; read -r _ ;;
            r|R) return 0 ;;
            s|S)
                report_add_entry "$_label" "$_result_file"
                printf "  %s[+] Saved · Entry %02d · %s%s\n" "${GRN}" "$REPORT_COUNTER" "$_label" "${RST}"
                sleep 1
                ;;
            b|B) return 1 ;;
            q|Q) printf "\n  %s999 · FEZZY G.I.JOE · Out.%s\n\n" "${HOT}" "${RST}"; exit 0 ;;
            *) printf "  %s[!] Invalid.%s\n" "${RED}" "${RST}"; sleep 1 ;;
        esac
    done
}
install_module_deps() {
    local name="$1" pkgs="$2" method="$3" var="$4"
    printf "\n  %s[*] Installing %s dependencies...%s\n" "${CYN}" "$name" "${RST}"
    local ok=true
    for p in $pkgs; do
        if [[ "$method" == "pip" ]]; then
            pip list 2>/dev/null | grep -qi "$p" \
                && printf "  %s[+] %s already installed.%s\n" "${GRN}" "$p" "${RST}" \
                || install_pip_package "$p" "$p installed." || ok=false
        else
            command -v "$p" >/dev/null 2>&1 \
                && printf "  %s[+] %s already installed.%s\n" "${GRN}" "$p" "${RST}" \
                || install_package "$p" "$p installed." || ok=false
        fi
    done
    $ok && eval "$var=true" && printf "\n%s  [+] %s ready. 999%s\n" "${GRN}" "$name" "${RST}" \
         || eval "$var=false" && printf "\n%s  [!!] Some %s deps failed.%s\n" "${RED}" "$name" "${RST}"
    sleep 1
}

install_domain_intel()      { install_module_deps "Domain Intelligence" "dnsutils whois" "pkg" "DOMAIN_INTEL_INSTALLED"; check_deps; }
install_web_fingerprint()   { install_module_deps "Web Fingerprint" "whatweb" "pkg" "WEB_FINGERPRINT_INSTALLED"; check_deps; }
install_ssl_check()         { install_module_deps "SSL Check" "openssl nmap" "pkg" "SSL_CHECK_INSTALLED"; check_deps; }
install_vulnerability_scan(){ install_module_deps "Vulnerability Scan" "nikto" "pkg" "VULN_SCAN_INSTALLED"; check_deps; }
install_directory_hunter()  { install_module_deps "Directory Hunter" "gobuster" "pkg" "DIRECTORY_HUNTER_INSTALLED"; check_deps; }
install_web_crawler()       { install_module_deps "Web Crawler" "photon" "pip" "WEB_CRAWLER_INSTALLED"; check_deps; }
install_fuzzing_engine()    { install_module_deps "Fuzzing Engine" "wfuzz" "pip" "FUZZING_ENGINE_INSTALLED"; check_deps; }

# ── V5 install functions ──
install_netcat() {
    printf "\n  %s[*] Installing netcat...%s\n" "${CYN}" "${RST}"
    install_package "ncat" "netcat (ncat) ready." || install_package "netcat-openbsd" "netcat ready."
    check_deps
}
install_jq() {
    install_module_deps "jq (JSON parser)" "jq" "pkg" "JQ_INSTALLED"; check_deps
}
install_harvester() {
    printf "\n  %s[*] Installing theHarvester (pip)...%s\n" "${CYN}" "${RST}"
    install_pip_package "theHarvester" "theHarvester ready."
    check_deps

    check_deps
}
install_httprobe() {
    printf "\n  %s[*] Installing httprobe (pkg go + go install)...%s\n" "${CYN}" "${RST}"
    if ! command -v go >/dev/null 2>&1; then
        install_package "golang" "golang ready."
    fi
    if command -v go >/dev/null 2>&1; then
        go install github.com/tomnomnom/httprobe@latest 2>/dev/null \
            && printf "%s  [+] httprobe installed to ~/go/bin/%s\n" "${GRN}" "${RST}" \
            || printf "%s  [!!] httprobe install failed. Add ~/go/bin to PATH.%s\n" "${RED}" "${RST}"
    fi
    check_deps
}
install_sqlmap() {
    printf "\n  %s[*] Installing sqlmap (pip)...%s\n" "${CYN}" "${RST}"
    install_pip_package "sqlmap" "sqlmap ready."
    check_deps
}
install_wafw00f() {
    printf "\n  %s[*] Installing wafw00f (pip)...%s\n" "${CYN}" "${RST}"
    install_pip_package "wafw00f" "wafw00f ready."
    check_deps
}
install_ffuf() {
    printf "\n  %s[*] Installing ffuf (pkg go + go install)...%s\n" "${CYN}" "${RST}"
    if ! command -v go >/dev/null 2>&1; then
        install_package "golang" "golang ready."
    fi
    if command -v go >/dev/null 2>&1; then
        go install github.com/ffuf/ffuf/v2@latest 2>/dev/null \
            && printf "%s  [+] ffuf installed to ~/go/bin/%s\n" "${GRN}" "${RST}" \
            || printf "%s  [!!] ffuf install failed.%s\n" "${RED}" "${RST}"
    fi
    check_deps
}


# ── V8 Install Functions ─────────────────────────────────────
_go_install() {
    local name="$1" pkg="$2" var="$3"
    printf "\n  %s[*] Installing %s via go install...%s\n" "${CYN}" "$name" "${RST}"
    if ! command -v go >/dev/null 2>&1; then
        install_package "golang" "golang ready."
    fi
    if command -v go >/dev/null 2>&1; then
        go install "${pkg}" 2>/tmp/_gijoe_err             && printf "  %s[+] %s installed → ~/go/bin/%s\n" "${GRN}" "$name" "${RST}"                 && eval "$var=true"             || printf "  %s[!!] %s install failed: %s%s\n" "${RED}" "$name" "$(tail -1 /tmp/_gijoe_err 2>/dev/null)" "${RST}"                 && eval "$var=false"
        rm -f /tmp/_gijoe_err
    fi
    check_deps
}
install_amass() {
    _go_install "Amass" "github.com/owasp-amass/amass/v4/...@master" "AMASS_INSTALLED"
}
install_nuclei() {
    _go_install "Nuclei" "github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest" "NUCLEI_INSTALLED"
    local _n="${HOME}/go/bin/nuclei"
    [[ -x "$_n" ]] && { printf "  %s[*] Updating nuclei templates...%s\n" "${CYN}" "${RST}"; "$_n" -update-templates 2>/dev/null && printf "  %s[+] Templates updated.%s\n" "${GRN}" "${RST}"; }
}
install_katana() {
    _go_install "Katana" "github.com/projectdiscovery/katana/cmd/katana@latest" "KATANA_INSTALLED"
}
install_shuffledns() {
    _go_install "ShuffleDNS" "github.com/projectdiscovery/shuffledns/cmd/shuffledns@latest" "SHUFFLEDNS_INSTALLED"
}
install_httpx_tool() {
    _go_install "HTTPX" "github.com/projectdiscovery/httpx/cmd/httpx@latest" "HTTPX_T_INSTALLED"
}
install_subfinder() {
    _go_install "Subfinder" "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest" "SUBFINDER_INSTALLED"
}
install_naabu() {
    _go_install "Naabu" "github.com/projectdiscovery/naabu/v2/cmd/naabu@latest" "NAABU_INSTALLED"
}
install_dnsx_tool() {
    _go_install "DNSx" "github.com/projectdiscovery/dnsx/cmd/dnsx@latest" "DNSX_INSTALLED"
    [[ -x "${HOME}/go/bin/dnsx" ]] && cp "${HOME}/go/bin/dnsx" "${PREFIX}/bin/" 2>/dev/null \
        && printf "  %s[+] dnsx copied to \$PREFIX/bin%s\n" "${GRN}" "${RST}"
}
install_massdns_tool() {
    printf "\n  %s[*] Installing massdns via pkg...%s\n" "${CYN}" "${RST}"
    install_package "massdns" "massdns ready."
    check_deps
}
install_waybackurls() {
    _go_install "Waybackurls" "github.com/tomnomnom/waybackurls@latest" "WAYBACKURLS_INSTALLED"
}
install_gau_tool() {
    _go_install "GAU" "github.com/lc/gau/v2/cmd/gau@latest" "GAU_INSTALLED"
    [[ -x "${HOME}/go/bin/gau" ]] && cp "${HOME}/go/bin/gau" "${PREFIX}/bin/" 2>/dev/null \
        && printf "  %s[+] gau copied to \$PREFIX/bin%s\n" "${GRN}" "${RST}"
}

# ── V10 · Fezzy Station Install Functions ────────────────────
install_arjun() {
    printf "\n  %s[*] Installing Arjun (pip)...%s\n" "${CYN}" "${RST}"
    if ! command -v pip >/dev/null 2>&1 && ! command -v pip3 >/dev/null 2>&1; then
        install_package "python" "python ready."
    fi
    pip install arjun 2>/dev/null || pip3 install arjun 2>/dev/null \
        && printf "  %s[+] Arjun installed.%s\n" "${GRN}" "${RST}" \
        || printf "  %s[!!] Arjun install failed. Try: pip install arjun%s\n" "${RED}" "${RST}"
    check_deps
}

install_optiva() {
    printf "\n  %s[*] Installing Optiva Framework...%s\n" "${CYN}" "${RST}"
    # Deps
    for _dep in git python2; do
        command -v "$_dep" >/dev/null 2>&1 \
            && printf "  %s[+] %s already present.%s\n" "${GRN}" "$_dep" "${RST}" \
            || { printf "  %s[*] Installing %s...%s\n" "${CYN}" "$_dep" "${RST}"; pkg install -y "$_dep" 2>/dev/null; }
    done
    # Clone if not present
    if [[ ! -d "${HOME}/Optiva-Framework" ]]; then
        printf "  %s[*] Cloning Optiva-Framework...%s\n" "${CYN}" "${RST}"
        git clone https://github.com/joker25000/Optiva-Framework "${HOME}/Optiva-Framework" 2>/dev/null \
            && printf "  %s[+] Cloned OK.%s\n" "${GRN}" "${RST}" \
            || { printf "  %s[!!] Clone failed. Check internet.%s\n" "${RED}" "${RST}"; sleep 2; return; }
    else
        printf "  %s[+] Optiva-Framework already cloned.%s\n" "${GRN}" "${RST}"
    fi
    # Run installer
    cd "${HOME}/Optiva-Framework" && chmod +x installer.sh && bash installer.sh 2>/dev/null
    # Python2 deps
    pip2 install bs4 requests termcolor mechanize 2>/dev/null \
        || printf "  %s[!] pip2 deps failed — run manually if needed.%s\n" "${YLW}" "${RST}"
    cd "${HOME}"
    OPTIVA_INSTALLED=true
    printf "\n  %s[+] Optiva Framework ready. Launch: cd ~/Optiva-Framework && python2 optiva.py%s\n" "${GRN}" "${RST}"
    check_deps; sleep 2
}

install_hiddenurl() {
    printf "\n  %s[*] Installing HiddenURL...%s\n" "${CYN}" "${RST}"
    command -v git >/dev/null 2>&1 \
        || { pkg install -y git 2>/dev/null; }
    if [[ ! -d "${HOME}/HiddenURL" ]]; then
        printf "  %s[*] Cloning HiddenURL...%s\n" "${CYN}" "${RST}"
        git clone https://github.com/Err0r-ICA/HiddenURL "${HOME}/HiddenURL" 2>/dev/null \
            && printf "  %s[+] Cloned OK.%s\n" "${GRN}" "${RST}" \
            || { printf "  %s[!!] Clone failed. Check internet.%s\n" "${RED}" "${RST}"; sleep 2; return; }
    else
        printf "  %s[+] HiddenURL already cloned.%s\n" "${GRN}" "${RST}"
    fi
    cd "${HOME}/HiddenURL" && chmod +x HiddenURL 2>/dev/null
    cd "${HOME}"
    HIDDENURL_INSTALLED=true
    printf "\n  %s[+] HiddenURL ready. Launch: cd ~/HiddenURL && bash HiddenURL%s\n" "${GRN}" "${RST}"
    check_deps; sleep 2
}

install_dalfox() {
    printf "%s  [*] dalfox (Go)...%s\n" "${CYN}" "${RST}"
    go install github.com/hahwul/dalfox/v2@latest 2>/dev/null &
    local pid=$!; spinner $pid; wait $pid
    { command -v dalfox >/dev/null 2>&1 || [[ -x "${HOME}/go/bin/dalfox" ]]; } \
        && { DALFOX_INSTALLED=true; printf "%s  [+] dalfox ready%s\n" "${GRN}" "${RST}"; } \
        || printf "%s  [!!] dalfox failed%s\n" "${RED}" "${RST}"; sleep 1
}
install_kxss() {
    printf "%s  [*] kxss (Go)...%s\n" "${CYN}" "${RST}"
    go install github.com/Emoe/kxss@latest 2>/dev/null &
    local pid=$!; spinner $pid; wait $pid
    { command -v kxss >/dev/null 2>&1 || [[ -x "${HOME}/go/bin/kxss" ]]; } \
        && { KXSS_INSTALLED=true; printf "%s  [+] kxss ready%s\n" "${GRN}" "${RST}"; } \
        || printf "%s  [!!] kxss failed%s\n" "${RED}" "${RST}"; sleep 1
}
install_gf() {
    printf "%s  [*] gf + patterns (Go)...%s\n" "${CYN}" "${RST}"
    go install github.com/tomnomnom/gf@latest 2>/dev/null &
    local pid=$!; spinner $pid; wait $pid
    mkdir -p ~/.gf
    git clone -q https://github.com/1ndianl33t/Gf-Patterns "${TMPDIR:-/tmp}/gf-p" 2>/dev/null \
        && cp "${TMPDIR:-/tmp}/gf-p"/*.json ~/.gf/ 2>/dev/null \
        && rm -rf "${TMPDIR:-/tmp}/gf-p"
    { command -v gf >/dev/null 2>&1 || [[ -x "${HOME}/go/bin/gf" ]]; } \
        && { GF_INSTALLED=true; printf "%s  [+] gf ready%s\n" "${GRN}" "${RST}"; } \
        || printf "%s  [!!] gf failed%s\n" "${RED}" "${RST}"; sleep 1
}
install_trufflehog() {
    printf "%s  [*] trufflehog (Go)...%s\n" "${CYN}" "${RST}"
    go install github.com/trufflesecurity/trufflehog/v3@latest 2>/dev/null &
    local pid=$!; spinner $pid; wait $pid
    { command -v trufflehog >/dev/null 2>&1 || [[ -x "${HOME}/go/bin/trufflehog" ]]; } \
        && { TRUFFLEHOG_INSTALLED=true; printf "%s  [+] trufflehog ready%s\n" "${GRN}" "${RST}"; } \
        || printf "%s  [!!] trufflehog failed%s\n" "${RED}" "${RST}"; sleep 1
}
install_crlfuzz() {
    printf "%s  [*] crlfuzz (Go)...%s\n" "${CYN}" "${RST}"
    go install github.com/dwisiswant0/crlfuzz/cmd/crlfuzz@latest 2>/dev/null &
    local pid=$!; spinner $pid; wait $pid
    { command -v crlfuzz >/dev/null 2>&1 || [[ -x "${HOME}/go/bin/crlfuzz" ]]; } \
        && { CRLFUZZ_INSTALLED=true; printf "%s  [+] crlfuzz ready%s\n" "${GRN}" "${RST}"; } \
        || printf "%s  [!!] crlfuzz failed%s\n" "${RED}" "${RST}"; sleep 1
}
install_byp4xx() {
    printf "%s  [*] byp4xx (Go)...%s\n" "${CYN}" "${RST}"
    go install github.com/lobuhi/byp4xx@latest 2>/dev/null &
    local pid=$!; spinner $pid; wait $pid
    { command -v byp4xx >/dev/null 2>&1 || [[ -x "${HOME}/go/bin/byp4xx" ]]; } \
        && { BYP4XX_INSTALLED=true; printf "%s  [+] byp4xx ready%s\n" "${GRN}" "${RST}"; } \
        || printf "%s  [!!] byp4xx failed%s\n" "${RED}" "${RST}"; sleep 1
}
install_feroxbuster() {
    printf "%s  [*] feroxbuster...%s\n" "${CYN}" "${RST}"
    mkdir -p "${HOME}/.local/bin"
    curl -sL https://raw.githubusercontent.com/epi052/feroxbuster/main/install-nix.sh \
        | bash -s -- "${HOME}/.local/bin" 2>/dev/null &
    local pid=$!; spinner $pid; wait $pid
    command -v feroxbuster >/dev/null 2>&1 \
        && { FEROXBUSTER_INSTALLED=true; printf "%s  [+] feroxbuster ready%s\n" "${GRN}" "${RST}"; } \
        || printf "%s  [!!] failed — try: pkg install feroxbuster%s\n" "${RED}" "${RST}"; sleep 1
}


install_assetfinder() {
    _go_install "Assetfinder" "github.com/tomnomnom/assetfinder@latest" "ASSETFINDER_INSTALLED"
}
install_gospider() {
    _go_install "Gospider" "github.com/jaeles-project/gospider@latest" "GOSPIDER_INSTALLED"
}
install_qsreplace() {
    _go_install "Qsreplace" "github.com/tomnomnom/qsreplace@latest" "QSREPLACE_INSTALLED"
}
install_unfurl() {
    _go_install "Unfurl" "github.com/tomnomnom/unfurl@latest" "UNFURL_INSTALLED"
}
install_paramspider() {
    printf "\n  %s[*] Installing ParamSpider (git + pip)...%s\n" "${CYN}" "${RST}"
    command -v git >/dev/null 2>&1 || pkg install -y git 2>/dev/null
    if [[ ! -d "${HOME}/ParamSpider" ]]; then
        git clone -q https://github.com/devanshbatham/ParamSpider "${HOME}/ParamSpider" 2>/dev/null \
            && printf "  %s[+] Cloned OK.%s\n" "${GRN}" "${RST}" \
            || { printf "  %s[!!] Clone failed.%s\n" "${RED}" "${RST}"; sleep 2; return; }
    else
        printf "  %s[+] ParamSpider already cloned.%s\n" "${GRN}" "${RST}"
    fi
    pip install -r "${HOME}/ParamSpider/requirements.txt" 2>/dev/null \
        && printf "  %s[+] Deps installed.%s\n" "${GRN}" "${RST}" \
        || printf "  %s[!] pip deps failed.%s\n" "${YLW}" "${RST}"
    PARAMSPIDER_INSTALLED=true; check_deps; sleep 1
}
install_ssrfmap() {
    printf "\n  %s[*] Installing SSRFmap (git + pip)...%s\n" "${CYN}" "${RST}"
    command -v git >/dev/null 2>&1 || pkg install -y git 2>/dev/null
    if [[ ! -d "${HOME}/ssrfmap" ]]; then
        git clone -q https://github.com/swisskyrepo/SSRFmap "${HOME}/ssrfmap" 2>/dev/null \
            && printf "  %s[+] Cloned OK.%s\n" "${GRN}" "${RST}" \
            || { printf "  %s[!!] Clone failed.%s\n" "${RED}" "${RST}"; sleep 2; return; }
    else
        printf "  %s[+] SSRFmap already cloned.%s\n" "${GRN}" "${RST}"
    fi
    pip install -r "${HOME}/ssrfmap/requirements.txt" 2>/dev/null \
        && printf "  %s[+] Deps installed.%s\n" "${GRN}" "${RST}" \
        || printf "  %s[!] pip deps failed.%s\n" "${YLW}" "${RST}"
    SSRFMAP_INSTALLED=true; check_deps; sleep 1
}
install_chaos() {
    _go_install "Chaos" "github.com/projectdiscovery/chaos-client/cmd/chaos@latest" "CHAOS_INSTALLED"
}

submenu_assetfinder() {
    while true; do
        clear; banner; echo ""
        center_in_box "ASSETFINDER · SUBDOMAIN DISCOVERY"
        short_pink_line 32; echo ""
        printf "${PNK}╔══════════════════════════════════════════════════════════════╗${RST}\n"
        printf "${PNK}║${RST} ${CYN}SYNOPSIS:${RST} Assetfinder — fast subdomain discovery via cert     ${RST}\n"
        printf "${PNK}║${RST}          transparency, DNS, web archives. Lightweight & fast. ${RST}\n"
        printf "${PNK}║${RST} ${CYN}USE:${RST} Enter domain (e.g. example.com) when prompted.          ${RST}\n"
        printf "${PNK}║${RST} ${CYN}INSTALL:${RST} go install github.com/tomnomnom/assetfinder@latest  ${RST}\n"
        printf "${PNK}╚══════════════════════════════════════════════════════════════╝${RST}\n\n"
        printf "  ${GRN}[1]${RST}  All Subdomains         ${DESC}- assetfinder --subs-only <domain>${RST}\n"
        printf "  ${GRN}[2]${RST}  All Assets             ${DESC}- assetfinder <domain>${RST}\n"
        printf "  ${GRN}[3]${RST}  Save Output            ${DESC}- → downloads/assetfinder_out.txt${RST}\n"
        printf "  ${GRN}[4]${RST}  Pipe to HTTPX          ${DESC}- live probe discovered subs${RST}\n"
        printf "  ${GRN}[I]${RST}  Install                ${DESC}- go install assetfinder${RST}\n"
        printf "  ${YLW}[B]${RST}  Back\n\n"
        printf "  %sChoose: %s" "${HOT}" "${RST}"; read -r SC
        local _AF="${HOME}/go/bin/assetfinder"; command -v assetfinder >/dev/null 2>&1 && _AF="assetfinder"
        local _HX="${HOME}/go/bin/httpx"; command -v httpx >/dev/null 2>&1 && _HX="httpx"
        case "$SC" in
            1) ! $ASSETFINDER_INSTALLED && { install_assetfinder; $ASSETFINDER_INSTALLED || continue; }
               run_web_tool "${_AF} --subs-only TARGET_PLACEHOLDER" "Assetfinder · Subs Only" "yes" "assetfinder --subs-only <domain>" ;;
            2) ! $ASSETFINDER_INSTALLED && { install_assetfinder; $ASSETFINDER_INSTALLED || continue; }
               run_web_tool "${_AF} TARGET_PLACEHOLDER" "Assetfinder · All Assets" "yes" "assetfinder <domain>" ;;
            3) ! $ASSETFINDER_INSTALLED && { install_assetfinder; $ASSETFINDER_INSTALLED || continue; }
               run_web_tool "${_AF} --subs-only TARGET_PLACEHOLDER | tee ${HOME}/storage/downloads/assetfinder_out.txt" "Assetfinder · Save" "yes" "assetfinder + save" ;;
            4) ! $ASSETFINDER_INSTALLED && { install_assetfinder; $ASSETFINDER_INSTALLED || continue; }
               run_web_tool "{ ${_AF} --subs-only TARGET_PLACEHOLDER | tee ${HOME}/storage/downloads/assetfinder_out.txt; echo '=== LIVE PROBE ==='; ${_HX} -l ${HOME}/storage/downloads/assetfinder_out.txt -title -status-code -silent 2>/dev/null || echo 'httpx not installed'; }" "Assetfinder · Pipe HTTPX" "yes" "assetfinder + httpx" ;;
            i|I) install_assetfinder ;;
            b|B) break ;;
            *) printf "  %s[!] Invalid.%s\n" "${RED}" "${RST}"; sleep 1 ;;
        esac
    done
}

submenu_gospider() {
    while true; do
        clear; banner; echo ""
        center_in_box "GOSPIDER · FAST WEB SPIDER"
        short_pink_line 32; echo ""
        printf "${PNK}╔══════════════════════════════════════════════════════════════╗${RST}\n"
        printf "${PNK}║${RST} ${CYN}SYNOPSIS:${RST} Gospider — fast web spider, extracts URLs, JS,     ${RST}\n"
        printf "${PNK}║${RST}          forms, linkfinder patterns. Go rootless.             ${RST}\n"
        printf "${PNK}║${RST} ${CYN}USE:${RST} Enter target URL (e.g. https://example.com).           ${RST}\n"
        printf "${PNK}║${RST} ${CYN}INSTALL:${RST} go install github.com/jaeles-project/gospider@latest${RST}\n"
        printf "${PNK}╚══════════════════════════════════════════════════════════════╝${RST}\n\n"
        printf "  ${GRN}[1]${RST}  Basic Spider           ${DESC}- gospider -s <url>${RST}\n"
        printf "  ${GRN}[2]${RST}  Depth 3 Crawl          ${DESC}- gospider -s <url> -d 3${RST}\n"
        printf "  ${GRN}[3]${RST}  Extract JS Sources     ${DESC}- gospider -s <url> --js${RST}\n"
        printf "  ${GRN}[4]${RST}  Save Output            ${DESC}- → downloads/gospider_out.txt${RST}\n"
        printf "  ${GRN}[5]${RST}  Full Auto              ${DESC}- depth 3 + js + save${RST}\n"
        printf "  ${GRN}[I]${RST}  Install                ${DESC}- go install gospider${RST}\n"
        printf "  ${YLW}[B]${RST}  Back\n\n"
        printf "  %sChoose: %s" "${HOT}" "${RST}"; read -r SC
        local _GS="${HOME}/go/bin/gospider"; command -v gospider >/dev/null 2>&1 && _GS="gospider"
        case "$SC" in
            1) ! $GOSPIDER_INSTALLED && { install_gospider; $GOSPIDER_INSTALLED || continue; }
               run_web_tool "${_GS} -s TARGET_PLACEHOLDER -q" "Gospider · Basic" "yes" "gospider -s <url>" ;;
            2) ! $GOSPIDER_INSTALLED && { install_gospider; $GOSPIDER_INSTALLED || continue; }
               run_web_tool "${_GS} -s TARGET_PLACEHOLDER -d 3 -q" "Gospider · Depth 3" "yes" "gospider -d 3" ;;
            3) ! $GOSPIDER_INSTALLED && { install_gospider; $GOSPIDER_INSTALLED || continue; }
               run_web_tool "${_GS} -s TARGET_PLACEHOLDER --js -q" "Gospider · JS Sources" "yes" "gospider --js" ;;
            4) ! $GOSPIDER_INSTALLED && { install_gospider; $GOSPIDER_INSTALLED || continue; }
               run_web_tool "${_GS} -s TARGET_PLACEHOLDER -q -o ${HOME}/storage/downloads/gospider_out.txt && cat ${HOME}/storage/downloads/gospider_out.txt" "Gospider · Save" "yes" "gospider + save" ;;
            5) ! $GOSPIDER_INSTALLED && { install_gospider; $GOSPIDER_INSTALLED || continue; }
               run_web_tool "${_GS} -s TARGET_PLACEHOLDER -d 3 --js -q -o ${HOME}/storage/downloads/gospider_out.txt && cat ${HOME}/storage/downloads/gospider_out.txt" "Gospider · Full Auto" "yes" "gospider full auto" ;;
            i|I) install_gospider ;;
            b|B) break ;;
            *) printf "  %s[!] Invalid.%s\n" "${RED}" "${RST}"; sleep 1 ;;
        esac
    done
}

submenu_qsreplace() {
    while true; do
        clear; banner; echo ""
        center_in_box "QSREPLACE · QUERYSTRING VALUE REPLACER"
        short_pink_line 32; echo ""
        printf "${PNK}╔══════════════════════════════════════════════════════════════╗${RST}\n"
        printf "${PNK}║${RST} ${CYN}SYNOPSIS:${RST} Qsreplace — replaces all querystring values in     ${RST}\n"
        printf "${PNK}║${RST}          piped URLs with a payload. Use after gau/wayback.   ${RST}\n"
        printf "${PNK}║${RST} ${CYN}USE:${RST} Enter a URL file path as target.                       ${RST}\n"
        printf "${PNK}║${RST} ${CYN}INSTALL:${RST} go install github.com/tomnomnom/qsreplace@latest   ${RST}\n"
        printf "${PNK}╚══════════════════════════════════════════════════════════════╝${RST}\n\n"
        printf "  ${GRN}[1]${RST}  XSS Probe              ${DESC}- inject <script>alert(1)</script>${RST}\n"
        printf "  ${GRN}[2]${RST}  SQLi Probe             ${DESC}- inject ' OR 1=1--${RST}\n"
        printf "  ${GRN}[3]${RST}  SSRF Probe             ${DESC}- inject http://169.254.169.254/${RST}\n"
        printf "  ${GRN}[4]${RST}  Custom Payload         ${DESC}- enter your own value${RST}\n"
        printf "  ${GRN}[I]${RST}  Install                ${DESC}- go install qsreplace${RST}\n"
        printf "  ${YLW}[B]${RST}  Back\n\n"
        printf "  %sChoose: %s" "${HOT}" "${RST}"; read -r SC
        local _QS="${HOME}/go/bin/qsreplace"; command -v qsreplace >/dev/null 2>&1 && _QS="qsreplace"
        case "$SC" in
            1) ! $QSREPLACE_INSTALLED && { install_qsreplace; $QSREPLACE_INSTALLED || continue; }
               run_web_tool "cat TARGET_PLACEHOLDER | ${_QS} '<script>alert(1)</script>'" "Qsreplace · XSS" "yes" "cat urls.txt | qsreplace payload" ;;
            2) ! $QSREPLACE_INSTALLED && { install_qsreplace; $QSREPLACE_INSTALLED || continue; }
               run_web_tool "cat TARGET_PLACEHOLDER | ${_QS} \"' OR 1=1--\"" "Qsreplace · SQLi" "yes" "qsreplace sqli" ;;
            3) ! $QSREPLACE_INSTALLED && { install_qsreplace; $QSREPLACE_INSTALLED || continue; }
               run_web_tool "cat TARGET_PLACEHOLDER | ${_QS} 'http://169.254.169.254/'" "Qsreplace · SSRF" "yes" "qsreplace ssrf" ;;
            4) ! $QSREPLACE_INSTALLED && { install_qsreplace; $QSREPLACE_INSTALLED || continue; }
               printf "  %sPayload: %s" "${HOT}" "${RST}"; read -r QS_PAYLOAD
               [ -z "$QS_PAYLOAD" ] && { printf "  %s[!] No payload.%s\n" "${RED}" "${RST}"; sleep 1; continue; }
               run_web_tool "cat TARGET_PLACEHOLDER | ${_QS} '${QS_PAYLOAD}'" "Qsreplace · Custom" "yes" "qsreplace custom" ;;
            i|I) install_qsreplace ;;
            b|B) break ;;
            *) printf "  %s[!] Invalid.%s\n" "${RED}" "${RST}"; sleep 1 ;;
        esac
    done
}

submenu_unfurl() {
    while true; do
        clear; banner; echo ""
        center_in_box "UNFURL · URL STRUCTURE PARSER"
        short_pink_line 32; echo ""
        printf "${PNK}╔══════════════════════════════════════════════════════════════╗${RST}\n"
        printf "${PNK}║${RST} ${CYN}SYNOPSIS:${RST} Unfurl — parses URLs into keys, values, paths,     ${RST}\n"
        printf "${PNK}║${RST}          domains, apex domains. Pipe URL list as target.      ${RST}\n"
        printf "${PNK}║${RST} ${CYN}USE:${RST} Enter path to URL file when prompted.                  ${RST}\n"
        printf "${PNK}║${RST} ${CYN}INSTALL:${RST} go install github.com/tomnomnom/unfurl@latest       ${RST}\n"
        printf "${PNK}╚══════════════════════════════════════════════════════════════╝${RST}\n\n"
        printf "  ${GRN}[1]${RST}  Extract Keys           ${DESC}- param names only${RST}\n"
        printf "  ${GRN}[2]${RST}  Extract Values         ${DESC}- param values only${RST}\n"
        printf "  ${GRN}[3]${RST}  Extract Paths          ${DESC}- URL paths only${RST}\n"
        printf "  ${GRN}[4]${RST}  Extract Apex Domains   ${DESC}- apex domains only${RST}\n"
        printf "  ${GRN}[5]${RST}  Extract Domains        ${DESC}- all domains${RST}\n"
        printf "  ${GRN}[I]${RST}  Install                ${DESC}- go install unfurl${RST}\n"
        printf "  ${YLW}[B]${RST}  Back\n\n"
        printf "  %sChoose: %s" "${HOT}" "${RST}"; read -r SC
        local _UF="${HOME}/go/bin/unfurl"; command -v unfurl >/dev/null 2>&1 && _UF="unfurl"
        case "$SC" in
            1) ! $UNFURL_INSTALLED && { install_unfurl; $UNFURL_INSTALLED || continue; }
               run_web_tool "cat TARGET_PLACEHOLDER | ${_UF} keys" "Unfurl · Keys" "yes" "cat urls.txt | unfurl keys" ;;
            2) ! $UNFURL_INSTALLED && { install_unfurl; $UNFURL_INSTALLED || continue; }
               run_web_tool "cat TARGET_PLACEHOLDER | ${_UF} values" "Unfurl · Values" "yes" "unfurl values" ;;
            3) ! $UNFURL_INSTALLED && { install_unfurl; $UNFURL_INSTALLED || continue; }
               run_web_tool "cat TARGET_PLACEHOLDER | ${_UF} paths" "Unfurl · Paths" "yes" "unfurl paths" ;;
            4) ! $UNFURL_INSTALLED && { install_unfurl; $UNFURL_INSTALLED || continue; }
               run_web_tool "cat TARGET_PLACEHOLDER | ${_UF} apexes" "Unfurl · Apex Domains" "yes" "unfurl apexes" ;;
            5) ! $UNFURL_INSTALLED && { install_unfurl; $UNFURL_INSTALLED || continue; }
               run_web_tool "cat TARGET_PLACEHOLDER | ${_UF} domains" "Unfurl · Domains" "yes" "unfurl domains" ;;
            i|I) install_unfurl ;;
            b|B) break ;;
            *) printf "  %s[!] Invalid.%s\n" "${RED}" "${RST}"; sleep 1 ;;
        esac
    done
}

submenu_paramspider() {
    while true; do
        clear; banner; echo ""
        center_in_box "PARAMSPIDER · WEB ARCHIVE PARAM DISCOVERY"
        short_pink_line 32; echo ""
        printf "${PNK}╔══════════════════════════════════════════════════════════════╗${RST}\n"
        printf "${PNK}║${RST} ${CYN}SYNOPSIS:${RST} ParamSpider — mines URLs with parameters from web ${RST}\n"
        printf "${PNK}║${RST}          archives. Passive, no active probing.               ${RST}\n"
        printf "${PNK}║${RST} ${CYN}USE:${RST} Enter domain — returns parameterised URLs.            ${RST}\n"
        printf "${PNK}║${RST} ${CYN}INSTALL:${RST} git clone + pip install requirements.txt           ${RST}\n"
        printf "${PNK}╚══════════════════════════════════════════════════════════════╝${RST}\n\n"
        printf "  ${GRN}[1]${RST}  Basic Crawl            ${DESC}- paramspider -d <domain>${RST}\n"
        printf "  ${GRN}[2]${RST}  Exclude Extensions     ${DESC}- exclude css/js/png/jpg${RST}\n"
        printf "  ${GRN}[3]${RST}  Save Output            ${DESC}- → downloads/paramspider_out.txt${RST}\n"
        printf "  ${GRN}[I]${RST}  Install                ${DESC}- git clone + pip${RST}\n"
        printf "  ${YLW}[B]${RST}  Back\n\n"
        printf "  %sChoose: %s" "${HOT}" "${RST}"; read -r SC
        local _PS="python3 ${HOME}/ParamSpider/paramspider.py"
        case "$SC" in
            1) ! $PARAMSPIDER_INSTALLED && { install_paramspider; $PARAMSPIDER_INSTALLED || continue; }
               run_web_tool "${_PS} -d TARGET_PLACEHOLDER" "ParamSpider · Basic" "yes" "paramspider -d <domain>" ;;
            2) ! $PARAMSPIDER_INSTALLED && { install_paramspider; $PARAMSPIDER_INSTALLED || continue; }
               run_web_tool "${_PS} -d TARGET_PLACEHOLDER --exclude css,js,png,jpg,svg,woff" "ParamSpider · Exclude" "yes" "paramspider --exclude" ;;
            3) ! $PARAMSPIDER_INSTALLED && { install_paramspider; $PARAMSPIDER_INSTALLED || continue; }
               run_web_tool "${_PS} -d TARGET_PLACEHOLDER -o ${HOME}/storage/downloads/paramspider_out.txt && cat ${HOME}/storage/downloads/paramspider_out.txt" "ParamSpider · Save" "yes" "paramspider + save" ;;
            i|I) install_paramspider ;;
            b|B) break ;;
            *) printf "  %s[!] Invalid.%s\n" "${RED}" "${RST}"; sleep 1 ;;
        esac
    done
}

submenu_ssrfmap() {
    while true; do
        clear; banner; echo ""
        center_in_box "SSRFMAP · SSRF DETECTION AND EXPLOITATION"
        short_pink_line 32; echo ""
        printf "${PNK}╔══════════════════════════════════════════════════════════════╗${RST}\n"
        printf "${PNK}║${RST} ${CYN}SYNOPSIS:${RST} SSRFmap — automated SSRF detection and exploit    ${RST}\n"
        printf "${PNK}║${RST}          tool. Python3. Uses a request file as input.        ${RST}\n"
        printf "${PNK}║${RST} ${CYN}USE:${RST} Enter path to saved HTTP request file.                ${RST}\n"
        printf "${PNK}║${RST} ${CYN}INSTALL:${RST} git clone + pip install requirements.txt           ${RST}\n"
        printf "${PNK}╚══════════════════════════════════════════════════════════════╝${RST}\n\n"
        printf "  ${GRN}[1]${RST}  Scan Request File      ${DESC}- ssrfmap -r <request_file>${RST}\n"
        printf "  ${GRN}[2]${RST}  List Modules           ${DESC}- show available exploit modules${RST}\n"
        printf "  ${GRN}[3]${RST}  Run with Module        ${DESC}- specify exploit module${RST}\n"
        printf "  ${GRN}[I]${RST}  Install                ${DESC}- git clone + pip${RST}\n"
        printf "  ${YLW}[B]${RST}  Back\n\n"
        printf "  %sChoose: %s" "${HOT}" "${RST}"; read -r SC
        local _SM="python3 ${HOME}/ssrfmap/ssrfmap.py"
        case "$SC" in
            1) ! $SSRFMAP_INSTALLED && { install_ssrfmap; $SSRFMAP_INSTALLED || continue; }
               printf "  %sRequest file path: %s" "${HOT}" "${RST}"; read -r SM_REQ
               [ -z "$SM_REQ" ] && { printf "  %s[!] No input.%s\n" "${RED}" "${RST}"; sleep 1; continue; }
               printf "\n  %s[*] Running SSRFmap...%s\n\n" "${CYN}" "${RST}"
               ${_SM} -r "$SM_REQ" 2>&1 | tee -a "$LOG"
               printf "  %sPress ENTER...%s" "${HOT}" "${RST}"; read -r _ ;;
            2) ! $SSRFMAP_INSTALLED && { install_ssrfmap; $SSRFMAP_INSTALLED || continue; }
               ${_SM} --list 2>&1 | tee -a "$LOG"
               printf "  %sPress ENTER...%s" "${HOT}" "${RST}"; read -r _ ;;
            3) ! $SSRFMAP_INSTALLED && { install_ssrfmap; $SSRFMAP_INSTALLED || continue; }
               printf "  %sRequest file: %s" "${HOT}" "${RST}"; read -r SM_REQ
               printf "  %sModule (e.g. readfiles): %s" "${HOT}" "${RST}"; read -r SM_MOD
               [ -z "$SM_REQ" ] && { printf "  %s[!] No input.%s\n" "${RED}" "${RST}"; sleep 1; continue; }
               printf "\n  %s[*] Running SSRFmap -m %s...%s\n\n" "${CYN}" "$SM_MOD" "${RST}"
               ${_SM} -r "$SM_REQ" -m "$SM_MOD" 2>&1 | tee -a "$LOG"
               printf "  %sPress ENTER...%s" "${HOT}" "${RST}"; read -r _ ;;
            i|I) install_ssrfmap ;;
            b|B) break ;;
            *) printf "  %s[!] Invalid.%s\n" "${RED}" "${RST}"; sleep 1 ;;
        esac
    done
}

submenu_chaos() {
    while true; do
        clear; banner; echo ""
        center_in_box "CHAOS · PROJECTDISCOVERY SUBDOMAIN DATASET"
        short_pink_line 32; echo ""
        printf "${PNK}╔══════════════════════════════════════════════════════════════╗${RST}\n"
        printf "${PNK}║${RST} ${CYN}SYNOPSIS:${RST} Chaos — queries ProjectDiscovery recon dataset    ${RST}\n"
        printf "${PNK}║${RST}          for known subdomains. Requires free API key.        ${RST}\n"
        printf "${PNK}║${RST} ${CYN}KEY:${RST} chaos.projectdiscovery.io → free signup               ${RST}\n"
        printf "${PNK}║${RST} ${CYN}INSTALL:${RST} go install github.com/projectdiscovery/chaos-client${RST}\n"
        printf "${PNK}╚══════════════════════════════════════════════════════════════╝${RST}\n\n"
        printf "  ${GRN}[1]${RST}  Query Domain           ${DESC}- chaos -d <domain>${RST}\n"
        printf "  ${GRN}[2]${RST}  Save Output            ${DESC}- → downloads/chaos_out.txt${RST}\n"
        printf "  ${GRN}[3]${RST}  Set API Key            ${DESC}- saves CHAOS_KEY to .bashrc${RST}\n"
        printf "  ${GRN}[I]${RST}  Install                ${DESC}- go install chaos-client${RST}\n"
        printf "  ${YLW}[B]${RST}  Back\n\n"
        printf "  %sChoose: %s" "${HOT}" "${RST}"; read -r SC
        local _CH="${HOME}/go/bin/chaos"; command -v chaos >/dev/null 2>&1 && _CH="chaos"
        case "$SC" in
            1) ! $CHAOS_INSTALLED && { install_chaos; $CHAOS_INSTALLED || continue; }
               [ -z "$CHAOS_KEY" ] && { printf "  %s[!] CHAOS_KEY not set. Use option 3.%s\n" "${RED}" "${RST}"; sleep 2; continue; }
               run_web_tool "CHAOS_KEY=${CHAOS_KEY} ${_CH} -d TARGET_PLACEHOLDER -silent" "Chaos · Query" "yes" "chaos -d <domain>" ;;
            2) ! $CHAOS_INSTALLED && { install_chaos; $CHAOS_INSTALLED || continue; }
               [ -z "$CHAOS_KEY" ] && { printf "  %s[!] CHAOS_KEY not set. Use option 3.%s\n" "${RED}" "${RST}"; sleep 2; continue; }
               run_web_tool "CHAOS_KEY=${CHAOS_KEY} ${_CH} -d TARGET_PLACEHOLDER -silent | tee ${HOME}/storage/downloads/chaos_out.txt" "Chaos · Save" "yes" "chaos + save" ;;
            3) printf "  %sPaste Chaos API key: %s" "${HOT}" "${RST}"; read -r CHAOS_KEY
               [ -n "$CHAOS_KEY" ] && {
                   grep -q "export CHAOS_KEY=" "${HOME}/.bashrc" 2>/dev/null \
                       && sed -i "s|export CHAOS_KEY=.*|export CHAOS_KEY=${CHAOS_KEY}|" "${HOME}/.bashrc" \
                       || echo "export CHAOS_KEY=${CHAOS_KEY}" >> "${HOME}/.bashrc"
                   export CHAOS_KEY
                   printf "  %s[+] Key saved to .bashrc.%s\n" "${GRN}" "${RST}"
               }
               printf "  %sPress ENTER...%s" "${HOT}" "${RST}"; read -r _ ;;
            i|I) install_chaos ;;
            b|B) break ;;
            *) printf "  %s[!] Invalid.%s\n" "${RED}" "${RST}"; sleep 1 ;;
        esac
    done
}

install_all_web_modules() {
    clear; banner; echo ""
    printf "%s  [*] FEZZY G.I.JOE — Installing All Web Modules...%s\n\n" "${CYN}" "${RST}"
    install_domain_intel; install_web_fingerprint; install_ssl_check
    install_vulnerability_scan; install_directory_hunter
    install_web_crawler; install_fuzzing_engine
    install_netcat; install_jq; install_harvester
    install_httprobe; install_sqlmap; install_wafw00f; install_ffuf
    printf "\n  %s[*] Installing V8 rootless arsenal...%s\n" "${CYN}" "${RST}"
    install_amass; install_nuclei; install_katana; install_shuffledns
    install_httpx_tool; install_subfinder; install_naabu; install_dnsx_tool
    install_massdns_tool; install_waybackurls; install_gau_tool
    printf "\n  %s[*] Installing V10 · Fezzy Station tools...%s\n" "${CYN}" "${RST}"
    install_arjun; install_optiva; install_hiddenurl
    printf "\n  %s[*] Installing V11 · Bounty Arsenal...%s\n" "${CYN}" "${RST}"
    install_dalfox; install_kxss; install_gf
    install_trufflehog; install_crlfuzz; install_byp4xx; install_feroxbuster
    printf "\n%s  [+] All modules done. V11 · Bounty Arsenal · 999%s\n\n" "${GRN}" "${RST}"; sleep 2
}

backup_web_config() {
    mkdir -p "$TOOL_DIR"
    cat > "$CONFIG_FILE" << EOF
DOMAIN_INTEL_INSTALLED=$DOMAIN_INTEL_INSTALLED
WEB_FINGERPRINT_INSTALLED=$WEB_FINGERPRINT_INSTALLED
SSL_CHECK_INSTALLED=$SSL_CHECK_INSTALLED
VULN_SCAN_INSTALLED=$VULN_SCAN_INSTALLED
DIRECTORY_HUNTER_INSTALLED=$DIRECTORY_HUNTER_INSTALLED
WEB_CRAWLER_INSTALLED=$WEB_CRAWLER_INSTALLED
FUZZING_ENGINE_INSTALLED=$FUZZING_ENGINE_INSTALLED
EOF
    printf "\n  %s[+] Web config backed up → %s%s\n" "${GRN}" "$CONFIG_FILE" "${RST}"; sleep 1
}

restore_web_config() {
    [ -f "$CONFIG_FILE" ] \
        && { source "$CONFIG_FILE"; printf "\n  %s[+] Config restored.%s\n" "${GRN}" "${RST}"; } \
        || printf "\n  %s[!] No backup found.%s\n" "${RED}" "${RST}"
    sleep 1
}

submenu_domain_intel() {
    while true; do
        clear; banner; echo ""
        center_in_box "DOMAIN INTELLIGENCE · SUBMENU"
        short_pink_line 32; echo ""
        printf "${PNK}╔══════════════════════════════════════════════════════════════╗${RST}\n"
        printf "${PNK}║${RST} ${CYN}SYNOPSIS:${RST} Full DNS recon — A/MX/NS/TXT/SPF, WHOIS, reverse IP,   ${RST}\n"
        printf "${PNK}║${RST}          subdomain brute. Paste domain → auto full recon.      ${RST}\n"
        printf "${PNK}║${RST} ${CYN}USE:${RST} Enter domain (e.g. example.com) or IP when prompted.      ${RST}\n"
        printf "${PNK}╚══════════════════════════════════════════════════════════════╝${RST}\n\n"
        printf "  ${GRN}[1]${RST}  DNS Lookup              ${DESC}- dig A record for target${RST}\n"
        printf "  ${GRN}[2]${RST}  WHOIS Query             ${DESC}- registrar, dates, contacts${RST}\n"
        printf "  ${GRN}[3]${RST}  DNS + WHOIS (Full)      ${DESC}- combined recon in one shot${RST}\n"
        printf "  ${GRN}[4]${RST}  DNS Brute Force         ${DESC}- brute common subdomains via dig${RST}\n"
        printf "  ${GRN}[5]${RST}  MX Records              ${DESC}- mail server enumeration${RST}\n"
        printf "  ${GRN}[6]${RST}  NS Records              ${DESC}- name server lookup${RST}\n"
        printf "  ${GRN}[7]${RST}  TXT / SPF Records       ${DESC}- SPF, DMARC, DKIM verification${RST}\n"
        printf "  ${GRN}[8]${RST}  Reverse IP Lookup       ${DESC}- who else is on this IP${RST}\n"
        printf "  ${GRN}[9]${RST}  Full Auto Recon         ${DESC}- paste domain → dig/whois/mx/ns/txt${RST}\n"
        printf "  ${GRN}[I]${RST}  Install Module          ${DESC}- install dig + whois${RST}\n"
        printf "  ${YLW}[B]${RST}  Back\n\n"
        printf "  %sChoose: %s" "${HOT}" "${RST}"; read -r SC
        case "$SC" in
            1) ! $DOMAIN_INTEL_INSTALLED && { install_domain_intel; $DOMAIN_INTEL_INSTALLED || continue; }
               run_web_tool "dig TARGET_PLACEHOLDER" "Domain Intelligence · DNS Lookup" "yes" "dig <target>" ;;
            2) ! $DOMAIN_INTEL_INSTALLED && { install_domain_intel; $DOMAIN_INTEL_INSTALLED || continue; }
               run_web_tool "whois TARGET_PLACEHOLDER" "Domain Intelligence · WHOIS Query" "yes" "whois <target>" ;;
            3) ! $DOMAIN_INTEL_INSTALLED && { install_domain_intel; $DOMAIN_INTEL_INSTALLED || continue; }
               run_web_tool "{ echo '--- DNS ---'; dig TARGET_PLACEHOLDER; echo ''; echo '--- WHOIS ---'; whois TARGET_PLACEHOLDER; }" \
                   "Domain Intelligence · Full" "yes" "dig + whois <target>" ;;
            4) ! $DOMAIN_INTEL_INSTALLED && { install_domain_intel; $DOMAIN_INTEL_INSTALLED || continue; }
               run_web_tool "for sub in www admin mail ftp blog dev test api vpn; do echo -n \"\$sub.\"; dig +short \"\${sub}.TARGET_PLACEHOLDER\" || echo 'N/A'; done" \
                   "Domain Intelligence · DNS Brute Force" "yes" "dig subdomain brute <target>" ;;
            5) ! $DOMAIN_INTEL_INSTALLED && { install_domain_intel; $DOMAIN_INTEL_INSTALLED || continue; }
               run_web_tool "dig MX TARGET_PLACEHOLDER" "Domain Intelligence · MX Records" "yes" "dig MX <target>" ;;
            6) ! $DOMAIN_INTEL_INSTALLED && { install_domain_intel; $DOMAIN_INTEL_INSTALLED || continue; }
               run_web_tool "dig NS TARGET_PLACEHOLDER" "Domain Intelligence · NS Records" "yes" "dig NS <target>" ;;
            7) ! $DOMAIN_INTEL_INSTALLED && { install_domain_intel; $DOMAIN_INTEL_INSTALLED || continue; }
               run_web_tool "{ echo '--- TXT ---'; dig TXT TARGET_PLACEHOLDER; echo ''; echo '--- SPF ---'; dig TXT TARGET_PLACEHOLDER | grep -i spf; echo ''; echo '--- DMARC ---'; dig TXT _dmarc.TARGET_PLACEHOLDER; }" \
                   "Domain Intelligence · TXT/SPF/DMARC" "yes" "dig TXT + SPF + DMARC <target>" ;;
            8) ! $DOMAIN_INTEL_INSTALLED && { install_domain_intel; $DOMAIN_INTEL_INSTALLED || continue; }
               run_web_tool "{ IP=\$(dig +short TARGET_PLACEHOLDER | head -n1); echo \"IP: \$IP\"; dig +short -x \"\$IP\"; }" \
                   "Domain Intelligence · Reverse IP" "yes" "dig -x <resolved IP>" ;;
            9) ! $DOMAIN_INTEL_INSTALLED && { install_domain_intel; $DOMAIN_INTEL_INSTALLED || continue; }
               run_web_tool "{ echo '=== A RECORD ==='; dig +short TARGET_PLACEHOLDER; echo ''; echo '=== MX ==='; dig MX TARGET_PLACEHOLDER; echo ''; echo '=== NS ==='; dig NS TARGET_PLACEHOLDER; echo ''; echo '=== TXT/SPF ==='; dig TXT TARGET_PLACEHOLDER; echo ''; echo '=== WHOIS ==='; whois TARGET_PLACEHOLDER; echo ''; echo '=== REVERSE IP ==='; IP=\$(dig +short TARGET_PLACEHOLDER | head -n1); dig +short -x \"\$IP\"; }" \
                   "Domain Intelligence · Full Auto Recon" "yes" "dig/whois/mx/ns/txt/reverse <target>" ;;
            i|I) install_domain_intel ;;
            b|B) return ;;
            *) printf "  %s[!] Invalid.%s\n" "${RED}" "${RST}"; sleep 1 ;;
        esac
    done
}

submenu_web_fingerprint() {
    while true; do
        clear; banner; echo ""
        center_in_box "WEB FINGERPRINT · SUBMENU"
        short_pink_line 32; echo ""
        printf "${PNK}╔══════════════════════════════════════════════════════════════╗${RST}\n"
        printf "${PNK}║${RST} ${CYN}SYNOPSIS:${RST} Fingerprint target — CMS, server, framework, WAF,       ${RST}\n"
        printf "${PNK}║${RST}          headers, tech stack. Paste URL → auto full stack ID.  ${RST}\n"
        printf "${PNK}║${RST} ${CYN}USE:${RST} Enter full URL (e.g. https://example.com) when prompted.   ${RST}\n"
        printf "${PNK}╚══════════════════════════════════════════════════════════════╝${RST}\n\n"
        printf "  ${GRN}[1]${RST}  Basic Fingerprint        ${DESC}- whatweb standard scan${RST}\n"
        printf "  ${GRN}[2]${RST}  Aggressive Fingerprint   ${DESC}- whatweb -a 3 deep scan${RST}\n"
        printf "  ${GRN}[3]${RST}  Verbose Output           ${DESC}- whatweb full verbose mode${RST}\n"
        printf "  ${GRN}[4]${RST}  Export to JSON           ${DESC}- whatweb JSON output${RST}\n"
        printf "  ${GRN}[5]${RST}  Headers Only             ${DESC}- curl -I response headers${RST}\n"
        printf "  ${GRN}[6]${RST}  Technology Audit         ${DESC}- curl + grep CMS/framework patterns${RST}\n"
        printf "  ${GRN}[7]${RST}  WAF Detection            ${DESC}- nmap http-waf-detect script${RST}\n"
        printf "  ${GRN}[8]${RST}  Full Stack Auto Recon    ${DESC}- paste URL → headers+whatweb+WAF${RST}\n"
        printf "  ${GRN}[I]${RST}  Install Module           ${DESC}- install whatweb${RST}\n"
        printf "  ${YLW}[B]${RST}  Back\n\n"
        printf "  %sChoose: %s" "${HOT}" "${RST}"; read -r SC
        case "$SC" in
            1) ! $WEB_FINGERPRINT_INSTALLED && { install_web_fingerprint; $WEB_FINGERPRINT_INSTALLED || continue; }
               run_web_tool "whatweb TARGET_PLACEHOLDER" "Web Fingerprint · Basic" "yes" "whatweb <target>" ;;
            2) ! $WEB_FINGERPRINT_INSTALLED && { install_web_fingerprint; $WEB_FINGERPRINT_INSTALLED || continue; }
               run_web_tool "whatweb -a 3 TARGET_PLACEHOLDER" "Web Fingerprint · Aggressive" "yes" "whatweb -a 3 <target>" ;;
            3) ! $WEB_FINGERPRINT_INSTALLED && { install_web_fingerprint; $WEB_FINGERPRINT_INSTALLED || continue; }
               run_web_tool "whatweb -v TARGET_PLACEHOLDER" "Web Fingerprint · Verbose" "yes" "whatweb -v <target>" ;;
            4) ! $WEB_FINGERPRINT_INSTALLED && { install_web_fingerprint; $WEB_FINGERPRINT_INSTALLED || continue; }
               run_web_tool "whatweb --json TARGET_PLACEHOLDER" "Web Fingerprint · JSON Export" "yes" "whatweb --json <target>" ;;
            5) run_web_tool "curl -I -s --max-time 10 TARGET_PLACEHOLDER" \
                   "Web Fingerprint · Headers Only" "yes" "curl -I <target>" ;;
            6) run_web_tool "{ echo '=== HEADERS ==='; curl -I -s --max-time 10 TARGET_PLACEHOLDER; echo ''; echo '=== TECH PATTERNS ==='; curl -sL --max-time 15 TARGET_PLACEHOLDER | grep -Eo '(WordPress|Joomla|Drupal|Laravel|React|Angular|Vue|Bootstrap|jQuery|PHP|ASP\.NET|nginx|Apache)[^\"]*' | sort -u; }" \
                   "Web Fingerprint · Technology Audit" "yes" "curl + grep tech patterns <target>" ;;
            7) ! $NMAP_INSTALLED && { printf "  %s[!] nmap required.%s\n" "${RED}" "${RST}"; sleep 2; continue; }
               run_web_tool "nmap --script http-waf-detect -p 80,443 TARGET_PLACEHOLDER" \
                   "Web Fingerprint · WAF Detection" "yes" "nmap http-waf-detect <target>" ;;
            8) ! $WEB_FINGERPRINT_INSTALLED && { install_web_fingerprint; $WEB_FINGERPRINT_INSTALLED || continue; }
               run_web_tool "{ echo '=== HEADERS ==='; curl -I -s --max-time 10 TARGET_PLACEHOLDER; echo ''; echo '=== WHATWEB ==='; whatweb -a 3 TARGET_PLACEHOLDER; echo ''; echo '=== WAF DETECT ==='; nmap --script http-waf-detect -p 80,443 TARGET_PLACEHOLDER 2>/dev/null | grep -i waf; }" \
                   "Web Fingerprint · Full Stack Auto Recon" "yes" "headers + whatweb + WAF <target>" ;;
            i|I) install_web_fingerprint ;;
            b|B) return ;;
            *) printf "  %s[!] Invalid.%s\n" "${RED}" "${RST}"; sleep 1 ;;
        esac
    done
}

submenu_ssl_check() {
    while true; do
        clear; banner; echo ""
        center_in_box "SSL CHECK · SUBMENU"
        short_pink_line 24; echo ""
        printf "${PNK}╔══════════════════════════════════════════════════════════════╗${RST}\n"
        printf "${PNK}║${RST} ${CYN}SYNOPSIS:${RST} Inspect SSL/TLS — expiry, chain, ciphers, HSTS,         ${RST}\n"
        printf "${PNK}║${RST}          SAN domains, protocol version. Paste domain → auto.   ${RST}\n"
        printf "${PNK}║${RST} ${CYN}USE:${RST} Enter domain or IP (port 443 used by default).             ${RST}\n"
        printf "${PNK}╚══════════════════════════════════════════════════════════════╝${RST}\n\n"
        printf "  ${GRN}[1]${RST}  Basic SSL Check          ${DESC}- openssl s_client connect${RST}\n"
        printf "  ${GRN}[2]${RST}  Full Certificate Chain   ${DESC}- openssl -showcerts full dump${RST}\n"
        printf "  ${GRN}[3]${RST}  Check Weak Ciphers       ${DESC}- nmap ssl-enum-ciphers${RST}\n"
        printf "  ${GRN}[4]${RST}  Expiry Date Only         ${DESC}- openssl x509 -noout -dates${RST}\n"
        printf "  ${GRN}[5]${RST}  Protocol Version Check   ${DESC}- TLS 1.0/1.1/1.2/1.3 support${RST}\n"
        printf "  ${GRN}[6]${RST}  HSTS Header Check        ${DESC}- curl for Strict-Transport-Security${RST}\n"
        printf "  ${GRN}[7]${RST}  SAN Domains              ${DESC}- Subject Alt Names on cert${RST}\n"
        printf "  ${GRN}[8]${RST}  Full Cert Auto Dump      ${DESC}- paste domain → all cert data${RST}\n"
        printf "  ${GRN}[I]${RST}  Install Module           ${DESC}- install openssl + nmap${RST}\n"
        printf "  ${YLW}[B]${RST}  Back\n\n"
        printf "  %sChoose: %s" "${HOT}" "${RST}"; read -r SC
        case "$SC" in
            1) ! $SSL_CHECK_INSTALLED && { install_ssl_check; $SSL_CHECK_INSTALLED || continue; }
               run_web_tool "openssl s_client -connect TARGET_PLACEHOLDER:443 2>&1 | head -50" "SSL Check · Basic" "yes" "openssl s_client <target>:443" ;;
            2) ! $SSL_CHECK_INSTALLED && { install_ssl_check; $SSL_CHECK_INSTALLED || continue; }
               run_web_tool "openssl s_client -connect TARGET_PLACEHOLDER:443 -showcerts 2>&1" "SSL Check · Full Chain" "yes" "openssl s_client <target>:443 -showcerts" ;;
            3) ! $SSL_CHECK_INSTALLED && { install_ssl_check; $SSL_CHECK_INSTALLED || continue; }
               run_web_tool "nmap --script ssl-enum-ciphers -p 443 TARGET_PLACEHOLDER" "SSL Check · Weak Ciphers" "yes" "nmap ssl-enum-ciphers <target>" ;;
            4) ! $SSL_CHECK_INSTALLED && { install_ssl_check; $SSL_CHECK_INSTALLED || continue; }
               run_web_tool "echo | openssl s_client -servername TARGET_PLACEHOLDER -connect TARGET_PLACEHOLDER:443 2>/dev/null | openssl x509 -noout -dates" "SSL Check · Expiry Date" "yes" "openssl x509 dates <target>" ;;
            5) ! $SSL_CHECK_INSTALLED && { install_ssl_check; $SSL_CHECK_INSTALLED || continue; }
               run_web_tool "{ for proto in tls1 tls1_1 tls1_2 tls1_3; do printf \"%-10s: \" \"\$proto\"; echo | openssl s_client -connect TARGET_PLACEHOLDER:443 -\$proto 2>&1 | grep -q 'Cipher is' && echo 'SUPPORTED' || echo 'NOT supported'; done; }" \
                   "SSL Check · Protocol Version" "yes" "openssl tls version check <target>" ;;
            6) run_web_tool "{ R=\$(curl -sI --max-time 10 https://TARGET_PLACEHOLDER); echo \"\$R\" | grep -i 'strict-transport' || echo 'HSTS NOT SET'; echo ''; echo \"\$R\" | grep -i 'server:'; }" \
                   "SSL Check · HSTS Header" "yes" "curl -I HSTS check <target>" ;;
            7) ! $SSL_CHECK_INSTALLED && { install_ssl_check; $SSL_CHECK_INSTALLED || continue; }
               run_web_tool "echo | openssl s_client -servername TARGET_PLACEHOLDER -connect TARGET_PLACEHOLDER:443 2>/dev/null | openssl x509 -noout -text | grep -A1 'Subject Alternative Name'" \
                   "SSL Check · SAN Domains" "yes" "openssl x509 SAN <target>" ;;
            8) ! $SSL_CHECK_INSTALLED && { install_ssl_check; $SSL_CHECK_INSTALLED || continue; }
               run_web_tool "{ echo '=== EXPIRY ==='; echo | openssl s_client -servername TARGET_PLACEHOLDER -connect TARGET_PLACEHOLDER:443 2>/dev/null | openssl x509 -noout -dates; echo ''; echo '=== SAN DOMAINS ==='; echo | openssl s_client -servername TARGET_PLACEHOLDER -connect TARGET_PLACEHOLDER:443 2>/dev/null | openssl x509 -noout -text | grep -A1 'Subject Alternative Name'; echo ''; echo '=== HSTS ==='; curl -sI --max-time 10 https://TARGET_PLACEHOLDER | grep -i strict || echo 'HSTS NOT SET'; echo ''; echo '=== WEAK CIPHERS ==='; nmap --script ssl-enum-ciphers -p 443 TARGET_PLACEHOLDER 2>/dev/null | grep -E 'TLS|SSL|weak|least'; }" \
                   "SSL Check · Full Auto Cert Dump" "yes" "expiry+SAN+HSTS+ciphers <target>" ;;
            i|I) install_ssl_check ;;
            b|B) return ;;
            *) printf "  %s[!] Invalid.%s\n" "${RED}" "${RST}"; sleep 1 ;;
        esac
    done
}

submenu_vulnerability_scan() {
    while true; do
        clear; banner; echo ""
        center_in_box "VULNERABILITY SCAN · SUBMENU"
        short_pink_line 36; echo ""
        printf "${PNK}╔══════════════════════════════════════════════════════════════╗${RST}\n"
        printf "${PNK}║${RST} ${CYN}SYNOPSIS:${RST} Audit web servers — nikto, CVE scripts, port 80/443     ${RST}\n"
        printf "${PNK}║${RST}          combo, SSL+headers audit. Paste URL → auto vuln run.  ${RST}\n"
        printf "${PNK}║${RST} ${CYN}USE:${RST} Enter full URL or IP when prompted.                        ${RST}\n"
        printf "${PNK}╚══════════════════════════════════════════════════════════════╝${RST}\n\n"
        printf "  ${GRN}[1]${RST}  Quick Scan (Common Plugins)  ${DESC}- nikto -T 1-5${RST}\n"
        printf "  ${GRN}[2]${RST}  Full Vulnerability Scan      ${DESC}- nikto full default run${RST}\n"
        printf "  ${GRN}[3]${RST}  Verbose Scan                 ${DESC}- nikto -v verbose output${RST}\n"
        printf "  ${GRN}[4]${RST}  Scan with Custom Plugins     ${DESC}- nikto -Plugins custom${RST}\n"
        printf "  ${GRN}[5]${RST}  SSL + Headers Combo          ${DESC}- nikto -ssl + header checks${RST}\n"
        printf "  ${GRN}[6]${RST}  CVE Script Check             ${DESC}- nmap --script vuln port 80/443${RST}\n"
        printf "  ${GRN}[7]${RST}  Port 80/443 Auto Combo       ${DESC}- nikto on both ports${RST}\n"
        printf "  ${GRN}[8]${RST}  Full Auto Vuln Recon         ${DESC}- paste URL → nikto+nmap vuln${RST}\n"
        printf "  ${GRN}[I]${RST}  Install Module               ${DESC}- install nikto${RST}\n"
        printf "  ${YLW}[B]${RST}  Back\n\n"
        printf "  %sChoose: %s" "${HOT}" "${RST}"; read -r SC
        case "$SC" in
            1) ! $VULN_SCAN_INSTALLED && { install_vulnerability_scan; $VULN_SCAN_INSTALLED || continue; }
               run_web_tool "nikto -h TARGET_PLACEHOLDER -T 1-5" "Vulnerability Scan · Quick" "yes" "nikto -h <target> -T 1-5" ;;
            2) ! $VULN_SCAN_INSTALLED && { install_vulnerability_scan; $VULN_SCAN_INSTALLED || continue; }
               run_web_tool "nikto -h TARGET_PLACEHOLDER" "Vulnerability Scan · Full" "yes" "nikto -h <target>" ;;
            3) ! $VULN_SCAN_INSTALLED && { install_vulnerability_scan; $VULN_SCAN_INSTALLED || continue; }
               run_web_tool "nikto -h TARGET_PLACEHOLDER -v" "Vulnerability Scan · Verbose" "yes" "nikto -h <target> -v" ;;
            4) ! $VULN_SCAN_INSTALLED && { install_vulnerability_scan; $VULN_SCAN_INSTALLED || continue; }
               printf "  %sEnter plugins (e.g. apacheversion,cgi): %s" "${HOT}" "${RST}"; read -r PLGS
               [ -z "$PLGS" ] && PLGS="apacheversion,cgi,cms,headers"
               run_web_tool "nikto -h TARGET_PLACEHOLDER -Plugins '$PLGS'" "Vulnerability Scan · Custom Plugins" "yes" "nikto -h <target> -Plugins $PLGS" ;;
            5) ! $VULN_SCAN_INSTALLED && { install_vulnerability_scan; $VULN_SCAN_INSTALLED || continue; }
               run_web_tool "{ echo '=== SSL AUDIT ==='; nikto -h TARGET_PLACEHOLDER -ssl; echo ''; echo '=== HEADER AUDIT ==='; curl -I -s --max-time 10 https://TARGET_PLACEHOLDER | grep -Ei 'server:|x-powered|content-security|x-frame|x-xss|strict-transport'; }" \
                   "Vulnerability Scan · SSL + Headers Combo" "yes" "nikto -ssl + curl headers <target>" ;;
            6) ! $NMAP_INSTALLED && { printf "  %s[!] nmap required.%s\n" "${RED}" "${RST}"; sleep 2; continue; }
               run_web_tool "nmap --script vuln -p 80,443 TARGET_PLACEHOLDER" \
                   "Vulnerability Scan · CVE Script Check" "yes" "nmap --script vuln -p 80,443 <target>" ;;
            7) ! $VULN_SCAN_INSTALLED && { install_vulnerability_scan; $VULN_SCAN_INSTALLED || continue; }
               run_web_tool "{ echo '=== PORT 80 ==='; nikto -h TARGET_PLACEHOLDER -port 80; echo ''; echo '=== PORT 443 ==='; nikto -h TARGET_PLACEHOLDER -port 443 -ssl; }" \
                   "Vulnerability Scan · Port 80/443 Combo" "yes" "nikto port 80 + 443 <target>" ;;
            8) ! $VULN_SCAN_INSTALLED && { install_vulnerability_scan; $VULN_SCAN_INSTALLED || continue; }
               run_web_tool "{ echo '=== NIKTO FULL ==='; nikto -h TARGET_PLACEHOLDER; echo ''; echo '=== NMAP VULN ==='; nmap --script vuln -p 80,443 TARGET_PLACEHOLDER 2>/dev/null; echo ''; echo '=== HEADERS ==='; curl -I -s --max-time 10 TARGET_PLACEHOLDER | grep -Ei 'server:|x-powered|content-security|x-frame|x-xss|strict-transport'; }" \
                   "Vulnerability Scan · Full Auto Recon" "yes" "nikto + nmap vuln + headers <target>" ;;
            i|I) install_vulnerability_scan ;;
            b|B) return ;;
            *) printf "  %s[!] Invalid.%s\n" "${RED}" "${RST}"; sleep 1 ;;
        esac
    done
}

submenu_directory_hunter() {
    while true; do
        clear; banner; echo ""
        center_in_box "DIRECTORY HUNTER · SUBMENU"
        short_pink_line 32; echo ""
        printf "${PNK}╔══════════════════════════════════════════════════════════════╗${RST}\n"
        printf "${PNK}║${RST} ${CYN}SYNOPSIS:${RST} Brute-force dirs, subdomains, extensions, vhosts,       ${RST}\n"
        printf "${PNK}║${RST}          robots.txt, sitemap, backup files. Paste URL → auto.  ${RST}\n"
        printf "${PNK}║${RST} ${CYN}USE:${RST} Enter full URL (dirs) or domain (subdomains).              ${RST}\n"
        printf "${PNK}╚══════════════════════════════════════════════════════════════╝${RST}\n\n"
        printf "  ${GRN}[1]${RST}  Directory Brute Force          ${DESC}- gobuster dir common.txt${RST}\n"
        printf "  ${GRN}[2]${RST}  Subdomain Brute Force          ${DESC}- gobuster dns common.txt${RST}\n"
        printf "  ${GRN}[3]${RST}  File Extension Brute Force     ${DESC}- gobuster dir -x php,html,asp${RST}\n"
        printf "  ${GRN}[4]${RST}  Directory Brute (Custom WL)    ${DESC}- gobuster dir custom wordlist${RST}\n"
        printf "  ${GRN}[5]${RST}  Subdomain Brute (Custom WL)    ${DESC}- gobuster dns custom wordlist${RST}\n"
        printf "  ${GRN}[6]${RST}  Vhost Brute Force              ${DESC}- gobuster vhost virtual hosts${RST}\n"
        printf "  ${GRN}[7]${RST}  Robots.txt + Sitemap Harvest   ${DESC}- curl robots.txt + sitemap.xml${RST}\n"
        printf "  ${GRN}[8]${RST}  Backup File Hunt               ${DESC}- check .bak .old .zip .sql files${RST}\n"
        printf "  ${GRN}[9]${RST}  Full Auto Dir Recon            ${DESC}- paste URL → dir+ext+robots${RST}\n"
        printf "  ${GRN}[I]${RST}  Install Module                 ${DESC}- install gobuster${RST}\n"
        printf "  ${YLW}[B]${RST}  Back\n\n"
        printf "  %sChoose: %s" "${HOT}" "${RST}"; read -r SC
        local WL="/usr/share/wordlists/dirb/common.txt"
        case "$SC" in
            1) ! $DIRECTORY_HUNTER_INSTALLED && { install_directory_hunter; $DIRECTORY_HUNTER_INSTALLED || continue; }
               run_web_tool "gobuster dir -u TARGET_PLACEHOLDER -w $WL" "Directory Hunter · Directories" "yes" "gobuster dir -u <target>" ;;
            2) ! $DIRECTORY_HUNTER_INSTALLED && { install_directory_hunter; $DIRECTORY_HUNTER_INSTALLED || continue; }
               run_web_tool "gobuster dns -d TARGET_PLACEHOLDER -w $WL" "Directory Hunter · Subdomains" "yes" "gobuster dns -d <target>" ;;
            3) ! $DIRECTORY_HUNTER_INSTALLED && { install_directory_hunter; $DIRECTORY_HUNTER_INSTALLED || continue; }
               run_web_tool "gobuster dir -u TARGET_PLACEHOLDER -w $WL -x php,html,asp,aspx,jsp,do,action" "Directory Hunter · Extensions" "yes" "gobuster dir -x php,html..." ;;
            4) ! $DIRECTORY_HUNTER_INSTALLED && { install_directory_hunter; $DIRECTORY_HUNTER_INSTALLED || continue; }
               printf "  %sWordlist path: %s" "${HOT}" "${RST}"; read -r WLP
               [ -z "$WLP" ] && { printf "  %s[!] No path entered.%s\n" "${RED}" "${RST}"; sleep 1; continue; }
               run_web_tool "gobuster dir -u TARGET_PLACEHOLDER -w $WLP" "Directory Hunter · Custom Dir Wordlist" "yes" "gobuster dir custom" ;;
            5) ! $DIRECTORY_HUNTER_INSTALLED && { install_directory_hunter; $DIRECTORY_HUNTER_INSTALLED || continue; }
               printf "  %sWordlist path: %s" "${HOT}" "${RST}"; read -r WLP
               [ -z "$WLP" ] && { printf "  %s[!] No path entered.%s\n" "${RED}" "${RST}"; sleep 1; continue; }
               run_web_tool "gobuster dns -d TARGET_PLACEHOLDER -w $WLP" "Directory Hunter · Custom Subdomain Wordlist" "yes" "gobuster dns custom" ;;
            6) ! $DIRECTORY_HUNTER_INSTALLED && { install_directory_hunter; $DIRECTORY_HUNTER_INSTALLED || continue; }
               run_web_tool "gobuster vhost -u TARGET_PLACEHOLDER -w $WL" "Directory Hunter · Vhost Brute" "yes" "gobuster vhost -u <target>" ;;
            7) run_web_tool "{ echo '=== ROBOTS.TXT ==='; curl -sL --max-time 10 TARGET_PLACEHOLDER/robots.txt; echo ''; echo '=== SITEMAP.XML ==='; curl -sL --max-time 10 TARGET_PLACEHOLDER/sitemap.xml; echo ''; echo '=== SITEMAP_INDEX ==='; curl -sL --max-time 10 TARGET_PLACEHOLDER/sitemap_index.xml; }" \
                   "Directory Hunter · Robots + Sitemap Harvest" "yes" "curl robots.txt + sitemap <target>" ;;
            8) run_web_tool "{ for ext in .bak .old .zip .sql .tar.gz .log .swp .orig .backup; do URL=\"TARGET_PLACEHOLDER/index\$ext\"; CODE=\$(curl -o /dev/null -s -w '%{http_code}' --max-time 8 \"\$URL\"); [ \"\$CODE\" != '404' ] && echo \"[\$CODE] \$URL\" || true; done; }" \
                   "Directory Hunter · Backup File Hunt" "yes" "curl backup file hunt <target>" ;;
            9) ! $DIRECTORY_HUNTER_INSTALLED && { install_directory_hunter; $DIRECTORY_HUNTER_INSTALLED || continue; }
               run_web_tool "{ echo '=== DIRECTORIES ==='; gobuster dir -u TARGET_PLACEHOLDER -w $WL -q 2>/dev/null; echo ''; echo '=== EXTENSIONS ==='; gobuster dir -u TARGET_PLACEHOLDER -w $WL -x php,html,asp,aspx -q 2>/dev/null; echo ''; echo '=== ROBOTS.TXT ==='; curl -sL --max-time 10 TARGET_PLACEHOLDER/robots.txt; echo ''; echo '=== SITEMAP ==='; curl -sL --max-time 10 TARGET_PLACEHOLDER/sitemap.xml | head -30; }" \
                   "Directory Hunter · Full Auto Dir Recon" "yes" "dir+ext+robots+sitemap <target>" ;;
            i|I) install_directory_hunter ;;
            b|B) return ;;
            *) printf "  %s[!] Invalid.%s\n" "${RED}" "${RST}"; sleep 1 ;;
        esac
    done
}

submenu_web_crawler() {
    while true; do
        clear; banner; echo ""
        center_in_box "WEB CRAWLER · SUBMENU"
        short_pink_line 28; echo ""
        printf "${PNK}╔══════════════════════════════════════════════════════════════╗${RST}\n"
        printf "${PNK}║${RST} ${CYN}SYNOPSIS:${RST} Crawl target — extract URLs, emails, JS files, forms,   ${RST}\n"
        printf "${PNK}║${RST}          comments, links. Paste URL → auto full crawl extract.  ${RST}\n"
        printf "${PNK}║${RST} ${CYN}USE:${RST} Enter full URL (e.g. https://example.com) when prompted.   ${RST}\n"
        printf "${PNK}╚══════════════════════════════════════════════════════════════╝${RST}\n\n"
        printf "  ${GRN}[1]${RST}  Basic Crawl (depth 1)      ${DESC}- photon -l 1 standard crawl${RST}\n"
        printf "  ${GRN}[2]${RST}  Deep Crawl (depth 3)       ${DESC}- photon -l 3 deep crawl${RST}\n"
        printf "  ${GRN}[3]${RST}  Extract Emails Only        ${DESC}- photon -e email harvest${RST}\n"
        printf "  ${GRN}[4]${RST}  Export to JSON             ${DESC}- photon -j JSON output${RST}\n"
        printf "  ${GRN}[5]${RST}  Crawl with Custom Depth    ${DESC}- photon -l N enter depth${RST}\n"
        printf "  ${GRN}[6]${RST}  Extract All Links          ${DESC}- curl + grep all href/src links${RST}\n"
        printf "  ${GRN}[7]${RST}  Find Forms / Input Fields  ${DESC}- curl + grep form/input tags${RST}\n"
        printf "  ${GRN}[8]${RST}  Find JS Files              ${DESC}- curl + grep .js file references${RST}\n"
        printf "  ${GRN}[9]${RST}  Extract HTML Comments      ${DESC}- curl + grep <!-- comments${RST}\n"
        printf "  ${GRN}[10]${RST} Full Auto Crawl Extract    ${DESC}- paste URL → links+forms+JS+email${RST}\n"
        printf "  ${GRN}[I]${RST}  Install Module             ${DESC}- install photon${RST}\n"
        printf "  ${YLW}[B]${RST}  Back\n\n"
        printf "  %sChoose: %s" "${HOT}" "${RST}"; read -r SC
        case "$SC" in
            1) ! $WEB_CRAWLER_INSTALLED && { install_web_crawler; $WEB_CRAWLER_INSTALLED || continue; }
               run_web_tool "photon -u TARGET_PLACEHOLDER -l 1" "Web Crawler · Basic" "yes" "photon -u <target> -l 1" ;;
            2) ! $WEB_CRAWLER_INSTALLED && { install_web_crawler; $WEB_CRAWLER_INSTALLED || continue; }
               run_web_tool "photon -u TARGET_PLACEHOLDER -l 3" "Web Crawler · Deep" "yes" "photon -u <target> -l 3" ;;
            3) ! $WEB_CRAWLER_INSTALLED && { install_web_crawler; $WEB_CRAWLER_INSTALLED || continue; }
               run_web_tool "photon -u TARGET_PLACEHOLDER -e" "Web Crawler · Emails" "yes" "photon -u <target> -e" ;;
            4) ! $WEB_CRAWLER_INSTALLED && { install_web_crawler; $WEB_CRAWLER_INSTALLED || continue; }
               run_web_tool "photon -u TARGET_PLACEHOLDER -j" "Web Crawler · JSON Export" "yes" "photon -u <target> -j" ;;
            5) ! $WEB_CRAWLER_INSTALLED && { install_web_crawler; $WEB_CRAWLER_INSTALLED || continue; }
               printf "  %sEnter crawl depth: %s" "${HOT}" "${RST}"; read -r CD
               [ -z "$CD" ] && CD=2
               run_web_tool "photon -u TARGET_PLACEHOLDER -l $CD" "Web Crawler · Custom Depth" "yes" "photon -u <target> -l $CD" ;;
            6) run_web_tool "curl -sL --max-time 15 TARGET_PLACEHOLDER | grep -Eo '(href|src)=\"[^\"]+\"' | sed 's/(href|src)=//g' | tr -d '\"' | sort -u" \
                   "Web Crawler · All Links" "yes" "curl + grep href/src <target>" ;;
            7) run_web_tool "curl -sL --max-time 15 TARGET_PLACEHOLDER | grep -Ei '<form|<input|<textarea|<select' | sed 's/>/>\n/g'" \
                   "Web Crawler · Forms + Inputs" "yes" "curl + grep form/input <target>" ;;
            8) run_web_tool "curl -sL --max-time 15 TARGET_PLACEHOLDER | grep -Eo 'src=\"[^\"]+\.js[^\"]*\"' | sort -u" \
                   "Web Crawler · JS Files" "yes" "curl + grep .js refs <target>" ;;
            9) run_web_tool "curl -sL --max-time 15 TARGET_PLACEHOLDER | grep -Eo '<!--.*?-->' | head -40" \
                   "Web Crawler · HTML Comments" "yes" "curl + grep <!-- comments <target>" ;;
            10) ! $WEB_CRAWLER_INSTALLED && { install_web_crawler; $WEB_CRAWLER_INSTALLED || continue; }
                run_web_tool "{ echo '=== ALL LINKS ==='; curl -sL --max-time 15 TARGET_PLACEHOLDER | grep -Eo '(href|src)=\"[^\"]+\"' | tr -d '\"' | sort -u; echo ''; echo '=== FORMS/INPUTS ==='; curl -sL --max-time 15 TARGET_PLACEHOLDER | grep -Ei '<form|<input' | head -20; echo ''; echo '=== JS FILES ==='; curl -sL --max-time 15 TARGET_PLACEHOLDER | grep -Eo 'src=\"[^\"]+\.js[^\"]*\"' | sort -u; echo ''; echo '=== EMAILS (photon) ==='; photon -u TARGET_PLACEHOLDER -l 2 -e 2>/dev/null; echo ''; echo '=== HTML COMMENTS ==='; curl -sL --max-time 15 TARGET_PLACEHOLDER | grep -Eo '<!--.*?-->' | head -20; }" \
                    "Web Crawler · Full Auto Extract" "yes" "links+forms+JS+email+comments <target>" ;;
            i|I) install_web_crawler ;;
            b|B) return ;;
            *) printf "  %s[!] Invalid.%s\n" "${RED}" "${RST}"; sleep 1 ;;
        esac
    done
}

submenu_fuzzing_engine() {
    while true; do
        clear; banner; echo ""
        center_in_box "FUZZING ENGINE · SUBMENU"
        short_pink_line 32; echo ""
        printf "${PNK}╔══════════════════════════════════════════════════════════════╗${RST}\n"
        printf "${PNK}║${RST} ${CYN}SYNOPSIS:${RST} Fuzz endpoints, params, headers, cookies, paths —       ${RST}\n"
        printf "${PNK}║${RST}          uncover injection points & hidden bugs. Paste URL → run.${RST}\n"
        printf "${PNK}║${RST} ${CYN}USE:${RST} Enter full URL (e.g. https://example.com/page) when prompted.${RST}\n"
        printf "${PNK}╚══════════════════════════════════════════════════════════════╝${RST}\n\n"
        printf "  ${GRN}[1]${RST}  Basic Fuzzing               ${DESC}- wfuzz path FUZZ default WL${RST}\n"
        printf "  ${GRN}[2]${RST}  Parameter Fuzzing           ${DESC}- wfuzz ?FUZZ=1 param discovery${RST}\n"
        printf "  ${GRN}[3]${RST}  POST Request Fuzzing        ${DESC}- wfuzz -d POST body fuzzing${RST}\n"
        printf "  ${GRN}[4]${RST}  Basic Fuzzing (Custom WL)   ${DESC}- wfuzz path custom wordlist${RST}\n"
        printf "  ${GRN}[5]${RST}  Parameter Fuzzing (Custom)  ${DESC}- wfuzz param custom wordlist${RST}\n"
        printf "  ${GRN}[6]${RST}  POST Fuzzing (Custom WL)    ${DESC}- wfuzz POST custom wordlist${RST}\n"
        printf "  ${GRN}[7]${RST}  Header Injection Fuzz       ${DESC}- wfuzz -H header payload inject${RST}\n"
        printf "  ${GRN}[8]${RST}  Cookie Fuzzing              ${DESC}- wfuzz -b cookie value fuzzing${RST}\n"
        printf "  ${GRN}[9]${RST}  Path Traversal Auto Patterns ${DESC}- curl test ../../../etc/passwd${RST}\n"
        printf "  ${GRN}[10]${RST} Full Auto Fuzz Recon        ${DESC}- paste URL → path+param+header${RST}\n"
        printf "  ${GRN}[I]${RST}  Install Module              ${DESC}- install wfuzz${RST}\n"
        printf "  ${YLW}[B]${RST}  Back\n\n"
        printf "  %sChoose: %s" "${HOT}" "${RST}"; read -r SC
        local WL="/usr/share/wordlists/wfuzz/general/common.txt"
        case "$SC" in
            1) ! $FUZZING_ENGINE_INSTALLED && { install_fuzzing_engine; $FUZZING_ENGINE_INSTALLED || continue; }
               run_web_tool "wfuzz -c -z file,$WL TARGET_PLACEHOLDER/FUZZ" "Fuzzing Engine · Basic" "yes" "wfuzz basic" ;;
            2) ! $FUZZING_ENGINE_INSTALLED && { install_fuzzing_engine; $FUZZING_ENGINE_INSTALLED || continue; }
               run_web_tool "wfuzz -c -z file,$WL \"TARGET_PLACEHOLDER?FUZZ=1\"" "Fuzzing Engine · Parameters" "yes" "wfuzz params" ;;
            3) ! $FUZZING_ENGINE_INSTALLED && { install_fuzzing_engine; $FUZZING_ENGINE_INSTALLED || continue; }
               run_web_tool "wfuzz -c -z file,$WL -d \"FUZZ=1\" TARGET_PLACEHOLDER" "Fuzzing Engine · POST" "yes" "wfuzz POST" ;;
            4) ! $FUZZING_ENGINE_INSTALLED && { install_fuzzing_engine; $FUZZING_ENGINE_INSTALLED || continue; }
               printf "  %sWordlist path: %s" "${HOT}" "${RST}"; read -r WLP
               [ -z "$WLP" ] && { printf "  %s[!] No path.%s\n" "${RED}" "${RST}"; sleep 1; continue; }
               run_web_tool "wfuzz -c -z file,$WLP TARGET_PLACEHOLDER/FUZZ" "Fuzzing Engine · Custom Basic" "yes" "wfuzz custom basic" ;;
            5) ! $FUZZING_ENGINE_INSTALLED && { install_fuzzing_engine; $FUZZING_ENGINE_INSTALLED || continue; }
               printf "  %sWordlist path: %s" "${HOT}" "${RST}"; read -r WLP
               [ -z "$WLP" ] && { printf "  %s[!] No path.%s\n" "${RED}" "${RST}"; sleep 1; continue; }
               run_web_tool "wfuzz -c -z file,$WLP \"TARGET_PLACEHOLDER?FUZZ=1\"" "Fuzzing Engine · Custom Parameters" "yes" "wfuzz custom params" ;;
            6) ! $FUZZING_ENGINE_INSTALLED && { install_fuzzing_engine; $FUZZING_ENGINE_INSTALLED || continue; }
               printf "  %sWordlist path: %s" "${HOT}" "${RST}"; read -r WLP
               [ -z "$WLP" ] && { printf "  %s[!] No path.%s\n" "${RED}" "${RST}"; sleep 1; continue; }
               run_web_tool "wfuzz -c -z file,$WLP -d \"FUZZ=1\" TARGET_PLACEHOLDER" "Fuzzing Engine · Custom POST" "yes" "wfuzz custom POST" ;;
            7) ! $FUZZING_ENGINE_INSTALLED && { install_fuzzing_engine; $FUZZING_ENGINE_INSTALLED || continue; }
               printf "  %sEnter header name (e.g. X-Forwarded-For): %s" "${HOT}" "${RST}"; read -r HDR
               [ -z "$HDR" ] && HDR="X-Forwarded-For"
               run_web_tool "wfuzz -c -z file,$WL -H \"$HDR: FUZZ\" TARGET_PLACEHOLDER" \
                   "Fuzzing Engine · Header Injection" "yes" "wfuzz -H $HDR: FUZZ <target>" ;;
            8) ! $FUZZING_ENGINE_INSTALLED && { install_fuzzing_engine; $FUZZING_ENGINE_INSTALLED || continue; }
               printf "  %sEnter cookie name (e.g. session): %s" "${HOT}" "${RST}"; read -r CKN
               [ -z "$CKN" ] && CKN="session"
               run_web_tool "wfuzz -c -z file,$WL -b \"$CKN=FUZZ\" TARGET_PLACEHOLDER" \
                   "Fuzzing Engine · Cookie Fuzzing" "yes" "wfuzz -b $CKN=FUZZ <target>" ;;
            9) run_web_tool "{ for PAY in '../etc/passwd' '../../etc/passwd' '../../../etc/passwd' '../../../../etc/passwd' '../../../../../etc/passwd' '..%2Fetc%2Fpasswd' '%2e%2e%2fetc%2fpasswd'; do CODE=\$(curl -o /dev/null -s -w '%{http_code}' --max-time 8 \"TARGET_PLACEHOLDER/\$PAY\"); BODY=\$(curl -sL --max-time 8 \"TARGET_PLACEHOLDER/\$PAY\" | head -3); echo \"[\$CODE] \$PAY → \$BODY\"; done; }" \
                   "Fuzzing Engine · Path Traversal Patterns" "yes" "curl path traversal auto test <target>" ;;
            10) ! $FUZZING_ENGINE_INSTALLED && { install_fuzzing_engine; $FUZZING_ENGINE_INSTALLED || continue; }
                run_web_tool "{ echo '=== PATH FUZZ ==='; wfuzz -c -z file,$WL TARGET_PLACEHOLDER/FUZZ 2>/dev/null | head -30; echo ''; echo '=== PARAM FUZZ ==='; wfuzz -c -z file,$WL \"TARGET_PLACEHOLDER?FUZZ=1\" 2>/dev/null | head -30; echo ''; echo '=== HEADER INJECT ==='; wfuzz -c -z file,$WL -H 'X-Forwarded-For: FUZZ' TARGET_PLACEHOLDER 2>/dev/null | head -20; echo ''; echo '=== PATH TRAVERSAL ==='; for PAY in '../etc/passwd' '../../etc/passwd' '../../../etc/passwd'; do CODE=\$(curl -o /dev/null -s -w '%{http_code}' --max-time 6 \"TARGET_PLACEHOLDER/\$PAY\"); echo \"[\$CODE] \$PAY\"; done; }" \
                    "Fuzzing Engine · Full Auto Fuzz Recon" "yes" "path+param+header+traversal <target>" ;;
            i|I) install_fuzzing_engine ;;
            b|B) return ;;
            *) printf "  %s[!] Invalid.%s\n" "${RED}" "${RST}"; sleep 1 ;;
        esac
    done
}
submenu_netcat() {
    while true; do
        clear; banner; echo ""
        center_in_box "NETCAT · SUBMENU"
        short_pink_line 20; echo ""
        printf "${PNK}╔══════════════════════════════════════════════════════════════╗${RST}\n"
        printf "${PNK}║${RST} ${CYN}SYNOPSIS:${RST} Raw TCP/UDP probe — grab service banners, test ports,    ${RST}\n"
        printf "${PNK}║${RST}          scan open states, chain into recon pipelines.         ${RST}\n"
        printf "${PNK}║${RST} ${CYN}USE:${RST} Enter target IP or domain + port when prompted.           ${RST}\n"
        printf "${PNK}╚══════════════════════════════════════════════════════════════╝${RST}\n\n"
        printf "  ${GRN}[1]${RST}  Banner Grab               ${DESC}- nc -v host port (read banner)${RST}\n"
        printf "  ${GRN}[2]${RST}  Port Test (TCP)           ${DESC}- nc -zv host port${RST}\n"
        printf "  ${GRN}[3]${RST}  Port Range Test           ${DESC}- nc -zv host startport-endport${RST}\n"
        printf "  ${GRN}[4]${RST}  HTTP Banner Probe         ${DESC}- nc + HEAD / HTTP/1.0 request${RST}\n"
        printf "  ${GRN}[5]${RST}  SMTP Banner Grab          ${DESC}- nc port 25 / 587 banner${RST}\n"
        printf "  ${GRN}[6]${RST}  FTP Banner Grab           ${DESC}- nc port 21 banner${RST}\n"
        printf "  ${GRN}[7]${RST}  Service Probe (Custom)    ${DESC}- nc with custom port input${RST}\n"
        printf "  ${GRN}[8]${RST}  Full Auto Probe           ${DESC}- banner+tcp test on 22/80/443/3306${RST}\n"
        printf "  ${GRN}[I]${RST}  Install Module            ${DESC}- install ncat/netcat${RST}\n"
        printf "  ${YLW}[B]${RST}  Back\n\n"
        printf "  %sChoose: %s" "${HOT}" "${RST}"; read -r SC
        case "$SC" in
            1) ! $NETCAT_INSTALLED && { install_netcat; $NETCAT_INSTALLED || continue; }
               run_web_tool "{ echo '' | nc -v -w 3 TARGET_PLACEHOLDER 80 2>&1; }" "Netcat · Banner Grab" "yes" "nc -v <host> 80" ;;
            2) ! $NETCAT_INSTALLED && { install_netcat; $NETCAT_INSTALLED || continue; }
               printf "  %sEnter port: %s" "${HOT}" "${RST}"; read -r NCPORT
               [ -z "$NCPORT" ] && NCPORT=80
               run_web_tool "nc -zv TARGET_PLACEHOLDER $NCPORT 2>&1" "Netcat · Port Test TCP" "yes" "nc -zv <host> $NCPORT" ;;
            3) ! $NETCAT_INSTALLED && { install_netcat; $NETCAT_INSTALLED || continue; }
               printf "  %sEnter port range (e.g. 20-100): %s" "${HOT}" "${RST}"; read -r NCRANGE
               [ -z "$NCRANGE" ] && NCRANGE="20-100"
               run_web_tool "nc -zv TARGET_PLACEHOLDER $NCRANGE 2>&1" "Netcat · Port Range Test" "yes" "nc -zv <host> $NCRANGE" ;;
            4) ! $NETCAT_INSTALLED && { install_netcat; $NETCAT_INSTALLED || continue; }
               run_web_tool "{ printf 'HEAD / HTTP/1.0\r\n\r\n' | nc -w 5 TARGET_PLACEHOLDER 80 2>&1; }" "Netcat · HTTP Banner Probe" "yes" "nc HEAD HTTP/1.0 <host>:80" ;;
            5) ! $NETCAT_INSTALLED && { install_netcat; $NETCAT_INSTALLED || continue; }
               run_web_tool "{ echo '' | nc -w 5 TARGET_PLACEHOLDER 25 2>&1; }" "Netcat · SMTP Banner" "yes" "nc <host> 25" ;;
            6) ! $NETCAT_INSTALLED && { install_netcat; $NETCAT_INSTALLED || continue; }
               run_web_tool "{ echo '' | nc -w 5 TARGET_PLACEHOLDER 21 2>&1; }" "Netcat · FTP Banner" "yes" "nc <host> 21" ;;
            7) ! $NETCAT_INSTALLED && { install_netcat; $NETCAT_INSTALLED || continue; }
               printf "  %sEnter port: %s" "${HOT}" "${RST}"; read -r NCPORT
               [ -z "$NCPORT" ] && NCPORT=443
               run_web_tool "{ echo '' | nc -v -w 5 TARGET_PLACEHOLDER $NCPORT 2>&1; }" "Netcat · Service Probe Custom" "yes" "nc -v <host> $NCPORT" ;;
            8) ! $NETCAT_INSTALLED && { install_netcat; $NETCAT_INSTALLED || continue; }
               run_web_tool "{ for P in 22 80 443 3306 8080 8443; do printf '[PORT %s] ' \"\$P\"; nc -zv TARGET_PLACEHOLDER \$P 2>&1 | tail -1; done; echo ''; printf 'HEAD / HTTP/1.0\r\n\r\n' | nc -w 5 TARGET_PLACEHOLDER 80 2>&1 | head -5; }" \
                   "Netcat · Full Auto Probe" "yes" "nc port sweep + HTTP banner <target>" ;;
            i|I) install_netcat ;;
            b|B) return ;;
            *) printf "  %s[!] Invalid.%s\n" "${RED}" "${RST}"; sleep 1 ;;
        esac
    done
}

submenu_jq() {
    while true; do
        clear; banner; echo ""
        center_in_box "JQ PARSER · SUBMENU"
        short_pink_line 24; echo ""
        printf "${PNK}╔══════════════════════════════════════════════════════════════╗${RST}\n"
        printf "${PNK}║${RST} ${CYN}SYNOPSIS:${RST} Parse JSON API responses from recon tools — extract       ${RST}\n"
        printf "${PNK}║${RST}          keys, filter fields, prettify raw JSON output.        ${RST}\n"
        printf "${PNK}║${RST} ${CYN}USE:${RST} Enter a URL that returns JSON, or a local JSON file path.   ${RST}\n"
        printf "${PNK}╚══════════════════════════════════════════════════════════════╝${RST}\n\n"
        printf "  ${GRN}[1]${RST}  Pretty Print JSON URL     ${DESC}- curl URL | jq .${RST}\n"
        printf "  ${GRN}[2]${RST}  List Top-Level Keys       ${DESC}- curl URL | jq keys${RST}\n"
        printf "  ${GRN}[3]${RST}  Extract Single Field      ${DESC}- curl URL | jq .fieldname${RST}\n"
        printf "  ${GRN}[4]${RST}  Compact Output            ${DESC}- curl URL | jq -c .${RST}\n"
        printf "  ${GRN}[5]${RST}  Parse Local JSON File     ${DESC}- jq . file.json${RST}\n"
        printf "  ${GRN}[6]${RST}  Filter Array Items        ${DESC}- curl URL | jq '.[] | .field'${RST}\n"
        printf "  ${GRN}[7]${RST}  Extract Nested Field      ${DESC}- jq custom dot path${RST}\n"
        printf "  ${GRN}[8]${RST}  Full Auto API Parse       ${DESC}- curl URL | jq (keys + pretty + values)${RST}\n"
        printf "  ${GRN}[I]${RST}  Install Module            ${DESC}- install jq${RST}\n"
        printf "  ${YLW}[B]${RST}  Back\n\n"
        printf "  %sChoose: %s" "${HOT}" "${RST}"; read -r SC
        case "$SC" in
            1) ! $JQ_INSTALLED && { install_jq; $JQ_INSTALLED || continue; }
               run_web_tool "curl -s --max-time 15 TARGET_PLACEHOLDER | jq ." "JQ Parser · Pretty Print" "yes" "curl <url> | jq ." ;;
            2) ! $JQ_INSTALLED && { install_jq; $JQ_INSTALLED || continue; }
               run_web_tool "curl -s --max-time 15 TARGET_PLACEHOLDER | jq 'keys'" "JQ Parser · Keys" "yes" "curl <url> | jq keys" ;;
            3) ! $JQ_INSTALLED && { install_jq; $JQ_INSTALLED || continue; }
               printf "  %sEnter field name (e.g. data): %s" "${HOT}" "${RST}"; read -r JQF
               [ -z "$JQF" ] && JQF="data"
               run_web_tool "curl -s --max-time 15 TARGET_PLACEHOLDER | jq '.$JQF'" "JQ Parser · Extract Field" "yes" "curl <url> | jq .$JQF" ;;
            4) ! $JQ_INSTALLED && { install_jq; $JQ_INSTALLED || continue; }
               run_web_tool "curl -s --max-time 15 TARGET_PLACEHOLDER | jq -c ." "JQ Parser · Compact" "yes" "curl <url> | jq -c ." ;;
            5) ! $JQ_INSTALLED && { install_jq; $JQ_INSTALLED || continue; }
               printf "  %sEnter file path: %s" "${HOT}" "${RST}"; read -r JQFILE
               [ -z "$JQFILE" ] && { printf "  %s[!] No file.%s\n" "${RED}" "${RST}"; sleep 1; continue; }
               run_web_tool "jq . '$JQFILE'" "JQ Parser · Local File" "no" "jq . $JQFILE" ;;
            6) ! $JQ_INSTALLED && { install_jq; $JQ_INSTALLED || continue; }
               printf "  %sEnter field to extract from array (e.g. name): %s" "${HOT}" "${RST}"; read -r JQF
               [ -z "$JQF" ] && JQF="name"
               run_web_tool "curl -s --max-time 15 TARGET_PLACEHOLDER | jq '.[] | .$JQF'" "JQ Parser · Array Filter" "yes" "curl <url> | jq .[] | .$JQF" ;;
            7) ! $JQ_INSTALLED && { install_jq; $JQ_INSTALLED || continue; }
               printf "  %sEnter jq path (e.g. .results[0].host): %s" "${HOT}" "${RST}"; read -r JQPATH
               [ -z "$JQPATH" ] && JQPATH=".results[0]"
               run_web_tool "curl -s --max-time 15 TARGET_PLACEHOLDER | jq '$JQPATH'" "JQ Parser · Nested Field" "yes" "curl <url> | jq $JQPATH" ;;
            8) ! $JQ_INSTALLED && { install_jq; $JQ_INSTALLED || continue; }
               run_web_tool "{ RAW=\$(curl -s --max-time 15 TARGET_PLACEHOLDER); echo '=== PRETTY ==='; echo \"\$RAW\" | jq . 2>/dev/null; echo ''; echo '=== KEYS ==='; echo \"\$RAW\" | jq 'keys' 2>/dev/null; echo ''; echo '=== COMPACT ==='; echo \"\$RAW\" | jq -c . 2>/dev/null; }" \
                   "JQ Parser · Full Auto Parse" "yes" "curl + jq pretty+keys+compact <url>" ;;
            i|I) install_jq ;;
            b|B) return ;;
            *) printf "  %s[!] Invalid.%s\n" "${RED}" "${RST}"; sleep 1 ;;
        esac
    done
}

submenu_harvester() {
    while true; do
        clear; banner; echo ""
        center_in_box "theHARVESTER · SUBMENU"
        short_pink_line 28; echo ""
        printf "${PNK}╔══════════════════════════════════════════════════════════════╗${RST}\n"
        printf "${PNK}║${RST} ${CYN}SYNOPSIS:${RST} Passive OSINT — emails, subdomains, IPs from Google,    ${RST}\n"
        printf "${PNK}║${RST}          Bing, DNS records, HackerTarget & more sources.     ${RST}\n"
        printf "${PNK}║${RST} ${CYN}USE:${RST} Enter domain (e.g. example.com) when prompted.             ${RST}\n"
        printf "${PNK}╚══════════════════════════════════════════════════════════════╝${RST}\n\n"
        printf "  ${GRN}[1]${RST}  Google OSINT              ${DESC}- theHarvester -b google${RST}\n"
        printf "  ${GRN}[2]${RST}  Bing OSINT                ${DESC}- theHarvester -b bing${RST}\n"
        printf "  ${GRN}[3]${RST}  DNS Brute Force           ${DESC}- theHarvester -b dnsdumpster${RST}\n"
        printf "  ${GRN}[4]${RST}  HackerTarget Source       ${DESC}- theHarvester -b hackertarget${RST}\n"
        printf "  ${GRN}[5]${RST}  Certspotter / SSL Certs   ${DESC}- theHarvester -b certspotter${RST}\n"
        printf "  ${GRN}[6]${RST}  All Sources               ${DESC}- theHarvester -b all${RST}\n"
        printf "  ${GRN}[7]${RST}  Export XML Report         ${DESC}- theHarvester -b google -f report${RST}\n"
        printf "  ${GRN}[8]${RST}  Full Auto OSINT           ${DESC}- google+bing+hackertarget combined${RST}\n"
        printf "  ${GRN}[I]${RST}  Install Module            ${DESC}- pip install theHarvester${RST}\n"
        printf "  ${YLW}[B]${RST}  Back\n\n"
        printf "  %sChoose: %s" "${HOT}" "${RST}"; read -r SC
        case "$SC" in
            1) ! $HARVESTER_INSTALLED && { install_harvester; $HARVESTER_INSTALLED || continue; }
               run_web_tool "theHarvester -d TARGET_PLACEHOLDER -b google -l 200" "theHarvester · Google" "yes" "theHarvester -d <domain> -b google" ;;
            2) ! $HARVESTER_INSTALLED && { install_harvester; $HARVESTER_INSTALLED || continue; }
               run_web_tool "theHarvester -d TARGET_PLACEHOLDER -b bing -l 200" "theHarvester · Bing" "yes" "theHarvester -d <domain> -b bing" ;;
            3) ! $HARVESTER_INSTALLED && { install_harvester; $HARVESTER_INSTALLED || continue; }
               run_web_tool "theHarvester -d TARGET_PLACEHOLDER -b dnsdumpster" "theHarvester · DNS Dumpster" "yes" "theHarvester -d <domain> -b dnsdumpster" ;;
            4) ! $HARVESTER_INSTALLED && { install_harvester; $HARVESTER_INSTALLED || continue; }
               run_web_tool "theHarvester -d TARGET_PLACEHOLDER -b hackertarget" "theHarvester · HackerTarget" "yes" "theHarvester -d <domain> -b hackertarget" ;;
            5) ! $HARVESTER_INSTALLED && { install_harvester; $HARVESTER_INSTALLED || continue; }
               run_web_tool "theHarvester -d TARGET_PLACEHOLDER -b certspotter" "theHarvester · Certspotter" "yes" "theHarvester -d <domain> -b certspotter" ;;
            6) ! $HARVESTER_INSTALLED && { install_harvester; $HARVESTER_INSTALLED || continue; }
               run_web_tool "theHarvester -d TARGET_PLACEHOLDER -b all -l 300" "theHarvester · All Sources" "yes" "theHarvester -d <domain> -b all" ;;
            7) ! $HARVESTER_INSTALLED && { install_harvester; $HARVESTER_INSTALLED || continue; }
               run_web_tool "theHarvester -d TARGET_PLACEHOLDER -b google -l 200 -f ${HOME}/storage/downloads/harvester_report" "theHarvester · XML Export" "yes" "theHarvester -d <domain> -b google -f report" ;;
            8) ! $HARVESTER_INSTALLED && { install_harvester; $HARVESTER_INSTALLED || continue; }
               run_web_tool "{ echo '=== GOOGLE ==='; theHarvester -d TARGET_PLACEHOLDER -b google -l 100 2>/dev/null; echo ''; echo '=== BING ==='; theHarvester -d TARGET_PLACEHOLDER -b bing -l 100 2>/dev/null; echo ''; echo '=== HACKERTARGET ==='; theHarvester -d TARGET_PLACEHOLDER -b hackertarget 2>/dev/null; echo ''; echo '=== CERTSPOTTER ==='; theHarvester -d TARGET_PLACEHOLDER -b certspotter 2>/dev/null; }" \
                   "theHarvester · Full Auto OSINT" "yes" "google+bing+hackertarget+certspotter <domain>" ;;
            i|I) install_harvester ;;
            b|B) return ;;
            *) printf "  %s[!] Invalid.%s\n" "${RED}" "${RST}"; sleep 1 ;;
        esac
    done
}

submenu_httprobe() {
    while true; do
        clear; banner; echo ""
        center_in_box "HTTPROBE · SUBMENU"
        short_pink_line 24; echo ""
        printf "${PNK}╔══════════════════════════════════════════════════════════════╗${RST}\n"
        printf "${PNK}║${RST} ${CYN}SYNOPSIS:${RST} Confirm which domains in a list are live HTTP/S.         ${RST}\n"
        printf "${PNK}║${RST}          Filters dead domains — outputs active targets only.   ${RST}\n"
        printf "${PNK}║${RST} ${CYN}USE:${RST} Enter domains (one per line from file, or manual input).   ${RST}\n"
        printf "${PNK}╚══════════════════════════════════════════════════════════════╝${RST}\n\n"
        printf "  ${GRN}[1]${RST}  Single Domain Probe       ${DESC}- echo domain | httprobe${RST}\n"
        printf "  ${GRN}[2]${RST}  File Domain List Probe    ${DESC}- cat file | httprobe${RST}\n"
        printf "  ${GRN}[3]${RST}  With Custom Ports         ${DESC}- httprobe -p https:8443,http:8080${RST}\n"
        printf "  ${GRN}[4]${RST}  Concurrency Tuned         ${DESC}- httprobe -c 50 for speed${RST}\n"
        printf "  ${GRN}[5]${RST}  Prefer HTTPS Only         ${DESC}- httprobe -prefer-https${RST}\n"
        printf "  ${GRN}[6]${RST}  Subdomain List from dig   ${DESC}- dig brute + httprobe pipe${RST}\n"
        printf "  ${GRN}[7]${RST}  Save Live to File         ${DESC}- httprobe → live_hosts.txt${RST}\n"
        printf "  ${GRN}[8]${RST}  Full Auto Live Filter     ${DESC}- domain list + probe + save${RST}\n"
        printf "  ${GRN}[I]${RST}  Install Module            ${DESC}- go install httprobe${RST}\n"
        printf "  ${YLW}[B]${RST}  Back\n\n"
        printf "  %sChoose: %s" "${HOT}" "${RST}"; read -r SC
        local HTTPROBECMD="$HOME/go/bin/httprobe"
        command -v httprobe >/dev/null 2>&1 && HTTPROBECMD="httprobe"
        case "$SC" in
            1) ! $HTTPROBE_INSTALLED && { install_httprobe; $HTTPROBE_INSTALLED || continue; }
               printf "  %sEnter domain: %s" "${HOT}" "${RST}"; read -r HPDOMAIN
               [ -z "$HPDOMAIN" ] && { printf "  %s[!] No domain.%s\n" "${RED}" "${RST}"; sleep 1; continue; }
               run_web_tool "echo '$HPDOMAIN' | $HTTPROBECMD" "Httprobe · Single Domain" "no" "echo $HPDOMAIN | httprobe" ;;
            2) ! $HTTPROBE_INSTALLED && { install_httprobe; $HTTPROBE_INSTALLED || continue; }
               printf "  %sEnter file path: %s" "${HOT}" "${RST}"; read -r HPFILE
               [ -z "$HPFILE" ] && { printf "  %s[!] No file.%s\n" "${RED}" "${RST}"; sleep 1; continue; }
               run_web_tool "cat '$HPFILE' | $HTTPROBECMD" "Httprobe · File List" "no" "cat $HPFILE | httprobe" ;;
            3) ! $HTTPROBE_INSTALLED && { install_httprobe; $HTTPROBE_INSTALLED || continue; }
               printf "  %sEnter domain: %s" "${HOT}" "${RST}"; read -r HPDOMAIN
               run_web_tool "echo '$HPDOMAIN' | $HTTPROBECMD -p https:8443 -p http:8080" "Httprobe · Custom Ports" "no" "httprobe -p https:8443 -p http:8080" ;;
            4) ! $HTTPROBE_INSTALLED && { install_httprobe; $HTTPROBE_INSTALLED || continue; }
               printf "  %sEnter domain or file path: %s" "${HOT}" "${RST}"; read -r HPINPUT
               run_web_tool "{ [ -f '$HPINPUT' ] && cat '$HPINPUT' || echo '$HPINPUT'; } | $HTTPROBECMD -c 50" "Httprobe · Concurrency 50" "no" "httprobe -c 50" ;;
            5) ! $HTTPROBE_INSTALLED && { install_httprobe; $HTTPROBE_INSTALLED || continue; }
               printf "  %sEnter domain: %s" "${HOT}" "${RST}"; read -r HPDOMAIN
               run_web_tool "echo '$HPDOMAIN' | $HTTPROBECMD -prefer-https" "Httprobe · HTTPS Prefer" "no" "httprobe -prefer-https" ;;
            6) ! $HTTPROBE_INSTALLED && { install_httprobe; $HTTPROBE_INSTALLED || continue; }
               printf "  %sEnter domain for dig brute: %s" "${HOT}" "${RST}"; read -r HPDOMAIN
               run_web_tool "for sub in www mail api dev test admin; do echo \"\${sub}.${HPDOMAIN}\"; done | $HTTPROBECMD" "Httprobe · Subdomain Brute + Probe" "no" "dig brute | httprobe $HPDOMAIN" ;;
            7) ! $HTTPROBE_INSTALLED && { install_httprobe; $HTTPROBE_INSTALLED || continue; }
               printf "  %sEnter domain or file path: %s" "${HOT}" "${RST}"; read -r HPINPUT
               run_web_tool "{ [ -f '$HPINPUT' ] && cat '$HPINPUT' || echo '$HPINPUT'; } | $HTTPROBECMD | tee ${HOME}/storage/downloads/httprobe_live.txt" "Httprobe · Save Live" "no" "httprobe → live_hosts.txt" ;;
            8) ! $HTTPROBE_INSTALLED && { install_httprobe; $HTTPROBE_INSTALLED || continue; }
               printf "  %sEnter domain: %s" "${HOT}" "${RST}"; read -r HPDOMAIN
               run_web_tool "{ echo '=== PROBING HTTP/S ==='; echo '$HPDOMAIN' | $HTTPROBECMD -c 30 | tee ${HOME}/storage/downloads/httprobe_live.txt; echo ''; echo '=== SAVED TO ==='; echo '${HOME}/storage/downloads/httprobe_live.txt'; }" "Httprobe · Full Auto" "no" "httprobe full auto $HPDOMAIN" ;;
            i|I) install_httprobe ;;
            b|B) return ;;
            *) printf "  %s[!] Invalid.%s\n" "${RED}" "${RST}"; sleep 1 ;;
        esac
    done
}

submenu_sqlmap() {
    while true; do
        clear; banner; echo ""
        center_in_box "SQLMAP · SUBMENU"
        short_pink_line 24; echo ""
        printf "${PNK}╔══════════════════════════════════════════════════════════════╗${RST}\n"
        printf "${PNK}║${RST} ${CYN}SYNOPSIS:${RST} SQL injection detection — GET/POST, blind, union,         ${RST}\n"
        printf "${PNK}║${RST}          error-based, time-based. Fills the gap nikto misses.  ${RST}\n"
        printf "${PNK}║${RST} ${CYN}USE:${RST} Enter full URL with parameter (e.g. http://site/?id=1).     ${RST}\n"
        printf "${PNK}╚══════════════════════════════════════════════════════════════╝${RST}\n\n"
        printf "  ${GRN}[1]${RST}  Quick Detection           ${DESC}- sqlmap -u URL --batch${RST}\n"
        printf "  ${GRN}[2]${RST}  Full GET Scan             ${DESC}- sqlmap -u URL --dbs --batch${RST}\n"
        printf "  ${GRN}[3]${RST}  POST Request Scan         ${DESC}- sqlmap -u URL --data params${RST}\n"
        printf "  ${GRN}[4]${RST}  Enumerate Databases       ${DESC}- sqlmap --dbs${RST}\n"
        printf "  ${GRN}[5]${RST}  Enumerate Tables          ${DESC}- sqlmap -D dbname --tables${RST}\n"
        printf "  ${GRN}[6]${RST}  Dump Table Data           ${DESC}- sqlmap -D db -T table --dump${RST}\n"
        printf "  ${GRN}[7]${RST}  Blind Injection Test      ${DESC}- sqlmap --technique=B${RST}\n"
        printf "  ${GRN}[8]${RST}  Full Auto SQLi Recon      ${DESC}- URL → dbs+tables+detection${RST}\n"
        printf "  ${GRN}[I]${RST}  Install Module            ${DESC}- pip install sqlmap${RST}\n"
        printf "  ${YLW}[B]${RST}  Back\n\n"
        printf "  %sChoose: %s" "${HOT}" "${RST}"; read -r SC
        case "$SC" in
            1) ! $SQLMAP_INSTALLED && { install_sqlmap; $SQLMAP_INSTALLED || continue; }
               run_web_tool "sqlmap -u TARGET_PLACEHOLDER --batch --level=1 --risk=1" "SQLMap · Quick Detection" "yes" "sqlmap -u <url> --batch" ;;
            2) ! $SQLMAP_INSTALLED && { install_sqlmap; $SQLMAP_INSTALLED || continue; }
               run_web_tool "sqlmap -u TARGET_PLACEHOLDER --dbs --batch" "SQLMap · Full GET + DBs" "yes" "sqlmap -u <url> --dbs --batch" ;;
            3) ! $SQLMAP_INSTALLED && { install_sqlmap; $SQLMAP_INSTALLED || continue; }
               printf "  %sEnter POST data (e.g. user=a&pass=b): %s" "${HOT}" "${RST}"; read -r SMPOST
               [ -z "$SMPOST" ] && { printf "  %s[!] No POST data.%s\n" "${RED}" "${RST}"; sleep 1; continue; }
               run_web_tool "sqlmap -u TARGET_PLACEHOLDER --data='$SMPOST' --batch" "SQLMap · POST Scan" "yes" "sqlmap --data <params>" ;;
            4) ! $SQLMAP_INSTALLED && { install_sqlmap; $SQLMAP_INSTALLED || continue; }
               run_web_tool "sqlmap -u TARGET_PLACEHOLDER --dbs --batch" "SQLMap · Enumerate DBs" "yes" "sqlmap --dbs" ;;
            5) ! $SQLMAP_INSTALLED && { install_sqlmap; $SQLMAP_INSTALLED || continue; }
               printf "  %sEnter database name: %s" "${HOT}" "${RST}"; read -r SMDB
               [ -z "$SMDB" ] && { printf "  %s[!] No DB name.%s\n" "${RED}" "${RST}"; sleep 1; continue; }
               run_web_tool "sqlmap -u TARGET_PLACEHOLDER -D '$SMDB' --tables --batch" "SQLMap · Tables" "yes" "sqlmap -D $SMDB --tables" ;;
            6) ! $SQLMAP_INSTALLED && { install_sqlmap; $SQLMAP_INSTALLED || continue; }
               printf "  %sEnter DB name: %s" "${HOT}" "${RST}"; read -r SMDB
               printf "  %sEnter table name: %s" "${HOT}" "${RST}"; read -r SMTBL
               [ -z "$SMDB" ] || [ -z "$SMTBL" ] && { printf "  %s[!] Missing input.%s\n" "${RED}" "${RST}"; sleep 1; continue; }
               run_web_tool "sqlmap -u TARGET_PLACEHOLDER -D '$SMDB' -T '$SMTBL' --dump --batch" "SQLMap · Dump Table" "yes" "sqlmap --dump $SMDB.$SMTBL" ;;
            7) ! $SQLMAP_INSTALLED && { install_sqlmap; $SQLMAP_INSTALLED || continue; }
               run_web_tool "sqlmap -u TARGET_PLACEHOLDER --technique=B --batch" "SQLMap · Blind Injection" "yes" "sqlmap --technique=B" ;;
            8) ! $SQLMAP_INSTALLED && { install_sqlmap; $SQLMAP_INSTALLED || continue; }
               run_web_tool "{ echo '=== DETECTION ==='; sqlmap -u TARGET_PLACEHOLDER --batch --level=2 2>/dev/null; echo ''; echo '=== DATABASES ==='; sqlmap -u TARGET_PLACEHOLDER --dbs --batch 2>/dev/null | grep -E '^\[\*\]|^\[INFO\]|available databases'; }" \
                   "SQLMap · Full Auto SQLi Recon" "yes" "sqlmap detect + dbs <url>" ;;
            i|I) install_sqlmap ;;
            b|B) return ;;
            *) printf "  %s[!] Invalid.%s\n" "${RED}" "${RST}"; sleep 1 ;;
        esac
    done
}

submenu_wafw00f() {
    while true; do
        clear; banner; echo ""
        center_in_box "WAFW00F · SUBMENU"
        short_pink_line 24; echo ""
        printf "${PNK}╔══════════════════════════════════════════════════════════════╗${RST}\n"
        printf "${PNK}║${RST} ${CYN}SYNOPSIS:${RST} Dedicated WAF identification — more accurate than nmap    ${RST}\n"
        printf "${PNK}║${RST}          http-waf-detect. Names the WAF vendor & product.     ${RST}\n"
        printf "${PNK}║${RST} ${CYN}USE:${RST} Enter full URL (e.g. https://example.com) when prompted.   ${RST}\n"
        printf "${PNK}╚══════════════════════════════════════════════════════════════╝${RST}\n\n"
        printf "  ${GRN}[1]${RST}  Basic WAF Detection       ${DESC}- wafw00f URL${RST}\n"
        printf "  ${GRN}[2]${RST}  Verbose Detection         ${DESC}- wafw00f -v URL${RST}\n"
        printf "  ${GRN}[3]${RST}  Test All WAFs             ${DESC}- wafw00f -a URL (all signatures)${RST}\n"
        printf "  ${GRN}[4]${RST}  List Supported WAFs       ${DESC}- wafw00f -l (no target needed)${RST}\n"
        printf "  ${GRN}[5]${RST}  JSON Output               ${DESC}- wafw00f -o json URL${RST}\n"
        printf "  ${GRN}[6]${RST}  Multiple Targets          ${DESC}- wafw00f from file list${RST}\n"
        printf "  ${GRN}[7]${RST}  Proxy Through Proxy       ${DESC}- wafw00f --proxy http://proxy:port${RST}\n"
        printf "  ${GRN}[8]${RST}  Full Auto WAF Recon       ${DESC}- basic + verbose + all sigs${RST}\n"
        printf "  ${GRN}[I]${RST}  Install Module            ${DESC}- pip install wafw00f${RST}\n"
        printf "  ${YLW}[B]${RST}  Back\n\n"
        printf "  %sChoose: %s" "${HOT}" "${RST}"; read -r SC
        case "$SC" in
            1) ! $WAFW00F_INSTALLED && { install_wafw00f; $WAFW00F_INSTALLED || continue; }
               run_web_tool "wafw00f TARGET_PLACEHOLDER" "WAF Detect · Basic" "yes" "wafw00f <url>" ;;
            2) ! $WAFW00F_INSTALLED && { install_wafw00f; $WAFW00F_INSTALLED || continue; }
               run_web_tool "wafw00f -v TARGET_PLACEHOLDER" "WAF Detect · Verbose" "yes" "wafw00f -v <url>" ;;
            3) ! $WAFW00F_INSTALLED && { install_wafw00f; $WAFW00F_INSTALLED || continue; }
               run_web_tool "wafw00f -a TARGET_PLACEHOLDER" "WAF Detect · All Signatures" "yes" "wafw00f -a <url>" ;;
            4) ! $WAFW00F_INSTALLED && { install_wafw00f; $WAFW00F_INSTALLED || continue; }
               run_web_tool "wafw00f -l" "WAF Detect · List Supported" "no" "wafw00f -l" ;;
            5) ! $WAFW00F_INSTALLED && { install_wafw00f; $WAFW00F_INSTALLED || continue; }
               run_web_tool "wafw00f -o json TARGET_PLACEHOLDER" "WAF Detect · JSON Output" "yes" "wafw00f -o json <url>" ;;
            6) ! $WAFW00F_INSTALLED && { install_wafw00f; $WAFW00F_INSTALLED || continue; }
               printf "  %sEnter file path with URLs: %s" "${HOT}" "${RST}"; read -r WAFFILE
               [ -z "$WAFFILE" ] && { printf "  %s[!] No file.%s\n" "${RED}" "${RST}"; sleep 1; continue; }
               run_web_tool "wafw00f -i '$WAFFILE'" "WAF Detect · Multi Target" "no" "wafw00f -i $WAFFILE" ;;
            7) ! $WAFW00F_INSTALLED && { install_wafw00f; $WAFW00F_INSTALLED || continue; }
               printf "  %sEnter proxy (e.g. http://127.0.0.1:8080): %s" "${HOT}" "${RST}"; read -r WAFPROXY
               [ -z "$WAFPROXY" ] && WAFPROXY="http://127.0.0.1:8080"
               run_web_tool "wafw00f --proxy '$WAFPROXY' TARGET_PLACEHOLDER" "WAF Detect · Through Proxy" "yes" "wafw00f --proxy $WAFPROXY <url>" ;;
            8) ! $WAFW00F_INSTALLED && { install_wafw00f; $WAFW00F_INSTALLED || continue; }
               run_web_tool "{ echo '=== BASIC ==='; wafw00f TARGET_PLACEHOLDER 2>/dev/null; echo ''; echo '=== VERBOSE ==='; wafw00f -v TARGET_PLACEHOLDER 2>/dev/null; echo ''; echo '=== ALL SIGNATURES ==='; wafw00f -a TARGET_PLACEHOLDER 2>/dev/null; }" \
                   "WAF Detect · Full Auto Recon" "yes" "basic+verbose+all sigs <url>" ;;
            i|I) install_wafw00f ;;
            b|B) return ;;
            *) printf "  %s[!] Invalid.%s\n" "${RED}" "${RST}"; sleep 1 ;;
        esac
    done
}

submenu_ffuf() {
    while true; do
        clear; banner; echo ""
        center_in_box "FFUF · SUBMENU"
        short_pink_line 20; echo ""
        printf "${PNK}╔══════════════════════════════════════════════════════════════╗${RST}\n"
        printf "${PNK}║${RST} ${CYN}SYNOPSIS:${RST} Fast web fuzzer — dir, param, vhost, header. Better      ${RST}\n"
        printf "${PNK}║${RST}          filter control than wfuzz. FUZZ keyword placement.   ${RST}\n"
        printf "${PNK}║${RST} ${CYN}USE:${RST} Enter full URL (include FUZZ keyword) when prompted.        ${RST}\n"
        printf "${PNK}╚══════════════════════════════════════════════════════════════╝${RST}\n\n"
        printf "  ${GRN}[1]${RST}  Directory Fuzz            ${DESC}- ffuf -u URL/FUZZ -w wordlist${RST}\n"
        printf "  ${GRN}[2]${RST}  Parameter Fuzz (GET)      ${DESC}- ffuf -u URL?FUZZ=val -w wordlist${RST}\n"
        printf "  ${GRN}[3]${RST}  POST Body Fuzz            ${DESC}- ffuf -d FUZZ=1 -X POST${RST}\n"
        printf "  ${GRN}[4]${RST}  Vhost Fuzz                ${DESC}- ffuf -H Host:FUZZ -w wordlist${RST}\n"
        printf "  ${GRN}[5]${RST}  Filter by Status Code     ${DESC}- ffuf -fc 404 (exclude code)${RST}\n"
        printf "  ${GRN}[6]${RST}  Filter by Response Size   ${DESC}- ffuf -fs SIZE${RST}\n"
        printf "  ${GRN}[7]${RST}  Recursive Dir Fuzz        ${DESC}- ffuf -recursion depth 2${RST}\n"
        printf "  ${GRN}[8]${RST}  Custom Wordlist Fuzz      ${DESC}- ffuf dir with custom WL path${RST}\n"
        printf "  ${GRN}[9]${RST}  Extension Fuzz            ${DESC}- ffuf dir with -e .php,.html,.asp${RST}\n"
        printf "  ${GRN}[10]${RST} Full Auto Fuzz Recon      ${DESC}- dir+param+ext combined${RST}\n"
        printf "  ${GRN}[I]${RST}  Install Module            ${DESC}- go install ffuf${RST}\n"
        printf "  ${YLW}[B]${RST}  Back\n\n"
        printf "  %sChoose: %s" "${HOT}" "${RST}"; read -r SC
        local FFUFCMD="$HOME/go/bin/ffuf"
        command -v ffuf >/dev/null 2>&1 && FFUFCMD="ffuf"
        local FFWL="/usr/share/wordlists/dirb/common.txt"
        [ ! -f "$FFWL" ] && FFWL="/data/data/com.termux/files/usr/share/dirb/wordlists/common.txt"
        [ ! -f "$FFWL" ] && FFWL="${HOME}/wordlists/common.txt"
        case "$SC" in
            1) ! $FFUF_INSTALLED && { install_ffuf; $FFUF_INSTALLED || continue; }
               run_web_tool "$FFUFCMD -u TARGET_PLACEHOLDER/FUZZ -w $FFWL -mc 200,204,301,302,403 -t 40" "FFUF · Directory Fuzz" "yes" "ffuf -u <url>/FUZZ -w wordlist" ;;
            2) ! $FFUF_INSTALLED && { install_ffuf; $FFUF_INSTALLED || continue; }
               run_web_tool "$FFUFCMD -u 'TARGET_PLACEHOLDER?FUZZ=test' -w $FFWL -mc 200 -t 30" "FFUF · Parameter Fuzz GET" "yes" "ffuf -u <url>?FUZZ=val -w wordlist" ;;
            3) ! $FFUF_INSTALLED && { install_ffuf; $FFUF_INSTALLED || continue; }
               run_web_tool "$FFUFCMD -u TARGET_PLACEHOLDER -d 'FUZZ=1' -X POST -w $FFWL -mc 200 -t 30" "FFUF · POST Fuzz" "yes" "ffuf -d FUZZ=1 -X POST" ;;
            4) ! $FFUF_INSTALLED && { install_ffuf; $FFUF_INSTALLED || continue; }
               run_web_tool "$FFUFCMD -u TARGET_PLACEHOLDER -H 'Host: FUZZ.TARGET_PLACEHOLDER' -w $FFWL -mc 200 -t 30" "FFUF · Vhost Fuzz" "yes" "ffuf -H Host:FUZZ.target" ;;
            5) ! $FFUF_INSTALLED && { install_ffuf; $FFUF_INSTALLED || continue; }
               printf "  %sEnter status code to filter out (e.g. 404): %s" "${HOT}" "${RST}"; read -r FFFC
               [ -z "$FFFC" ] && FFFC=404
               run_web_tool "$FFUFCMD -u TARGET_PLACEHOLDER/FUZZ -w $FFWL -fc $FFFC -t 40" "FFUF · Filter Status $FFFC" "yes" "ffuf -fc $FFFC" ;;
            6) ! $FFUF_INSTALLED && { install_ffuf; $FFUF_INSTALLED || continue; }
               printf "  %sEnter response size to filter (e.g. 1234): %s" "${HOT}" "${RST}"; read -r FFFS
               [ -z "$FFFS" ] && FFFS=0
               run_web_tool "$FFUFCMD -u TARGET_PLACEHOLDER/FUZZ -w $FFWL -fs $FFFS -t 40" "FFUF · Filter Size $FFFS" "yes" "ffuf -fs $FFFS" ;;
            7) ! $FFUF_INSTALLED && { install_ffuf; $FFUF_INSTALLED || continue; }
               run_web_tool "$FFUFCMD -u TARGET_PLACEHOLDER/FUZZ -w $FFWL -recursion -recursion-depth 2 -mc 200,301,302 -t 30" "FFUF · Recursive Fuzz" "yes" "ffuf -recursion -depth 2" ;;
            8) ! $FFUF_INSTALLED && { install_ffuf; $FFUF_INSTALLED || continue; }
               printf "  %sEnter wordlist path: %s" "${HOT}" "${RST}"; read -r FFCWL
               [ -z "$FFCWL" ] && { printf "  %s[!] No path.%s\n" "${RED}" "${RST}"; sleep 1; continue; }
               run_web_tool "$FFUFCMD -u TARGET_PLACEHOLDER/FUZZ -w '$FFCWL' -mc 200,301,302 -t 40" "FFUF · Custom Wordlist" "yes" "ffuf custom wordlist" ;;
            9) ! $FFUF_INSTALLED && { install_ffuf; $FFUF_INSTALLED || continue; }
               run_web_tool "$FFUFCMD -u TARGET_PLACEHOLDER/FUZZ -w $FFWL -e .php,.html,.asp,.aspx,.txt -mc 200,301,302 -t 40" "FFUF · Extension Fuzz" "yes" "ffuf -e .php,.html,.asp" ;;
            10) ! $FFUF_INSTALLED && { install_ffuf; $FFUF_INSTALLED || continue; }
                run_web_tool "{ echo '=== DIR FUZZ ==='; $FFUFCMD -u TARGET_PLACEHOLDER/FUZZ -w $FFWL -mc 200,301,302 -t 40 2>/dev/null | head -40; echo ''; echo '=== PARAM FUZZ ==='; $FFUFCMD -u 'TARGET_PLACEHOLDER?FUZZ=test' -w $FFWL -mc 200 -t 30 2>/dev/null | head -20; echo ''; echo '=== EXTENSION FUZZ ==='; $FFUFCMD -u TARGET_PLACEHOLDER/FUZZ -w $FFWL -e .php,.html,.asp -mc 200 -t 30 2>/dev/null | head -20; }" \
                    "FFUF · Full Auto Fuzz Recon" "yes" "dir+param+ext <url>" ;;
            i|I) install_ffuf ;;
            b|B) return ;;
            *) printf "  %s[!] Invalid.%s\n" "${RED}" "${RST}"; sleep 1 ;;
        esac
    done
}


# ============================================================
#  REPORT ENGINE · FEZZY G.I.JOE V7
# ============================================================

init_session() {
    local dt
    dt=$(date +%Y%m%d-%H%M%S)
    SESSION_ID="GJR-${dt}"
    SESSION_FILE="${TMPDIR:-/tmp}/fezzy_session_${dt}.tmp"
    touch "$SESSION_FILE"
    printf "SESSION_ID=%s\nSESSION_TARGET=%s\nSESSION_DATE=%s\n" \
        "$SESSION_ID" "$SESSION_TARGET" "$(date)" > "$SESSION_FILE"
    printf "---ENTRIES---\n" >> "$SESSION_FILE"
}

session_target_prompt() {
    echo ""
    printf "  %s╔══════════════════════════════════════════════════╗%s\n" "${HOT}" "${RST}"
    printf "  %s║         FEZZY G.I.JOE · SESSION TARGET          ║%s\n" "${HOT}" "${RST}"
    printf "  %s╚══════════════════════════════════════════════════╝%s\n" "${HOT}" "${RST}"
    echo ""
    printf "  %sEnter target for this session (e.g. example.com)%s\n" "${CYN}" "${RST}"
    printf "  %sPress ENTER to skip (free-form mode): %s" "${YLW}" "${RST}"
    read -r SESSION_TARGET
    [ -z "$SESSION_TARGET" ] && SESSION_TARGET="unspecified"
    init_session
    echo ""
    printf "  %s[+] Session started · %s · Target: %s%s\n" "${GRN}" "$SESSION_ID" "$SESSION_TARGET" "${RST}"
    echo ""
    sleep 1
}

report_add_entry() {
    local tool_name="$1"
    local result_file="$2"
    [ ! -f "$SESSION_FILE" ] && init_session
    REPORT_COUNTER=$(( REPORT_COUNTER + 1 ))
    local ts
    ts=$(date +%H:%M:%S)
    {
        printf "ENTRY_START\n"
        printf "NUM=%02d\n" "$REPORT_COUNTER"
        printf "TOOL=%s\n" "$tool_name"
        printf "TIMESTAMP=%s\n" "$ts"
        printf "TARGET=%s\n" "$SESSION_TARGET"
        printf "RESULT_START\n"
        [ -f "$result_file" ] && cat "$result_file" || printf "(no output captured)\n"
        printf "RESULT_END\n"
        printf "ENTRY_END\n"
    } >> "$SESSION_FILE"
}

report_prompt_save() {
    local tool_name="$1"
    local result_file="$2"
    echo ""
    printf "  %s[R] Add this result to session report? (y/n): %s" "${HOT}" "${RST}"
    read -r SAVE_CHOICE
    if [[ "$SAVE_CHOICE" =~ ^[Yy]$ ]]; then
        report_add_entry "$tool_name" "$result_file"
        printf "  %s[+] Saved to report · Entry %02d%s\n" "${GRN}" "$REPORT_COUNTER" "${RST}"
    fi
}

build_txt_report() {
    local outfile="${HOME}/storage/downloads/fezzy_report_${SESSION_TARGET}_$(date +%Y%m%d).txt"
    {
        printf "═%.0s" {1..60}; printf "\n"
        printf "  FEZZY G.I.JOE · RECON REPORT\n"
        printf "═%.0s" {1..60}; printf "\n"
        printf "  Target   : %s\n" "$SESSION_TARGET"
        printf "  Session  : %s\n" "$SESSION_ID"
        printf "  Date     : %s\n" "$(date)"
        printf "  Tool     : FEZZY G.I.JOE V7.0\n"
        printf "═%.0s" {1..60}; printf "\n\n"

        local in_entry=false in_result=false
        local num="" tool="" ts="" target=""
        while IFS= read -r line; do
            case "$line" in
                "ENTRY_START") in_entry=true ;;
                "ENTRY_END")
                    in_entry=false; in_result=false
                    printf "─%.0s" {1..60}; printf "\n\n"
                    ;;
                "RESULT_START") in_result=true ;;
                "RESULT_END")   in_result=false ;;
                NUM=*)    num="${line#NUM=}" ;;
                TOOL=*)   tool="${line#TOOL=}"
                          printf "[%s] %s\n" "$num" "$tool"
                          printf "    Target    : %s\n" "$SESSION_TARGET"
                          printf "    Timestamp : %s\n" "$ts"
                          printf "\n" ;;
                TIMESTAMP=*) ts="${line#TIMESTAMP=}" ;;
                TARGET=*)    ;;
                SESSION_ID=*|SESSION_TARGET=*|SESSION_DATE=*|---ENTRIES---) ;;
                *)
                    $in_result && printf "    %s\n" "$line"
                    ;;
            esac
        done < "$SESSION_FILE"
        printf "\n  999 · Strategy Over Impulse · Fezzy Arsenal\n"
        printf "═%.0s" {1..60}; printf "\n"
    } > "$outfile"
    echo "$outfile"
}

build_html_report() {
    local outfile="${HOME}/storage/downloads/fezzy_report_${SESSION_TARGET}_$(date +%Y%m%d).html"
    {
        cat << 'HTMLHEAD'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Fezzy G.I.JOE · Recon Report</title>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { background: #0a0a0f; color: #e0e0e0; font-family: 'Courier New', monospace; padding: 16px; }
  .header { border: 2px solid #c6007e; padding: 20px; margin-bottom: 20px; text-align: center; }
  .header h1 { color: #ff2d78; font-size: 1.4em; letter-spacing: 2px; }
  .header .meta { color: #a020a0; margin-top: 10px; font-size: 0.85em; line-height: 1.8; }
  .session-id { color: #00ffff; font-size: 0.8em; margin-top: 6px; }
  .divider { height: 2px; background: linear-gradient(90deg,#c6007e,#5b0090,#0033ff); margin: 16px 0; }
  .entry { border: 1px solid #2a0a3a; background: #100018; border-radius: 6px; margin-bottom: 16px; overflow: hidden; }
  .entry-header { background: #1e0030; padding: 12px 16px; display: flex; justify-content: space-between; align-items: center; }
  .entry-num { color: #ff2d78; font-weight: bold; font-size: 1em; }
  .entry-tool { color: #00ffff; font-size: 1em; font-weight: bold; }
  .entry-ts { color: #888; font-size: 0.78em; }
  .entry-target { color: #a020a0; font-size: 0.8em; padding: 6px 16px; background: #0d0020; border-bottom: 1px solid #2a0a3a; }
  .entry-result { padding: 14px 16px; font-size: 0.82em; line-height: 1.7; color: #c8c8c8; white-space: pre-wrap; word-break: break-all; max-height: 400px; overflow-y: auto; }
  .footer { text-align: center; color: #5b0090; font-size: 0.8em; margin-top: 30px; padding: 16px; border-top: 1px solid #2a0a3a; }
  .badge { display: inline-block; background: #ff2d78; color: #000; padding: 2px 8px; border-radius: 3px; font-size: 0.75em; font-weight: bold; }
  .no-entries { text-align: center; color: #555; padding: 40px; }
</style>
</head>
<body>
HTMLHEAD

        printf '<div class="header">\n'
        printf '  <h1>⚡ FEZZY G.I.JOE · RECON REPORT ⚡</h1>\n'
        printf '  <div class="meta">\n'
        printf '    <strong>Target:</strong> %s &nbsp;|&nbsp; <strong>Date:</strong> %s\n' \
            "$SESSION_TARGET" "$(date '+%Y-%m-%d %H:%M')"
        printf '  </div>\n'
        printf '  <div class="session-id">Session: %s &nbsp;|&nbsp; Tool: FEZZY G.I.JOE V7.0</div>\n' "$SESSION_ID"
        printf '</div>\n'
        printf '<div class="divider"></div>\n'

        local entry_count=0
        local in_result=false
        local num="" tool="" ts=""
        while IFS= read -r line; do
            case "$line" in
                "ENTRY_START")
                    entry_count=$(( entry_count + 1 ))
                    in_result=false
                    printf '<div class="entry">\n'
                    ;;
                "ENTRY_END")
                    printf '</div>\n</div>\n'
                    in_result=false
                    ;;
                "RESULT_START")
                    in_result=true
                    printf '<div class="entry-result">'
                    ;;
                "RESULT_END")
                    in_result=false
                    printf '</div>\n'
                    ;;
                NUM=*)
                    num="${line#NUM=}"
                    ;;
                TOOL=*)
                    tool="${line#TOOL=}"
                    printf '<div class="entry-header">\n'
                    printf '  <span class="entry-num">[%s]</span>\n' "$num"
                    printf '  <span class="entry-tool">%s</span>\n' "$tool"
                    printf '  <span class="entry-ts">%s</span>\n' "$ts"
                    printf '</div>\n'
                    printf '<div class="entry-target">🎯 Target: %s</div>\n' "$SESSION_TARGET"
                    ;;
                TIMESTAMP=*) ts="${line#TIMESTAMP=}" ;;
                TARGET=*|SESSION_ID=*|SESSION_TARGET=*|SESSION_DATE=*|---ENTRIES---) ;;
                *)
                    if $in_result; then
                        # HTML-escape basic chars
                        local escaped
                        escaped="${line//&/&amp;}"
                        escaped="${escaped//</&lt;}"
                        escaped="${escaped//>/&gt;}"
                        printf '%s\n' "$escaped"
                    fi
                    ;;
            esac
        done < "$SESSION_FILE"

        [ "$entry_count" -eq 0 ] && printf '<div class="no-entries">No entries saved to this session yet.</div>\n'

        printf '<div class="footer">\n'
        printf '  <span class="badge">999</span> &nbsp; Strategy Over Impulse · Fezzy Arsenal · philfesters\n'
        printf '</div>\n'
        printf '</body>\n</html>\n'
    } > "$outfile"
    echo "$outfile"
}

report_builder_menu() {
    while true; do
        clear; banner; echo ""
        center_in_box "REPORT BUILDER · SESSION COMPILER"
        pink_line
        echo ""
        printf "  %sSession ID  : %s%s\n" "${CYN}" "${SESSION_ID:-none}" "${RST}"
        printf "  %sTarget      : %s%s\n" "${CYN}" "${SESSION_TARGET:-unspecified}" "${RST}"
        printf "  %sEntries     : %s%s\n" "${CYN}" "$REPORT_COUNTER" "${RST}"
        echo ""
        pink_line
        echo ""
        printf "  ${GRN}[1]${RST} Build TXT Report   ${DESC}- Clean text file to downloads${RST}\n"
        printf "  ${GRN}[2]${RST} Build HTML Report  ${DESC}- Styled dark theme to downloads${RST}\n"
        printf "  ${GRN}[3]${RST} Build Both         ${DESC}- TXT + HTML at once${RST}\n"
        printf "  ${GRN}[4]${RST} View Session Log   ${DESC}- Raw session data preview${RST}\n"
        printf "  ${GRN}[5]${RST} Change Target      ${DESC}- Update session target${RST}\n"
        printf "  ${GRN}[6]${RST} Clear Session      ${DESC}- Wipe entries and start fresh${RST}\n"
        printf "  ${YLW}[B]${RST} Back to Main Menu\n"
        echo ""
        printf "  %sChoose: %s" "${HOT}" "${RST}"
        read -r RC
        case "$RC" in
            1)
                [ "$REPORT_COUNTER" -eq 0 ] && { printf "  %s[!] No entries yet. Run tools first.%s\n" "${RED}" "${RST}"; sleep 2; continue; }
                local txt_out
                txt_out=$(build_txt_report)
                printf "  %s[+] TXT Report saved:%s\n  %s\n" "${GRN}" "${RST}" "$txt_out"
                echo ""; printf "  %sPress ENTER...%s" "${HOT}" "${RST}"; read -r _
                ;;
            2)
                [ "$REPORT_COUNTER" -eq 0 ] && { printf "  %s[!] No entries yet. Run tools first.%s\n" "${RED}" "${RST}"; sleep 2; continue; }
                local html_out
                html_out=$(build_html_report)
                printf "  %s[+] HTML Report saved:%s\n  %s\n" "${GRN}" "${RST}" "$html_out"
                echo ""; printf "  %sPress ENTER...%s" "${HOT}" "${RST}"; read -r _
                ;;
            3)
                [ "$REPORT_COUNTER" -eq 0 ] && { printf "  %s[!] No entries yet. Run tools first.%s\n" "${RED}" "${RST}"; sleep 2; continue; }
                local txt_out html_out
                txt_out=$(build_txt_report)
                html_out=$(build_html_report)
                printf "  %s[+] TXT  → %s%s\n" "${GRN}" "$txt_out" "${RST}"
                printf "  %s[+] HTML → %s%s\n" "${GRN}" "$html_out" "${RST}"
                echo ""; printf "  %sPress ENTER...%s" "${HOT}" "${RST}"; read -r _
                ;;
            4)
                echo ""
                [ -f "$SESSION_FILE" ] && cat "$SESSION_FILE" | head -80 \
                    || printf "  %s[!] No session file yet.%s\n" "${RED}" "${RST}"
                echo ""; printf "  %sPress ENTER...%s" "${HOT}" "${RST}"; read -r _
                ;;
            5)
                printf "  %sNew target: %s" "${HOT}" "${RST}"
                read -r SESSION_TARGET
                [ -z "$SESSION_TARGET" ] && SESSION_TARGET="unspecified"
                printf "  %s[+] Target updated to: %s%s\n" "${GRN}" "$SESSION_TARGET" "${RST}"
                sleep 1
                ;;
            6)
                printf "  %s[!] Clear all entries? (y/n): %s" "${RED}" "${RST}"
                read -r CLR
                if [[ "$CLR" =~ ^[Yy]$ ]]; then
                    REPORT_COUNTER=0
                    init_session
                    printf "  %s[+] Session cleared.%s\n" "${GRN}" "${RST}"
                    sleep 1
                fi
                ;;
            b|B) return ;;
            *) printf "  %s[!] Invalid.%s\n" "${RED}" "${RST}"; sleep 1 ;;
        esac
    done
}

# ══════════════════════════════════════════════════════════════
#  V8 ROOTLESS ARSENAL · SUBMENUS (50-60)
# ══════════════════════════════════════════════════════════════

submenu_amass() {
    while true; do
        clear; banner; echo ""
        center_in_box "AMASS · PASSIVE SUBDOMAIN ENUM"
        short_pink_line 32; echo ""
        printf "${PNK}╔══════════════════════════════════════════════════════════════╗${RST}\n"
        printf "${PNK}║${RST} ${CYN}SYNOPSIS:${RST} OWASP Amass — passive subdomain enumeration via       ${RST}\n"
        printf "${PNK}║${RST}          30+ data sources: Shodan, VirusTotal, Censys, Wayback ${RST}\n"
        printf "${PNK}║${RST}          and more. No brute force — pure passive intel.         ${RST}\n"
        printf "${PNK}║${RST} ${CYN}USE:${RST} Enter domain (e.g. example.com) when prompted.          ${RST}\n"
        printf "${PNK}║${RST} ${CYN}INSTALL:${RST} go install github.com/owasp-amass/amass/v4/...@master ${RST}\n"
        printf "${PNK}╚══════════════════════════════════════════════════════════════╝${RST}\n\n"
        printf "  ${GRN}[1]${RST}  Passive Enum           ${DESC}- amass enum -passive -d <target>${RST}\n"
        printf "  ${GRN}[2]${RST}  Active Enum            ${DESC}- amass enum -active -d <target>${RST}\n"
        printf "  ${GRN}[3]${RST}  Brute Force            ${DESC}- amass enum -brute -d <target>${RST}\n"
        printf "  ${GRN}[4]${RST}  All Sources            ${DESC}- amass enum -d <target> -src${RST}\n"
        printf "  ${GRN}[5]${RST}  Save to File           ${DESC}- passive enum → output.txt${RST}\n"
        printf "  ${GRN}[6]${RST}  Intel (ASN/CIDR)       ${DESC}- amass intel -asn / -cidr${RST}\n"
        printf "  ${GRN}[7]${RST}  Full Auto Recon        ${DESC}- passive + src tags combined${RST}\n"
        printf "  ${GRN}[I]${RST}  Install Module         ${DESC}- go install amass${RST}\n"
        printf "  ${YLW}[B]${RST}  Back\n\n"
        printf "  %sChoose: %s" "${HOT}" "${RST}"; read -r SC
        case "$SC" in
            1) ! $AMASS_INSTALLED && { install_amass; $AMASS_INSTALLED || continue; }
               run_web_tool "amass enum -passive -d TARGET_PLACEHOLDER" "Amass · Passive Enum" "yes" "amass enum -passive -d <domain>" ;;
            2) ! $AMASS_INSTALLED && { install_amass; $AMASS_INSTALLED || continue; }
               run_web_tool "amass enum -active -d TARGET_PLACEHOLDER" "Amass · Active Enum" "yes" "amass enum -active -d <domain>" ;;
            3) ! $AMASS_INSTALLED && { install_amass; $AMASS_INSTALLED || continue; }
               run_web_tool "amass enum -brute -d TARGET_PLACEHOLDER" "Amass · Brute Force" "yes" "amass enum -brute -d <domain>" ;;
            4) ! $AMASS_INSTALLED && { install_amass; $AMASS_INSTALLED || continue; }
               run_web_tool "amass enum -d TARGET_PLACEHOLDER -src" "Amass · All Sources" "yes" "amass enum -d <domain> -src" ;;
            5) ! $AMASS_INSTALLED && { install_amass; $AMASS_INSTALLED || continue; }
               run_web_tool "amass enum -passive -d TARGET_PLACEHOLDER -o ${HOME}/storage/downloads/amass_out.txt && cat ${HOME}/storage/downloads/amass_out.txt" "Amass · Save Output" "yes" "amass enum -passive -d <domain> -o out.txt" ;;
            6) ! $AMASS_INSTALLED && { install_amass; $AMASS_INSTALLED || continue; }
               printf "  %sEnter ASN or CIDR: %s" "${HOT}" "${RST}"; read -r _aval
               run_web_tool "amass intel -asn ${_aval}" "Amass · Intel" "no" "amass intel -asn <val>" ;;
            7) ! $AMASS_INSTALLED && { install_amass; $AMASS_INSTALLED || continue; }
               run_web_tool "{ echo '=== PASSIVE ==='; amass enum -passive -d TARGET_PLACEHOLDER -src 2>/dev/null; echo ''; echo '=== COUNT ==='; amass enum -passive -d TARGET_PLACEHOLDER 2>/dev/null | wc -l | xargs echo 'Total subdomains:'; }" "Amass · Full Auto Recon" "yes" "amass full auto" ;;
            i|I) install_amass ;;
            b|B) break ;;
            *) printf "  %s[!] Invalid.%s\n" "${RED}" "${RST}"; sleep 1 ;;
        esac
    done
}

submenu_nuclei() {
    while true; do
        clear; banner; echo ""
        center_in_box "NUCLEI · TEMPLATE-BASED VULN SCANNER"
        short_pink_line 32; echo ""
        printf "${PNK}╔══════════════════════════════════════════════════════════════╗${RST}\n"
        printf "${PNK}║${RST} ${CYN}SYNOPSIS:${RST} Nuclei — fast, YAML-template vulnerability scanner.  ${RST}\n"
        printf "${PNK}║${RST}          Replaces nikto. 9000+ community templates covering    ${RST}\n"
        printf "${PNK}║${RST}          CVEs, misconfigs, exposures, network probes.           ${RST}\n"
        printf "${PNK}║${RST} ${CYN}USE:${RST} Enter URL or IP. Runs rootless, no sudo needed.          ${RST}\n"
        printf "${PNK}║${RST} ${CYN}INSTALL:${RST} go install github.com/projectdiscovery/nuclei/v3/...  ${RST}\n"
        printf "${PNK}╚══════════════════════════════════════════════════════════════╝${RST}\n\n"
        printf "  ${GRN}[1]${RST}  Quick Scan             ${DESC}- nuclei default templates${RST}\n"
        printf "  ${GRN}[2]${RST}  CVE Scan               ${DESC}- -tags cve only${RST}\n"
        printf "  ${GRN}[3]${RST}  Misconfig Scan         ${DESC}- -tags misconfig${RST}\n"
        printf "  ${GRN}[4]${RST}  Exposure Scan          ${DESC}- -tags exposure${RST}\n"
        printf "  ${GRN}[5]${RST}  Network Scan           ${DESC}- -tags network${RST}\n"
        printf "  ${GRN}[6]${RST}  Severity Filter        ${DESC}- critical + high only${RST}\n"
        printf "  ${GRN}[7]${RST}  Full Auto Recon        ${DESC}- all severity, save report${RST}\n"
        printf "  ${GRN}[U]${RST}  Update Templates       ${DESC}- nuclei -update-templates${RST}\n"
        printf "  ${GRN}[I]${RST}  Install Module         ${DESC}- go install nuclei${RST}\n"
        printf "  ${YLW}[B]${RST}  Back\n\n"
        printf "  %sChoose: %s" "${HOT}" "${RST}"; read -r SC
        local _NUC="${HOME}/go/bin/nuclei"; command -v nuclei >/dev/null 2>&1 && _NUC="nuclei"
        case "$SC" in
            1) ! $NUCLEI_INSTALLED && { install_nuclei; $NUCLEI_INSTALLED || continue; }
               run_web_tool "${_NUC} -u TARGET_PLACEHOLDER -silent" "Nuclei · Quick Scan" "yes" "nuclei -u <target>" ;;
            2) ! $NUCLEI_INSTALLED && { install_nuclei; $NUCLEI_INSTALLED || continue; }
               run_web_tool "${_NUC} -u TARGET_PLACEHOLDER -tags cve -silent" "Nuclei · CVE Scan" "yes" "nuclei -u <target> -tags cve" ;;
            3) ! $NUCLEI_INSTALLED && { install_nuclei; $NUCLEI_INSTALLED || continue; }
               run_web_tool "${_NUC} -u TARGET_PLACEHOLDER -tags misconfig -silent" "Nuclei · Misconfig" "yes" "nuclei -u <target> -tags misconfig" ;;
            4) ! $NUCLEI_INSTALLED && { install_nuclei; $NUCLEI_INSTALLED || continue; }
               run_web_tool "${_NUC} -u TARGET_PLACEHOLDER -tags exposure -silent" "Nuclei · Exposure" "yes" "nuclei -u <target> -tags exposure" ;;
            5) ! $NUCLEI_INSTALLED && { install_nuclei; $NUCLEI_INSTALLED || continue; }
               run_web_tool "${_NUC} -u TARGET_PLACEHOLDER -tags network -silent" "Nuclei · Network" "yes" "nuclei -u <target> -tags network" ;;
            6) ! $NUCLEI_INSTALLED && { install_nuclei; $NUCLEI_INSTALLED || continue; }
               run_web_tool "${_NUC} -u TARGET_PLACEHOLDER -severity critical,high -silent" "Nuclei · Severity Filter" "yes" "nuclei -severity critical,high" ;;
            7) ! $NUCLEI_INSTALLED && { install_nuclei; $NUCLEI_INSTALLED || continue; }
               run_web_tool "{ ${_NUC} -u TARGET_PLACEHOLDER -silent -o ${HOME}/storage/downloads/nuclei_report.txt; echo ''; echo '=== REPORT SAVED ==='; cat ${HOME}/storage/downloads/nuclei_report.txt; }" "Nuclei · Full Auto Recon" "yes" "nuclei full + report" ;;
            u|U) local _n="${HOME}/go/bin/nuclei"; [[ -x "$_n" ]] && "$_n" -update-templates || nuclei -update-templates ;;
            i|I) install_nuclei ;;
            b|B) break ;;
            *) printf "  %s[!] Invalid.%s\n" "${RED}" "${RST}"; sleep 1 ;;
        esac
    done
}

submenu_katana() {
    while true; do
        clear; banner; echo ""
        center_in_box "KATANA · JS-AWARE WEB CRAWLER"
        short_pink_line 32; echo ""
        printf "${PNK}╔══════════════════════════════════════════════════════════════╗${RST}\n"
        printf "${PNK}║${RST} ${CYN}SYNOPSIS:${RST} Katana — next-gen web crawler with JavaScript        ${RST}\n"
        printf "${PNK}║${RST}          rendering. Extracts endpoints, forms, JS sources.    ${RST}\n"
        printf "${PNK}║${RST}          Far superior to photon on modern JS-heavy sites.     ${RST}\n"
        printf "${PNK}║${RST} ${CYN}USE:${RST} Enter full URL (e.g. https://example.com).              ${RST}\n"
        printf "${PNK}║${RST} ${CYN}INSTALL:${RST} go install github.com/projectdiscovery/katana/...    ${RST}\n"
        printf "${PNK}╚══════════════════════════════════════════════════════════════╝${RST}\n\n"
        printf "  ${GRN}[1]${RST}  Basic Crawl            ${DESC}- katana -u <target>${RST}\n"
        printf "  ${GRN}[2]${RST}  Deep Crawl (depth 5)   ${DESC}- katana -d 5${RST}\n"
        printf "  ${GRN}[3]${RST}  JS Endpoint Extract    ${DESC}- katana -jc (JS crawl mode)${RST}\n"
        printf "  ${GRN}[4]${RST}  Form Discovery         ${DESC}- katana -ef (known forms)${RST}\n"
        printf "  ${GRN}[5]${RST}  Silent + Save          ${DESC}- crawl to downloads/katana_out.txt${RST}\n"
        printf "  ${GRN}[6]${RST}  Full Auto Recon        ${DESC}- JS crawl + save + count${RST}\n"
        printf "  ${GRN}[I]${RST}  Install Module         ${DESC}- go install katana${RST}\n"
        printf "  ${YLW}[B]${RST}  Back\n\n"
        printf "  %sChoose: %s" "${HOT}" "${RST}"; read -r SC
        local _KT="${HOME}/go/bin/katana"; command -v katana >/dev/null 2>&1 && _KT="katana"
        case "$SC" in
            1) ! $KATANA_INSTALLED && { install_katana; $KATANA_INSTALLED || continue; }
               run_web_tool "${_KT} -u TARGET_PLACEHOLDER -silent" "Katana · Basic Crawl" "yes" "katana -u <target>" ;;
            2) ! $KATANA_INSTALLED && { install_katana; $KATANA_INSTALLED || continue; }
               run_web_tool "${_KT} -u TARGET_PLACEHOLDER -d 5 -silent" "Katana · Deep Crawl" "yes" "katana -u <target> -d 5" ;;
            3) ! $KATANA_INSTALLED && { install_katana; $KATANA_INSTALLED || continue; }
               run_web_tool "${_KT} -u TARGET_PLACEHOLDER -jc -silent" "Katana · JS Endpoints" "yes" "katana -u <target> -jc" ;;
            4) ! $KATANA_INSTALLED && { install_katana; $KATANA_INSTALLED || continue; }
               run_web_tool "${_KT} -u TARGET_PLACEHOLDER -ef -silent" "Katana · Form Discovery" "yes" "katana -u <target> -ef" ;;
            5) ! $KATANA_INSTALLED && { install_katana; $KATANA_INSTALLED || continue; }
               run_web_tool "${_KT} -u TARGET_PLACEHOLDER -silent -o ${HOME}/storage/downloads/katana_out.txt && cat ${HOME}/storage/downloads/katana_out.txt" "Katana · Save Output" "yes" "katana -u <target> -o out.txt" ;;
            6) ! $KATANA_INSTALLED && { install_katana; $KATANA_INSTALLED || continue; }
               run_web_tool "{ echo '=== JS CRAWL ==='; ${_KT} -u TARGET_PLACEHOLDER -jc -silent -o ${HOME}/storage/downloads/katana_out.txt; echo ''; echo '=== ENDPOINTS FOUND ==='; cat ${HOME}/storage/downloads/katana_out.txt 2>/dev/null; echo ''; wc -l ${HOME}/storage/downloads/katana_out.txt 2>/dev/null | xargs echo 'Total:'; }" "Katana · Full Auto Recon" "yes" "katana JS full" ;;
            i|I) install_katana ;;
            b|B) break ;;
            *) printf "  %s[!] Invalid.%s\n" "${RED}" "${RST}"; sleep 1 ;;
        esac
    done
}

submenu_shuffledns() {
    while true; do
        clear; banner; echo ""
        center_in_box "SHUFFLEDNS · HIGH-SPEED DNS RESOLVER"
        short_pink_line 32; echo ""
        printf "${PNK}╔══════════════════════════════════════════════════════════════╗${RST}\n"
        printf "${PNK}║${RST} ${CYN}SYNOPSIS:${RST} ShuffleDNS — DNS resolver wrapper around MassDNS.   ${RST}\n"
        printf "${PNK}║${RST}          Bruteforce subdomains or resolve domain lists at      ${RST}\n"
        printf "${PNK}║${RST}          massive speed. Handles wildcards intelligently.        ${RST}\n"
        printf "${PNK}║${RST} ${CYN}USE:${RST} Enter domain. Requires a resolver list (auto-fetched).  ${RST}\n"
        printf "${PNK}║${RST} ${CYN}INSTALL:${RST} go install github.com/projectdiscovery/shuffledns/... ${RST}\n"
        printf "${PNK}╚══════════════════════════════════════════════════════════════╝${RST}\n\n"
        printf "  ${GRN}[1]${RST}  Resolve Domain List    ${DESC}- resolve stdin list against domain${RST}\n"
        printf "  ${GRN}[2]${RST}  Brute Subdomains       ${DESC}- shuffledns -d <target> -w wordlist${RST}\n"
        printf "  ${GRN}[3]${RST}  Wildcard Filter        ${DESC}- auto-filter wildcard DNS entries${RST}\n"
        printf "  ${GRN}[4]${RST}  Full Auto Recon        ${DESC}- brute + save + count${RST}\n"
        printf "  ${GRN}[I]${RST}  Install Module         ${DESC}- go install shuffledns${RST}\n"
        printf "  ${YLW}[B]${RST}  Back\n\n"
        printf "  %sChoose: %s" "${HOT}" "${RST}"; read -r SC
        local _SD="${HOME}/go/bin/shuffledns"; command -v shuffledns >/dev/null 2>&1 && _SD="shuffledns"
        local _WL="/usr/share/wordlists/dns/subdomains-top1million-5000.txt"
        [[ ! -f "$_WL" ]] && _WL="${HOME}/.fezzy-gijoe/resolvers.txt"
        case "$SC" in
            1) ! $SHUFFLEDNS_INSTALLED && { install_shuffledns; $SHUFFLEDNS_INSTALLED || continue; }
               run_web_tool "{ curl -sL https://raw.githubusercontent.com/janmasarik/resolvers/master/resolvers.txt -o ${TMPDIR:-/tmp}/resolvers.txt 2>/dev/null; ${_SD} -d TARGET_PLACEHOLDER -r ${TMPDIR:-/tmp}/resolvers.txt -silent; }" "ShuffleDNS · Resolve" "yes" "shuffledns -d <domain>" ;;
            2) ! $SHUFFLEDNS_INSTALLED && { install_shuffledns; $SHUFFLEDNS_INSTALLED || continue; }
               run_web_tool "{ curl -sL https://raw.githubusercontent.com/janmasarik/resolvers/master/resolvers.txt -o ${TMPDIR:-/tmp}/resolvers.txt 2>/dev/null; ${_SD} -d TARGET_PLACEHOLDER -w ${_WL} -r ${TMPDIR:-/tmp}/resolvers.txt -silent; }" "ShuffleDNS · Brute" "yes" "shuffledns brute" ;;
            3) ! $SHUFFLEDNS_INSTALLED && { install_shuffledns; $SHUFFLEDNS_INSTALLED || continue; }
               run_web_tool "{ curl -sL https://raw.githubusercontent.com/janmasarik/resolvers/master/resolvers.txt -o ${TMPDIR:-/tmp}/resolvers.txt 2>/dev/null; ${_SD} -d TARGET_PLACEHOLDER -r ${TMPDIR:-/tmp}/resolvers.txt -sw -silent; }" "ShuffleDNS · Wildcard Filter" "yes" "shuffledns wildcard" ;;
            4) ! $SHUFFLEDNS_INSTALLED && { install_shuffledns; $SHUFFLEDNS_INSTALLED || continue; }
               run_web_tool "{ curl -sL https://raw.githubusercontent.com/janmasarik/resolvers/master/resolvers.txt -o ${TMPDIR:-/tmp}/resolvers.txt 2>/dev/null; ${_SD} -d TARGET_PLACEHOLDER -w ${_WL} -r ${TMPDIR:-/tmp}/resolvers.txt -silent -o ${HOME}/storage/downloads/shuffledns_out.txt; echo '=== OUTPUT ==='; cat ${HOME}/storage/downloads/shuffledns_out.txt 2>/dev/null; wc -l ${HOME}/storage/downloads/shuffledns_out.txt 2>/dev/null | xargs echo 'Total:'; }" "ShuffleDNS · Full Auto" "yes" "shuffledns full" ;;
            i|I) install_shuffledns ;;
            b|B) break ;;
            *) printf "  %s[!] Invalid.%s\n" "${RED}" "${RST}"; sleep 1 ;;
        esac
    done
}

submenu_httpx_tool() {
    while true; do
        clear; banner; echo ""
        center_in_box "HTTPX · HTTP PROBE & TECH DETECTION"
        short_pink_line 32; echo ""
        printf "${PNK}╔══════════════════════════════════════════════════════════════╗${RST}\n"
        printf "${PNK}║${RST} ${CYN}SYNOPSIS:${RST} HTTPX — fast HTTP/S probe returning status codes,   ${RST}\n"
        printf "${PNK}║${RST}          page titles, content length, technology fingerprint. ${RST}\n"
        printf "${PNK}║${RST}          Far superior to httprobe for full HTTP intel.         ${RST}\n"
        printf "${PNK}║${RST} ${CYN}USE:${RST} Enter URL or pipe domain list. Rootless, no sudo.       ${RST}\n"
        printf "${PNK}║${RST} ${CYN}INSTALL:${RST} go install github.com/projectdiscovery/httpx/...    ${RST}\n"
        printf "${PNK}╚══════════════════════════════════════════════════════════════╝${RST}\n\n"
        printf "  ${GRN}[1]${RST}  Probe Single Target    ${DESC}- httpx -u <target>${RST}\n"
        printf "  ${GRN}[2]${RST}  Status + Title         ${DESC}- httpx -title -status-code${RST}\n"
        printf "  ${GRN}[3]${RST}  Tech Detection         ${DESC}- httpx -tech-detect${RST}\n"
        printf "  ${GRN}[4]${RST}  Full Response Info     ${DESC}- status + title + tech + server${RST}\n"
        printf "  ${GRN}[5]${RST}  Follow Redirects       ${DESC}- httpx -follow-redirects${RST}\n"
        printf "  ${GRN}[6]${RST}  Screenshot Mode        ${DESC}- httpx -screenshot (if supported)${RST}\n"
        printf "  ${GRN}[7]${RST}  Full Auto Recon        ${DESC}- all flags + save report${RST}\n"
        printf "  ${GRN}[I]${RST}  Install Module         ${DESC}- go install httpx${RST}\n"
        printf "  ${YLW}[B]${RST}  Back\n\n"
        printf "  %sChoose: %s" "${HOT}" "${RST}"; read -r SC
        local _HX="${HOME}/go/bin/httpx"; command -v httpx >/dev/null 2>&1 && _HX="httpx"
        case "$SC" in
            1) ! $HTTPX_T_INSTALLED && { install_httpx_tool; $HTTPX_T_INSTALLED || continue; }
               run_web_tool "${_HX} -u TARGET_PLACEHOLDER -silent" "HTTPX · Probe" "yes" "httpx -u <target>" ;;
            2) ! $HTTPX_T_INSTALLED && { install_httpx_tool; $HTTPX_T_INSTALLED || continue; }
               run_web_tool "${_HX} -u TARGET_PLACEHOLDER -title -status-code -silent" "HTTPX · Status+Title" "yes" "httpx -title -status-code" ;;
            3) ! $HTTPX_T_INSTALLED && { install_httpx_tool; $HTTPX_T_INSTALLED || continue; }
               run_web_tool "${_HX} -u TARGET_PLACEHOLDER -tech-detect -silent" "HTTPX · Tech Detect" "yes" "httpx -tech-detect" ;;
            4) ! $HTTPX_T_INSTALLED && { install_httpx_tool; $HTTPX_T_INSTALLED || continue; }
               run_web_tool "${_HX} -u TARGET_PLACEHOLDER -title -status-code -tech-detect -web-server -silent" "HTTPX · Full Response" "yes" "httpx full response" ;;
            5) ! $HTTPX_T_INSTALLED && { install_httpx_tool; $HTTPX_T_INSTALLED || continue; }
               run_web_tool "${_HX} -u TARGET_PLACEHOLDER -follow-redirects -silent" "HTTPX · Follow Redirects" "yes" "httpx -follow-redirects" ;;
            6) ! $HTTPX_T_INSTALLED && { install_httpx_tool; $HTTPX_T_INSTALLED || continue; }
               run_web_tool "${_HX} -u TARGET_PLACEHOLDER -screenshot -silent" "HTTPX · Screenshot" "yes" "httpx -screenshot" ;;
            7) ! $HTTPX_T_INSTALLED && { install_httpx_tool; $HTTPX_T_INSTALLED || continue; }
               run_web_tool "{ ${_HX} -u TARGET_PLACEHOLDER -title -status-code -tech-detect -web-server -follow-redirects -silent -o ${HOME}/storage/downloads/httpx_report.txt; echo '=== REPORT ==='; cat ${HOME}/storage/downloads/httpx_report.txt; }" "HTTPX · Full Auto Recon" "yes" "httpx full auto" ;;
            i|I) install_httpx_tool ;;
            b|B) break ;;
            *) printf "  %s[!] Invalid.%s\n" "${RED}" "${RST}"; sleep 1 ;;
        esac
    done
}

submenu_subfinder() {
    while true; do
        clear; banner; echo ""
        center_in_box "SUBFINDER · PASSIVE SUBDOMAIN DISCOVERY"
        short_pink_line 32; echo ""
        printf "${PNK}╔══════════════════════════════════════════════════════════════╗${RST}\n"
        printf "${PNK}║${RST} ${CYN}SYNOPSIS:${RST} Subfinder — passive subdomain discovery via 30+     ${RST}\n"
        printf "${PNK}║${RST}          sources: crt.sh, Shodan, VirusTotal, Censys, etc.    ${RST}\n"
        printf "${PNK}║${RST}          Fastest passive sub-enum tool available.              ${RST}\n"
        printf "${PNK}║${RST} ${CYN}USE:${RST} Enter domain (e.g. example.com) when prompted.          ${RST}\n"
        printf "${PNK}║${RST} ${CYN}INSTALL:${RST} go install github.com/projectdiscovery/subfinder/... ${RST}\n"
        printf "${PNK}╚══════════════════════════════════════════════════════════════╝${RST}\n\n"
        printf "  ${GRN}[1]${RST}  Basic Passive Enum     ${DESC}- subfinder -d <target>${RST}\n"
        printf "  ${GRN}[2]${RST}  All Sources            ${DESC}- subfinder -d <target> -all${RST}\n"
        printf "  ${GRN}[3]${RST}  Verbose + Sources      ${DESC}- show which source found each${RST}\n"
        printf "  ${GRN}[4]${RST}  Save to File           ${DESC}- output to downloads/subfinder_out.txt${RST}\n"
        printf "  ${GRN}[5]${RST}  Recursive Enum         ${DESC}- subfinder -d <target> -recursive${RST}\n"
        printf "  ${GRN}[6]${RST}  Full Auto Recon        ${DESC}- all sources + save + pipe to httpx${RST}\n"
        printf "  ${GRN}[I]${RST}  Install Module         ${DESC}- go install subfinder${RST}\n"
        printf "  ${YLW}[B]${RST}  Back\n\n"
        printf "  %sChoose: %s" "${HOT}" "${RST}"; read -r SC
        local _SF="${HOME}/go/bin/subfinder"; command -v subfinder >/dev/null 2>&1 && _SF="subfinder"
        local _HX="${HOME}/go/bin/httpx"; command -v httpx >/dev/null 2>&1 && _HX="httpx"
        case "$SC" in
            1) ! $SUBFINDER_INSTALLED && { install_subfinder; $SUBFINDER_INSTALLED || continue; }
               run_web_tool "${_SF} -d TARGET_PLACEHOLDER -silent" "Subfinder · Passive Enum" "yes" "subfinder -d <domain>" ;;
            2) ! $SUBFINDER_INSTALLED && { install_subfinder; $SUBFINDER_INSTALLED || continue; }
               run_web_tool "${_SF} -d TARGET_PLACEHOLDER -all -silent" "Subfinder · All Sources" "yes" "subfinder -d <domain> -all" ;;
            3) ! $SUBFINDER_INSTALLED && { install_subfinder; $SUBFINDER_INSTALLED || continue; }
               run_web_tool "${_SF} -d TARGET_PLACEHOLDER -v 2>&1 | head -60" "Subfinder · Verbose" "yes" "subfinder -d <domain> -v" ;;
            4) ! $SUBFINDER_INSTALLED && { install_subfinder; $SUBFINDER_INSTALLED || continue; }
               run_web_tool "${_SF} -d TARGET_PLACEHOLDER -silent -o ${HOME}/storage/downloads/subfinder_out.txt && cat ${HOME}/storage/downloads/subfinder_out.txt" "Subfinder · Save Output" "yes" "subfinder -o out.txt" ;;
            5) ! $SUBFINDER_INSTALLED && { install_subfinder; $SUBFINDER_INSTALLED || continue; }
               run_web_tool "${_SF} -d TARGET_PLACEHOLDER -recursive -silent" "Subfinder · Recursive" "yes" "subfinder -recursive" ;;
            6) ! $SUBFINDER_INSTALLED && { install_subfinder; $SUBFINDER_INSTALLED || continue; }
               run_web_tool "{ echo '=== SUBDOMAINS ==='; ${_SF} -d TARGET_PLACEHOLDER -all -silent -o ${HOME}/storage/downloads/subfinder_out.txt; cat ${HOME}/storage/downloads/subfinder_out.txt; echo ''; echo '=== LIVE PROBE (httpx) ==='; ${_HX} -l ${HOME}/storage/downloads/subfinder_out.txt -title -status-code -silent 2>/dev/null || echo 'httpx not installed — run option 54'; }" "Subfinder · Full Auto Recon" "yes" "subfinder + httpx probe" ;;
            i|I) install_subfinder ;;
            b|B) break ;;
            *) printf "  %s[!] Invalid.%s\n" "${RED}" "${RST}"; sleep 1 ;;
        esac
    done
}

submenu_naabu() {
    while true; do
        clear; banner; echo ""
        center_in_box "NAABU · ROOTLESS FAST PORT SCANNER"
        short_pink_line 32; echo ""
        printf "${PNK}╔══════════════════════════════════════════════════════════════╗${RST}\n"
        printf "${PNK}║${RST} ${CYN}SYNOPSIS:${RST} Naabu — fast port scanner that works WITHOUT root.  ${RST}\n"
        printf "${PNK}║${RST}          Nmap SYN scan needs root; Naabu uses connect() scan. ${RST}\n"
        printf "${PNK}║${RST}          Best rootless port scan option for Termux.            ${RST}\n"
        printf "${PNK}║${RST} ${CYN}USE:${RST} Enter IP or hostname. No sudo required.                ${RST}\n"
        printf "${PNK}║${RST} ${CYN}INSTALL:${RST} go install github.com/projectdiscovery/naabu/...   ${RST}\n"
        printf "${PNK}╚══════════════════════════════════════════════════════════════╝${RST}\n\n"
        printf "  ${GRN}[1]${RST}  Top 100 Ports          ${DESC}- naabu -top-ports 100${RST}\n"
        printf "  ${GRN}[2]${RST}  Top 1000 Ports         ${DESC}- naabu -top-ports 1000${RST}\n"
        printf "  ${GRN}[3]${RST}  Full Port Range        ${DESC}- naabu -p - (all 65535)${RST}\n"
        printf "  ${GRN}[4]${RST}  Custom Port Range      ${DESC}- naabu -p 80,443,8080-8090${RST}\n"
        printf "  ${GRN}[5]${RST}  With Service Detection ${DESC}- naabu + nmap sV on open ports${RST}\n"
        printf "  ${GRN}[6]${RST}  Full Auto Recon        ${DESC}- top 1000 + save + service detect${RST}\n"
        printf "  ${GRN}[I]${RST}  Install Module         ${DESC}- go install naabu${RST}\n"
        printf "  ${YLW}[B]${RST}  Back\n\n"
        printf "  %sChoose: %s" "${HOT}" "${RST}"; read -r SC
        local _NB="${HOME}/go/bin/naabu"; command -v naabu >/dev/null 2>&1 && _NB="naabu"
        case "$SC" in
            1) ! $NAABU_INSTALLED && { install_naabu; $NAABU_INSTALLED || continue; }
               run_web_tool "${_NB} -host TARGET_PLACEHOLDER -top-ports 100 -silent" "Naabu · Top 100" "yes" "naabu -host <target> -top-ports 100" ;;
            2) ! $NAABU_INSTALLED && { install_naabu; $NAABU_INSTALLED || continue; }
               run_web_tool "${_NB} -host TARGET_PLACEHOLDER -top-ports 1000 -silent" "Naabu · Top 1000" "yes" "naabu -top-ports 1000" ;;
            3) ! $NAABU_INSTALLED && { install_naabu; $NAABU_INSTALLED || continue; }
               run_web_tool "${_NB} -host TARGET_PLACEHOLDER -p - -silent" "Naabu · Full Scan" "yes" "naabu -p - (all ports)" ;;
            4) ! $NAABU_INSTALLED && { install_naabu; $NAABU_INSTALLED || continue; }
               printf "  %sEnter port range (e.g. 80,443,8080-8090): %s" "${HOT}" "${RST}"; read -r _pr
               run_web_tool "${_NB} -host TARGET_PLACEHOLDER -p ${_pr} -silent" "Naabu · Custom Ports" "yes" "naabu -p ${_pr}" ;;
            5) ! $NAABU_INSTALLED && { install_naabu; $NAABU_INSTALLED || continue; }
               run_web_tool "{ echo '=== PORT SCAN ==='; PORTS=\$(${_NB} -host TARGET_PLACEHOLDER -top-ports 1000 -silent 2>/dev/null | grep -oP ':\K[0-9]+' | tr '\n' ',' | sed 's/,\$//'); echo "Open: \$PORTS"; echo ''; echo '=== SERVICE DETECT ==='; [ -n "\$PORTS" ] && nmap -sV -p "\$PORTS" TARGET_PLACEHOLDER 2>/dev/null || echo 'No open ports found'; }" "Naabu · With Service Detect" "yes" "naabu + nmap -sV" ;;
            6) ! $NAABU_INSTALLED && { install_naabu; $NAABU_INSTALLED || continue; }
               run_web_tool "{ ${_NB} -host TARGET_PLACEHOLDER -top-ports 1000 -silent -o ${HOME}/storage/downloads/naabu_out.txt; echo '=== OPEN PORTS ==='; cat ${HOME}/storage/downloads/naabu_out.txt; }" "Naabu · Full Auto Recon" "yes" "naabu full auto" ;;
            i|I) install_naabu ;;
            b|B) break ;;
            *) printf "  %s[!] Invalid.%s\n" "${RED}" "${RST}"; sleep 1 ;;
        esac
    done
}

submenu_dnsx() {
    while true; do
        clear; banner; echo ""
        center_in_box "DNSX · BULK DNS RESOLUTION"
        short_pink_line 32; echo ""
        printf "${PNK}╔══════════════════════════════════════════════════════════════╗${RST}\n"
        printf "${PNK}║${RST} ${CYN}SYNOPSIS:${RST} DNSx — ultra-fast DNS resolver for A, AAAA, CNAME,  ${RST}\n"
        printf "${PNK}║${RST}          MX, NS, TXT records. Process domain lists at speed.  ${RST}\n"
        printf "${PNK}║${RST}          Perfect complement to subfinder/amass output.          ${RST}\n"
        printf "${PNK}║${RST} ${CYN}USE:${RST} Enter domain or pipe list. Rootless.                   ${RST}\n"
        printf "${PNK}║${RST} ${CYN}INSTALL:${RST} go install github.com/projectdiscovery/dnsx/...    ${RST}\n"
        printf "${PNK}╚══════════════════════════════════════════════════════════════╝${RST}\n\n"
        printf "  ${GRN}[1]${RST}  A Record Lookup        ${DESC}- dnsx -a${RST}\n"
        printf "  ${GRN}[2]${RST}  All Record Types       ${DESC}- dnsx -a -aaaa -cname -mx -ns${RST}\n"
        printf "  ${GRN}[3]${RST}  MX Records             ${DESC}- dnsx -mx${RST}\n"
        printf "  ${GRN}[4]${RST}  TXT / SPF              ${DESC}- dnsx -txt${RST}\n"
        printf "  ${GRN}[5]${RST}  Resolve + Save         ${DESC}- A records to downloads/dnsx_out.txt${RST}\n"
        printf "  ${GRN}[6]${RST}  Full Auto Recon        ${DESC}- all record types + save${RST}\n"
        printf "  ${GRN}[I]${RST}  Install Module         ${DESC}- go install dnsx${RST}\n"
        printf "  ${YLW}[B]${RST}  Back\n\n"
        printf "  %sChoose: %s" "${HOT}" "${RST}"; read -r SC
        local _DX="${HOME}/go/bin/dnsx"; command -v dnsx >/dev/null 2>&1 && _DX="dnsx"
        case "$SC" in
            1) ! $DNSX_INSTALLED && { install_dnsx_tool; $DNSX_INSTALLED || continue; }
               run_web_tool "echo TARGET_PLACEHOLDER | ${_DX} -a -silent" "DNSx · A Record" "yes" "echo <domain> | dnsx -a" ;;
            2) ! $DNSX_INSTALLED && { install_dnsx_tool; $DNSX_INSTALLED || continue; }
               run_web_tool "echo TARGET_PLACEHOLDER | ${_DX} -a -aaaa -cname -mx -ns -silent" "DNSx · All Records" "yes" "dnsx all records" ;;
            3) ! $DNSX_INSTALLED && { install_dnsx_tool; $DNSX_INSTALLED || continue; }
               run_web_tool "echo TARGET_PLACEHOLDER | ${_DX} -mx -silent" "DNSx · MX Records" "yes" "dnsx -mx" ;;
            4) ! $DNSX_INSTALLED && { install_dnsx_tool; $DNSX_INSTALLED || continue; }
               run_web_tool "echo TARGET_PLACEHOLDER | ${_DX} -txt -silent" "DNSx · TXT/SPF" "yes" "dnsx -txt" ;;
            5) ! $DNSX_INSTALLED && { install_dnsx_tool; $DNSX_INSTALLED || continue; }
               run_web_tool "echo TARGET_PLACEHOLDER | ${_DX} -a -silent -o ${HOME}/storage/downloads/dnsx_out.txt && cat ${HOME}/storage/downloads/dnsx_out.txt" "DNSx · Save Output" "yes" "dnsx -a -o out.txt" ;;
            6) ! $DNSX_INSTALLED && { install_dnsx_tool; $DNSX_INSTALLED || continue; }
               run_web_tool "{ echo '=== A ==='; echo TARGET_PLACEHOLDER | ${_DX} -a -silent; echo ''; echo '=== CNAME ==='; echo TARGET_PLACEHOLDER | ${_DX} -cname -silent; echo ''; echo '=== MX ==='; echo TARGET_PLACEHOLDER | ${_DX} -mx -silent; echo ''; echo '=== TXT ==='; echo TARGET_PLACEHOLDER | ${_DX} -txt -silent; }" "DNSx · Full Auto Recon" "yes" "dnsx all types" ;;
            i|I) install_dnsx_tool ;;
            b|B) break ;;
            *) printf "  %s[!] Invalid.%s\n" "${RED}" "${RST}"; sleep 1 ;;
        esac
    done
}

submenu_massdns() {
    while true; do
        clear; banner; echo ""
        center_in_box "MASSDNS · BULK DNS RESOLVER"
        short_pink_line 32; echo ""
        printf "${PNK}╔══════════════════════════════════════════════════════════════╗${RST}\n"
        printf "${PNK}║${RST} ${CYN}SYNOPSIS:${RST} MassDNS — resolve massive domain lists at 1000x    ${RST}\n"
        printf "${PNK}║${RST}          the speed of dig loops. Handles millions of domains.  ${RST}\n"
        printf "${PNK}║${RST}          Best used to validate subfinder/amass output lists.    ${RST}\n"
        printf "${PNK}║${RST} ${CYN}USE:${RST} Provide domain list file or single domain.             ${RST}\n"
        printf "${PNK}║${RST} ${CYN}INSTALL:${RST} pkg install massdns                                ${RST}\n"
        printf "${PNK}╚══════════════════════════════════════════════════════════════╝${RST}\n\n"
        printf "  ${GRN}[1]${RST}  Resolve Single Domain  ${DESC}- massdns single target${RST}\n"
        printf "  ${GRN}[2]${RST}  Resolve From File      ${DESC}- provide path to domain list${RST}\n"
        printf "  ${GRN}[3]${RST}  A Records Only         ${DESC}- filter A record results${RST}\n"
        printf "  ${GRN}[4]${RST}  Full Auto Recon        ${DESC}- resolve + save + filter${RST}\n"
        printf "  ${GRN}[I]${RST}  Install Module         ${DESC}- pkg install massdns${RST}\n"
        printf "  ${YLW}[B]${RST}  Back\n\n"
        printf "  %sChoose: %s" "${HOT}" "${RST}"; read -r SC
        local _RS="${TMPDIR:-/tmp}/resolvers.txt"
        case "$SC" in
            1) ! $MASSDNS_INSTALLED && { install_massdns_tool; $MASSDNS_INSTALLED || continue; }
               run_web_tool "{ curl -sL https://raw.githubusercontent.com/janmasarik/resolvers/master/resolvers.txt -o ${_RS} 2>/dev/null; echo TARGET_PLACEHOLDER | massdns -r ${_RS} -t A -o S 2>/dev/null; }" "MassDNS · Single Domain" "yes" "massdns single" ;;
            2) ! $MASSDNS_INSTALLED && { install_massdns_tool; $MASSDNS_INSTALLED || continue; }
               printf "  %sEnter path to domain list file: %s" "${HOT}" "${RST}"; read -r _fl
               [[ -f "$_fl" ]] || { printf "  %s[!] File not found.%s\n" "${RED}" "${RST}"; sleep 1; continue; }
               run_web_tool "{ curl -sL https://raw.githubusercontent.com/janmasarik/resolvers/master/resolvers.txt -o ${_RS} 2>/dev/null; massdns -r ${_RS} -t A -o S ${_fl} 2>/dev/null; }" "MassDNS · From File" "no" "massdns from file" ;;
            3) ! $MASSDNS_INSTALLED && { install_massdns_tool; $MASSDNS_INSTALLED || continue; }
               run_web_tool "{ curl -sL https://raw.githubusercontent.com/janmasarik/resolvers/master/resolvers.txt -o ${_RS} 2>/dev/null; echo TARGET_PLACEHOLDER | massdns -r ${_RS} -t A -o S 2>/dev/null | grep ' A '; }" "MassDNS · A Records Only" "yes" "massdns A only" ;;
            4) ! $MASSDNS_INSTALLED && { install_massdns_tool; $MASSDNS_INSTALLED || continue; }
               run_web_tool "{ curl -sL https://raw.githubusercontent.com/janmasarik/resolvers/master/resolvers.txt -o ${_RS} 2>/dev/null; echo TARGET_PLACEHOLDER | massdns -r ${_RS} -t A -o S 2>/dev/null | tee ${HOME}/storage/downloads/massdns_out.txt; echo ''; wc -l ${HOME}/storage/downloads/massdns_out.txt 2>/dev/null | xargs echo 'Resolved:'; }" "MassDNS · Full Auto Recon" "yes" "massdns full" ;;
            i|I) install_massdns_tool ;;
            b|B) break ;;
            *) printf "  %s[!] Invalid.%s\n" "${RED}" "${RST}"; sleep 1 ;;
        esac
    done
}

submenu_waybackurls() {
    while true; do
        clear; banner; echo ""
        center_in_box "WAYBACKURLS · HISTORICAL URL EXTRACTION"
        short_pink_line 32; echo ""
        printf "${PNK}╔══════════════════════════════════════════════════════════════╗${RST}\n"
        printf "${PNK}║${RST} ${CYN}SYNOPSIS:${RST} Waybackurls — pull historical URLs from Wayback     ${RST}\n"
        printf "${PNK}║${RST}          Machine archive.org. Find forgotten endpoints, old     ${RST}\n"
        printf "${PNK}║${RST}          params, hidden APIs, backup files. Pure passive.       ${RST}\n"
        printf "${PNK}║${RST} ${CYN}USE:${RST} Enter domain (e.g. example.com).                        ${RST}\n"
        printf "${PNK}║${RST} ${CYN}INSTALL:${RST} go install github.com/tomnomnom/waybackurls@latest   ${RST}\n"
        printf "${PNK}╚══════════════════════════════════════════════════════════════╝${RST}\n\n"
        printf "  ${GRN}[1]${RST}  All Historical URLs    ${DESC}- waybackurls <domain>${RST}\n"
        printf "  ${GRN}[2]${RST}  Filter Parameters      ${DESC}- URLs with ?param= only${RST}\n"
        printf "  ${GRN}[3]${RST}  Filter JS Files        ${DESC}- .js endpoint extraction${RST}\n"
        printf "  ${GRN}[4]${RST}  Filter Juicy Paths     ${DESC}- admin/backup/config/api paths${RST}\n"
        printf "  ${GRN}[5]${RST}  Save + Count           ${DESC}- all URLs to downloads/wayback_out.txt${RST}\n"
        printf "  ${GRN}[6]${RST}  Full Auto Recon        ${DESC}- all + filter params + save${RST}\n"
        printf "  ${GRN}[I]${RST}  Install Module         ${DESC}- go install waybackurls${RST}\n"
        printf "  ${YLW}[B]${RST}  Back\n\n"
        printf "  %sChoose: %s" "${HOT}" "${RST}"; read -r SC
        local _WB="${HOME}/go/bin/waybackurls"; command -v waybackurls >/dev/null 2>&1 && _WB="waybackurls"
        case "$SC" in
            1) ! $WAYBACKURLS_INSTALLED && { install_waybackurls; $WAYBACKURLS_INSTALLED || continue; }
               run_web_tool "echo TARGET_PLACEHOLDER | ${_WB}" "Waybackurls · All URLs" "yes" "echo <domain> | waybackurls" ;;
            2) ! $WAYBACKURLS_INSTALLED && { install_waybackurls; $WAYBACKURLS_INSTALLED || continue; }
               run_web_tool "echo TARGET_PLACEHOLDER | ${_WB} | grep '?'" "Waybackurls · Parameters" "yes" "waybackurls | grep ?" ;;
            3) ! $WAYBACKURLS_INSTALLED && { install_waybackurls; $WAYBACKURLS_INSTALLED || continue; }
               run_web_tool "echo TARGET_PLACEHOLDER | ${_WB} | grep '\.js'" "Waybackurls · JS Files" "yes" "waybackurls | grep .js" ;;
            4) ! $WAYBACKURLS_INSTALLED && { install_waybackurls; $WAYBACKURLS_INSTALLED || continue; }
               run_web_tool "echo TARGET_PLACEHOLDER | ${_WB} | grep -Ei 'admin|backup|config|api|secret|token|key|passwd|db'" "Waybackurls · Juicy Paths" "yes" "waybackurls juicy filter" ;;
            5) ! $WAYBACKURLS_INSTALLED && { install_waybackurls; $WAYBACKURLS_INSTALLED || continue; }
               run_web_tool "echo TARGET_PLACEHOLDER | ${_WB} | tee ${HOME}/storage/downloads/wayback_out.txt; wc -l ${HOME}/storage/downloads/wayback_out.txt | xargs echo 'Total URLs:'" "Waybackurls · Save+Count" "yes" "waybackurls save" ;;
            6) ! $WAYBACKURLS_INSTALLED && { install_waybackurls; $WAYBACKURLS_INSTALLED || continue; }
               run_web_tool "{ echo '=== ALL URLS ==='; echo TARGET_PLACEHOLDER | ${_WB} | tee ${HOME}/storage/downloads/wayback_out.txt; echo ''; echo '=== PARAMS ==='; grep '?' ${HOME}/storage/downloads/wayback_out.txt | head -20; echo ''; echo '=== JUICY ==='; grep -Ei 'admin|backup|api|secret|key|config' ${HOME}/storage/downloads/wayback_out.txt | head -20; echo ''; wc -l ${HOME}/storage/downloads/wayback_out.txt | xargs echo 'Total:'; }" "Waybackurls · Full Auto Recon" "yes" "waybackurls full" ;;
            i|I) install_waybackurls ;;
            b|B) break ;;
            *) printf "  %s[!] Invalid.%s\n" "${RED}" "${RST}"; sleep 1 ;;
        esac
    done
}

submenu_gau() {
    while true; do
        clear; banner; echo ""
        center_in_box "GAU · GET ALL URLS FROM ARCHIVES"
        short_pink_line 32; echo ""
        printf "${PNK}╔══════════════════════════════════════════════════════════════╗${RST}\n"
        printf "${PNK}║${RST} ${CYN}SYNOPSIS:${RST} GAU — Get All URLs from Wayback, CommonCrawl,       ${RST}\n"
        printf "${PNK}║${RST}          AlienVault OTX, URLScan. More comprehensive than      ${RST}\n"
        printf "${PNK}║${RST}          waybackurls alone. Best for passive URL harvesting.    ${RST}\n"
        printf "${PNK}║${RST} ${CYN}USE:${RST} Enter domain (e.g. example.com).                        ${RST}\n"
        printf "${PNK}║${RST} ${CYN}INSTALL:${RST} go install github.com/lc/gau/v2/cmd/gau@latest       ${RST}\n"
        printf "${PNK}╚══════════════════════════════════════════════════════════════╝${RST}\n\n"
        printf "  ${GRN}[1]${RST}  All URLs               ${DESC}- gau <domain>${RST}\n"
        printf "  ${GRN}[2]${RST}  Wayback Only           ${DESC}- gau --providers wayback${RST}\n"
        printf "  ${GRN}[3]${RST}  CommonCrawl Only       ${DESC}- gau --providers commoncrawl${RST}\n"
        printf "  ${GRN}[4]${RST}  Filter Parameters      ${DESC}- gau | grep ? (param URLs)${RST}\n"
        printf "  ${GRN}[5]${RST}  Filter Juicy Paths     ${DESC}- api/admin/token/secret paths${RST}\n"
        printf "  ${GRN}[6]${RST}  Save + Count           ${DESC}- all URLs to downloads/gau_out.txt${RST}\n"
        printf "  ${GRN}[7]${RST}  Full Auto Recon        ${DESC}- all providers + filter + save${RST}\n"
        printf "  ${GRN}[I]${RST}  Install Module         ${DESC}- go install gau${RST}\n"
        printf "  ${YLW}[B]${RST}  Back\n\n"
        printf "  %sChoose: %s" "${HOT}" "${RST}"; read -r SC
        local _GA="${HOME}/go/bin/gau"; command -v gau >/dev/null 2>&1 && _GA="gau"
        case "$SC" in
            1) ! $GAU_INSTALLED && { install_gau_tool; $GAU_INSTALLED || continue; }
               run_web_tool "${_GA} TARGET_PLACEHOLDER" "GAU · All URLs" "yes" "gau <domain>" ;;
            2) ! $GAU_INSTALLED && { install_gau_tool; $GAU_INSTALLED || continue; }
               run_web_tool "${_GA} --providers wayback TARGET_PLACEHOLDER" "GAU · Wayback Only" "yes" "gau --providers wayback" ;;
            3) ! $GAU_INSTALLED && { install_gau_tool; $GAU_INSTALLED || continue; }
               run_web_tool "${_GA} --providers commoncrawl TARGET_PLACEHOLDER" "GAU · CommonCrawl Only" "yes" "gau --providers commoncrawl" ;;
            4) ! $GAU_INSTALLED && { install_gau_tool; $GAU_INSTALLED || continue; }
               run_web_tool "${_GA} TARGET_PLACEHOLDER | grep '?'" "GAU · Filter Params" "yes" "gau | grep ?" ;;
            5) ! $GAU_INSTALLED && { install_gau_tool; $GAU_INSTALLED || continue; }
               run_web_tool "${_GA} TARGET_PLACEHOLDER | grep -Ei 'admin|api|token|secret|key|config|backup|passwd|db'" "GAU · Juicy Paths" "yes" "gau juicy filter" ;;
            6) ! $GAU_INSTALLED && { install_gau_tool; $GAU_INSTALLED || continue; }
               run_web_tool "${_GA} TARGET_PLACEHOLDER | tee ${HOME}/storage/downloads/gau_out.txt; wc -l ${HOME}/storage/downloads/gau_out.txt | xargs echo 'Total URLs:'" "GAU · Save+Count" "yes" "gau save" ;;
            7) ! $GAU_INSTALLED && { install_gau_tool; $GAU_INSTALLED || continue; }
               run_web_tool "{ echo '=== ALL PROVIDERS ==='; ${_GA} TARGET_PLACEHOLDER | tee ${HOME}/storage/downloads/gau_out.txt; echo ''; echo '=== PARAMS ==='; grep '?' ${HOME}/storage/downloads/gau_out.txt | head -20; echo ''; echo '=== JUICY ==='; grep -Ei 'admin|api|token|secret|key|config' ${HOME}/storage/downloads/gau_out.txt | head -20; echo ''; wc -l ${HOME}/storage/downloads/gau_out.txt | xargs echo 'Total:'; }" "GAU · Full Auto Recon" "yes" "gau full" ;;
            i|I) install_gau_tool ;;
            b|B) break ;;
            *) printf "  %s[!] Invalid.%s\n" "${RED}" "${RST}"; sleep 1 ;;
        esac
    done
}

submenu_arjun() {
    while true; do
        clear; banner; echo ""
        center_in_box "ARJUN · HIDDEN PARAMETER DISCOVERY"
        short_pink_line 36; echo ""
        printf "${PNK}╔══════════════════════════════════════════════════════════════╗${RST}\n"
        printf "${PNK}║${RST} ${CYN}SYNOPSIS:${RST} Arjun — finds hidden GET/POST/JSON/XML parameters     ${RST}\n"
        printf "${PNK}║${RST}          on web targets. Tests 10,000+ param names silently.  ${RST}\n"
        printf "${PNK}║${RST}          Essential step before SQLMap, FFUF, or fuzzing runs. ${RST}\n"
        printf "${PNK}║${RST} ${CYN}USE:${RST} Enter full URL (e.g. https://example.com/page).           ${RST}\n"
        printf "${PNK}║${RST} ${CYN}INSTALL:${RST} pip install arjun                                      ${RST}\n"
        printf "${PNK}╚══════════════════════════════════════════════════════════════╝${RST}\n\n"
        printf "  ${GRN}[1]${RST}  GET Parameter Scan     ${DESC}- arjun -u <url> -m GET${RST}\n"
        printf "  ${GRN}[2]${RST}  POST Parameter Scan    ${DESC}- arjun -u <url> -m POST${RST}\n"
        printf "  ${GRN}[3]${RST}  JSON Parameter Scan    ${DESC}- arjun -u <url> -m JSON${RST}\n"
        printf "  ${GRN}[4]${RST}  XML Parameter Scan     ${DESC}- arjun -u <url> -m XML${RST}\n"
        printf "  ${GRN}[5]${RST}  All Methods            ${DESC}- GET + POST + JSON + XML combined${RST}\n"
        printf "  ${GRN}[6]${RST}  Quiet + Save           ${DESC}- results to downloads/arjun_out.txt${RST}\n"
        printf "  ${GRN}[7]${RST}  Full Auto Recon        ${DESC}- all methods + save + count${RST}\n"
        printf "  ${GRN}[I]${RST}  Install Module         ${DESC}- pip install arjun${RST}\n"
        printf "  ${YLW}[B]${RST}  Back\n\n"
        printf "  %sChoose: %s" "${HOT}" "${RST}"; read -r SC
        case "$SC" in
            1) ! $ARJUN_INSTALLED && { install_arjun; $ARJUN_INSTALLED || continue; }
               run_web_tool "arjun -u TARGET_PLACEHOLDER -m GET" "Arjun · GET Params" "yes" "arjun -u <url> -m GET" ;;
            2) ! $ARJUN_INSTALLED && { install_arjun; $ARJUN_INSTALLED || continue; }
               run_web_tool "arjun -u TARGET_PLACEHOLDER -m POST" "Arjun · POST Params" "yes" "arjun -u <url> -m POST" ;;
            3) ! $ARJUN_INSTALLED && { install_arjun; $ARJUN_INSTALLED || continue; }
               run_web_tool "arjun -u TARGET_PLACEHOLDER -m JSON" "Arjun · JSON Params" "yes" "arjun -u <url> -m JSON" ;;
            4) ! $ARJUN_INSTALLED && { install_arjun; $ARJUN_INSTALLED || continue; }
               run_web_tool "arjun -u TARGET_PLACEHOLDER -m XML" "Arjun · XML Params" "yes" "arjun -u <url> -m XML" ;;
            5) ! $ARJUN_INSTALLED && { install_arjun; $ARJUN_INSTALLED || continue; }
               run_web_tool "{ echo '=== GET ==='; arjun -u TARGET_PLACEHOLDER -m GET; echo ''; echo '=== POST ==='; arjun -u TARGET_PLACEHOLDER -m POST; echo ''; echo '=== JSON ==='; arjun -u TARGET_PLACEHOLDER -m JSON; }" "Arjun · All Methods" "yes" "arjun all methods" ;;
            6) ! $ARJUN_INSTALLED && { install_arjun; $ARJUN_INSTALLED || continue; }
               run_web_tool "arjun -u TARGET_PLACEHOLDER -oT ${HOME}/storage/downloads/arjun_out.txt 2>/dev/null; cat ${HOME}/storage/downloads/arjun_out.txt 2>/dev/null" "Arjun · Save Output" "yes" "arjun -u <url> -oT out.txt" ;;
            7) ! $ARJUN_INSTALLED && { install_arjun; $ARJUN_INSTALLED || continue; }
               run_web_tool "{ echo '=== GET ==='; arjun -u TARGET_PLACEHOLDER -m GET; echo ''; echo '=== POST ==='; arjun -u TARGET_PLACEHOLDER -m POST; echo ''; echo '=== JSON ==='; arjun -u TARGET_PLACEHOLDER -m JSON; echo ''; echo '=== XML ==='; arjun -u TARGET_PLACEHOLDER -m XML; echo ''; echo '=== SAVING ==='; arjun -u TARGET_PLACEHOLDER -oT ${HOME}/storage/downloads/arjun_out.txt 2>/dev/null; echo 'Saved to downloads/arjun_out.txt'; }" "Arjun · Full Auto Recon" "yes" "arjun full" ;;
            i|I) install_arjun ;;
            b|B) break ;;
            *) printf "  %s[!] Invalid.%s\n" "${RED}" "${RST}"; sleep 1 ;;
        esac
    done
}

submenu_optiva() {
    while true; do
        clear; banner; echo ""
        center_in_box "OPTIVA FRAMEWORK · MULTI-MODULE TOOLKIT"
        short_pink_line 38; echo ""
        printf "${PNK}╔══════════════════════════════════════════════════════════════╗${RST}\n"
        printf "${PNK}║${RST} ${CYN}SYNOPSIS:${RST} Optiva — Python2 multi-module offensive framework.   ${RST}\n"
        printf "${PNK}║${RST}          Web scanners, recon tools, and payload modules.      ${RST}\n"
        printf "${PNK}║${RST}          Authorised use only. Legal environments strictly.    ${RST}\n"
        printf "${PNK}║${RST} ${CYN}USE:${RST} Launch interactive console. Use on owned/permitted labs.  ${RST}\n"
        printf "${PNK}║${RST} ${CYN}INSTALL:${RST} git clone + bash installer.sh (auto-handled below)    ${RST}\n"
        printf "${PNK}╚══════════════════════════════════════════════════════════════╝${RST}\n\n"
        printf "  ${GRN}[1]${RST}  Launch Optiva          ${DESC}- python2 optiva.py (interactive)${RST}\n"
        printf "  ${GRN}[2]${RST}  Update Framework       ${DESC}- git pull latest version${RST}\n"
        printf "  ${GRN}[3]${RST}  Show Module List       ${DESC}- list all available modules${RST}\n"
        printf "  ${GRN}[4]${RST}  Check Install          ${DESC}- verify Optiva is ready${RST}\n"
        printf "  ${GRN}[I]${RST}  Install Framework      ${DESC}- clone + installer + pip2 deps${RST}\n"
        printf "  ${YLW}[B]${RST}  Back\n\n"
        printf "  %sChoose: %s" "${HOT}" "${RST}"; read -r SC
        local _OPT="${HOME}/Optiva-Framework"
        case "$SC" in
            1) ! $OPTIVA_INSTALLED && { install_optiva; $OPTIVA_INSTALLED || continue; }
               if [[ -d "$_OPT" ]]; then
                   printf "\n  %s[*] Launching Optiva Framework...%s\n\n" "${CYN}" "${RST}"
                   cd "$_OPT" && python2 optiva.py; cd "${HOME}"
               else
                   printf "  %s[!] Optiva not found. Run Install first.%s\n" "${RED}" "${RST}"; sleep 2
               fi ;;
            2) ! $OPTIVA_INSTALLED && { install_optiva; $OPTIVA_INSTALLED || continue; }
               if [[ -d "$_OPT" ]]; then
                   printf "\n  %s[*] Updating Optiva...%s\n\n" "${CYN}" "${RST}"
                   cd "$_OPT" && git pull 2>&1; cd "${HOME}"
               else
                   printf "  %s[!] Optiva not found.%s\n" "${RED}" "${RST}"; sleep 2
               fi ;;
            3) ! $OPTIVA_INSTALLED && { install_optiva; $OPTIVA_INSTALLED || continue; }
               if [[ -d "$_OPT" ]]; then
                   printf "\n  %s[*] Optiva Modules:%s\n\n" "${CYN}" "${RST}"
                   ls "${_OPT}/modules/" 2>/dev/null || printf "  %s[!] No modules dir found.%s\n" "${YLW}" "${RST}"
               fi ;;
            4) if [[ -d "$_OPT" ]]; then
                   printf "\n  %s[+] Optiva found at: %s%s\n" "${GRN}" "$_OPT" "${RST}"
                   python2 --version 2>/dev/null && printf "  %s[+] Python2 OK%s\n" "${GRN}" "${RST}" \
                       || printf "  %s[!] Python2 missing — run Install%s\n" "${YLW}" "${RST}"
               else
                   printf "\n  %s[!] Optiva not installed. Press I to install.%s\n" "${RED}" "${RST}"
               fi ;;
            i|I) install_optiva ;;
            b|B) break ;;
            *) printf "  %s[!] Invalid.%s\n" "${RED}" "${RST}"; sleep 1 ;;
        esac
        echo ""; printf "  %sPress ENTER...%s" "${HOT}" "${RST}"; read -r _
    done
}

submenu_hiddenurl() {
    while true; do
        clear; banner; echo ""
        center_in_box "HIDDENURL · OBSCURED PATH DISCOVERY"
        short_pink_line 36; echo ""
        printf "${PNK}╔══════════════════════════════════════════════════════════════╗${RST}\n"
        printf "${PNK}║${RST} ${CYN}SYNOPSIS:${RST} HiddenURL — discovers obscured, cloaked, and hidden   ${RST}\n"
        printf "${PNK}║${RST}          URL paths that standard crawlers miss. Bash-based.  ${RST}\n"
        printf "${PNK}║${RST}          Pair with GAU and Katana for maximum URL coverage.  ${RST}\n"
        printf "${PNK}║${RST} ${CYN}USE:${RST} Enter domain or full URL when prompted.                   ${RST}\n"
        printf "${PNK}║${RST} ${CYN}INSTALL:${RST} git clone + chmod (auto-handled below)                ${RST}\n"
        printf "${PNK}╚══════════════════════════════════════════════════════════════╝${RST}\n\n"
        printf "  ${GRN}[1]${RST}  Launch HiddenURL       ${DESC}- interactive bash session${RST}\n"
        printf "  ${GRN}[2]${RST}  Update Tool            ${DESC}- git pull latest version${RST}\n"
        printf "  ${GRN}[3]${RST}  Check Install          ${DESC}- verify HiddenURL is ready${RST}\n"
        printf "  ${GRN}[I]${RST}  Install Tool           ${DESC}- git clone + chmod${RST}\n"
        printf "  ${YLW}[B]${RST}  Back\n\n"
        printf "  %sChoose: %s" "${HOT}" "${RST}"; read -r SC
        local _HU="${HOME}/HiddenURL"
        case "$SC" in
            1) ! $HIDDENURL_INSTALLED && { install_hiddenurl; $HIDDENURL_INSTALLED || continue; }
               if [[ -d "$_HU" ]]; then
                   printf "\n  %s[*] Launching HiddenURL...%s\n\n" "${CYN}" "${RST}"
                   cd "$_HU" && bash HiddenURL; cd "${HOME}"
               else
                   printf "  %s[!] HiddenURL not found. Run Install first.%s\n" "${RED}" "${RST}"; sleep 2
               fi ;;
            2) ! $HIDDENURL_INSTALLED && { install_hiddenurl; $HIDDENURL_INSTALLED || continue; }
               if [[ -d "$_HU" ]]; then
                   printf "\n  %s[*] Updating HiddenURL...%s\n\n" "${CYN}" "${RST}"
                   cd "$_HU" && git pull 2>&1; cd "${HOME}"
               else
                   printf "  %s[!] HiddenURL not found.%s\n" "${RED}" "${RST}"; sleep 2
               fi ;;
            3) if [[ -d "$_HU" ]]; then
                   printf "\n  %s[+] HiddenURL found at: %s%s\n" "${GRN}" "$_HU" "${RST}"
                   printf "  %s[+] Launch: cd ~/HiddenURL && bash HiddenURL%s\n" "${CYN}" "${RST}"
               else
                   printf "\n  %s[!] HiddenURL not installed. Press I to install.%s\n" "${RED}" "${RST}"
               fi ;;
            i|I) install_hiddenurl ;;
            b|B) break ;;
            *) printf "  %s[!] Invalid.%s\n" "${RED}" "${RST}"; sleep 1 ;;
        esac
        echo ""; printf "  %sPress ENTER...%s" "${HOT}" "${RST}"; read -r _
    done
}

submenu_dalfox() {
    while true; do
        clear; banner; echo ""
        center_in_box "DALFOX · XSS SCANNER + PoC GENERATOR"
        short_pink_line 32; echo ""
        printf "${PNK}╔══════════════════════════════════════════════════════════════╗${RST}\n"
        printf "${PNK}║${RST} ${CYN}SYNOPSIS:${RST} Dalfox — XSS scanner with blind XSS + PoC output. ${RST}\n"
        printf "${PNK}║${RST} ${CYN}USE:${RST} Enter target URL or file of URLs. Go binary, rootless. ${RST}\n"
        printf "${PNK}║${RST} ${CYN}INSTALL:${RST} go install github.com/hahwul/dalfox/v2@latest      ${RST}\n"
        printf "${PNK}╚══════════════════════════════════════════════════════════════╝${RST}\n\n"
        printf "  ${GRN}[1]${RST}  Scan URL               ${DESC}- dalfox url <target>${RST}\n"
        printf "  ${GRN}[2]${RST}  PoC Only               ${DESC}- dalfox url --only-poc${RST}\n"
        printf "  ${GRN}[3]${RST}  Scan URL File          ${DESC}- dalfox file <urls.txt>${RST}\n"
        printf "  ${GRN}[4]${RST}  Blind XSS Mode         ${DESC}- dalfox url --blind <callback>${RST}\n"
        printf "  ${GRN}[5]${RST}  Save Output            ${DESC}- → downloads/dalfox_out.txt${RST}\n"
        printf "  ${GRN}[I]${RST}  Install                ${DESC}- go install dalfox${RST}\n"
        printf "  ${YLW}[B]${RST}  Back\n\n"
        printf "  %sChoose: %s" "${HOT}" "${RST}"; read -r SC
        local _DF="${HOME}/go/bin/dalfox"; command -v dalfox >/dev/null 2>&1 && _DF="dalfox"
        case "$SC" in
            1) ! $DALFOX_INSTALLED && { install_dalfox; $DALFOX_INSTALLED || continue; }
               run_web_tool "${_DF} url TARGET_PLACEHOLDER --silent" "Dalfox · Scan" "yes" "dalfox url <target>" ;;
            2) ! $DALFOX_INSTALLED && { install_dalfox; $DALFOX_INSTALLED || continue; }
               run_web_tool "${_DF} url TARGET_PLACEHOLDER --only-poc --silent" "Dalfox · PoC Only" "yes" "dalfox --only-poc" ;;
            3) ! $DALFOX_INSTALLED && { install_dalfox; $DALFOX_INSTALLED || continue; }
               printf "  %sFile path: %s" "${HOT}" "${RST}"; read -r FPATH
               [ -f "$FPATH" ] && ${_DF} file "$FPATH" --silent || printf "  %s[!] Not found%s\n" "${RED}" "${RST}"
               printf "  %sPress ENTER...%s" "${HOT}" "${RST}"; read -r _ ;;
            4) ! $DALFOX_INSTALLED && { install_dalfox; $DALFOX_INSTALLED || continue; }
               printf "  %sBlind callback URL: %s" "${HOT}" "${RST}"; read -r CB
               run_web_tool "${_DF} url TARGET_PLACEHOLDER --blind ${CB} --silent" "Dalfox · Blind XSS" "yes" "dalfox blind" ;;
            5) ! $DALFOX_INSTALLED && { install_dalfox; $DALFOX_INSTALLED || continue; }
               run_web_tool "${_DF} url TARGET_PLACEHOLDER --silent -o ${HOME}/storage/downloads/dalfox_out.txt && cat ${HOME}/storage/downloads/dalfox_out.txt" "Dalfox · Save" "yes" "dalfox + save" ;;
            i|I) install_dalfox ;;
            b|B) break ;;
            *) printf "  %s[!] Invalid.%s\n" "${RED}" "${RST}"; sleep 1 ;;
        esac
    done
}
submenu_kxss() {
    while true; do
        clear; banner; echo ""
        center_in_box "KXSS · REFLECTED XSS PARAMETER FINDER"
        short_pink_line 32; echo ""
        printf "${PNK}╔══════════════════════════════════════════════════════════════╗${RST}\n"
        printf "${PNK}║${RST} ${CYN}SYNOPSIS:${RST} KXSS — pipe URLs to find reflected parameters.    ${RST}\n"
        printf "${PNK}║${RST} ${CYN}USE:${RST} Best piped from gau/waybackurls. Go binary, rootless.  ${RST}\n"
        printf "${PNK}║${RST} ${CYN}INSTALL:${RST} go install github.com/Emoe/kxss@latest             ${RST}\n"
        printf "${PNK}╚══════════════════════════════════════════════════════════════╝${RST}\n\n"
        printf "  ${GRN}[1]${RST}  Scan URL File          ${DESC}- cat urls.txt | kxss${RST}\n"
        printf "  ${GRN}[2]${RST}  Single URL             ${DESC}- echo <url> | kxss${RST}\n"
        printf "  ${GRN}[3]${RST}  Save Reflected Params  ${DESC}- → downloads/kxss_out.txt${RST}\n"
        printf "  ${GRN}[I]${RST}  Install                ${DESC}- go install kxss${RST}\n"
        printf "  ${YLW}[B]${RST}  Back\n\n"
        printf "  %sChoose: %s" "${HOT}" "${RST}"; read -r SC
        local _KX="${HOME}/go/bin/kxss"; command -v kxss >/dev/null 2>&1 && _KX="kxss"
        case "$SC" in
            1) ! $KXSS_INSTALLED && { install_kxss; $KXSS_INSTALLED || continue; }
               printf "  %sURL file path: %s" "${HOT}" "${RST}"; read -r FPATH
               [ -f "$FPATH" ] && cat "$FPATH" | ${_KX} || printf "  %s[!] Not found%s\n" "${RED}" "${RST}"
               printf "  %sPress ENTER...%s" "${HOT}" "${RST}"; read -r _ ;;
            2) ! $KXSS_INSTALLED && { install_kxss; $KXSS_INSTALLED || continue; }
               run_web_tool "echo TARGET_PLACEHOLDER | ${_KX}" "KXSS · Single" "yes" "echo <url> | kxss" ;;
            3) ! $KXSS_INSTALLED && { install_kxss; $KXSS_INSTALLED || continue; }
               printf "  %sURL file path: %s" "${HOT}" "${RST}"; read -r FPATH
               [ -f "$FPATH" ] && cat "$FPATH" | ${_KX} | tee "${HOME}/storage/downloads/kxss_out.txt" \
                   && printf "  %s[+] Saved%s\n" "${GRN}" "${RST}" \
                   || printf "  %s[!] Not found%s\n" "${RED}" "${RST}"
               printf "  %sPress ENTER...%s" "${HOT}" "${RST}"; read -r _ ;;
            i|I) install_kxss ;;
            b|B) break ;;
            *) printf "  %s[!] Invalid.%s\n" "${RED}" "${RST}"; sleep 1 ;;
        esac
    done
}
submenu_gf() {
    while true; do
        clear; banner; echo ""
        center_in_box "GF PATTERNS · GREP URL FILTER"
        short_pink_line 32; echo ""
        printf "${PNK}╔══════════════════════════════════════════════════════════════╗${RST}\n"
        printf "${PNK}║${RST} ${CYN}SYNOPSIS:${RST} GF — grep wrapper filtering URLs by vuln class.   ${RST}\n"
        printf "${PNK}║${RST}          Patterns: xss sqli lfi ssrf idor rce redirect.       ${RST}\n"
        printf "${PNK}║${RST} ${CYN}USE:${RST} Pipe URL file. Patterns stored in ~/.gf/               ${RST}\n"
        printf "${PNK}║${RST} ${CYN}INSTALL:${RST} go install github.com/tomnomnom/gf@latest          ${RST}\n"
        printf "${PNK}╚══════════════════════════════════════════════════════════════╝${RST}\n\n"
        printf "  ${GRN}[1]${RST}  XSS params             ${DESC}- cat urls | gf xss${RST}\n"
        printf "  ${GRN}[2]${RST}  SQLi params            ${DESC}- cat urls | gf sqli${RST}\n"
        printf "  ${GRN}[3]${RST}  LFI params             ${DESC}- cat urls | gf lfi${RST}\n"
        printf "  ${GRN}[4]${RST}  SSRF params            ${DESC}- cat urls | gf ssrf${RST}\n"
        printf "  ${GRN}[5]${RST}  IDOR params            ${DESC}- cat urls | gf idor${RST}\n"
        printf "  ${GRN}[6]${RST}  RCE params             ${DESC}- cat urls | gf rce${RST}\n"
        printf "  ${GRN}[7]${RST}  All patterns + Save    ${DESC}- → downloads/gf_*.txt${RST}\n"
        printf "  ${GRN}[I]${RST}  Install                ${DESC}- go install gf + patterns${RST}\n"
        printf "  ${YLW}[B]${RST}  Back\n\n"
        printf "  %sChoose: %s" "${HOT}" "${RST}"; read -r SC
        local _GF="${HOME}/go/bin/gf"; command -v gf >/dev/null 2>&1 && _GF="gf"
        case "$SC" in
            [1-6])
                ! $GF_INSTALLED && { install_gf; $GF_INSTALLED || continue; }
                local pats=("" "xss" "sqli" "lfi" "ssrf" "idor" "rce")
                local pat="${pats[$SC]}"
                printf "  %sURL file path: %s" "${HOT}" "${RST}"; read -r FPATH
                [ -f "$FPATH" ] && cat "$FPATH" | ${_GF} "$pat" || printf "  %s[!] Not found%s\n" "${RED}" "${RST}"
                printf "  %sPress ENTER...%s" "${HOT}" "${RST}"; read -r _ ;;
            7)
                ! $GF_INSTALLED && { install_gf; $GF_INSTALLED || continue; }
                printf "  %sURL file path: %s" "${HOT}" "${RST}"; read -r FPATH
                [ ! -f "$FPATH" ] && printf "  %s[!] Not found%s\n" "${RED}" "${RST}" && continue
                for p in xss sqli lfi ssrf idor rce redirect; do
                    local out="${HOME}/storage/downloads/gf_${p}.txt"
                    cat "$FPATH" | ${_GF} "$p" 2>/dev/null > "$out"
                    printf "  ${GRN}%s:${RST} %s hits\n" "$p" "$(wc -l < "$out")"
                done
                printf "  %sPress ENTER...%s" "${HOT}" "${RST}"; read -r _ ;;
            i|I) install_gf ;;
            b|B) break ;;
            *) printf "  %s[!] Invalid.%s\n" "${RED}" "${RST}"; sleep 1 ;;
        esac
    done
}
submenu_trufflehog() {
    while true; do
        clear; banner; echo ""
        center_in_box "TRUFFLEHOG · SECRET & CREDENTIAL SCANNER"
        short_pink_line 32; echo ""
        printf "${PNK}╔══════════════════════════════════════════════════════════════╗${RST}\n"
        printf "${PNK}║${RST} ${CYN}SYNOPSIS:${RST} TruffleHog — scans git repos and filesystems for  ${RST}\n"
        printf "${PNK}║${RST}          leaked API keys, tokens, and credentials.           ${RST}\n"
        printf "${PNK}║${RST} ${CYN}USE:${RST} Enter repo URL or local path.                          ${RST}\n"
        printf "${PNK}║${RST} ${CYN}INSTALL:${RST} go install github.com/trufflesecurity/trufflehog/v3${RST}\n"
        printf "${PNK}╚══════════════════════════════════════════════════════════════╝${RST}\n\n"
        printf "  ${GRN}[1]${RST}  Scan Git Repo URL      ${DESC}- trufflehog git <url>${RST}\n"
        printf "  ${GRN}[2]${RST}  Scan Local Repo        ${DESC}- trufflehog git file://<path>${RST}\n"
        printf "  ${GRN}[3]${RST}  Scan Filesystem        ${DESC}- trufflehog filesystem <path>${RST}\n"
        printf "  ${GRN}[4]${RST}  JSON Output + Save     ${DESC}- → downloads/secrets.json${RST}\n"
        printf "  ${GRN}[I]${RST}  Install                ${DESC}- go install trufflehog${RST}\n"
        printf "  ${YLW}[B]${RST}  Back\n\n"
        printf "  %sChoose: %s" "${HOT}" "${RST}"; read -r SC
        local _TF="${HOME}/go/bin/trufflehog"; command -v trufflehog >/dev/null 2>&1 && _TF="trufflehog"
        case "$SC" in
            1) ! $TRUFFLEHOG_INSTALLED && { install_trufflehog; $TRUFFLEHOG_INSTALLED || continue; }
               run_web_tool "${_TF} git TARGET_PLACEHOLDER" "TruffleHog · Git" "yes" "trufflehog git <url>" ;;
            2) ! $TRUFFLEHOG_INSTALLED && { install_trufflehog; $TRUFFLEHOG_INSTALLED || continue; }
               printf "  %sLocal path: %s" "${HOT}" "${RST}"; read -r LPATH
               ${_TF} git "file://${LPATH}"; printf "  %sPress ENTER...%s" "${HOT}" "${RST}"; read -r _ ;;
            3) ! $TRUFFLEHOG_INSTALLED && { install_trufflehog; $TRUFFLEHOG_INSTALLED || continue; }
               printf "  %sFilesystem path: %s" "${HOT}" "${RST}"; read -r LPATH
               ${_TF} filesystem "$LPATH"; printf "  %sPress ENTER...%s" "${HOT}" "${RST}"; read -r _ ;;
            4) ! $TRUFFLEHOG_INSTALLED && { install_trufflehog; $TRUFFLEHOG_INSTALLED || continue; }
               run_web_tool "${_TF} git TARGET_PLACEHOLDER --json | tee ${HOME}/storage/downloads/secrets.json" "TruffleHog · JSON" "yes" "trufflehog json" ;;
            i|I) install_trufflehog ;;
            b|B) break ;;
            *) printf "  %s[!] Invalid.%s\n" "${RED}" "${RST}"; sleep 1 ;;
        esac
    done
}
submenu_crlfuzz() {
    while true; do
        clear; banner; echo ""
        center_in_box "CRLFUZZ · CRLF INJECTION FUZZER"
        short_pink_line 32; echo ""
        printf "${PNK}╔══════════════════════════════════════════════════════════════╗${RST}\n"
        printf "${PNK}║${RST} ${CYN}SYNOPSIS:${RST} CRLFuzz — fast CRLF injection fuzzer. Go rootless.${RST}\n"
        printf "${PNK}║${RST} ${CYN}USE:${RST} Enter target URL or file of URLs.                      ${RST}\n"
        printf "${PNK}║${RST} ${CYN}INSTALL:${RST} go install github.com/dwisiswant0/crlfuzz/cmd/...  ${RST}\n"
        printf "${PNK}╚══════════════════════════════════════════════════════════════╝${RST}\n\n"
        printf "  ${GRN}[1]${RST}  Single URL             ${DESC}- crlfuzz -u <target>${RST}\n"
        printf "  ${GRN}[2]${RST}  URL File               ${DESC}- crlfuzz -l <urls.txt>${RST}\n"
        printf "  ${GRN}[3]${RST}  Save Output            ${DESC}- → downloads/crlf_out.txt${RST}\n"
        printf "  ${GRN}[I]${RST}  Install                ${DESC}- go install crlfuzz${RST}\n"
        printf "  ${YLW}[B]${RST}  Back\n\n"
        printf "  %sChoose: %s" "${HOT}" "${RST}"; read -r SC
        local _CF="${HOME}/go/bin/crlfuzz"; command -v crlfuzz >/dev/null 2>&1 && _CF="crlfuzz"
        case "$SC" in
            1) ! $CRLFUZZ_INSTALLED && { install_crlfuzz; $CRLFUZZ_INSTALLED || continue; }
               run_web_tool "${_CF} -u TARGET_PLACEHOLDER" "CRLFuzz · Single" "yes" "crlfuzz -u <target>" ;;
            2) ! $CRLFUZZ_INSTALLED && { install_crlfuzz; $CRLFUZZ_INSTALLED || continue; }
               printf "  %sURL file: %s" "${HOT}" "${RST}"; read -r FPATH
               [ -f "$FPATH" ] && ${_CF} -l "$FPATH" || printf "  %s[!] Not found%s\n" "${RED}" "${RST}"
               printf "  %sPress ENTER...%s" "${HOT}" "${RST}"; read -r _ ;;
            3) ! $CRLFUZZ_INSTALLED && { install_crlfuzz; $CRLFUZZ_INSTALLED || continue; }
               run_web_tool "${_CF} -u TARGET_PLACEHOLDER -o ${HOME}/storage/downloads/crlf_out.txt && cat ${HOME}/storage/downloads/crlf_out.txt" "CRLFuzz · Save" "yes" "crlfuzz + save" ;;
            i|I) install_crlfuzz ;;
            b|B) break ;;
            *) printf "  %s[!] Invalid.%s\n" "${RED}" "${RST}"; sleep 1 ;;
        esac
    done
}
submenu_byp4xx() {
    while true; do
        clear; banner; echo ""
        center_in_box "BYP4XX · 403 BYPASS ENGINE"
        short_pink_line 32; echo ""
        printf "${PNK}╔══════════════════════════════════════════════════════════════╗${RST}\n"
        printf "${PNK}║${RST} ${CYN}SYNOPSIS:${RST} Byp4xx — bypass 403 Forbidden via header tricks.  ${RST}\n"
        printf "${PNK}║${RST} ${CYN}USE:${RST} Enter full URL returning 403. Go binary, rootless.     ${RST}\n"
        printf "${PNK}║${RST} ${CYN}INSTALL:${RST} go install github.com/lobuhi/byp4xx@latest         ${RST}\n"
        printf "${PNK}╚══════════════════════════════════════════════════════════════╝${RST}\n\n"
        printf "  ${GRN}[1]${RST}  Bypass URL             ${DESC}- byp4xx <url>${RST}\n"
        printf "  ${GRN}[2]${RST}  Bypass + Save          ${DESC}- → downloads/byp4xx_out.txt${RST}\n"
        printf "  ${GRN}[I]${RST}  Install                ${DESC}- go install byp4xx${RST}\n"
        printf "  ${YLW}[B]${RST}  Back\n\n"
        printf "  %sChoose: %s" "${HOT}" "${RST}"; read -r SC
        local _BP="${HOME}/go/bin/byp4xx"; command -v byp4xx >/dev/null 2>&1 && _BP="byp4xx"
        case "$SC" in
            1) ! $BYP4XX_INSTALLED && { install_byp4xx; $BYP4XX_INSTALLED || continue; }
               run_web_tool "${_BP} TARGET_PLACEHOLDER" "Byp4xx · Bypass" "yes" "byp4xx <url>" ;;
            2) ! $BYP4XX_INSTALLED && { install_byp4xx; $BYP4XX_INSTALLED || continue; }
               run_web_tool "${_BP} TARGET_PLACEHOLDER | tee ${HOME}/storage/downloads/byp4xx_out.txt" "Byp4xx · Save" "yes" "byp4xx + save" ;;
            i|I) install_byp4xx ;;
            b|B) break ;;
            *) printf "  %s[!] Invalid.%s\n" "${RED}" "${RST}"; sleep 1 ;;
        esac
    done
}
submenu_feroxbuster() {
    while true; do
        clear; banner; echo ""
        center_in_box "FEROXBUSTER · RECURSIVE CONTENT DISCOVERY"
        short_pink_line 32; echo ""
        printf "${PNK}╔══════════════════════════════════════════════════════════════╗${RST}\n"
        printf "${PNK}║${RST} ${CYN}SYNOPSIS:${RST} Feroxbuster — recursive dir brute-force in Rust.  ${RST}\n"
        printf "${PNK}║${RST}          Follows redirects. Filters by status/size.           ${RST}\n"
        printf "${PNK}║${RST} ${CYN}USE:${RST} Enter target URL. Wordlist optional.                   ${RST}\n"
        printf "${PNK}║${RST} ${CYN}INSTALL:${RST} auto curl script or pkg install feroxbuster        ${RST}\n"
        printf "${PNK}╚══════════════════════════════════════════════════════════════╝${RST}\n\n"
        printf "  ${GRN}[1]${RST}  Basic Scan             ${DESC}- feroxbuster -u <target>${RST}\n"
        printf "  ${GRN}[2]${RST}  Custom Wordlist        ${DESC}- feroxbuster -u <target> -w <list>${RST}\n"
        printf "  ${GRN}[3]${RST}  Filter 404             ${DESC}- feroxbuster -u <target> -C 404${RST}\n"
        printf "  ${GRN}[4]${RST}  Save Output            ${DESC}- → downloads/ferox_out.txt${RST}\n"
        printf "  ${GRN}[I]${RST}  Install                ${DESC}- auto curl install${RST}\n"
        printf "  ${YLW}[B]${RST}  Back\n\n"
        printf "  %sChoose: %s" "${HOT}" "${RST}"; read -r SC
        case "$SC" in
            1) ! $FEROXBUSTER_INSTALLED && { install_feroxbuster; $FEROXBUSTER_INSTALLED || continue; }
               run_web_tool "feroxbuster -u TARGET_PLACEHOLDER --silent" "Feroxbuster · Basic" "yes" "feroxbuster -u <target>" ;;
            2) ! $FEROXBUSTER_INSTALLED && { install_feroxbuster; $FEROXBUSTER_INSTALLED || continue; }
               printf "  %sWordlist path: %s" "${HOT}" "${RST}"; read -r WL
               [ -z "$WL" ] && WL="/data/data/com.termux/files/usr/share/dirb/wordlists/common.txt"
               run_web_tool "feroxbuster -u TARGET_PLACEHOLDER -w ${WL} --silent" "Feroxbuster · Wordlist" "yes" "feroxbuster -w" ;;
            3) ! $FEROXBUSTER_INSTALLED && { install_feroxbuster; $FEROXBUSTER_INSTALLED || continue; }
               run_web_tool "feroxbuster -u TARGET_PLACEHOLDER -C 404 --silent" "Feroxbuster · Filter" "yes" "feroxbuster -C 404" ;;
            4) ! $FEROXBUSTER_INSTALLED && { install_feroxbuster; $FEROXBUSTER_INSTALLED || continue; }
               run_web_tool "feroxbuster -u TARGET_PLACEHOLDER --silent -o ${HOME}/storage/downloads/ferox_out.txt && cat ${HOME}/storage/downloads/ferox_out.txt" "Feroxbuster · Save" "yes" "feroxbuster + save" ;;
            i|I) install_feroxbuster ;;
            b|B) break ;;
            *) printf "  %s[!] Invalid.%s\n" "${RED}" "${RST}"; sleep 1 ;;
        esac
    done
}


# ══════════════════════════════════════════════════════════════
#  V12 · OSINT INTEL · INSTALL FUNCTIONS + SUBMENUS (78-87)
#  S.O.I · BOJACK BRAND · FEZZY ARSENAL · 999
# ══════════════════════════════════════════════════════════════

install_holehe() {
    printf "%s  [*] Installing holehe (pip)...%s\n" "${CYN}" "${RST}"
    pip install holehe 2>/dev/null &
    local pid=$!; spinner $pid; wait $pid
    pip list 2>/dev/null | grep -qi "holehe" \
        && { HOLEHE_INSTALLED=true; printf "%s  [+] holehe ready%s\n" "${GRN}" "${RST}"; } \
        || printf "%s  [!!] holehe failed — try: pip install holehe%s\n" "${RED}" "${RST}"
    check_deps; sleep 1
}

install_blackbird() {
    printf "%s  [*] Installing Blackbird (git + pip)...%s\n" "${CYN}" "${RST}"
    command -v git >/dev/null 2>&1 || pkg install -y git 2>/dev/null
    if [[ ! -d "${HOME}/blackbird" ]]; then
        printf "  %s[*] Cloning Blackbird...%s\n" "${CYN}" "${RST}"
        git clone -q https://github.com/p1ngul1n0/blackbird "${HOME}/blackbird" 2>/dev/null \
            && printf "  %s[+] Cloned OK.%s\n" "${GRN}" "${RST}" \
            || { printf "  %s[!!] Clone failed. Check internet.%s\n" "${RED}" "${RST}"; sleep 2; return; }
    else
        printf "  %s[+] Already cloned.%s\n" "${GRN}" "${RST}"
    fi
    pip install -r "${HOME}/blackbird/requirements.txt" 2>/dev/null \
        && { BLACKBIRD_INSTALLED=true; printf "  %s[+] Blackbird ready%s\n" "${GRN}" "${RST}"; } \
        || printf "  %s[!] pip deps failed — try manually%s\n" "${YLW}" "${RST}"
    check_deps; sleep 1
}

install_toutatis() {
    printf "%s  [*] Installing toutatis (pip)...%s\n" "${CYN}" "${RST}"
    pip install toutatis 2>/dev/null &
    local pid=$!; spinner $pid; wait $pid
    pip list 2>/dev/null | grep -qi "toutatis" \
        && { TOUTATIS_INSTALLED=true; printf "%s  [+] toutatis ready%s\n" "${GRN}" "${RST}"; } \
        || printf "%s  [!!] toutatis failed — try: pip install toutatis%s\n" "${RED}" "${RST}"
    check_deps; sleep 1
}

install_moriarty() {
    printf "%s  [*] Installing Moriarty-Project (git + pip)...%s\n" "${CYN}" "${RST}"
    command -v git >/dev/null 2>&1 || pkg install -y git 2>/dev/null
    if [[ ! -d "${HOME}/Moriarty-Project" ]]; then
        printf "  %s[*] Cloning Moriarty-Project...%s\n" "${CYN}" "${RST}"
        git clone -q https://github.com/AzizKpln/Moriarty-Project "${HOME}/Moriarty-Project" 2>/dev/null \
            && printf "  %s[+] Cloned OK.%s\n" "${GRN}" "${RST}" \
            || { printf "  %s[!!] Clone failed. Check internet.%s\n" "${RED}" "${RST}"; sleep 2; return; }
    else
        printf "  %s[+] Already cloned.%s\n" "${GRN}" "${RST}"
    fi
    pip install -r "${HOME}/Moriarty-Project/requirements.txt" 2>/dev/null \
        && { MORIARTY_INSTALLED=true; printf "  %s[+] Moriarty ready%s\n" "${GRN}" "${RST}"; } \
        || printf "  %s[!] pip deps failed%s\n" "${YLW}" "${RST}"
    check_deps; sleep 1
}

install_daprofiler() {
    printf "%s  [*] Installing DaProfiler (git + pip)...%s\n" "${CYN}" "${RST}"
    command -v git >/dev/null 2>&1 || pkg install -y git 2>/dev/null
    if [[ ! -d "${HOME}/DaProfiler" ]]; then
        printf "  %s[*] Cloning DaProfiler...%s\n" "${CYN}" "${RST}"
        git clone -q https://github.com/daprofiler/DaProfiler "${HOME}/DaProfiler" 2>/dev/null \
            && printf "  %s[+] Cloned OK.%s\n" "${GRN}" "${RST}" \
            || { printf "  %s[!!] Clone failed. Check internet.%s\n" "${RED}" "${RST}"; sleep 2; return; }
    else
        printf "  %s[+] Already cloned.%s\n" "${GRN}" "${RST}"
    fi
    pip install -r "${HOME}/DaProfiler/requirements.txt" 2>/dev/null \
        && { DAPROFILER_INSTALLED=true; printf "  %s[+] DaProfiler ready%s\n" "${GRN}" "${RST}"; } \
        || printf "  %s[!] pip deps failed%s\n" "${YLW}" "${RST}"
    check_deps; sleep 1
}

install_cloudpeler() {
    printf "%s  [*] Installing CloudPeler (git + pip)...%s\n" "${CYN}" "${RST}"
    command -v git >/dev/null 2>&1 || pkg install -y git 2>/dev/null
    if [[ ! -d "${HOME}/CloudPeler" ]]; then
        printf "  %s[*] Cloning CloudPeler...%s\n" "${CYN}" "${RST}"
        git clone -q https://github.com/karam09/CloudPeler "${HOME}/CloudPeler" 2>/dev/null \
            && printf "  %s[+] Cloned OK.%s\n" "${GRN}" "${RST}" \
            || { printf "  %s[!!] Clone failed. Check internet.%s\n" "${RED}" "${RST}"; sleep 2; return; }
    else
        printf "  %s[+] Already cloned.%s\n" "${GRN}" "${RST}"
    fi
    pip install -r "${HOME}/CloudPeler/requirements.txt" 2>/dev/null \
        && { CLOUDPELER_INSTALLED=true; printf "  %s[+] CloudPeler ready%s\n" "${GRN}" "${RST}"; } \
        || printf "  %s[!] pip deps failed%s\n" "${YLW}" "${RST}"
    check_deps; sleep 1
}

install_mosint() {
    printf "%s  [*] Installing mosint (Go)...%s\n" "${CYN}" "${RST}"
    if ! command -v go >/dev/null 2>&1; then
        printf "  %s[!] Go not installed. Run: pkg install golang%s\n" "${RED}" "${RST}"
        sleep 2; return 1
    fi
    go install github.com/alpkeskin/mosint/v3@latest 2>/dev/null &
    local pid=$!; spinner $pid; wait $pid
    { command -v mosint >/dev/null 2>&1 || [[ -x "${HOME}/go/bin/mosint" ]]; } \
        && { MOSINT_INSTALLED=true; printf "%s  [+] mosint ready → ~/go/bin/mosint%s\n" "${GRN}" "${RST}"; } \
        || printf "%s  [!!] mosint failed — ensure Go is installed: pkg install golang%s\n" "${RED}" "${RST}"
    check_deps; sleep 1
}

install_photon_osint() {
    printf "%s  [*] Installing Photon OSINT (git + pip)...%s\n" "${CYN}" "${RST}"
    command -v git >/dev/null 2>&1 || pkg install -y git 2>/dev/null
    if [[ ! -d "${HOME}/Photon" ]]; then
        printf "  %s[*] Cloning Photon...%s\n" "${CYN}" "${RST}"
        git clone -q https://github.com/s0md3v/Photon "${HOME}/Photon" 2>/dev/null \
            && printf "  %s[+] Cloned OK.%s\n" "${GRN}" "${RST}" \
            || { printf "  %s[!!] Clone failed. Check internet.%s\n" "${RED}" "${RST}"; sleep 2; return; }
    else
        printf "  %s[+] Already cloned.%s\n" "${GRN}" "${RST}"
    fi
    pip install -r "${HOME}/Photon/requirements.txt" 2>/dev/null \
        && { PHOTON_INSTALLED=true; printf "  %s[+] Photon ready%s\n" "${GRN}" "${RST}"; } \
        || printf "  %s[!] pip deps failed%s\n" "${YLW}" "${RST}"
    check_deps; sleep 1
}

install_onionsearch() {
    printf "%s  [*] Installing onionsearch (pip)...%s\n" "${CYN}" "${RST}"
    pip install onionsearch 2>/dev/null &
    local pid=$!; spinner $pid; wait $pid
    pip list 2>/dev/null | grep -qi "onionsearch" \
        && { ONIONSEARCH_INSTALLED=true; printf "%s  [+] onionsearch ready%s\n" "${GRN}" "${RST}"; } \
        || printf "%s  [!!] onionsearch failed — try: pip install onionsearch%s\n" "${RED}" "${RST}"
    check_deps; sleep 1
}

install_gitsniff() {
    printf "%s  [*] Installing GitSniff (git + pip)...%s\n" "${CYN}" "${RST}"
    command -v git >/dev/null 2>&1 || pkg install -y git 2>/dev/null
    if [[ ! -d "${HOME}/GitSniff" ]]; then
        printf "  %s[*] Cloning GitSniff...%s\n" "${CYN}" "${RST}"
        git clone -q https://github.com/GlebSukhanov/GitSniff "${HOME}/GitSniff" 2>/dev/null \
            && printf "  %s[+] Cloned OK.%s\n" "${GRN}" "${RST}" \
            || { printf "  %s[!!] Clone failed. Check internet.%s\n" "${RED}" "${RST}"; sleep 2; return; }
    else
        printf "  %s[+] Already cloned.%s\n" "${GRN}" "${RST}"
    fi
    pip install -r "${HOME}/GitSniff/requirements.txt" 2>/dev/null \
        && { GITSNIFF_INSTALLED=true; printf "  %s[+] GitSniff ready%s\n" "${GRN}" "${RST}"; } \
        || printf "  %s[!] pip deps failed%s\n" "${YLW}" "${RST}"
    check_deps; sleep 1
}

# ── V12 OSINT Submenus ─────────────────────────────────────

submenu_holehe() {
    while true; do
        clear; banner; echo ""
        center_in_box "HOLEHE · EMAIL ACCOUNT CHECKER"
        short_pink_line 32; echo ""
        printf "${PNK}╔══════════════════════════════════════════════════════════════╗${RST}\n"
        printf "${PNK}║${RST} ${CYN}SYNOPSIS:${RST} Holehe — checks if an email is registered on 120+  ${RST}\n"
        printf "${PNK}║${RST}          sites via forgot-password flows. Fully passive.    ${RST}\n"
        printf "${PNK}║${RST} ${CYN}USE:${RST} Paste target email when prompted.                      ${RST}\n"
        printf "${PNK}║${RST} ${CYN}INSTALL:${RST} pip install holehe                                  ${RST}\n"
        printf "${PNK}╚══════════════════════════════════════════════════════════════╝${RST}\n\n"
        printf "  ${GRN}[1]${RST}  Check Email           ${DESC}- holehe <email>${RST}\n"
        printf "  ${GRN}[2]${RST}  Only Show Hits        ${DESC}- holehe --only-used <email>${RST}\n"
        printf "  ${GRN}[3]${RST}  Save Output           ${DESC}- → downloads/holehe_out.txt${RST}\n"
        printf "  ${GRN}[4]${RST}  Paste Command         ${DESC}- run any holehe command directly${RST}\n"
        printf "  ${GRN}[I]${RST}  Install               ${DESC}- pip install holehe${RST}\n"
        printf "  ${YLW}[B]${RST}  Back\n\n"
        printf "  %sChoose: %s" "${HOT}" "${RST}"; read -r SC
        case "$SC" in
            1) ! $HOLEHE_INSTALLED && { install_holehe; $HOLEHE_INSTALLED || continue; }
               printf "  %sPaste email: %s" "${HOT}" "${RST}"; read -r _email
               [ -z "$_email" ] && { printf "  %s[!] No email.%s\n" "${RED}" "${RST}"; sleep 1; continue; }
               printf "\n  %s[*] Running holehe on %s...%s\n\n" "${CYN}" "$_email" "${RST}"
               holehe "$_email" 2>&1 | tee -a "$LOG"
               echo ""; printf "  %sPress ENTER...%s" "${HOT}" "${RST}"; read -r _ ;;
            2) ! $HOLEHE_INSTALLED && { install_holehe; $HOLEHE_INSTALLED || continue; }
               printf "  %sPaste email: %s" "${HOT}" "${RST}"; read -r _email
               [ -z "$_email" ] && { printf "  %s[!] No email.%s\n" "${RED}" "${RST}"; sleep 1; continue; }
               printf "\n  %s[*] Showing only registered sites for %s...%s\n\n" "${CYN}" "$_email" "${RST}"
               holehe --only-used "$_email" 2>&1 | tee -a "$LOG"
               echo ""; printf "  %sPress ENTER...%s" "${HOT}" "${RST}"; read -r _ ;;
            3) ! $HOLEHE_INSTALLED && { install_holehe; $HOLEHE_INSTALLED || continue; }
               printf "  %sPaste email: %s" "${HOT}" "${RST}"; read -r _email
               [ -z "$_email" ] && { printf "  %s[!] No email.%s\n" "${RED}" "${RST}"; sleep 1; continue; }
               local _out="${HOME}/storage/downloads/holehe_out.txt"
               [ ! -d "${HOME}/storage/downloads" ] && _out="${HOME}/holehe_out.txt"
               holehe --only-used "$_email" 2>&1 | tee "$_out" | tee -a "$LOG"
               printf "\n  %s[+] Saved: %s%s\n" "${GRN}" "$_out" "${RST}"
               echo ""; printf "  %sPress ENTER...%s" "${HOT}" "${RST}"; read -r _ ;;
            4) printf "  %sPaste holehe command: %s" "${HOT}" "${RST}"; read -r _cmd
               [ -z "$_cmd" ] && { printf "  %s[!] Nothing entered.%s\n" "${RED}" "${RST}"; sleep 1; continue; }
               printf "\n  %s[*] Executing...%s\n\n" "${CYN}" "${RST}"
               eval "$_cmd" 2>&1 | tee -a "$LOG"
               echo ""; printf "  %sPress ENTER...%s" "${HOT}" "${RST}"; read -r _ ;;
            i|I) install_holehe ;;
            b|B) break ;;
            *) printf "  %s[!] Invalid.%s\n" "${RED}" "${RST}"; sleep 1 ;;
        esac
    done
}

submenu_blackbird() {
    while true; do
        clear; banner; echo ""
        center_in_box "BLACKBIRD · USERNAME FOOTPRINT SCANNER"
        short_pink_line 38; echo ""
        printf "${PNK}╔══════════════════════════════════════════════════════════════╗${RST}\n"
        printf "${PNK}║${RST} ${CYN}SYNOPSIS:${RST} Blackbird — username search across 500+ social   ${RST}\n"
        printf "${PNK}║${RST}          platforms incl. crypto, gaming & regional sites.  ${RST}\n"
        printf "${PNK}║${RST} ${CYN}USE:${RST} Paste target username when prompted.                   ${RST}\n"
        printf "${PNK}║${RST} ${CYN}INSTALL:${RST} git clone + pip install -r requirements.txt        ${RST}\n"
        printf "${PNK}╚══════════════════════════════════════════════════════════════╝${RST}\n\n"
        printf "  ${GRN}[1]${RST}  Username Search       ${DESC}- python3 blackbird.py -u <username>${RST}\n"
        printf "  ${GRN}[2]${RST}  Save Output           ${DESC}- → downloads/blackbird_out.txt${RST}\n"
        printf "  ${GRN}[3]${RST}  Paste Command         ${DESC}- run any blackbird command directly${RST}\n"
        printf "  ${GRN}[I]${RST}  Install               ${DESC}- git clone + pip${RST}\n"
        printf "  ${YLW}[B]${RST}  Back\n\n"
        printf "  %sChoose: %s" "${HOT}" "${RST}"; read -r SC
        local _BB="python3 ${HOME}/blackbird/blackbird.py"
        case "$SC" in
            1) ! $BLACKBIRD_INSTALLED && { install_blackbird; $BLACKBIRD_INSTALLED || continue; }
               printf "  %sPaste username: %s" "${HOT}" "${RST}"; read -r _uname
               [ -z "$_uname" ] && { printf "  %s[!] No username.%s\n" "${RED}" "${RST}"; sleep 1; continue; }
               printf "\n  %s[*] Scanning for username: %s...%s\n\n" "${CYN}" "$_uname" "${RST}"
               cd "${HOME}/blackbird" && ${_BB} -u "$_uname" 2>&1 | tee -a "$LOG"; cd "${HOME}"
               echo ""; printf "  %sPress ENTER...%s" "${HOT}" "${RST}"; read -r _ ;;
            2) ! $BLACKBIRD_INSTALLED && { install_blackbird; $BLACKBIRD_INSTALLED || continue; }
               printf "  %sPaste username: %s" "${HOT}" "${RST}"; read -r _uname
               [ -z "$_uname" ] && { printf "  %s[!] No username.%s\n" "${RED}" "${RST}"; sleep 1; continue; }
               local _out="${HOME}/storage/downloads/blackbird_out.txt"
               [ ! -d "${HOME}/storage/downloads" ] && _out="${HOME}/blackbird_out.txt"
               cd "${HOME}/blackbird" && ${_BB} -u "$_uname" 2>&1 | tee "$_out" | tee -a "$LOG"; cd "${HOME}"
               printf "\n  %s[+] Saved: %s%s\n" "${GRN}" "$_out" "${RST}"
               echo ""; printf "  %sPress ENTER...%s" "${HOT}" "${RST}"; read -r _ ;;
            3) printf "  %sPaste command: %s" "${HOT}" "${RST}"; read -r _cmd
               [ -z "$_cmd" ] && { printf "  %s[!] Nothing entered.%s\n" "${RED}" "${RST}"; sleep 1; continue; }
               eval "$_cmd" 2>&1 | tee -a "$LOG"
               echo ""; printf "  %sPress ENTER...%s" "${HOT}" "${RST}"; read -r _ ;;
            i|I) install_blackbird ;;
            b|B) break ;;
            *) printf "  %s[!] Invalid.%s\n" "${RED}" "${RST}"; sleep 1 ;;
        esac
    done
}

submenu_toutatis() {
    while true; do
        clear; banner; echo ""
        center_in_box "TOUTATIS · INSTAGRAM INTEL EXTRACTOR"
        short_pink_line 36; echo ""
        printf "${PNK}╔══════════════════════════════════════════════════════════════╗${RST}\n"
        printf "${PNK}║${RST} ${CYN}SYNOPSIS:${RST} Toutatis — extracts hidden details from Instagram  ${RST}\n"
        printf "${PNK}║${RST}          profiles: partial emails, connected phone numbers.  ${RST}\n"
        printf "${PNK}║${RST} ${CYN}USE:${RST} Requires a valid Instagram sessionid cookie.           ${RST}\n"
        printf "${PNK}║${RST} ${CYN}INSTALL:${RST} pip install toutatis                                ${RST}\n"
        printf "${PNK}╚══════════════════════════════════════════════════════════════╝${RST}\n\n"
        printf "  ${GRN}[1]${RST}  Profile Intel         ${DESC}- toutatis -u <username> -s <sessionid>${RST}\n"
        printf "  ${GRN}[2]${RST}  Paste Command         ${DESC}- run any toutatis command directly${RST}\n"
        printf "  ${GRN}[I]${RST}  Install               ${DESC}- pip install toutatis${RST}\n"
        printf "  ${YLW}[B]${RST}  Back\n\n"
        printf "  %s[!] Requires your own Instagram sessionid cookie from browser.%s\n\n" "${YLW}" "${RST}"
        printf "  %sChoose: %s" "${HOT}" "${RST}"; read -r SC
        case "$SC" in
            1) ! $TOUTATIS_INSTALLED && { install_toutatis; $TOUTATIS_INSTALLED || continue; }
               printf "  %sPaste Instagram username: %s" "${HOT}" "${RST}"; read -r _uname
               printf "  %sPaste sessionid cookie: %s" "${HOT}" "${RST}"; read -r _sess
               [ -z "$_uname" ] || [ -z "$_sess" ] && { printf "  %s[!] Both username and sessionid required.%s\n" "${RED}" "${RST}"; sleep 1; continue; }
               printf "\n  %s[*] Running toutatis on @%s...%s\n\n" "${CYN}" "$_uname" "${RST}"
               toutatis -u "$_uname" -s "$_sess" 2>&1 | tee -a "$LOG"
               echo ""; printf "  %sPress ENTER...%s" "${HOT}" "${RST}"; read -r _ ;;
            2) printf "  %sPaste command: %s" "${HOT}" "${RST}"; read -r _cmd
               [ -z "$_cmd" ] && { printf "  %s[!] Nothing entered.%s\n" "${RED}" "${RST}"; sleep 1; continue; }
               eval "$_cmd" 2>&1 | tee -a "$LOG"
               echo ""; printf "  %sPress ENTER...%s" "${HOT}" "${RST}"; read -r _ ;;
            i|I) install_toutatis ;;
            b|B) break ;;
            *) printf "  %s[!] Invalid.%s\n" "${RED}" "${RST}"; sleep 1 ;;
        esac
    done
}

submenu_moriarty() {
    while true; do
        clear; banner; echo ""
        center_in_box "MORIARTY PROJECT · PHONE INTELLIGENCE"
        short_pink_line 38; echo ""
        printf "${PNK}╔══════════════════════════════════════════════════════════════╗${RST}\n"
        printf "${PNK}║${RST} ${CYN}SYNOPSIS:${RST} Moriarty — advanced phone number footprinting via  ${RST}\n"
        printf "${PNK}║${RST}          Amazon AWS endpoints and specialised business regs. ${RST}\n"
        printf "${PNK}║${RST} ${CYN}USE:${RST} Paste phone number with country code (+27...).          ${RST}\n"
        printf "${PNK}║${RST} ${CYN}INSTALL:${RST} git clone + pip install -r requirements.txt         ${RST}\n"
        printf "${PNK}╚══════════════════════════════════════════════════════════════╝${RST}\n\n"
        printf "  ${GRN}[1]${RST}  Phone Lookup          ${DESC}- python3 moriarty.py -n <number>${RST}\n"
        printf "  ${GRN}[2]${RST}  Save Output           ${DESC}- → downloads/moriarty_out.txt${RST}\n"
        printf "  ${GRN}[3]${RST}  Paste Command         ${DESC}- run any moriarty command directly${RST}\n"
        printf "  ${GRN}[I]${RST}  Install               ${DESC}- git clone + pip${RST}\n"
        printf "  ${YLW}[B]${RST}  Back\n\n"
        printf "  %sChoose: %s" "${HOT}" "${RST}"; read -r SC
        local _MR="python3 ${HOME}/Moriarty-Project/moriarty.py"
        case "$SC" in
            1) ! $MORIARTY_INSTALLED && { install_moriarty; $MORIARTY_INSTALLED || continue; }
               printf "  %sPaste phone number (e.g. +27821234567): %s" "${HOT}" "${RST}"; read -r _phone
               [ -z "$_phone" ] && { printf "  %s[!] No number entered.%s\n" "${RED}" "${RST}"; sleep 1; continue; }
               printf "\n  %s[*] Running Moriarty on %s...%s\n\n" "${CYN}" "$_phone" "${RST}"
               cd "${HOME}/Moriarty-Project" && ${_MR} -n "$_phone" 2>&1 | tee -a "$LOG"; cd "${HOME}"
               echo ""; printf "  %sPress ENTER...%s" "${HOT}" "${RST}"; read -r _ ;;
            2) ! $MORIARTY_INSTALLED && { install_moriarty; $MORIARTY_INSTALLED || continue; }
               printf "  %sPaste phone number: %s" "${HOT}" "${RST}"; read -r _phone
               [ -z "$_phone" ] && { printf "  %s[!] No number entered.%s\n" "${RED}" "${RST}"; sleep 1; continue; }
               local _out="${HOME}/storage/downloads/moriarty_out.txt"
               [ ! -d "${HOME}/storage/downloads" ] && _out="${HOME}/moriarty_out.txt"
               cd "${HOME}/Moriarty-Project" && ${_MR} -n "$_phone" 2>&1 | tee "$_out" | tee -a "$LOG"; cd "${HOME}"
               printf "\n  %s[+] Saved: %s%s\n" "${GRN}" "$_out" "${RST}"
               echo ""; printf "  %sPress ENTER...%s" "${HOT}" "${RST}"; read -r _ ;;
            3) printf "  %sPaste command: %s" "${HOT}" "${RST}"; read -r _cmd
               [ -z "$_cmd" ] && { printf "  %s[!] Nothing entered.%s\n" "${RED}" "${RST}"; sleep 1; continue; }
               eval "$_cmd" 2>&1 | tee -a "$LOG"
               echo ""; printf "  %sPress ENTER...%s" "${HOT}" "${RST}"; read -r _ ;;
            i|I) install_moriarty ;;
            b|B) break ;;
            *) printf "  %s[!] Invalid.%s\n" "${RED}" "${RST}"; sleep 1 ;;
        esac
    done
}

submenu_daprofiler() {
    while true; do
        clear; banner; echo ""
        center_in_box "DAPROFILER · IDENTITY FOOTPRINT MAPPER"
        short_pink_line 38; echo ""
        printf "${PNK}╔══════════════════════════════════════════════════════════════╗${RST}\n"
        printf "${PNK}║${RST} ${CYN}SYNOPSIS:${RST} DaProfiler — maps EU/Global public profiles to     ${RST}\n"
        printf "${PNK}║${RST}          physical addresses and company roles via OSINT.    ${RST}\n"
        printf "${PNK}║${RST} ${CYN}USE:${RST} Enter first name, last name, country when prompted.    ${RST}\n"
        printf "${PNK}║${RST} ${CYN}INSTALL:${RST} git clone + pip install -r requirements.txt         ${RST}\n"
        printf "${PNK}╚══════════════════════════════════════════════════════════════╝${RST}\n\n"
        printf "  ${GRN}[1]${RST}  Profile Search        ${DESC}- DaProfiler -fn <name> -ln <name>${RST}\n"
        printf "  ${GRN}[2]${RST}  Save Output           ${DESC}- → downloads/daprofiler_out.txt${RST}\n"
        printf "  ${GRN}[3]${RST}  Paste Command         ${DESC}- run any DaProfiler command directly${RST}\n"
        printf "  ${GRN}[I]${RST}  Install               ${DESC}- git clone + pip${RST}\n"
        printf "  ${YLW}[B]${RST}  Back\n\n"
        printf "  %sChoose: %s" "${HOT}" "${RST}"; read -r SC
        local _DP="python3 ${HOME}/DaProfiler/DaProfiler.py"
        case "$SC" in
            1) ! $DAPROFILER_INSTALLED && { install_daprofiler; $DAPROFILER_INSTALLED || continue; }
               printf "  %sFirst name: %s" "${HOT}" "${RST}"; read -r _fn
               printf "  %sLast name: %s" "${HOT}" "${RST}"; read -r _ln
               printf "  %sCountry code (e.g. za, fr, us — or ENTER to skip): %s" "${HOT}" "${RST}"; read -r _cn
               [ -z "$_fn" ] || [ -z "$_ln" ] && { printf "  %s[!] First and last name required.%s\n" "${RED}" "${RST}"; sleep 1; continue; }
               printf "\n  %s[*] Profiling %s %s...%s\n\n" "${CYN}" "$_fn" "$_ln" "${RST}"
               cd "${HOME}/DaProfiler" && ${_DP} -fn "$_fn" -ln "$_ln" ${_cn:+-c "$_cn"} 2>&1 | tee -a "$LOG"; cd "${HOME}"
               echo ""; printf "  %sPress ENTER...%s" "${HOT}" "${RST}"; read -r _ ;;
            2) ! $DAPROFILER_INSTALLED && { install_daprofiler; $DAPROFILER_INSTALLED || continue; }
               printf "  %sFirst name: %s" "${HOT}" "${RST}"; read -r _fn
               printf "  %sLast name: %s" "${HOT}" "${RST}"; read -r _ln
               [ -z "$_fn" ] || [ -z "$_ln" ] && { printf "  %s[!] Name required.%s\n" "${RED}" "${RST}"; sleep 1; continue; }
               local _out="${HOME}/storage/downloads/daprofiler_out.txt"
               [ ! -d "${HOME}/storage/downloads" ] && _out="${HOME}/daprofiler_out.txt"
               cd "${HOME}/DaProfiler" && ${_DP} -fn "$_fn" -ln "$_ln" 2>&1 | tee "$_out" | tee -a "$LOG"; cd "${HOME}"
               printf "\n  %s[+] Saved: %s%s\n" "${GRN}" "$_out" "${RST}"
               echo ""; printf "  %sPress ENTER...%s" "${HOT}" "${RST}"; read -r _ ;;
            3) printf "  %sPaste command: %s" "${HOT}" "${RST}"; read -r _cmd
               [ -z "$_cmd" ] && { printf "  %s[!] Nothing entered.%s\n" "${RED}" "${RST}"; sleep 1; continue; }
               eval "$_cmd" 2>&1 | tee -a "$LOG"
               echo ""; printf "  %sPress ENTER...%s" "${HOT}" "${RST}"; read -r _ ;;
            i|I) install_daprofiler ;;
            b|B) break ;;
            *) printf "  %s[!] Invalid.%s\n" "${RED}" "${RST}"; sleep 1 ;;
        esac
    done
}

submenu_cloudpeler() {
    while true; do
        clear; banner; echo ""
        center_in_box "CLOUDPELER · REAL IP BEHIND CLOUDFLARE"
        short_pink_line 38; echo ""
        printf "${PNK}╔══════════════════════════════════════════════════════════════╗${RST}\n"
        printf "${PNK}║${RST} ${CYN}SYNOPSIS:${RST} CloudPeler — finds real backend IPs hidden behind  ${RST}\n"
        printf "${PNK}║${RST}          Cloudflare WAF via historical DNS records + leaks. ${RST}\n"
        printf "${PNK}║${RST} ${CYN}USE:${RST} Paste domain (e.g. example.com) when prompted.         ${RST}\n"
        printf "${PNK}║${RST} ${CYN}INSTALL:${RST} git clone + pip install -r requirements.txt        ${RST}\n"
        printf "${PNK}╚══════════════════════════════════════════════════════════════╝${RST}\n\n"
        printf "  ${GRN}[1]${RST}  Detect Real IP        ${DESC}- python3 CloudPeler.py -d <domain>${RST}\n"
        printf "  ${GRN}[2]${RST}  Save Output           ${DESC}- → downloads/cloudpeler_out.txt${RST}\n"
        printf "  ${GRN}[3]${RST}  Paste Command         ${DESC}- run any CloudPeler command directly${RST}\n"
        printf "  ${GRN}[I]${RST}  Install               ${DESC}- git clone + pip${RST}\n"
        printf "  ${YLW}[B]${RST}  Back\n\n"
        printf "  %sChoose: %s" "${HOT}" "${RST}"; read -r SC
        local _CP="python3 ${HOME}/CloudPeler/CloudPeler.py"
        case "$SC" in
            1) ! $CLOUDPELER_INSTALLED && { install_cloudpeler; $CLOUDPELER_INSTALLED || continue; }
               printf "  %sPaste domain: %s" "${HOT}" "${RST}"; read -r _dom
               [ -z "$_dom" ] && { printf "  %s[!] No domain.%s\n" "${RED}" "${RST}"; sleep 1; continue; }
               printf "\n  %s[*] Peeling Cloudflare on %s...%s\n\n" "${CYN}" "$_dom" "${RST}"
               cd "${HOME}/CloudPeler" && ${_CP} -d "$_dom" 2>&1 | tee -a "$LOG"; cd "${HOME}"
               echo ""; printf "  %sPress ENTER...%s" "${HOT}" "${RST}"; read -r _ ;;
            2) ! $CLOUDPELER_INSTALLED && { install_cloudpeler; $CLOUDPELER_INSTALLED || continue; }
               printf "  %sPaste domain: %s" "${HOT}" "${RST}"; read -r _dom
               [ -z "$_dom" ] && { printf "  %s[!] No domain.%s\n" "${RED}" "${RST}"; sleep 1; continue; }
               local _out="${HOME}/storage/downloads/cloudpeler_out.txt"
               [ ! -d "${HOME}/storage/downloads" ] && _out="${HOME}/cloudpeler_out.txt"
               cd "${HOME}/CloudPeler" && ${_CP} -d "$_dom" 2>&1 | tee "$_out" | tee -a "$LOG"; cd "${HOME}"
               printf "\n  %s[+] Saved: %s%s\n" "${GRN}" "$_out" "${RST}"
               echo ""; printf "  %sPress ENTER...%s" "${HOT}" "${RST}"; read -r _ ;;
            3) printf "  %sPaste command: %s" "${HOT}" "${RST}"; read -r _cmd
               [ -z "$_cmd" ] && { printf "  %s[!] Nothing entered.%s\n" "${RED}" "${RST}"; sleep 1; continue; }
               eval "$_cmd" 2>&1 | tee -a "$LOG"
               echo ""; printf "  %sPress ENTER...%s" "${HOT}" "${RST}"; read -r _ ;;
            i|I) install_cloudpeler ;;
            b|B) break ;;
            *) printf "  %s[!] Invalid.%s\n" "${RED}" "${RST}"; sleep 1 ;;
        esac
    done
}

submenu_mosint() {
    while true; do
        clear; banner; echo ""
        center_in_box "MOSINT · GO EMAIL PROFILING ENGINE"
        short_pink_line 34; echo ""
        printf "${PNK}╔══════════════════════════════════════════════════════════════╗${RST}\n"
        printf "${PNK}║${RST} ${CYN}SYNOPSIS:${RST} Mosint — fast Go email profiler: breach checks,   ${RST}\n"
        printf "${PNK}║${RST}          DNS records, MX, and linked social accounts.      ${RST}\n"
        printf "${PNK}║${RST} ${CYN}USE:${RST} Paste target email when prompted.                      ${RST}\n"
        printf "${PNK}║${RST} ${CYN}INSTALL:${RST} go install github.com/alpkeskin/mosint/v3@latest   ${RST}\n"
        printf "${PNK}╚══════════════════════════════════════════════════════════════╝${RST}\n\n"
        printf "  ${GRN}[1]${RST}  Profile Email         ${DESC}- mosint <email>${RST}\n"
        printf "  ${GRN}[2]${RST}  Save Output           ${DESC}- → downloads/mosint_out.txt${RST}\n"
        printf "  ${GRN}[3]${RST}  Paste Command         ${DESC}- run any mosint command directly${RST}\n"
        printf "  ${GRN}[I]${RST}  Install               ${DESC}- go install mosint${RST}\n"
        printf "  ${YLW}[B]${RST}  Back\n\n"
        printf "  %sChoose: %s" "${HOT}" "${RST}"; read -r SC
        local _MS="${HOME}/go/bin/mosint"; command -v mosint >/dev/null 2>&1 && _MS="mosint"
        case "$SC" in
            1) ! $MOSINT_INSTALLED && { install_mosint; $MOSINT_INSTALLED || continue; }
               printf "  %sPaste email: %s" "${HOT}" "${RST}"; read -r _email
               [ -z "$_email" ] && { printf "  %s[!] No email.%s\n" "${RED}" "${RST}"; sleep 1; continue; }
               printf "\n  %s[*] Running mosint on %s...%s\n\n" "${CYN}" "$_email" "${RST}"
               ${_MS} "$_email" 2>&1 | tee -a "$LOG"
               echo ""; printf "  %sPress ENTER...%s" "${HOT}" "${RST}"; read -r _ ;;
            2) ! $MOSINT_INSTALLED && { install_mosint; $MOSINT_INSTALLED || continue; }
               printf "  %sPaste email: %s" "${HOT}" "${RST}"; read -r _email
               [ -z "$_email" ] && { printf "  %s[!] No email.%s\n" "${RED}" "${RST}"; sleep 1; continue; }
               local _out="${HOME}/storage/downloads/mosint_out.txt"
               [ ! -d "${HOME}/storage/downloads" ] && _out="${HOME}/mosint_out.txt"
               ${_MS} "$_email" 2>&1 | tee "$_out" | tee -a "$LOG"
               printf "\n  %s[+] Saved: %s%s\n" "${GRN}" "$_out" "${RST}"
               echo ""; printf "  %sPress ENTER...%s" "${HOT}" "${RST}"; read -r _ ;;
            3) printf "  %sPaste command: %s" "${HOT}" "${RST}"; read -r _cmd
               [ -z "$_cmd" ] && { printf "  %s[!] Nothing entered.%s\n" "${RED}" "${RST}"; sleep 1; continue; }
               eval "$_cmd" 2>&1 | tee -a "$LOG"
               echo ""; printf "  %sPress ENTER...%s" "${HOT}" "${RST}"; read -r _ ;;
            i|I) install_mosint ;;
            b|B) break ;;
            *) printf "  %s[!] Invalid.%s\n" "${RED}" "${RST}"; sleep 1 ;;
        esac
    done
}

submenu_photon() {
    while true; do
        clear; banner; echo ""
        center_in_box "PHOTON · HIGH-SPEED SITE CRAWLER + EXFIL"
        short_pink_line 40; echo ""
        printf "${PNK}╔══════════════════════════════════════════════════════════════╗${RST}\n"
        printf "${PNK}║${RST} ${CYN}SYNOPSIS:${RST} Photon — crawls targets extracting emails, keys,  ${RST}\n"
        printf "${PNK}║${RST}          subdomains, JS files, and hidden endpoints.       ${RST}\n"
        printf "${PNK}║${RST} ${CYN}USE:${RST} Paste full URL (e.g. https://example.com).             ${RST}\n"
        printf "${PNK}║${RST} ${CYN}INSTALL:${RST} git clone https://github.com/s0md3v/Photon          ${RST}\n"
        printf "${PNK}╚══════════════════════════════════════════════════════════════╝${RST}\n\n"
        printf "  ${GRN}[1]${RST}  Basic Crawl           ${DESC}- python3 photon.py -u <url>${RST}\n"
        printf "  ${GRN}[2]${RST}  Deep Crawl (Depth 3)  ${DESC}- python3 photon.py -u <url> -l 3${RST}\n"
        printf "  ${GRN}[3]${RST}  Save to Folder        ${DESC}- → downloads/photon_out/${RST}\n"
        printf "  ${GRN}[4]${RST}  Paste Command         ${DESC}- run any photon command directly${RST}\n"
        printf "  ${GRN}[I]${RST}  Install               ${DESC}- git clone + pip${RST}\n"
        printf "  ${YLW}[B]${RST}  Back\n\n"
        printf "  %sChoose: %s" "${HOT}" "${RST}"; read -r SC
        local _PH="python3 ${HOME}/Photon/photon.py"
        case "$SC" in
            1) ! $PHOTON_INSTALLED && { install_photon_osint; $PHOTON_INSTALLED || continue; }
               printf "  %sPaste URL: %s" "${HOT}" "${RST}"; read -r _url
               [ -z "$_url" ] && { printf "  %s[!] No URL.%s\n" "${RED}" "${RST}"; sleep 1; continue; }
               echo "$_url" | grep -qE "^https?://" || _url="https://${_url}"
               printf "\n  %s[*] Crawling %s...%s\n\n" "${CYN}" "$_url" "${RST}"
               cd "${HOME}/Photon" && ${_PH} -u "$_url" 2>&1 | tee -a "$LOG"; cd "${HOME}"
               echo ""; printf "  %sPress ENTER...%s" "${HOT}" "${RST}"; read -r _ ;;
            2) ! $PHOTON_INSTALLED && { install_photon_osint; $PHOTON_INSTALLED || continue; }
               printf "  %sPaste URL: %s" "${HOT}" "${RST}"; read -r _url
               [ -z "$_url" ] && { printf "  %s[!] No URL.%s\n" "${RED}" "${RST}"; sleep 1; continue; }
               echo "$_url" | grep -qE "^https?://" || _url="https://${_url}"
               printf "\n  %s[*] Deep crawling %s (depth 3)...%s\n\n" "${CYN}" "$_url" "${RST}"
               cd "${HOME}/Photon" && ${_PH} -u "$_url" -l 3 2>&1 | tee -a "$LOG"; cd "${HOME}"
               echo ""; printf "  %sPress ENTER...%s" "${HOT}" "${RST}"; read -r _ ;;
            3) ! $PHOTON_INSTALLED && { install_photon_osint; $PHOTON_INSTALLED || continue; }
               printf "  %sPaste URL: %s" "${HOT}" "${RST}"; read -r _url
               [ -z "$_url" ] && { printf "  %s[!] No URL.%s\n" "${RED}" "${RST}"; sleep 1; continue; }
               echo "$_url" | grep -qE "^https?://" || _url="https://${_url}"
               local _out="${HOME}/storage/downloads/photon_out"
               [ ! -d "${HOME}/storage/downloads" ] && _out="${HOME}/photon_out"
               mkdir -p "$_out"
               cd "${HOME}/Photon" && ${_PH} -u "$_url" -o "$_out" 2>&1 | tee -a "$LOG"; cd "${HOME}"
               printf "\n  %s[+] Saved to: %s%s\n" "${GRN}" "$_out" "${RST}"
               echo ""; printf "  %sPress ENTER...%s" "${HOT}" "${RST}"; read -r _ ;;
            4) printf "  %sPaste command: %s" "${HOT}" "${RST}"; read -r _cmd
               [ -z "$_cmd" ] && { printf "  %s[!] Nothing entered.%s\n" "${RED}" "${RST}"; sleep 1; continue; }
               eval "$_cmd" 2>&1 | tee -a "$LOG"
               echo ""; printf "  %sPress ENTER...%s" "${HOT}" "${RST}"; read -r _ ;;
            i|I) install_photon_osint ;;
            b|B) break ;;
            *) printf "  %s[!] Invalid.%s\n" "${RED}" "${RST}"; sleep 1 ;;
        esac
    done
}

submenu_onionsearch() {
    while true; do
        clear; banner; echo ""
        center_in_box "ONIONSEARCH · DARK WEB SEARCH ENGINE"
        short_pink_line 36; echo ""
        printf "${PNK}╔══════════════════════════════════════════════════════════════╗${RST}\n"
        printf "${PNK}║${RST} ${CYN}SYNOPSIS:${RST} OnionSearch — scrapes 10+ .onion search engines   ${RST}\n"
        printf "${PNK}║${RST}          for keywords. Passive, no Tor client required.   ${RST}\n"
        printf "${PNK}║${RST} ${CYN}USE:${RST} Paste search query when prompted.                      ${RST}\n"
        printf "${PNK}║${RST} ${CYN}INSTALL:${RST} pip install onionsearch                            ${RST}\n"
        printf "${PNK}╚══════════════════════════════════════════════════════════════╝${RST}\n\n"
        printf "  ${GRN}[1]${RST}  Search Dark Web       ${DESC}- onionsearch \"<query>\"\n"
        printf "  ${GRN}[2]${RST}  Save Output           ${DESC}- → downloads/onionsearch_out.txt${RST}\n"
        printf "  ${GRN}[3]${RST}  Paste Command         ${DESC}- run any onionsearch command directly${RST}\n"
        printf "  ${GRN}[I]${RST}  Install               ${DESC}- pip install onionsearch${RST}\n"
        printf "  ${YLW}[B]${RST}  Back\n\n"
        printf "  %s[!] For legal OSINT research only. Respect your local laws.%s\n\n" "${RED}" "${RST}"
        printf "  %sChoose: %s" "${HOT}" "${RST}"; read -r SC
        case "$SC" in
            1) ! $ONIONSEARCH_INSTALLED && { install_onionsearch; $ONIONSEARCH_INSTALLED || continue; }
               printf "  %sPaste search query: %s" "${HOT}" "${RST}"; read -r _query
               [ -z "$_query" ] && { printf "  %s[!] No query.%s\n" "${RED}" "${RST}"; sleep 1; continue; }
               printf "\n  %s[*] Searching dark web for: %s...%s\n\n" "${CYN}" "$_query" "${RST}"
               onionsearch "$_query" 2>&1 | tee -a "$LOG"
               echo ""; printf "  %sPress ENTER...%s" "${HOT}" "${RST}"; read -r _ ;;
            2) ! $ONIONSEARCH_INSTALLED && { install_onionsearch; $ONIONSEARCH_INSTALLED || continue; }
               printf "  %sPaste search query: %s" "${HOT}" "${RST}"; read -r _query
               [ -z "$_query" ] && { printf "  %s[!] No query.%s\n" "${RED}" "${RST}"; sleep 1; continue; }
               local _out="${HOME}/storage/downloads/onionsearch_out.txt"
               [ ! -d "${HOME}/storage/downloads" ] && _out="${HOME}/onionsearch_out.txt"
               onionsearch "$_query" 2>&1 | tee "$_out" | tee -a "$LOG"
               printf "\n  %s[+] Saved: %s%s\n" "${GRN}" "$_out" "${RST}"
               echo ""; printf "  %sPress ENTER...%s" "${HOT}" "${RST}"; read -r _ ;;
            3) printf "  %sPaste command: %s" "${HOT}" "${RST}"; read -r _cmd
               [ -z "$_cmd" ] && { printf "  %s[!] Nothing entered.%s\n" "${RED}" "${RST}"; sleep 1; continue; }
               eval "$_cmd" 2>&1 | tee -a "$LOG"
               echo ""; printf "  %sPress ENTER...%s" "${HOT}" "${RST}"; read -r _ ;;
            i|I) install_onionsearch ;;
            b|B) break ;;
            *) printf "  %s[!] Invalid.%s\n" "${RED}" "${RST}"; sleep 1 ;;
        esac
    done
}

submenu_gitsniff() {
    while true; do
        clear; banner; echo ""
        center_in_box "GITSNIFF · GITHUB COMMIT METADATA RIPPER"
        short_pink_line 40; echo ""
        printf "${PNK}╔══════════════════════════════════════════════════════════════╗${RST}\n"
        printf "${PNK}║${RST} ${CYN}SYNOPSIS:${RST} GitSniff — rips commit metadata from public repos  ${RST}\n"
        printf "${PNK}║${RST}          to extract real emails and user identities.       ${RST}\n"
        printf "${PNK}║${RST} ${CYN}USE:${RST} Paste GitHub username or repo URL when prompted.       ${RST}\n"
        printf "${PNK}║${RST} ${CYN}INSTALL:${RST} git clone + pip install -r requirements.txt        ${RST}\n"
        printf "${PNK}╚══════════════════════════════════════════════════════════════╝${RST}\n\n"
        printf "  ${GRN}[1]${RST}  Sniff Username        ${DESC}- python3 gitsniff.py -u <username>${RST}\n"
        printf "  ${GRN}[2]${RST}  Sniff Repo            ${DESC}- python3 gitsniff.py -r <repo_url>${RST}\n"
        printf "  ${GRN}[3]${RST}  Save Output           ${DESC}- → downloads/gitsniff_out.txt${RST}\n"
        printf "  ${GRN}[4]${RST}  Paste Command         ${DESC}- run any gitsniff command directly${RST}\n"
        printf "  ${GRN}[I]${RST}  Install               ${DESC}- git clone + pip${RST}\n"
        printf "  ${YLW}[B]${RST}  Back\n\n"
        printf "  %sChoose: %s" "${HOT}" "${RST}"; read -r SC
        local _GS="python3 ${HOME}/GitSniff/gitsniff.py"
        case "$SC" in
            1) ! $GITSNIFF_INSTALLED && { install_gitsniff; $GITSNIFF_INSTALLED || continue; }
               printf "  %sPaste GitHub username: %s" "${HOT}" "${RST}"; read -r _uname
               [ -z "$_uname" ] && { printf "  %s[!] No username.%s\n" "${RED}" "${RST}"; sleep 1; continue; }
               printf "\n  %s[*] Sniffing commits for %s...%s\n\n" "${CYN}" "$_uname" "${RST}"
               cd "${HOME}/GitSniff" && ${_GS} -u "$_uname" 2>&1 | tee -a "$LOG"; cd "${HOME}"
               echo ""; printf "  %sPress ENTER...%s" "${HOT}" "${RST}"; read -r _ ;;
            2) ! $GITSNIFF_INSTALLED && { install_gitsniff; $GITSNIFF_INSTALLED || continue; }
               printf "  %sPaste repo URL: %s" "${HOT}" "${RST}"; read -r _repo
               [ -z "$_repo" ] && { printf "  %s[!] No repo URL.%s\n" "${RED}" "${RST}"; sleep 1; continue; }
               printf "\n  %s[*] Sniffing repo %s...%s\n\n" "${CYN}" "$_repo" "${RST}"
               cd "${HOME}/GitSniff" && ${_GS} -r "$_repo" 2>&1 | tee -a "$LOG"; cd "${HOME}"
               echo ""; printf "  %sPress ENTER...%s" "${HOT}" "${RST}"; read -r _ ;;
            3) ! $GITSNIFF_INSTALLED && { install_gitsniff; $GITSNIFF_INSTALLED || continue; }
               printf "  %sPaste GitHub username: %s" "${HOT}" "${RST}"; read -r _uname
               [ -z "$_uname" ] && { printf "  %s[!] No username.%s\n" "${RED}" "${RST}"; sleep 1; continue; }
               local _out="${HOME}/storage/downloads/gitsniff_out.txt"
               [ ! -d "${HOME}/storage/downloads" ] && _out="${HOME}/gitsniff_out.txt"
               cd "${HOME}/GitSniff" && ${_GS} -u "$_uname" 2>&1 | tee "$_out" | tee -a "$LOG"; cd "${HOME}"
               printf "\n  %s[+] Saved: %s%s\n" "${GRN}" "$_out" "${RST}"
               echo ""; printf "  %sPress ENTER...%s" "${HOT}" "${RST}"; read -r _ ;;
            4) printf "  %sPaste command: %s" "${HOT}" "${RST}"; read -r _cmd
               [ -z "$_cmd" ] && { printf "  %s[!] Nothing entered.%s\n" "${RED}" "${RST}"; sleep 1; continue; }
               eval "$_cmd" 2>&1 | tee -a "$LOG"
               echo ""; printf "  %sPress ENTER...%s" "${HOT}" "${RST}"; read -r _ ;;
            i|I) install_gitsniff ;;
            b|B) break ;;
            *) printf "  %s[!] Invalid.%s\n" "${RED}" "${RST}"; sleep 1 ;;
        esac
    done
}

show_menu() {
    clear
    printf "\n"
    printf "${HOT}   ___ ___ __________   __   ___ ___      _  ___  ___   ___  ___  ___ ${RST}\n"
    printf "${PNK}  | __| __|_  /_  /\ \ / /  / __|_ _|  _ | |/ _ \| __|  / _ \/ _ \/ _ \${RST}\n"
    printf "${PUR}  | _|| _| / / / /  \ V /  | (_ || |  | || | (_) | _|   \_, /\_, /\_, /${RST}\n"
    printf "${NEON_BLU}  |_| |___/___/___|  |_|    \___|___|  \__/ \___/|___|  /_/  /_/  /_/${RST}\n"
    printf "\n"
    new_neon_line
    printf "${HOT}${BLD}"
    center_in_box "FEZZY G.I.JOE · V12.0 · Fezzy Station · 999"
    printf "${RST}"
    new_neon_line
    echo ""
    
    # Dot indicators — safe boolean check, no subshell bleed
    N_DOT=$(dot_status "$NMAP_INSTALLED")
    C_DOT=$(dot_status "$CURL_INSTALLED")
    A_DOT=$(dot_status "$ALIAS_INSTALLED")
    T_DOT=$(dot_status "$TAPI_INSTALLED")
    DID=$(dot_status "$DOMAIN_INTEL_INSTALLED")
    WFD=$(dot_status "$WEB_FINGERPRINT_INSTALLED")
    SSD=$(dot_status "$SSL_CHECK_INSTALLED")
    VSD=$(dot_status "$VULN_SCAN_INSTALLED")
    DHD=$(dot_status "$DIRECTORY_HUNTER_INSTALLED")
    WCD=$(dot_status "$WEB_CRAWLER_INSTALLED")
    FED=$(dot_status "$FUZZING_ENGINE_INSTALLED")
    # V5 dots
    NCD=$(dot_status "$NETCAT_INSTALLED")
    JQD=$(dot_status "$JQ_INSTALLED")
    HVD=$(dot_status "$HARVESTER_INSTALLED")
    HPD=$(dot_status "$HTTPROBE_INSTALLED")
    SMD=$(dot_status "$SQLMAP_INSTALLED")
    WFO=$(dot_status "$WAFW00F_INSTALLED")
    FFD=$(dot_status "$FFUF_INSTALLED")
    # V8 dots
    AMD=$(dot_status "$AMASS_INSTALLED")
    NUD=$(dot_status "$NUCLEI_INSTALLED")
    KTD=$(dot_status "$KATANA_INSTALLED")
    SHD=$(dot_status "$SHUFFLEDNS_INSTALLED")
    HXD=$(dot_status "$HTTPX_T_INSTALLED")
    SFD=$(dot_status "$SUBFINDER_INSTALLED")
    NBD=$(dot_status "$NAABU_INSTALLED")
    DXD=$(dot_status "$DNSX_INSTALLED")
    MSD=$(dot_status "$MASSDNS_INSTALLED")
    WBD=$(dot_status "$WAYBACKURLS_INSTALLED")
    GAD=$(dot_status "$GAU_INSTALLED")
    # V10 · Fezzy Station dots
    ARD=$(dot_status "$ARJUN_INSTALLED")
    OPD=$(dot_status "$OPTIVA_INSTALLED")
    HUD=$(dot_status "$HIDDENURL_INSTALLED")
    # V11 dots
    DFD=$(dot_status "$DALFOX_INSTALLED")
    KXD=$(dot_status "$KXSS_INSTALLED")
    GFD=$(dot_status "$GF_INSTALLED")
    TFD=$(dot_status "$TRUFFLEHOG_INSTALLED")
    CFD=$(dot_status "$CRLFUZZ_INSTALLED")
    BPD=$(dot_status "$BYP4XX_INSTALLED")
    FBD=$(dot_status "$FEROXBUSTER_INSTALLED")
    AFD=$(dot_status "$ASSETFINDER_INSTALLED")
    GSD=$(dot_status "$GOSPIDER_INSTALLED")
    QRD=$(dot_status "$QSREPLACE_INSTALLED")
    UFD=$(dot_status "$UNFURL_INSTALLED")
    PSD=$(dot_status "$PARAMSPIDER_INSTALLED")
    SRD=$(dot_status "$SSRFMAP_INSTALLED")
    CHD=$(dot_status "$CHAOS_INSTALLED")
    # V12 OSINT dots
    HLE=$(dot_status "$HOLEHE_INSTALLED")
    BLD_=$(dot_status "$BLACKBIRD_INSTALLED")
    TTS=$(dot_status "$TOUTATIS_INSTALLED")
    MRT=$(dot_status "$MORIARTY_INSTALLED")
    DAP=$(dot_status "$DAPROFILER_INSTALLED")
    CLP=$(dot_status "$CLOUDPELER_INSTALLED")
    MST=$(dot_status "$MOSINT_INSTALLED")
    PHT=$(dot_status "$PHOTON_INSTALLED")
    ONS=$(dot_status "$ONIONSEARCH_INSTALLED")
    GTS=$(dot_status "$GITSNIFF_INSTALLED")

    pink_line
    printf "${CYN}  [ NETWORK SCANNING ]${RST}
"
    printf "${GRN}[1]${RST} Quick Scan           ${DESC}- Fast sweep of common ports${RST}
"
    printf "${GRN}[2]${RST} Add Alias fezzynmap  ${DESC}- Global alias ${A_DOT}${RST}
"
    printf "${GRN}[3]${RST} Full Port Scan       ${DESC}- All 65535 ports${RST}
"
    printf "${GRN}[4]${RST} Intense Scan         ${DESC}- OS + version + aggressive${RST}
"
    printf "${GRN}[5]${RST} Stealth SYN          ${DESC}- Low & slow (may need root)${RST}
"
    printf "${GRN}[6]${RST} UDP Scan             ${DESC}- UDP layer enumeration${RST}
"
    printf "${GRN}[7]${RST} Vuln Script          ${DESC}- NSE vulnerability scan${RST}
"
    printf "${GRN}[8]${RST} Custom Flags         ${DESC}- Your own nmap flags${RST}
"
    printf "${GRN}[9]${RST} Paste Command        ${DESC}- Run any nmap command raw${RST}
"
    printf "${GRN}[10]${RST} Advanced Output    ${DESC}- XML, Grepable, All formats${RST}
"
    printf "${GRN}[11]${RST} Evasion & Stealth  ${DESC}- Decoys, Spoofing, Frag${RST}
"
    printf "${GRN}[12]${RST} Script Categories  ${DESC}- Safe, Auth, Discovery scripts${RST}
"
    printf "${GRN}[13]${RST} Advanced Targets   ${DESC}- Target lists, Exclusions${RST}
"
    printf "${GRN}[14]${RST} Advanced Stealth   ${DESC}- Idle Scan (-sI)${RST}
"
    printf "${GRN}[15]${RST} Network Spoofing   ${DESC}- MAC Address Spoofing${RST}
"
    printf "${GRN}[16]${RST} Firewall Testing   ${DESC}- Bad Checksums (--badsum)${RST}
"
    printf "${GRN}[17]${RST} Timing & Perf      ${DESC}- T0 to T5 Templates${RST}
"
    printf "${GRN}[18]${RST} NSE Pro            ${DESC}- Specific Script execution${RST}
"
    printf "${CYN}  [ ADVANCED NMAP FEATURES ]${RST}
"
    printf "${GRN}[19]${RST} IPv6 Scan         ${DESC}- Scan using -6 flag${RST}
"
    printf "${GRN}[20]${RST} Packet Trace      ${DESC}- Trace packets with --packet-trace${RST}
"
    printf "${GRN}[21]${RST} Traceroute        ${DESC}- Use --traceroute${RST}
"
    printf "${GRN}[22]${RST} DNS Servers       ${DESC}- Set --dns-servers${RST}
"
    printf "${GRN}[23]${RST} Version Intensity ${DESC}- Set --version-intensity${RST}
"
    printf "${GRN}[24]${RST} OS Detection      ${DESC}- Set accuracy control${RST}
"
    printf "${GRN}[25]${RST} Parallelism       ${DESC}- Set --min/max-parallelism${RST}
"
    printf "${GRN}[26]${RST} Packet Rate       ${DESC}- Set --min/max-rate${RST}
"
    printf "${GRN}[27]${RST} Interface         ${DESC}- Select with -e${RST}
"
    printf "${GRN}[28]${RST} Proxy Support     ${DESC}- Use --proxies${RST}
"
    printf "${GRN}[29]${RST} NSE Script Args   ${DESC}- Set --script-args${RST}
"
    printf "${GRN}[30]${RST} Host Timeout      ${DESC}- Set --host-timeout${RST}
"
    printf "${GRN}[31]${RST} Scan Delay        ${DESC}- Set --scan-delay${RST}
"
    printf "${GRN}[32]${RST} Max Retries       ${DESC}- Set --max-retries${RST}
"
    printf "${GRN}[33]${RST} No Ping           ${DESC}- Use -Pn${RST}
"
    printf "${GRN}[34]${RST} SCTP Scanning     ${DESC}- Use -sZ${RST}
"
    echo ""
    printf "${CYN}  [ WIFI ELITE · DIAGNOSTICS ]${RST}
"
    printf "${GRN}[W1]${RST} Scan Nearby Networks ${DESC}- List SSIDs, Signal, Channels${RST}
"
    printf "${GRN}[W2]${RST} Gateway Discovery   ${DESC}- Find router IP & details${RST}
"
    printf "${GRN}[W3]${RST} Local Device Scan   ${DESC}- Quick scan of connected hosts${RST}
"
    printf "${GRN}[W4]${RST} Network Bench       ${DESC}- Simple ping latency check${RST}
"
    echo ""
    printf "${CYN}  [ WEB ARSENAL · G.I.JOE ]${RST}\n"
    printf "${GRN}[35]${RST} Domain Intel      ${DESC}- DNS & Whois${RST}              ${DID}\n"
    printf "${GRN}[36]${RST} Fingerprint       ${DESC}- Tech Stack ID${RST}            ${WFD}\n"
    printf "${GRN}[37]${RST} SSL Check         ${DESC}- Cert Analysis${RST}            ${SSD}\n"
    printf "${GRN}[38]${RST} Vulnerability     ${DESC}- Server Audit (nikto)${RST}     ${VSD}\n"
    printf "${GRN}[39]${RST} Dir Hunter        ${DESC}- Dir & Subdomain Brute${RST}    ${DHD}\n"
    printf "${GRN}[40]${RST} Web Crawler       ${DESC}- Link Extractor (photon)${RST}  ${WCD}\n"
    printf "${GRN}[41]${RST} Fuzzing Engine    ${DESC}- Payload Testing (wfuzz)${RST}  ${FED}\n"
    printf "${GRN}[42]${RST} Raw Probe         ${DESC}- Service banner reader (tip: netcat)${RST}  ${NCD}\n"
    printf "${GRN}[43]${RST} Data Parser       ${DESC}- API response decoder (tip: jq)${RST}   ${JQD}\n"
    printf "${GRN}[44]${RST} Intel Sweep       ${DESC}- Passive OSINT collector (tip: theHarvester)${RST} ${HVD}\n"
    printf "${GRN}[45]${RST} WiFi Deep Scan    ${DESC}- Extended wireless diagnostics${RST}
"
    printf "${GRN}[46]${RST} Ghost Trace       ${DESC}- Live host confirmation engine (tip: httprobe)${RST} ${HPD}\n"
    printf "${GRN}[47]${RST} The Injector      ${DESC}- Parameter attack surface probe (tip: sqlmap)${RST} ${SMD}\n"
    printf "${GRN}[48]${RST} Shield Breaker    ${DESC}- WAF identification engine (tip: wafw00f)${RST} ${WFO}\n"
    printf "${GRN}[49]${RST} Shredder          ${DESC}- Ultra-fast endpoint fuzzer (tip: ffuf)${RST} ${FFD}\n"
    echo ""
    printf "${CYN}  [ V8 · ROOTLESS RECON ARSENAL ]${RST}\n"
    printf "${GRN}[50]${RST} Amass              ${DESC}- Passive subdomain enum (30+ sources)${RST}   ${AMD}\n"
    printf "${GRN}[51]${RST} Nuclei             ${DESC}- Template-based vuln scanner${RST}            ${NUD}\n"
    printf "${GRN}[52]${RST} Katana             ${DESC}- JS-aware web crawler${RST}                   ${KTD}\n"
    printf "${GRN}[53]${RST} ShuffleDNS         ${DESC}- High-speed DNS resolver wrapper${RST}        ${SHD}\n"
    printf "${GRN}[54]${RST} HTTPX              ${DESC}- HTTP probe · status/title/tech${RST}         ${HXD}\n"
    printf "${GRN}[55]${RST} Subfinder          ${DESC}- Passive subdomain discovery${RST}            ${SFD}\n"
    printf "${GRN}[56]${RST} Naabu              ${DESC}- Rootless fast port scanner${RST}             ${NBD}\n"
    printf "${GRN}[57]${RST} DNSx               ${DESC}- Bulk DNS resolution · A/CNAME/MX${RST}      ${DXD}\n"
    printf "${GRN}[58]${RST} MassDNS            ${DESC}- 1000x bulk DNS resolver${RST}               ${MSD}\n"
    printf "${GRN}[59]${RST} Waybackurls        ${DESC}- Historical URL extraction${RST}              ${WBD}\n"
    printf "${GRN}[60]${RST} GAU                ${DESC}- All URLs from archives${RST}                 ${GAD}\n"
    echo ""
    printf "${CYN}  [ V10 · FEZZY STATION · S.O.I ARSENAL ]${RST}\n"
    printf "${GRN}[61]${RST} Arjun              ${DESC}- Hidden parameter discovery${RST}              ${ARD}\n"
    printf "${GRN}[62]${RST} Optiva Framework   ${DESC}- Multi-module offensive toolkit${RST}          ${OPD}\n"
    printf "${GRN}[63]${RST} HiddenURL          ${DESC}- Obscured path & URL discovery${RST}           ${HUD}\n"
    echo ""
    echo ""
    printf "${CYN}  [ V11 · BOUNTY ARSENAL ]${RST}\n"
    printf "${GRN}[64]${RST} Dalfox            ${DESC}- XSS scanner + PoC generator${RST}           ${DFD}\n"
    printf "${GRN}[65]${RST} KXSS              ${DESC}- Reflected XSS parameter finder${RST}         ${KXD}\n"
    printf "${GRN}[66]${RST} GF Patterns       ${DESC}- grep filter (xss/sqli/lfi/ssrf/idor/rce)${RST} ${GFD}\n"
    printf "${GRN}[67]${RST} TruffleHog        ${DESC}- Secret & credential scanner${RST}            ${TFD}\n"
    printf "${GRN}[68]${RST} CRLFuzz           ${DESC}- CRLF injection fuzzer${RST}                  ${CFD}\n"
    printf "${GRN}[69]${RST} Byp4xx            ${DESC}- 403 bypass engine${RST}                      ${BPD}\n"
    printf "${GRN}[70]${RST} Feroxbuster       ${DESC}- Recursive content discovery${RST}            ${FBD}\n"
    printf "${GRN}[71]${RST} Assetfinder       ${DESC}- Fast subdomain discovery${RST}               ${AFD}\n"
    printf "${GRN}[72]${RST} Gospider          ${DESC}- Fast web spider · JS/form extraction${RST}   ${GSD}\n"
    printf "${GRN}[73]${RST} Qsreplace         ${DESC}- Replace querystring values with payloads${RST} ${QRD}\n"
    printf "${GRN}[74]${RST} Unfurl            ${DESC}- URL structure parser · keys/values/paths${RST} ${UFD}\n"
    printf "${GRN}[75]${RST} ParamSpider       ${DESC}- Web archive parameter miner${RST}             ${PSD}\n"
    printf "${GRN}[76]${RST} SSRFmap           ${DESC}- SSRF detection and exploitation${RST}         ${SRD}\n"
    printf "${GRN}[77]${RST} Chaos             ${DESC}- ProjectDiscovery subdomain dataset${RST}      ${CHD}\n"
    echo ""
    printf "${CYN}  [ V12 · OSINT INTEL ]${RST}\n"
    printf "  ${GRN}[78]${RST} Holehe           ${DESC}- Email → 120+ site account check${RST}        ${HLE}\n"
    printf "  ${GRN}[79]${RST} Blackbird        ${DESC}- Username footprint scanner${RST}             ${BLD_}\n"
    printf "  ${GRN}[80]${RST} Toutatis         ${DESC}- Instagram hidden detail extractor${RST}      ${TTS}\n"
    printf "  ${GRN}[81]${RST} Moriarty         ${DESC}- Phone intel · AWS + business regs${RST}      ${MRT}\n"
    printf "  ${GRN}[82]${RST} DaProfiler       ${DESC}- EU/Global identity footprint mapper${RST}    ${DAP}\n"
    printf "  ${GRN}[83]${RST} CloudPeler       ${DESC}- Real IP behind Cloudflare via DNS${RST}      ${CLP}\n"
    printf "  ${GRN}[84]${RST} Mosint           ${DESC}- Go email profiler · breach+DNS+MX${RST}      ${MST}\n"
    printf "  ${GRN}[85]${RST} Photon           ${DESC}- High-speed site crawler + exfil${RST}        ${PHT}\n"
    printf "  ${GRN}[86]${RST} OnionSearch      ${DESC}- Dark web 10+ .onion engine scraper${RST}     ${ONS}\n"
    printf "  ${GRN}[87]${RST} GitSniff         ${DESC}- GitHub commit metadata ripper${RST}          ${GTS}\n"
    echo ""
        printf "${GRN}[WA]${RST} Install Full Suite ${DESC}- Install all modules (35-49)${RST}\n"
    printf "${GRN}[R]${RST} Report Builder       ${DESC}- Build session recon report${RST}\n"
    printf "${GRN}[M]${RST} AUTOMATIC SCANS      ${DESC}- AI Network Discovery Strategy${RST}
"
    printf "${GRN}[I]${RST} Install Deps         ${DESC}- nmap(${N_DOT}) curl(${C_DOT})${RST}
"
    printf "${GRN}[U]${RST} Update Script        ${DESC}- Self-update from GitHub${RST}
"
    printf "${GRN}[V]${RST} Check Version        ${DESC}- Show nmap & script version${RST}
"
    printf "${GRN}[L]${RST} View Last Log        ${DESC}- Read previous scan${RST}
"
    printf "${GRN}[F]${RST} Facebook             ${DESC}- More scripts & tools${RST}
"
    printf "${GRN}[0]${RST} Exit                 ${DESC}- 999 · Out${RST}
"
    pink_line
    printf "${RST}
"
    printf "${GRN}●${RST}=Installed  ${RED}○${RST}=Missing  ${DESC}Descriptions${RST}

"
    printf "${HOT}Select option and press enter: ${RST}"
    read -r CHOICE
}

# ============================================================
#  MAIN EXECUTION
# ============================================================

check_deps
alias_check
clear
banner
echo ""
center_in_box "FEZZY G.I.JOE · FEZZY STATION · V12.0"
pink_line
echo ""
printf "  %sWelcome to the Fezzy Multiverse! The Admin Fezzy, Intoxicated Fezzy,%s\n" "${HOT}" "${RST}"
printf "  %sand the Fezzy Multiverse converge to command your digital arsenal.%s\n" "${HOT}" "${RST}"
printf "  %sBojack, the security daemon, stands guard. Strategy Over Impulse. 999.%s\n" "${HOT}" "${RST}"
echo ""
pink_line
center_in_box "FEZZY G.I.JOE · SYNOPSIS"
pink_line
echo ""
printf "  %sI walk the digital shadow, every footprint left a story\n" "${GRN}"
printf "  Network ports and web stacks – I find every hole\n"
printf "  Domain intel, SSL certs, directories – I take control\n"
printf "  FEZZY G.I.JOE – Strategy Over Impulse. 999.%s\n" "${RST}"
echo ""
printf "  %sKey Modules:%s\n" "${GRN}" "${RST}"
printf "  • Network Scanning – Quick, Full, Intense, Stealth, UDP, Vuln\n"
printf "  • Domain Intelligence – DNS & WHOIS lookups + brute force\n"
printf "  • Web Fingerprint – Tech stack detection (whatweb)\n"
printf "  • SSL Check – Certificate analysis, weak ciphers\n"
printf "  • Vulnerability Scan – Web server security audit (nikto)\n"
printf "  • SQLMap – SQL injection detection (fills niktofs gap)\n"
printf "  • WAF Detect – Dedicated WAF ID via wafw00f\n"
printf "  • Directory Hunter – Dir & subdomain brute force (gobuster)\n"
printf "  • FFUF – Fast fuzzing engine (replaces/enhances wfuzz)\n"
printf "  • Web Crawler – Link & endpoint extraction (photon)\n"
printf "  • Fuzzing Engine – Parameter & payload testing (wfuzz)\n"
printf "  • Netcat – Banner grabbing, port testing, service probing\n"
printf "  • JQ – Parse JSON API responses from recon tools\n"
printf "  • theHarvester – Emails, subdomains, IPs via public OSINT\n"
printf "  • Httprobe – Confirm live HTTP/S hosts from domain lists\n"
printf "  • WiFi Elite – Rootless network diagnostics\n"
printf "  • Automated recon strategies + integrated logging\n"
echo ""
printf "  %sV8 · Rootless Recon Arsenal:%s\n" "${CYN}" "${RST}"
printf "  • Amass – Passive subdomain enum via 30+ sources (Shodan, Censys, VirusTotal)\n"
printf "  • Nuclei – YAML-template vuln scanner · 9000+ CVE/misconfig/exposure templates\n"
printf "  • Katana – JS-aware web crawler · extracts endpoints, forms, JS sources\n"
printf "  • ShuffleDNS – High-speed DNS resolver wrapper for MassDNS\n"
printf "  • HTTPX – HTTP probe · status codes, titles, tech detection (rootless)\n"
printf "  • Subfinder – Passive subdomain discovery via 30+ passive sources\n"
printf "  • Naabu – Fast port scanner · no root required (replaces nmap SYN)\n"
printf "  • DNSx – Bulk DNS resolution · A, AAAA, CNAME, MX records at speed\n"
printf "  • MassDNS – 1000x bulk DNS resolver for large domain lists\n"
printf "  • Waybackurls – Historical URL extraction from archive.org\n"
printf "  • GAU – Get All URLs from Wayback, CommonCrawl, and archives\n"
echo ""
printf "  %sV11 · Bounty Arsenal:%s\n" "${HOT}" "${RST}"
printf "  • Dalfox      – XSS scanner with blind XSS + PoC generator (Go, rootless)\n"
printf "  • KXSS        – Fast reflected XSS parameter finder (Go, rootless)\n"
printf "  • GF          – grep filter for xss/sqli/lfi/ssrf/idor/rce URL patterns\n"
printf "  • TruffleHog  – Secret & API key scanner for git repos + filesystems\n"
printf "  • CRLFuzz     – CRLF injection fuzzer (Go, rootless)\n"
printf "  • Byp4xx      – 403 Forbidden bypass engine (Go, rootless)\n"
printf "  • Feroxbuster – Recursive directory & content discovery (Rust)\n"
echo ""
printf "  %sStrategy Over Impulse. Built for the Elite.%s\n" "${HOT}" "${RST}"
echo ""
pink_line
center_in_box "FEZZY G.I.JOE · LEGAL DISCLAIMER & TERMS OF USE"
pink_line
echo ""
printf "  %s╔══════════════════════════════════════════════════════════════════╗%s\n" "${RED}" "${RST}"
printf "  %s║              ⚠  IMPORTANT — READ BEFORE USE  ⚠                 ║%s\n" "${RED}" "${RST}"
printf "  %s╚══════════════════════════════════════════════════════════════════╝%s\n" "${RED}" "${RST}"
echo ""
printf "  %s1. AUTHORIZED USE ONLY%s\n" "${YLW}" "${RST}"
printf "     This tool is strictly for use on systems and networks you OWN\n"
printf "     or have EXPLICIT WRITTEN PERMISSION to test. No exceptions.\n"
echo ""
printf "  %s2. LEGAL COMPLIANCE%s\n" "${YLW}" "${RST}"
printf "     Unauthorized scanning, probing, or access of networks is a\n"
printf "     criminal offence under the Computer Misuse Act, CFAA, ECPA,\n"
printf "     and equivalent laws in your jurisdiction. You can be prosecuted.\n"
echo ""
printf "  %s3. NO LIABILITY%s\n" "${YLW}" "${RST}"
printf "     The author (Grant Festers / Fezzy Arsenal) accepts zero liability\n"
printf "     for damage, data loss, legal consequences, or misuse arising from\n"
printf "     the use of this tool. You deploy it — you own the outcome.\n"
echo ""
printf "  %s4. EDUCATIONAL PURPOSE%s\n" "${YLW}" "${RST}"
printf "     FEZZY G.I.JOE is built for security researchers, penetration\n"
printf "     testers, CTF players, and students operating in legal, controlled\n"
printf "     environments. It is not a weapon. Use it with integrity.\n"
echo ""
printf "  %s5. STRATEGY OVER IMPULSE — 999%s\n" "${YLW}" "${RST}"
printf "     Think before you scan. Document your scope. Respect boundaries.\n"
printf "     A good operator knows when NOT to pull the trigger.\n"
echo ""
printf "  %s  Your actions. Your responsibility. Strategy Over Impulse. 999.%s\n" "${RED}" "${RST}"
echo ""
printf "  %sPress ENTER to enter the Arsenal...%s" "${HOT}" "${RST}"
read -r _
session_target_prompt

while true; do
    show_menu
    case "${CHOICE,,}" in
    1) run_scan "-T4 -F"           "Quick Scan"    ;;
    2) alias_setup ;;
    3) run_scan "-T4 -p-"          "Full Port Scan" ;;
    4) run_scan "-T4 -A -v"        "Intense Scan"  ;;
    5) run_scan "-sS -T2"          "Stealth SYN"   ;;
    6) run_scan "-sU"              "UDP Scan"      ;;
    7) run_scan "--script vuln"    "Vuln Script"   ;;
    8)
        clear; banner; echo ""
        printf "  %sEnter custom flags: %s" "${HOT}" "${RST}"
        read -r CUSTOM_FLAGS
        [ -n "$CUSTOM_FLAGS" ] && run_scan "$CUSTOM_FLAGS" "Custom"
        ;;
    9) run_paste ;;
    10) advanced_output_menu ;;
    11) evasion_stealth_menu ;;
    12) script_category_menu ;;
    13) advanced_targets_menu ;;
    14) advanced_stealth_menu ;;
    15) network_spoofing_menu ;;
    16) firewall_testing_menu ;;
    17) timing_performance_menu ;;
    18) nse_pro_menu ;;
    19) run_scan "-6" "IPv6 Scan" ;;
    20) run_scan "--packet-trace" "Packet Trace" ;;
    21) run_scan "--traceroute" "Traceroute" ;;
    22) printf "  %sEnter DNS servers: %s" "${HOT}" "${RST}"; read -r dns; run_scan "--dns-servers $dns" "DNS Resolution Control" ;;
    23) printf "  %sEnter intensity (0-9): %s" "${HOT}" "${RST}"; read -r int; run_scan "--version-intensity $int" "Service Version Intensity" ;;
    24) run_scan "--osscan-limit --osscan-guess" "OS Detection Accuracy" ;;
    25) printf "  %sEnter min-parallelism: %s" "${HOT}" "${RST}"; read -r min; printf "  %sEnter max-parallelism: %s" "${HOT}" "${RST}"; read -r max; run_scan "--min-parallelism $min --max-parallelism $max" "Parallelism Control" ;;
    26) printf "  %sEnter min-rate: %s" "${HOT}" "${RST}"; read -r min; printf "  %sEnter max-rate: %s" "${HOT}" "${RST}"; read -r max; run_scan "--min-rate $min --max-rate $max" "Packet Rate Control" ;;
    27) printf "  %sEnter interface: %s" "${HOT}" "${RST}"; read -r iface; run_scan "-e $iface" "Interface Selection" ;;
    28) printf "  %sEnter proxy: %s" "${HOT}" "${RST}"; read -r proxy; run_scan "--proxies $proxy" "Proxy Support" ;;
    29) printf "  %sEnter script args: %s" "${HOT}" "${RST}"; read -r args; run_scan "--script-args $args" "NSE Script Args" ;;
    30) printf "  %sEnter host timeout: %s" "${HOT}" "${RST}"; read -r tout; run_scan "--host-timeout $tout" "Host Timeout Control" ;;
    31) printf "  %sEnter scan delay: %s" "${HOT}" "${RST}"; read -r delay; run_scan "--scan-delay $delay" "Scan Delay Control" ;;
    32) printf "  %sEnter max-retries: %s" "${HOT}" "${RST}"; read -r ret; run_scan "--max-retries $ret" "Retry Control" ;;
    33) run_scan "-Pn" "No Ping" ;;
    34) run_scan "-sZ" "SCTP Scanning" ;;
    w1) wifi_elite_menu ;;
    w2) wifi_elite_menu ;;
    w3) wifi_elite_menu ;;
    w4) wifi_elite_menu ;;
    35) submenu_domain_intel ;;
    36) submenu_web_fingerprint ;;
    37) submenu_ssl_check ;;
    38) submenu_vulnerability_scan ;;
    39) submenu_directory_hunter ;;
    40) submenu_web_crawler ;;
    41) submenu_fuzzing_engine ;;
    42) submenu_netcat ;;
    43) submenu_jq ;;
    44) submenu_harvester ;;
    45) wifi_elite_menu ;;
    46) submenu_httprobe ;;
    47) submenu_sqlmap ;;
    48) submenu_wafw00f ;;
    49) submenu_ffuf ;;
    50) submenu_amass ;;
    51) submenu_nuclei ;;
    52) submenu_katana ;;
    53) submenu_shuffledns ;;
    54) submenu_httpx_tool ;;
    55) submenu_subfinder ;;
    56) submenu_naabu ;;
    57) submenu_dnsx ;;
    58) submenu_massdns ;;
    59) submenu_waybackurls ;;
    60) submenu_gau ;;
    61) submenu_arjun ;;
    62) submenu_optiva ;;
    63) submenu_hiddenurl ;;
    64) submenu_dalfox ;;
    65) submenu_kxss ;;
    66) submenu_gf ;;
    67) submenu_trufflehog ;;
    68) submenu_crlfuzz ;;
    69) submenu_byp4xx ;;
    70) submenu_feroxbuster ;;
    71) submenu_assetfinder ;;
    72) submenu_gospider ;;
    73) submenu_qsreplace ;;
    74) submenu_unfurl ;;
    75) submenu_paramspider ;;
    76) submenu_ssrfmap ;;
    77) submenu_chaos ;;
    78) submenu_holehe ;;
    79) submenu_blackbird ;;
    80) submenu_toutatis ;;
    81) submenu_moriarty ;;
    82) submenu_daprofiler ;;
    83) submenu_cloudpeler ;;
    84) submenu_mosint ;;
    85) submenu_photon ;;
    86) submenu_onionsearch ;;
    87) submenu_gitsniff ;;
    wa) install_all_web_modules ;;
    r) report_builder_menu ;;
    m) auto_scan_menu ;;
    i) install_deps ;;
    u) self_update ;;
    v)
        clear; banner; echo ""
        printf "%sScript: %s%s
" "${GRN}" "$SCRIPT_VERSION" "${RST}"
        command -v nmap >/dev/null 2>&1 && nmap --version 2>&1 | head -3 || printf "%s    nmap not installed%s
" "${RED}" "${RST}"
        echo ""; printf "  %sPress ENTER...%s" "${HOT}" "${RST}"; read -r _
        ;;
    l)
        clear; banner; echo ""
        [ -f "$LOG" ] && cat "$LOG" || printf "  %s  No log yet.%s
" "${RED}" "${RST}"
        echo ""; printf "  %sPress ENTER...%s" "${HOT}" "${RST}"; read -r _
        ;;
    f) open_facebook ;;
    0) printf "
  %s999 · Fezzy Arsenal · Out.%s

" "${HOT}" "${RST}"; exit 0 ;;
    *) printf "  %s[!] Invalid.%s
" "${RED}" "${RST}"; sleep 1 ;;
    esac
done
