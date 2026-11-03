"""Genera los sonidos del juego como WAV (22 050 Hz, mono, 16 bits). Todo sale de fórmulas: sin derechos de autor.
Uso: python herramientas/sonidos.py sonidos   (necesita numpy)"""
import sys, wave, numpy as np
OUT = sys.argv[1]; SR = 22050
rng = np.random.default_rng(7)

def t(d): return np.arange(int(SR * d)) / SR
def env(n, a=0.005, r=0.1):
    e = np.ones(n); na = max(1, int(SR * a)); nr = max(1, int(SR * r))
    e[:na] = np.linspace(0, 1, na); e[-nr:] *= np.linspace(1, 0, nr); return e
def tono(f, d, forma="sen", vol=0.5):
    x = t(d); fase = 2 * np.pi * np.cumsum(np.broadcast_to(f, x.shape)) / SR
    if forma == "sen": s = np.sin(fase)
    elif forma == "cuadrada": s = np.sign(np.sin(fase)) * 0.6
    elif forma == "triangulo": s = 2 / np.pi * np.arcsin(np.sin(fase))
    else: s = 2 * ((fase / (2 * np.pi)) % 1) - 1
    return s * vol
def ruido(d): return rng.uniform(-1, 1, int(SR * d))
def pasa_bajos(x, a): 
    y = np.zeros_like(x); acc = 0.0
    for i, v in enumerate(x): acc += a * (v - acc); y[i] = acc
    return y
