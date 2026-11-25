"""Local worker verification; no user photos or remote image requests."""
import io
import os
import secrets
import sys
from pathlib import Path

root = Path(__file__).resolve().parents[1]
os.environ.setdefault("OMP_NUM_THREADS", "1")
os.environ.setdefault("U2NET_HOME", str(root / ".artifacts/u2net"))
os.environ["VEHICLE_AI_TOKEN"] = secrets.token_urlsafe(32)
sys.path.insert(0, str(root / "vehicle-ai"))

from fastapi.testclient import TestClient
from PIL import Image
from app import app

with TestClient(app) as client:
    assert client.get("/health").status_code == 200
    assert client.post("/render", content=b"x").status_code == 401
    headers = {"Authorization": f'Bearer {os.environ["VEHICLE_AI_TOKEN"]}'}
    assert client.post("/render", headers=headers, content=b"x").status_code == 400
    assert client.post("/render", headers=headers, content=b"\x89PNG\r\n\x1a\n").status_code == 422
    assert client.post("/render", headers=headers, content=b"\x89PNG\r\n\x1a\n" + bytes(10 * 1024 * 1024)).status_code == 413
    # This is the app's generated demo asset, not a photograph submitted by a user.
    response = client.post("/render", headers=headers,
        content=(root / "assets/images/png/night_drive_car.png").read_bytes())
    assert response.status_code == 200, response.text[:200] if response.status_code != 200 else ""
    result = Image.open(io.BytesIO(response.content))
    assert result.size == (960, 480)
    assert result.mode == "RGBA"
    assert result.getchannel("A").getextrema() == (0, 255)
    assert not result.getexif()
    assert response.headers["cache-control"] == "no-store"
print("PASS: auth, invalid PNG, size limit, local U2Net CPU inference, transparent PNG, no EXIF")
