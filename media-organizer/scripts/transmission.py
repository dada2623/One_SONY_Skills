#!/usr/bin/env python3
"""Transmission RPC 小工具（无第三方依赖）。

密码来源：--password > TR_PASS > macOS 钥匙串(transmission-rpc)

用法：
  transmission.py add "magnet:?xt=..." [--dir DIR] [--paused]
  transmission.py add movie.torrent [--dir DIR]
  transmission.py list
  transmission.py info 3
  transmission.py pause 3        # 支持多个 id
  transmission.py resume 3
  transmission.py remove 3 [--delete]
"""

import argparse
import base64
import json
import os
import subprocess
import sys
import urllib.error
import urllib.request

DEFAULT_URL = "http://192.168.50.87:9091/transmission/rpc"
DEFAULT_USER = "One_SONY"

STATUS = {
    0: "停止",
    1: "等待校验",
    2: "校验中",
    3: "等待下载",
    4: "下载中",
    5: "等待做种",
    6: "做种中",
}


def get_password(explicit):
    if explicit:
        return explicit
    env = os.environ.get("TR_PASS")
    if env:
        return env
    try:
        out = subprocess.run(
            ["security", "find-generic-password", "-s", "transmission-rpc", "-w"],
            capture_output=True, text=True, timeout=5,
        )
        if out.returncode == 0 and out.stdout.strip():
            return out.stdout.strip()
    except (OSError, subprocess.SubprocessError):
        pass
    sys.exit(
        "缺少 Transmission 密码。设置 TR_PASS，或执行：\n"
        "  security add-generic-password -s transmission-rpc -a One_SONY -w"
    )


class RPC:
    def __init__(self, url, user, password):
        self.url = url
        self.session = None
        token = base64.b64encode(f"{user}:{password}".encode()).decode()
        self.auth = "Basic " + token

    def call(self, method, arguments=None):
        payload = json.dumps({"method": method, "arguments": arguments or {}}).encode()
        for _ in range(3):
            req = urllib.request.Request(self.url, data=payload, method="POST")
            req.add_header("Content-Type", "application/json")
            req.add_header("Authorization", self.auth)
            if self.session:
                req.add_header("X-Transmission-Session-Id", self.session)
            try:
                with urllib.request.urlopen(req, timeout=30) as resp:
                    body = json.load(resp)
                if body.get("result") != "success":
                    sys.exit(f"RPC 失败：{body.get('result')}")
                return body.get("arguments", {})
            except urllib.error.HTTPError as exc:
                if exc.code == 409:
                    self.session = exc.headers.get("X-Transmission-Session-Id")
                    continue
                if exc.code == 401:
                    sys.exit("认证失败：Transmission 拒绝了这个用户名/密码（检查 TR_USER / TR_PASS）。")
                detail = exc.read().decode("utf-8", "replace")[:300]
                sys.exit(f"HTTP {exc.code}：{detail}")
            except urllib.error.URLError as exc:
                sys.exit(f"连不上 {self.url}：{exc.reason}（确认本机到 192.168.50.87:9091 通畅）")
        sys.exit("多次 409：拿不到 X-Transmission-Session-Id。")


def human_bytes(n):
    n = float(n or 0)
    for unit in ("B", "KB", "MB", "GB", "TB"):
        if abs(n) < 1024 or unit == "TB":
            return f"{n:.1f}{unit}"
        n /= 1024


def human_eta(seconds):
    if seconds is None or seconds < 0:
        return "—"
    seconds = int(seconds)
    if seconds < 60:
        return f"{seconds}s"
    if seconds < 3600:
        return f"{seconds // 60}m"
    if seconds < 86400:
        return f"{seconds // 3600}h{(seconds % 3600) // 60:02d}m"
    return f"{seconds // 86400}d{(seconds % 86400) // 3600:02d}h"


