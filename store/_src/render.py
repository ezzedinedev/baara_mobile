import asyncio, sys, pathlib
sys.path.insert(0, r'C:/Users/ADMIN/AppData/Local/Temp/claude/e--laragon-www-projet-de-l-emploi/8b2e324f-d368-4757-adf2-04296146c989/scratchpad/pylib')
from playwright.async_api import async_playwright
html, out, w, h = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4])
async def main():
    async with async_playwright() as p:
        b = await p.chromium.launch(executable_path=r'C:/Program Files/Google/Chrome/Application/chrome.exe')
        pg = await b.new_page(viewport={'width': w, 'height': h})
        await pg.goto(pathlib.Path(html).resolve().as_uri())
        await pg.evaluate('document.fonts.ready')
        await pg.wait_for_timeout(300)
        await pg.screenshot(path=out)
        await b.close()
asyncio.run(main())
