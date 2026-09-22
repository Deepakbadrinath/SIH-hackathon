import os
import zlib
import struct

def create_png(width, height, get_pixel_color):
    raw_data = bytearray()
    for y in range(height):
        raw_data.append(0)  # Filter type 0 (None)
        for x in range(width):
            r, g, b = get_pixel_color(x, y, width, height)
            raw_data.extend([r, g, b])
            
    compressed = zlib.compress(raw_data)
    
    png = bytearray(b'\x89PNG\r\n\x1a\n')
    
    # IHDR chunk
    ihdr_data = struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0)
    ihdr_crc = zlib.crc32(b'IHDR' + ihdr_data) & 0xffffffff
    png.extend(struct.pack('>I', len(ihdr_data)) + b'IHDR' + ihdr_data + struct.pack('>I', ihdr_crc))
    
    # IDAT chunk
    idat_crc = zlib.crc32(b'IDAT' + compressed) & 0xffffffff
    png.extend(struct.pack('>I', len(compressed)) + b'IDAT' + compressed + struct.pack('>I', idat_crc))
    
    # IEND chunk
    iend_crc = zlib.crc32(b'IEND') & 0xffffffff
    png.extend(struct.pack('>I', 0) + b'IEND' + struct.pack('>I', iend_crc))
    
    return bytes(png)

def draw_avatar(x, y, w, h, bg_rgb, head_rgb, hair_rgb, clothes_rgb):
    # Center circle for head, oval for body, hair on top
    cx, cy = w // 2, h // 2 - 8
    radius = 32
    dx = x - cx
    dy = y - cy
    dist_sq = dx * dx + dy * dy
    
    # Hair
    if dist_sq <= (radius + 6) ** 2 and y < cy - 6:
        return hair_rgb
    # Head
    if dist_sq <= radius * radius:
        # Eye dots
        if (abs(x - cx) == 12 or abs(x - cx) == 13) and (abs(y - (cy - 4)) <= 2):
            return (20, 20, 20)
        # Smile
        if abs(x - cx) <= 10 and (y == cy + 12 or y == cy + 13) and (x - cx)**2 + (y - (cy + 8))**2 >= 30:
            return (180, 50, 50)
        return head_rgb
    
    # Body / Shoulders
    body_cx, body_cy = w // 2, h + 15
    bdx = (x - body_cx) / 48.0
    bdy = (y - body_cy) / 36.0
    if bdx * bdx + bdy * bdy <= 1.0 and y > cy + 20:
        return clothes_rgb
        
    return bg_rgb

def main():
    out_dir = r"d:\SIH hackathon\mobile\assets\images\faces"
    os.makedirs(out_dir, exist_ok=True)
    
    # 1. Aita (Grandmother) - Warm amber bg, grey hair, traditional red sari
    aita_png = create_png(128, 128, lambda x, y, w, h: draw_avatar(
        x, y, w, h,
        bg_rgb=(254, 243, 199),
        head_rgb=(245, 208, 169),
        hair_rgb=(210, 215, 220),
        clothes_rgb=(185, 28, 28)
    ))
    with open(os.path.join(out_dir, "aita.png"), "wb") as f:
        f.write(aita_png)

    # 2. Koka (Grandfather) - Calming blue bg, white hair, cream kurta
    koka_png = create_png(128, 128, lambda x, y, w, h: draw_avatar(
        x, y, w, h,
        bg_rgb=(224, 242, 254),
        head_rgb=(240, 200, 160),
        hair_rgb=(240, 240, 245),
        clothes_rgb=(30, 64, 175)
    ))
    with open(os.path.join(out_dir, "koka.png"), "wb") as f:
        f.write(koka_png)

    # 3. Priya (Daughter) - Emerald green bg, dark hair, teal kurti
    daughter_png = create_png(128, 128, lambda x, y, w, h: draw_avatar(
        x, y, w, h,
        bg_rgb=(220, 252, 231),
        head_rgb=(248, 212, 176),
        hair_rgb=(45, 30, 20),
        clothes_rgb=(13, 148, 136)
    ))
    with open(os.path.join(out_dir, "daughter.png"), "wb") as f:
        f.write(daughter_png)

    # 4. Rahul (Grandson) - Warm lavender bg, dark brown hair, saffron shirt
    grandson_png = create_png(128, 128, lambda x, y, w, h: draw_avatar(
        x, y, w, h,
        bg_rgb=(243, 232, 255),
        head_rgb=(250, 215, 180),
        hair_rgb=(50, 35, 25),
        clothes_rgb=(234, 88, 12)
    ))
    with open(os.path.join(out_dir, "grandson.png"), "wb") as f:
        f.write(grandson_png)

    print("Portraits generated successfully!")

if __name__ == "__main__":
    main()