def nota(n): return 440 * 2 ** ((n - 69) / 12)
def guardar(nombre, x):
    x = np.clip(x, -1, 1); d = (x * 32767 * 0.9).astype(np.int16)
    with wave.open(f"{OUT}/{nombre}.wav", "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(d.tobytes())
def unir(*partes): return np.concatenate(partes)
def mezclar(largo, *pistas):
    m = np.zeros(int(SR * largo))
    for inicio, p in pistas:
        i = int(SR * inicio); f = min(len(m), i + len(p)); m[i:f] += p[: f - i]
    return m

# Timbre del colegio: campana que repica rápido y se apaga.
d = 1.6; x = t(d); golpe = (np.sin(2 * np.pi * 18 * x) > 0).astype(float)
campana = (np.sin(2*np.pi*1180*x) + 0.6*np.sin(2*np.pi*2360*x) + 0.3*np.sin(2*np.pi*3530*x))
guardar("timbre", campana * golpe * np.exp(-x * 1.4) * 0.45)

# Paso suave.
x = t(0.09); guardar("paso", pasa_bajos(ruido(0.09), 0.08) * np.exp(-x * 45) * 1.6)

# Recoger apunte: hoja que suena + arpegio brillante.
hoja = pasa_bajos(ruido(0.12), 0.35) * np.exp(-t(0.12) * 30) * 0.5
arp = unir(*[tono(nota(n), 0.07, "cuadrada", 0.18) * env(int(SR*0.07), 0.002, 0.03) for n in (76, 81, 88)])
guardar("apunte", mezclar(0.36, (0, hoja), (0.05, arp)))

# Perder una vida: zumbido que baja.
x = t(0.6); guardar("vida", tono(np.linspace(420, 110, len(x)), 0.6, "sierra", 0.35) * env(len(x), 0.005, 0.15))

# "¡Shhh!" de la bibliotecaria: ruido agudo filtrado.
r = ruido(0.75); agudo = r - pasa_bajos(r, 0.25)
guardar("shh", agudo * env(len(r), 0.06, 0.3) * 0.7)

# Silbato del vigilante.
x = t(0.55); vib = 2600 + 120 * np.sin(2 * np.pi * 28 * x)
guardar("silbato", tono(vib, 0.55, "sen", 0.45) * env(len(x), 0.01, 0.1) + ruido(0.55) * 0.04 * env(len(x), 0.01, 0.1))

# Tinto: sorbo con burbujas.
burbujas = mezclar(0.45, *[(i * 0.05, tono(nota(70 + (i * 5) % 12), 0.04, "sen", 0.3) * env(int(SR*0.04), 0.002, 0.02)) for i in range(8)])
sorbo = pasa_bajos(ruido(0.45), 0.15) * env(int(SR*0.45), 0.05, 0.2) * 0.6
guardar("tinto", burbujas + sorbo)

# Puerta que se abre.
x = t(0.6); guardar("puerta", (pasa_bajos(ruido(0.6), 0.05) * 1.5 + tono(np.linspace(180, 90, len(x)), 0.6, "triangulo", 0.25)) * env(len(x), 0.02, 0.3))

# Rana (Xaca Rana): un "cro-ac" como el de una rana de verdad.
# La garganta de la rana da golpecitos rápidos (40-70 por segundo); cada golpe hace
# sonar dos "resonancias" (como la boca y el saco de la garganta). Dos sílabas: "cro" y "aac".
def resonador(x, f, ancho):
    r = np.exp(-np.pi * ancho / SR); c = 2 * r * np.cos(2 * np.pi * f / SR)
    y = np.zeros_like(x); y1 = y2 = 0.0
    for i, v in enumerate(x):
        y0 = v + c * y1 - r * r * y2; y[i] = y0; y2, y1 = y1, y0
    return y
azar_rana = np.random.default_rng(11)  # generador propio: no cambia los demás sonidos
def silaba(dur, golpes_ini, golpes_fin, formante1, formante2):
    n = int(SR * dur); pulso = np.zeros(n)
    frec = np.linspace(golpes_ini, golpes_fin, n); fase = np.cumsum(frec) / SR
    marcas = np.where(np.diff(np.floor(fase)) > 0)[0]
    for m in marcas:
        pulso[m] = 1.0 + azar_rana.uniform(-0.25, 0.25)  # golpecitos un poco irregulares
    voz = resonador(pulso, formante1, 120) * 0.6 + resonador(pulso, formante2, 260) * 0.35
    voz += pasa_bajos(azar_rana.uniform(-1, 1, n), 0.3) * 0.08  # algo de aire
    voz /= np.max(np.abs(voz)) + 1e-9
    return voz * env(n, 0.012, dur * 0.45)
cro = silaba(0.13, 48, 55, 480, 1350)
aac = silaba(0.24, 62, 72, 620, 1650)
guardar("rana", unir(cro, np.zeros(int(SR * 0.045)), aac, np.zeros(int(SR * 0.08))) * 0.85)

# Clic de botones.
x = t(0.05); guardar("clic", tono(1400, 0.05, "triangulo", 0.35) * np.exp(-x * 90))

# Pista usada / acierto / error del examen.
guardar("acierto", unir(tono(nota(79), 0.09, "cuadrada", 0.2) * env(int(SR*.09), .002, .04), tono(nota(84), 0.16, "cuadrada", 0.2) * env(int(SR*.16), .002, .1)))
guardar("error", unir(tono(nota(52), 0.14, "sierra", 0.25) * env(int(SR*.14), .002, .05), tono(nota(49), 0.26, "sierra", 0.25) * env(int(SR*.26), .002, .15)))

# Victoria: fanfarria corta.
fan = [(72, .12), (76, .12), (79, .12), (84, .36), (79, .12), (84, .5)]
guardar("victoria", unir(*[tono(nota(n), d, "cuadrada", 0.22) * env(int(SR*d), .003, .05) for n, d in fan]))

# Derrota: trombón triste.
tri = [(58, .32), (57, .32), (56, .32), (55, .9)]
partes = []
for n, d in tri:
    x = t(d); f = nota(n) * (1 + 0.012 * np.sin(2 * np.pi * 6 * x)) if d > .5 else nota(n)
    partes.append(tono(f, d, "sierra", 0.3) * env(len(x), .02, .12))
guardar("derrota", pasa_bajos(unir(*partes), 0.3) * 1.4)

# Música del menú: alegre, 8 compases a 112 bpm, en bucle.
def musica(nombre, bpm, acordes, melodia, onda_mel, vol_bajo, vol_mel, bateria=True):
    negra = 60 / bpm; largo = negra * 4 * len(acordes); pistas = []
    for c, raiz in enumerate(acordes):
        for b in range(4):
            ini = (c * 4 + b) * negra
            n = raiz - 24 + (7 if b % 2 else 0)
            pistas.append((ini, tono(nota(n), negra * 0.9, "triangulo", vol_bajo) * env(int(SR*negra*0.9), .005, .08)))
            if bateria:
                pistas.append((ini, pasa_bajos(ruido(0.06), 0.5) * np.exp(-t(0.06) * 60) * (0.5 if b % 2 == 0 else 0.25)))
                pistas.append((ini + negra / 2, (ruido(0.03) - pasa_bajos(ruido(0.03), .3)) * np.exp(-t(0.03) * 120) * 0.15))
    pos = 0.0
    for n, dur in melodia:
        d = dur * negra
        if n: pistas.append((pos, tono(nota(n), d * 0.92, onda_mel, vol_mel) * env(int(SR*d*0.92), .005, min(.1, d*.4))))
        pos += d
    guardar(nombre, mezclar(largo, *pistas))

mel_menu = [(72,1),(74,.5),(76,.5),(79,1),(76,1), (77,1),(76,.5),(74,.5),(72,2),
            (69,1),(72,.5),(74,.5),(76,1),(74,1), (72,1),(71,.5),(72,.5),(74,2),
            (72,1),(74,.5),(76,.5),(79,1),(81,1), (79,1),(77,.5),(76,.5),(74,2),
            (72,1),(76,.5),(74,.5),(72,1),(71,1), (72,4)]
musica("musica_menu", 112, [60, 65, 57, 62, 60, 65, 62, 60], mel_menu, "cuadrada", 0.22, 0.10)

# Música del juego: sigilosa, en menor, pasos de bajo.
mel_juego = [(0,1),(69,.5),(0,.5),(72,.5),(71,.5),(69,1), (0,1),(64,.5),(0,.5),(67,.5),(65,.5),(64,1),
             (0,1),(69,.5),(0,.5),(72,.5),(74,.5),(76,1), (75,.5),(74,.5),(72,.5),(71,.5),(69,2),
             (0,1),(69,.5),(0,.5),(72,.5),(71,.5),(69,1), (0,1),(64,.5),(0,.5),(67,.5),(65,.5),(64,1),
             (0,1),(76,.5),(0,.5),(74,.5),(72,.5),(71,1), (69,4)]
musica("musica_juego", 100, [57, 57, 53, 52, 57, 57, 53, 52], mel_juego, "triangulo", 0.28, 0.12)
print("listo")
