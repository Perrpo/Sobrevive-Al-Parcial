"""Revisa los mapas de niveles/Datos.gd: que todas las filas midan igual y que los apuntes,
la salida y las rutas de los vigilantes se puedan alcanzar desde el inicio.
Uso: python herramientas/validar_mapas.py niveles/Datos.gd"""
import re, sys
from collections import deque
s = open(sys.argv[1]).read()
bloques = re.findall(r'(?:const|static var) (\w+) := \{(.*?)\n\}', s, re.S)
SOLIDO = set("#EMBSCJKGLN")
ok = True
for nombre, cuerpo in bloques:
    filas = re.findall(r'^\t\t"([^"]+)",$', cuerpo, re.M)
    anchos = {len(f) for f in filas}
    print(f"== {nombre}: {len(filas)} filas, anchos {anchos}")
    if len(anchos) != 1: ok = False; continue
    W, H = len(filas[0]), len(filas)
    req = int(re.search(r'"puerta_requiere": (\d+)', cuerpo).group(1))
    celdas = {(x, y): filas[y][x] for y in range(H) for x in range(W)}
    P = [k for k, v in celdas.items() if v == "P"][0]
    A = [k for k, v in celdas.items() if v == "A"]
    S = [k for k, v in celdas.items() if v == "S"]
    def alcanzables(puertas_abiertas):
        vis = {P}; q = deque([P])
        while q:
            x, y = q.popleft()
            for dx, dy in ((1,0),(-1,0),(0,1),(0,-1)):
                n = (x+dx, y+dy); c = celdas.get(n)
                if c is None or n in vis: continue
                if c in SOLIDO and c != "S": continue
                if c == "D" and not puertas_abiertas: continue
                vis.add(n)
                if c != "S": q.append(n)
        return vis
    cerr, abie = alcanzables(False), alcanzables(True)
    a_cerr = sum(1 for a in A if a in cerr)
    print(f"   apuntes {len(A)}; sin puertas se alcanzan {a_cerr}; con puertas {sum(1 for a in A if a in abie)}; salida alcanzable: {all(x in abie for x in S)}; requiere {req}")
    if any(a not in abie for a in A) or not all(x in abie for x in S): ok = False; print("   !! falta algo por alcanzar")
    if req and a_cerr < req: ok = False; print("   !! no alcanzan los apuntes para abrir la puerta")
    for k in ("R", "X", "T"):
        for c in [p for p, v in celdas.items() if v == k]:
            if c not in abie: ok = False; print(f"   !! {k} en {c} inalcanzable")
    # rutas de guardias y estudiantes: celdas libres y alcanzables
    for ruta in re.findall(r'"ruta": \[(.*?)\]', cuerpo):
        pts = [tuple(map(int, m)) for m in re.findall(r'Vector2i\((\d+), (\d+)\)', ruta)]
        for p in pts:
            if celdas[p] in SOLIDO or p not in abie: ok = False; print(f"   !! punto de ruta {p} = '{celdas[p]}'")
    for par in re.findall(r'\[Vector2i\((\d+), (\d+)\), Vector2i\((\d+), (\d+)\)\]', cuerpo):
        a, b = (int(par[0]), int(par[1])), (int(par[2]), int(par[3]))
        for p in (a, b):
            if celdas[p] in SOLIDO: ok = False; print(f"   !! estudiante en {p} = '{celdas[p]}'")
print("TODO BIEN" if ok else "HAY PROBLEMAS")
