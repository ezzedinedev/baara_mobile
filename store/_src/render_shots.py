import asyncio, sys, pathlib, urllib.parse
sys.path.insert(0, r'C:/Users/ADMIN/AppData/Local/Temp/claude/e--laragon-www-projet-de-l-emploi/8b2e324f-d368-4757-adf2-04296146c989/scratchpad/pylib')
from playwright.async_api import async_playwright
items = [
  (1, 'Emploi · Burkina Faso', 'Le travail qui<br>vous <em>ressemble</em>.'),
  (2, 'Offres vérifiées', 'Des offres <em>vérifiées</em>,<br>près de chez vous.'),
  (3, 'Assistant IA', 'Votre CV <em>adapté</em><br>à chaque offre.'),
  (4, 'Tableau de bord', 'Suivez vos<br><em>candidatures</em>.'),
  (5, 'Profil', 'Un profil complet,<br>plus de <em>chances</em>.'),
]
async def main():
    base = pathlib.Path('capture.html').resolve().as_uri()
    async with async_playwright() as p:
        b = await p.chromium.launch(executable_path=r'C:/Program Files/Google/Chrome/Application/chrome.exe')
        pg = await b.new_page(viewport={'width': 1080, 'height': 1920})
        for n, k, t in items:
            await pg.goto(base + '?' + urllib.parse.urlencode({'n': n, 'k': k, 't': t}))
            await pg.evaluate('document.fonts.ready')
            await pg.wait_for_function("document.getElementById('s').complete && document.getElementById('s').naturalWidth > 0")
            await pg.screenshot(path=f'../capture-{n}.png')
            print('ok', n)
        await b.close()
asyncio.run(main())
