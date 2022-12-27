# IGEO.PD2

Mérési jegyzőkönyv és koordináta jegyzék generáló program SurPad és SurvX terepi adatgyűjtőhöz.

![image](https://user-images.githubusercontent.com/89804084/209412640-538481c0-c152-4149-b1d7-1360a725d2f2.png)

## Követelmények

- GIT: https://git-scm.com/
- Lazarus: https://www.lazarus-ide.org/
- SQLite3: https://www.sqlite.org/index.html
- InnoSetup: https://jrsoftware.org/isinfo.php

## Fordítás

```terminal
git clone https://github.com/faludiz/fpc-markdown.git
git clone https://github.com/faludiz/IGEO_PD2.git
cd IGEO_PD2
build.bat
```

## Telepítés

Igazából nem szükséges, ha manuálisan is hozzá tudod rendelni a .PD kiterjesztéshez.

Telepítőprogramot a **setup/pd_setup_\*.iss** szkript segítségével lehet készíteni InnoSetupban.

## Használat

- beállítás: a Start menüből indítsd el, add meg az adatokat, kilépéskor automatikusan ment
- dupla klikk egy PD fájlon: elkészül a mérési jegyzőkönyv és a koordináta jegyzék, amit meg is jelenít
  - mérési jegyzőkönyv: 
    - formátum: [Markdown](https://hu.wikipedia.org/wiki/Markdown)
	  - fájlnév: \*.fbk.md
    - formátum: [HTML](https://hu.wikipedia.org/wiki/HTML)
	  - fájlnév: \*.fbk.html	
  - koordináta jegyzék:
    - formátum: `psz,y,x,z,kód,státusz,hrms,vrms,pdop`
	  - fájlnév: \*.pts.txt
	- formátum: [KML](https://hu.wikipedia.org/wiki/Keyhole_Markup_Language)
	  - fájlnév: \*.pts.kml
	
## Támogatás

A szoftverhez nem jár felhasználó támogatás.

## Hívj meg egy kávéra:

[![bmc_qr](https://user-images.githubusercontent.com/89804084/208740036-e8d7cd50-1aed-4ae8-a36c-f4d221958299.png)](https://www.buymeacoffee.com/faludiz)

https://www.buymeacoffee.com/faludiz
