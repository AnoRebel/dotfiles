#!/usr/bin/env bash
# AnoSpot — LocalSend device discovery.
# Two-phase: UDP multicast announce/listen, then HTTPS scan of the local
# /24 as a fallback for hosts that don't announce. Emits one line per
# discovered device:    <alias>\t<ip>
#
# Ported from Devvvmn/ActivSpot (experimental branch). Changes from
# upstream:
#   - Alias is parameterized via env ANOSPOT_ALIAS (default "AnoSpot").
#   - Multicast wait is configurable via ANOSPOT_DISCOVER_TIMEOUT (sec).
#
# Dependencies: bash, python3, ip (iproute2). No external pip packages.

ALIAS="${ANOSPOT_ALIAS:-AnoSpot}"
TIMEOUT="${ANOSPOT_DISCOVER_TIMEOUT:-2.0}"

export ANOSPOT_ALIAS_EXPORT="$ALIAS"
export ANOSPOT_TIMEOUT_EXPORT="$TIMEOUT"

python3 - <<'EOF'
import os, socket, json, time, struct, re, subprocess, asyncio, ssl, sys

ALIAS = os.environ.get("ANOSPOT_ALIAS_EXPORT", "AnoSpot")
TIMEOUT = float(os.environ.get("ANOSPOT_TIMEOUT_EXPORT", "2.0"))

MCAST = '224.0.0.167'
PORT  = 53317

try:
    out = subprocess.check_output(["ip", "-4", "addr"], text=True)
except Exception:
    out = ""
local_ips = set(re.findall(r'inet (\d+\.\d+\.\d+\.\d+)', out))

# Pick the source IP that routes to multicast (the LAN-facing iface).
lan_ip = ""
try:
    route_out = subprocess.check_output(["ip", "route", "get", MCAST], text=True)
    src_m = re.search(r'src (\d+\.\d+\.\d+\.\d+)', route_out)
    if src_m:
        lan_ip = src_m.group(1)
except Exception:
    pass

seen = set()

def emit(ip, alias):
    if ip in seen or ip in local_ips:
        return
    seen.add(ip)
    # alias may contain tabs/newlines from a malicious peer — strip them.
    safe_alias = re.sub(r'[\t\r\n]+', ' ', str(alias)).strip() or "Unknown"
    print(f"{safe_alias}\t{ip}", flush=True)

# ── Phase 1: UDP multicast announce/listen ────────────────────────────────
rx = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)
rx.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
try:
    rx.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEPORT, 1)
except Exception:
    pass
try:
    rx.bind(('', PORT))
    if lan_ip:
        mreq = struct.pack('4s4s', socket.inet_aton(MCAST), socket.inet_aton(lan_ip))
    else:
        mreq = struct.pack('4sL', socket.inet_aton(MCAST), socket.INADDR_ANY)
    rx.setsockopt(socket.IPPROTO_IP, socket.IP_ADD_MEMBERSHIP, mreq)
    rx.settimeout(0.1)

    tx = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)
    tx.setsockopt(socket.IPPROTO_IP, socket.IP_MULTICAST_TTL, 4)
    if lan_ip:
        tx.setsockopt(socket.IPPROTO_IP, socket.IP_MULTICAST_IF, socket.inet_aton(lan_ip))

    announce = json.dumps({
        "alias": ALIAS, "version": "2.1",
        "deviceModel": None, "deviceType": "headless",
        "fingerprint": "anospot_discover",
        "port": PORT, "protocol": "https",
        "download": False, "announce": True
    }).encode()

    tx.sendto(announce, (MCAST, PORT))
    deadline = time.time() + TIMEOUT
    sent_second = False
    while time.time() < deadline:
        if not sent_second and time.time() > deadline - (TIMEOUT / 2):
            tx.sendto(announce, (MCAST, PORT))
            sent_second = True
        try:
            data, (ip, _) = rx.recvfrom(65536)
            if ip in local_ips:
                continue
            try:
                info = json.loads(data.decode())
            except Exception:
                continue
            if info.get('fingerprint') == 'anospot_discover':
                continue
            emit(ip, info.get('alias', 'Unknown'))
        except socket.timeout:
            pass
except Exception as e:
    print(f"[discover] multicast phase failed: {e}", file=sys.stderr)

# ── Phase 2: HTTPS sweep of local /24 ─────────────────────────────────────
if not lan_ip:
    sys.exit(0)

prefix = '.'.join(lan_ip.split('.')[:3])
ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

async def probe(ip):
    if ip in local_ips or ip in seen:
        return
    try:
        r, w = await asyncio.wait_for(
            asyncio.open_connection(ip, PORT, ssl=ctx), timeout=0.6)
        w.write(f"GET /api/localsend/v2/info HTTP/1.0\r\nHost: {ip}\r\nConnection: close\r\n\r\n".encode())
        await w.drain()
        data = await asyncio.wait_for(r.read(4096), timeout=0.6)
        w.close()
        try:
            await asyncio.wait_for(w.wait_closed(), timeout=0.2)
        except Exception:
            pass
        body = data.split(b'\r\n\r\n', 1)
        if len(body) < 2:
            return
        info = json.loads(body[1].decode())
        emit(ip, info.get('alias', 'Unknown'))
    except Exception:
        pass

async def scan():
    tasks = [probe(f"{prefix}.{i}") for i in range(1, 255)]
    await asyncio.gather(*tasks)

try:
    asyncio.run(scan())
except Exception as e:
    print(f"[discover] http phase failed: {e}", file=sys.stderr)
EOF
