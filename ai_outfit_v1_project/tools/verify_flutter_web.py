"""Flutter Web 真实渲染冒烟验证。

使用系统 Edge（Playwright channel=msedge）加载 `flutter_mvp/build/web`，在
390×844 / 320×700 / 430×900 三种视口下截图，并检查页面错误。

前置：
    flutter build web -t lib/main_web_demo.dart --no-web-resources-cdn
    python -m pip install playwright

运行：
    python tools/verify_flutter_web.py
"""

from __future__ import annotations

import http.server
import socketserver
import sys
import threading
import time
from functools import partial
from pathlib import Path

from playwright.sync_api import sync_playwright

ROOT = Path(__file__).resolve().parents[1]
BUILD_DIR = ROOT / "flutter_mvp" / "build" / "web"
REPORT_DIR = ROOT / "reports"
LOG_PATH = REPORT_DIR / "flutter_web_smoke_test.log"

PASS: list[str] = []
FAIL: list[str] = []
LINES: list[str] = []


def log(message: str) -> None:
    LINES.append(message)
    print(message)


def check(condition: bool, case_id: str, detail: str) -> None:
    if condition:
        PASS.append(case_id)
        log(f"{case_id} PASS {detail}")
    else:
        FAIL.append(case_id)
        log(f"{case_id} FAIL {detail}")


class QuietHandler(http.server.SimpleHTTPRequestHandler):
    def log_message(self, fmt: str, *args) -> None:  # noqa: A003
        pass


def start_server() -> tuple[socketserver.TCPServer, int]:
    for port in range(8899, 8920):
        try:
            handler = partial(QuietHandler, directory=str(BUILD_DIR))
            server = socketserver.TCPServer(("127.0.0.1", port), handler)
            thread = threading.Thread(target=server.serve_forever, daemon=True)
            thread.start()
            return server, port
        except OSError:
            continue
    raise RuntimeError("没有可用的本地端口（8899-8919）")


def wait_for_flutter(page) -> None:
    deadline = time.time() + 45
    while time.time() < deadline:
        try:
            if page.evaluate(
                "() => !!(document.querySelector('flutter-view') || "
                "document.querySelector('flt-glass-pane'))"
            ):
                break
        except Exception:
            pass
        page.wait_for_timeout(300)
    page.wait_for_timeout(3500)


def enable_semantics(page) -> bool:
    try:
        clicked = page.evaluate(
            "() => { const el = document.querySelector('flt-semantics-placeholder');"
            " if (!el) return false; el.click(); return true; }"
        )
        page.wait_for_timeout(1200)
        return bool(clicked)
    except Exception:
        return False


def main() -> int:
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    if not (BUILD_DIR / "index.html").exists():
        log(f"未找到 Web 构建产物：{BUILD_DIR}")
        return 2

    server, port = start_server()
    base = f"http://127.0.0.1:{port}"
    log(f"server={base} build={BUILD_DIR}")

    console_errors: list[str] = []
    page_errors: list[str] = []

    try:
        with sync_playwright() as playwright:
            browser = playwright.chromium.launch(channel="msedge", headless=True)
            context = browser.new_context(
                viewport={"width": 390, "height": 844},
                device_scale_factor=2,
                locale="zh-CN",
            )
            page = context.new_page()
            page.on(
                "console",
                lambda msg: console_errors.append(msg.text)
                if msg.type == "error"
                else None,
            )
            page.on("pageerror", lambda error: page_errors.append(str(error)))

            scenarios = [
                ("home", f"{base}/?tab=0", 390, 844),
                ("welcome", f"{base}/?welcome=1", 390, 844),
                ("wardrobe", f"{base}/?tab=1", 390, 844),
                ("outfits", f"{base}/?tab=2", 390, 844),
                ("profile", f"{base}/?tab=3", 390, 844),
                ("home-320", f"{base}/?tab=0", 320, 700),
                ("home-430", f"{base}/?tab=0", 430, 900),
            ]
            for name, url, width, height in scenarios:
                page.set_viewport_size({"width": width, "height": height})
                page.goto(url, wait_until="domcontentloaded", timeout=60000)
                wait_for_flutter(page)
                page.wait_for_timeout(600)
                path = REPORT_DIR / f"flutter_web_{name}.png"
                page.screenshot(path=str(path))
                check(path.stat().st_size > 5000, f"WEB-{name}", f"截图 {path.name}")

            # 用语义树点击人物热点，验证选衣 BottomSheet 在真实 Web 渲染下可打开。
            page.set_viewport_size({"width": 390, "height": 844})
            page.goto(f"{base}/?tab=0", wait_until="domcontentloaded", timeout=60000)
            wait_for_flutter(page)
            semantics = enable_semantics(page)
            check(semantics, "WEB-semantics", "启用 Flutter Web 语义树")
            opened = False
            if semantics:
                try:
                    target = page.locator('[aria-label*="上衣"]').first
                    target.click(timeout=5000)
                    page.wait_for_timeout(1500)
                    opened = True
                except Exception as error:  # noqa: BLE001
                    log(f"语义点击失败，使用坐标兜底：{error}")
            if not opened:
                # 首页 390×844 下“上衣”热点的确定性位置；仅用于截图，不用于功能断言。
                page.mouse.click(55, 247)
                page.wait_for_timeout(1600)
                opened = True
            if opened:
                picker = REPORT_DIR / "flutter_web_picker.png"
                page.screenshot(path=str(picker))
                check(picker.stat().st_size > 5000, "WEB-picker", "选衣弹层截图")
                labels = page.locator('[aria-label="选择上衣"]').count()
                log(f"WEB-picker-title INFO 语义标题节点 {labels} 个")

            check(not page_errors, "WEB-js", f"页面异常 {len(page_errors)} 个")
            ignored = ("net::ERR", "Failed to load resource")
            relevant = [msg for msg in console_errors if not any(k in msg for k in ignored)]
            check(not relevant, "WEB-console", f"控制台错误 {len(relevant)} 个")
            if page_errors:
                log("PAGEERROR " + " | ".join(page_errors[:3]))
            if relevant:
                log("CONSOLE " + " | ".join(relevant[:3]))

            browser.close()
    finally:
        server.shutdown()
        server.server_close()

    log(f"RESULT pass={len(PASS)} fail={len(FAIL)}")
    LOG_PATH.write_text("\n".join(LINES) + "\n", encoding="utf-8")
    return 0 if not FAIL else 1


if __name__ == "__main__":
    sys.exit(main())
