#!/usr/bin/env python3
"""Independent browser smoke test of the HTML UI prototype.

This DOES NOT compile, run or verify Flutter/Dart source. It validates the
pre-existing interaction prototype against visible user flows.
Requires: pip install playwright; playwright install chromium
Run from project root: python tools/verify_browser.py
"""
import asyncio
import base64
import shutil
from pathlib import Path
from playwright.async_api import async_playwright

ROOT=Path(__file__).resolve().parents[1]
HTML=(ROOT/"prototype/interactive_prototype.html").read_text(encoding="utf-8")
REPORT=ROOT/"reports"
REPORT.mkdir(exist_ok=True)

async def run():
    results=[]
    errors=[]
    async with async_playwright() as pw:
        installed_chromium=shutil.which("chromium") or shutil.which("google-chrome")
        kwargs={"executable_path":installed_chromium} if installed_chromium else {}
        try:
            browser=await pw.chromium.launch(headless=True,args=["--no-sandbox"],channel="chrome",**kwargs)
        except Exception:
            browser=await pw.chromium.launch(headless=True,args=["--no-sandbox"],**kwargs)
        page=await browser.new_page(viewport={"width":390,"height":844})
        page.on("pageerror",lambda error: errors.append(str(error)))
        await page.set_content(HTML,wait_until="load")
        assert await page.locator(".ao-figure-svg svg").count()==1
        results.append("B01 PASS 首页出现 2D 人物绘制")
        await page.screenshot(path=str(REPORT/"browser_avatar_verified.png"))
        before=await page.locator(".ao-slot-name").first.inner_text()
        await page.locator(".ao-hot.top").click()
        assert "选择上衣" in await page.locator(".ao-sheet h3").inner_text()
        results.append("B02 PASS 点击上衣热点弹出对应分类面板")
        await page.locator(".ao-sheet .ao-gcard").first.click()
        assert await page.locator(".ao-sheet").count()==0
        assert "米白色基础衬衫" in await page.locator(".ao-slot-name").first.inner_text()
        results.append("B03 PASS 选衣后弹层关闭、卡片同步")

        await page.get_by_role("button",name="✦ 一键智能搭配").click()
        assert await page.locator(".ao-reco").count()==1
        current_top=await page.locator(".ao-slot-name").first.inner_text()
        assert "米白色基础衬衫" in current_top
        results.append("B04 PASS 推荐出现且保留已锁定上衣")
        await page.get_by_role("button",name="↻ 换一套").click()
        assert "米白色基础衬衫" in await page.locator(".ao-slot-name").first.inner_text()
        results.append("B05 PASS 换一套未覆盖锁定上衣")
        await page.screenshot(path=str(REPORT/"browser_recommend_verified.png"))
        await page.get_by_role("button",name="♡ 保存这套").click()
        assert "已保存" in await page.locator(".ao-toast").inner_text()
        results.append("B06 PASS 当前搭配收藏成功")
        await page.get_by_role("button",name="穿搭",exact=True).click()
        assert await page.locator(".ao-saved-card").count()>=2
        await page.locator(".ao-saved-card").first.click()
        await page.get_by_role("button",name="穿上这套").click()
        assert await page.locator(".ao-figure-svg svg").count()==1
        results.append("B07 PASS 收藏可打开并恢复到首页")

        await page.get_by_role("button",name="衣橱",exact=True).click()
        assert await page.locator(".ao-gcard").count()>3
        await page.locator(".ao-floating-add").click()
        await page.get_by_role("button",name="商品链接导入").click()
        await page.locator('input[data-bind="url"]').fill("https://item.taobao.com/item.htm?id=123")
        await page.get_by_role("button",name="继续填写服装信息").click()
        assert await page.locator(".ao-routebar .ttl").inner_text()=="确认识别信息"
        results.append("B08 PASS 商品 URL 进入补充图片/人工确认流程")
        await page.get_by_role("button",name="保存到我的衣橱").click()
        assert "请上传图片" in await page.locator(".ao-toast").inner_text()
        results.append("B09 PASS 无图片时拦截不合法保存")

        pixel=base64.b64decode(
          "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4"
          "z8DwHwAFgAI/ScL/nwAAAABJRU5ErkJggg=="
        )
        await page.locator('input[data-file="edit-photo"]').set_input_files(
            {"name":"shirt.png","mimeType":"image/png","buffer":pixel}
        )
        await page.locator('input[data-bind="draft-name"]').fill("测试新增衣服")
        await page.get_by_role("button",name="保存到我的衣橱").click()
        assert "19 件单品" in await page.locator(".ao-mini-tag").first.inner_text()
        results.append("B10 PASS 图片+手动确认后新增至演示衣柜")

        await page.get_by_role("button",name="我的",exact=True).click()
        await page.get_by_role("button",name="我的风格偏好").click()
        assert await page.locator(".ao-tag").count()>=6
        results.append("B11 PASS 个人中心可进入风格偏好设置")
        assert not errors, errors
        results.append("B12 PASS 页面运行未发生 JS 异常")
        await browser.close()
    (REPORT/"browser_smoke_test.log").write_text("\n".join(results)+"\n",encoding="utf-8")
    print("\n".join(results))
    print(f"TOTAL: {len(results)} PASS / 0 FAIL")

if __name__=="__main__":
    asyncio.run(run())
