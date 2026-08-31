from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.responses import Response
from rembg import remove
from PIL import Image
import io

app = FastAPI(title="Outfit App - Background Removal API")

@app.get("/")
def read_root():
    return {"message": "Background Removal API is running. Use POST /remove-background to process images."}

@app.post("/remove-background")
async def remove_background(image: UploadFile = File(...)):
    # Validasi format file
    if not image.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image.")
    
    try:
        # Membaca data gambar
        contents = await image.read()
        
        # Menggunakan rembg untuk menghapus latar belakang
        output_image_data = remove(contents)
        
        # Mengembalikan gambar hasil sebagai respon PNG
        return Response(content=output_image_data, media_type="image/png")
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
