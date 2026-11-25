"""DashCore's optional CPU image worker. Photos are never stored on disk."""
import asyncio
import hmac
import io
import os
from functools import lru_cache

from fastapi import FastAPI, HTTPException, Request, Response
from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageOps

app = FastAPI(docs_url=None, redoc_url=None)
busy = asyncio.Lock()
Image.MAX_IMAGE_PIXELS = 20_000_000


@lru_cache(maxsize=1)
def session():
    from rembg import new_session
    # Explicitly use the small, open U²-Net model, never a paid/default model.
    return new_session("u2netp", providers=["CPUExecutionProvider"])


def theme_cutout(image: Image.Image) -> bytes:
    """Keep the photographed angle and identity; do not invent a new view."""
    image = image.convert("RGBA")
    alpha = image.getchannel("A")
    bounds = alpha.point(lambda value: 255 if value > 24 else 0).getbbox()
    if not bounds:
        raise ValueError("No vehicle could be isolated")
    image = image.crop(bounds)
    image.thumbnail((860, 360), Image.Resampling.LANCZOS)
    alpha = image.getchannel("A")
    rgb = ImageEnhance.Contrast(image.convert("RGB")).enhance(1.08)
    rgb = ImageEnhance.Sharpness(rgb).enhance(1.12)
    image = rgb.convert("RGBA")
    image.putalpha(alpha)
    output = Image.new("RGBA", (960, 480))
    glow = Image.new("RGBA", output.size)
    draw = ImageDraw.Draw(glow)
    left = (output.width - image.width) // 2
    top = (output.height - image.height) // 2 - 8
    ground = top + image.height
    draw.ellipse((left, ground - 4, left + image.width, ground + 17), fill=(21, 167, 240, 100))
    output.alpha_composite(glow.filter(ImageFilter.GaussianBlur(10)))
    output.alpha_composite(image, (left, top))
    result = io.BytesIO()
    output.save(result, "PNG", optimize=True)
    return result.getvalue()


def process(payload: bytes) -> bytes:
    from rembg import remove
    source = ImageOps.exif_transpose(Image.open(io.BytesIO(payload))).convert("RGB")
    source.thumbnail((1280, 1024), Image.Resampling.LANCZOS)
    cutout = remove(source, session=session())
    return theme_cutout(cutout)


@app.get("/health")
def health():
    return {"ok": True, "model": "u2netp", "angle": "source"}


@app.post("/render")
async def render(request: Request):
    expected = os.getenv("VEHICLE_AI_TOKEN", "")
    supplied = request.headers.get("authorization", "")
    if not expected or not hmac.compare_digest(supplied, f"Bearer {expected}"):
        raise HTTPException(401, "Unauthorized")
    if busy.locked():
        raise HTTPException(429, "Worker busy; retry later")
    async with busy:
        body = bytearray()
        async for chunk in request.stream():
            body.extend(chunk)
            if len(body) > 10 * 1024 * 1024:
                raise HTTPException(413, "Image too large")
        if not body.startswith(b"\x89PNG\r\n\x1a\n"):
            raise HTTPException(400, "PNG required")
        try:
            result = await asyncio.to_thread(process, bytes(body))
        except Exception:
            raise HTTPException(422, "Could not isolate vehicle") from None
    return Response(result, media_type="image/png", headers={"Cache-Control": "no-store"})
