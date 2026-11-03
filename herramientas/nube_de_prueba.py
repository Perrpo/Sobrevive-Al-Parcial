"""Servidor de prueba que imita la API REST de Firebase Realtime Database.

Sirve para probar el ranking en línea sin internet:
    python3 herramientas/nube_de_prueba.py 8765
    godot --path . -- --recorrido --nube=http://127.0.0.1:8765

Revisa cada nota con las mismas reglas de firebase/database.rules.json.
"""
import json
import sys
import time
import uuid
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import parse_qs, urlparse

PUNTAJES = {}
CAMPOS = {"nombre", "nota", "puntaje", "ranas", "plataforma", "momento"}


def nota_valida(d):
    """Las mismas condiciones de las reglas de seguridad."""
    return (
        isinstance(d, dict)
        and set(d) == CAMPOS
        and isinstance(d["nombre"], str) and 0 < len(d["nombre"]) <= 14
        and isinstance(d["nota"], (int, float)) and 0 <= d["nota"] <= 5
        and isinstance(d["puntaje"], (int, float)) and 0 <= d["puntaje"] <= 100000
        and isinstance(d["ranas"], (int, float)) and 0 <= d["ranas"] <= 3
        and isinstance(d["plataforma"], str) and len(d["plataforma"]) <= 20
        and d["momento"] == {".sv": "timestamp"}
    )


class Nube(BaseHTTPRequestHandler):
    def _responder(self, codigo, datos):
        cuerpo = json.dumps(datos).encode()
        self.send_response(codigo)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(cuerpo)))
        self.end_headers()
        self.wfile.write(cuerpo)

    def do_POST(self):
        if urlparse(self.path).path != "/puntajes.json":
            return self._responder(401, {"error": "Permission denied"})
        largo = int(self.headers.get("Content-Length", 0))
        datos = json.loads(self.rfile.read(largo) or b"null")
        if not nota_valida(datos):
            print("[nube] RECHAZADA", datos, flush=True)
            return self._responder(401, {"error": "Permission denied"})
        datos["momento"] = int(time.time() * 1000)
        clave = "-N" + uuid.uuid4().hex[:18]
        PUNTAJES[clave] = datos
        print("[nube] guardada", clave, datos, flush=True)
        self._responder(200, {"name": clave})

    def do_GET(self):
        url = urlparse(self.path)
        if url.path != "/puntajes.json":
            return self._responder(401, {"error": "Permission denied"})
        q = parse_qs(url.query)
        filas = sorted(PUNTAJES.items(), key=lambda kv: kv[1]["puntaje"])
        if q.get("orderBy") == ['"puntaje"'] and "limitToLast" in q:
            filas = filas[-int(q["limitToLast"][0]):]
        self._responder(200, dict(filas) if filas else None)

    def log_message(self, *args):
        pass


if __name__ == "__main__":
    # Notas de otros "jugadores" para que el ranking no salga vacío.
    for i, (nombre, nota, puntaje) in enumerate([("Laura", 4.6, 15200), ("Mateo", 3.9, 12100), ("Sofi", 3.2, 9800)]):
        PUNTAJES[f"-Nprueba{i}"] = {"nombre": nombre, "nota": nota, "puntaje": puntaje, "ranas": 1,
                                   "plataforma": "Android", "momento": 0}
    HTTPServer(("127.0.0.1", int(sys.argv[1]) if len(sys.argv) > 1 else 8765), Nube).serve_forever()
