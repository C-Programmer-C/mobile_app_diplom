from PIL import Image
import os
from PIL import ImageChops

FOLDER = r"C:\Users\misha\Downloads\server\server_diplom\static\products"


def trim_whitespace(image):
    bg = Image.new(image.mode, image.size, (255, 255, 255))
    diff = ImageChops.difference(image, bg)
    bbox = diff.getbbox()
    if bbox:
        return image.crop(bbox)
    return image


for filename in os.listdir(FOLDER):
    if filename.lower().endswith((".jpg", ".jpeg", ".png")):
        path = os.path.join(FOLDER, filename)

        img = Image.open(path).convert("RGB")

        # 1. Удаляем белые края
        img = trim_whitespace(img)

        # 2. Приводим к квадрату
        img = img.resize((600, 600))

        # 3. Сохраняем
        img.save(path, quality=90)

print("Готово")
