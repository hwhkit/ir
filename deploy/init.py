#!/usr/bin/env python3
"""一次性初始化：等 Core → admin 登录 → 创建 remote_pull 演示智能体。"""
import json, os, sys, time, urllib.request, urllib.error, http.cookiejar

CORE = os.environ["CORE"]
USER = os.environ["ADMIN__USERNAME"]
PASSWORD = os.environ["ADMIN__PASSWORD"]
DEMO_KEY = os.environ["DEMO_KEY"]

cj = http.cookiejar.CookieJar()
opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(cj))

def call(method, path, payload=None, headers=None):
    data = json.dumps(payload).encode() if payload is not None else None
    req = urllib.request.Request(CORE + path, data=data, method=method)
    req.add_header("Content-Type", "application/json")
    for k, v in (headers or {}).items():
        req.add_header(k, v)
    try:
        with opener.open(req, timeout=10) as resp:
            return resp.status, json.loads(resp.read().decode())
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode()[:300]

print("[init] waiting for core health...")
for _ in range(60):
    try:
        with urllib.request.urlopen(CORE + "/health/ready", timeout=5) as r:
            if r.status == 200:
                break
    except Exception:
        time.sleep(1)
else:
    sys.exit("[init] FATAL: core not ready")

st, login = call("POST", "/api/admin/v2/login",
                 {"username": USER, "password": PASSWORD})
csrf = (login.get("data") or {}).get("csrfToken") if isinstance(login, dict) else None
if st != 200 or not csrf:
    sys.exit(f"[init] FATAL: login failed: {st} {login}")
print("[init] admin login ok")

agent = {"slug": "pool-demo", "name": "Pool Demo",
         "executor_kind": "remote-pull", "execution_mode": "remote_pull",
         "positions": ["STRATEGIST"], "signing_secret": DEMO_KEY,
         "max_concurrency": 2, "queue_capacity": 8}
st, resp = call("POST", "/api/admin/v2/agents", agent,
                {"X-CSRF-Token": csrf})
if st in (200, 201):
    print("[init] demo agent 'pool-demo' ready (key = preset DEMO_KEY)")
else:
    # 幂等：已存在时重跑不失败（保持 revision 兼容，直接放行让 edge 接管）
    text = resp if isinstance(resp, str) else json.dumps(resp)[:300]
    if "pool-demo" in text and ("conflict" in text.lower() or "revision" in text.lower()):
        print("[init] agent exists; continuing")
    else:
        sys.exit(f"[init] FATAL: create agent {st} {text}")