def print_torrents(torrents):
    if not torrents:
        print("没有任务。")
        return
    for t in torrents:
        pct = t.get("percentDone", 0) * 100
        status = STATUS.get(t.get("status"), "未知")
        if t.get("error"):
            status = f"错误({t.get('errorString') or t.get('error')})"
        rate = t.get("rateDownload", 0)
        speed = f"{human_bytes(rate)}/s" if rate else "—"
        eta = human_eta(t.get("eta")) if t.get("status") == 4 else "—"
        print(f"[{t.get('id')}] {t.get('name')}")
        print(
            f"    {pct:5.1f}%  {status}  ↓{speed}  ↑{human_bytes(t.get('rateUpload', 0))}/s"
            f"  ETA {eta}  {human_bytes(t.get('totalSize', 0))}"
        )
        print(f"    目录: {t.get('downloadDir')}")
        if t.get("isFinished"):
            print(f"    落地: {os.path.join(t.get('downloadDir', ''), t.get('name', ''))}")


FIELDS = [
    "id", "name", "status", "percentDone", "rateDownload", "rateUpload",
    "eta", "downloadDir", "totalSize", "error", "errorString", "isFinished",
]


def main():
    parser = argparse.ArgumentParser(description="Transmission RPC 控制（默认连武汉 fnOS）")
    parser.add_argument("--url", default=os.environ.get("TR_URL", DEFAULT_URL))
    parser.add_argument("--user", default=os.environ.get("TR_USER", DEFAULT_USER))
    parser.add_argument("--password", default=None)
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_add = sub.add_parser("add", help="添加磁力链接或 .torrent")
    p_add.add_argument("target")
    p_add.add_argument("--dir", default=None)
    p_add.add_argument("--paused", action="store_true")

    sub.add_parser("list", help="列出全部任务")

    p_info = sub.add_parser("info", help="查看指定任务")
    p_info.add_argument("ids", nargs="+", type=int)

    for name in ("pause", "resume"):
        p = sub.add_parser(name)
        p.add_argument("ids", nargs="+", type=int)

    p_rm = sub.add_parser("remove", help="移除任务")
    p_rm.add_argument("ids", nargs="+", type=int)
    p_rm.add_argument("--delete", action="store_true", help="同时删除已下载数据")

    args = parser.parse_args()
    rpc = RPC(args.url, args.user, get_password(args.password))

    if args.cmd == "add":
        if os.path.isfile(args.target):
            with open(args.target, "rb") as fh:
                arguments = {"metainfo": base64.b64encode(fh.read()).decode()}
        else:
            arguments = {"filename": args.target}
        if args.dir:
            arguments["download-dir"] = args.dir
        arguments["paused"] = bool(args.paused)
        result = rpc.call("torrent-add", arguments)
        added = result.get("torrent-added") or result.get("torrent-duplicate")
        if not added:
            sys.exit(f"添加失败：{result}")
        kind = "已存在" if "torrent-duplicate" in result else "已添加"
        print(f"{kind}：[{added['id']}] {added['name']}")
        return

    if args.cmd == "list":
        print_torrents(rpc.call("torrent-get", {"fields": FIELDS}).get("torrents", []))
        return

    if args.cmd == "info":
        torrents = rpc.call("torrent-get", {"ids": args.ids, "fields": FIELDS}).get("torrents", [])
        missing = sorted(set(args.ids) - {t["id"] for t in torrents})
        print_torrents(torrents)
        if missing:
            print(f"未找到：{missing}")
        return

    if args.cmd in ("pause", "resume"):
        method = "torrent-stop" if args.cmd == "pause" else "torrent-start"
        rpc.call(method, {"ids": args.ids})
        print(f"{'已暂停' if args.cmd == 'pause' else '已恢复'}：{args.ids}")
        return

    if args.cmd == "remove":
        rpc.call("torrent-remove", {"ids": args.ids, "delete-local-data": bool(args.delete)})
        print(f"已移除：{args.ids}" + ("（含数据）" if args.delete else "（保留数据）"))
        return


if __name__ == "__main__":
    main()
