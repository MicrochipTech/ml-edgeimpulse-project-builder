#%%
import bs4
import requests as rqs
import re

#%%
page = rqs.get('https://packs.download.microchip.com/')
soup = bs4.BeautifulSoup(page.content, 'html.parser')

#%%
p = re.compile(r'^\s*Microchip ([A-Za-z0-9\-]+) Series Device Support \((\d+\.\d+\.\d+)\)$')
parts = re.compile(r'PIC|dsPIC|XMEGA|AVR|SAM|AT')
for el in soup.find_all('h3', class_='panel-title pull-left'):
    txt = el.get_text().replace(u'\xa0', u' ')
    m = p.search(txt)
    if (m is None) or (parts.match(m.group(1)) is None):
        continue
    print(' '.join(m.groups()))

# %%
