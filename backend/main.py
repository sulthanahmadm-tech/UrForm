from fastapi import FastAPI, File, UploadFile, HTTPException, Request
from fastapi.responses import Response
from fastapi.middleware.cors import CORSMiddleware
from rembg import remove
from PIL import Image
import io
import os
import logging
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

# 1. Konfigurasi Logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s"
)
logger = logging.getLogger("urform_api")

# 2. Konfigurasi Rate Limiting
limiter = Limiter(key_func=get_remote_address)

# Cek mode produksi
is_production = os.getenv("ENV") == "production"

# 3. Matikan Docs Endpoint di Produksi
app = FastAPI(
    title="Outfit App - Background Removal API",
    docs_url=None if is_production else "/docs",
    redoc_url=None if is_production else "/redoc",
    openapi_url=None if is_production else "/openapi.json"
)

# 4. Konfigurasi CORS
# Di production, ALLOWED_ORIGINS harus diisi dengan domain spesifik (misal: https://urform.com)
# Untuk sekarang, kita set wildcard '*' agar mempermudah pengujian dari Android emulator
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # Ganti dengan domain spesifik jika sudah rilis
    allow_credentials=True,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["*"],
)

app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

MAX_FILE_SIZE = 10 * 1024 * 1024  # 10 MB
ALLOWED_TYPES = {"image/jpeg", "image/png", "image/webp"}

@app.get("/")
def read_root():
    # Sembunyikan informasi debug jika di production
    if is_production:
        raise HTTPException(status_code=404, detail="Not Found")
    return {"message": "Background Removal API is running. Use POST /remove-background to process images."}

@app.post("/remove-background")
@limiter.limit("10/minute") # Maks 10 request per menit per IP
async def remove_background(request: Request, image: UploadFile = File(...)):
    # Lapis 1: Cek tipe file (MIME)
    if image.content_type not in ALLOWED_TYPES:
        logger.warning(f"File type rejected: {image.content_type}")
        raise HTTPException(status_code=400, detail="Format file tidak didukung. Gunakan JPEG, PNG, atau WebP.")
        
    contents = await image.read()
    
    # Lapis 2: Cek ukuran file
    if len(contents) > MAX_FILE_SIZE:
        logger.warning(f"File size rejected: {len(contents)} bytes")
        raise HTTPException(status_code=413, detail="Ukuran file terlalu besar. Maksimal 10MB.")
        
    # Lapis 3: Verifikasi magic bytes (gambar valid)
    try:
        img = Image.open(io.BytesIO(contents))
        img.verify()
    except Exception as e:
        logger.warning(f"Corrupted image rejected: {e}")
        raise HTTPException(status_code=400, detail="File gambar rusak atau tidak valid.")

    try:
        # Menggunakan rembg untuk menghapus latar belakang
        output_image_data = remove(contents)
        logger.info(f"Successfully processed background removal for a {len(contents)} bytes image.")
        return Response(content=output_image_data, media_type="image/png")
        
    except Exception as e:
        # 4. Error Message (Sembunyikan dari User)
        logger.error(f"Error processing image: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="Gagal memproses gambar. Terjadi kesalahan internal pada server.")
