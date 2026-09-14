# Suport Electricel

Website static separat de aplicația Electricel. Toate resursele sale sunt în acest folder.

## Publicare

Site-ul trebuie comis mai întâi în branch-ul `master`. Apoi rulează din rădăcina repository-ului:

```sh
./site/deploy.sh
```

Scriptul publică numai conținutul folderului `site` în branch-ul `gh-pages`. Dacă GitHub CLI este autentificat, configurează și GitHub Pages să folosească rădăcina acelui branch.
