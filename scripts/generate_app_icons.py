import os
import zlib
import struct

base = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
icon_asset_path = os.path.join(base, 'assets', 'icon', 'app_icon.png')
android_base = os.path.join(base, 'android', 'app', 'src', 'main', 'res')
ios_base = os.path.join(base, 'ios', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset')

os.makedirs(os.path.dirname(icon_asset_path), exist_ok=True)


def write_png(path, width, height, rgba):
    def chunk(tag, data):
        f.write(struct.pack('>I', len(data)))
        f.write(tag)
        f.write(data)
        f.write(struct.pack('>I', zlib.crc32(tag + data) & 0xffffffff))

    raw = bytearray()
    for y in range(height):
        raw.append(0)
        offset = y * width * 4
        raw.extend(rgba[offset:offset + width * 4])

    with open(path, 'wb') as f:
        f.write(b'\x89PNG\r\n\x1a\n')
        ihdr = struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0)
        chunk(b'IHDR', ihdr)
        chunk(b'IDAT', zlib.compress(bytes(raw), level=9))
        chunk(b'IEND', b'')


def generate_rgba(width, height):
    rgba = bytearray(width * height * 4)
    for y in range(height):
        ratio = y / (height - 1)
        r_bg = int(21 * (1 - ratio) + 59 * ratio)
        g_bg = int(101 * (1 - ratio) + 130 * ratio)
        b_bg = int(192 * (1 - ratio) + 189 * ratio)
        for x in range(width):
            idx = (y * width + x) * 4
            rgba[idx:idx + 4] = bytes((r_bg, g_bg, b_bg, 255))

    for y in range(height):
        for x in range(width):
            nx = (x / width - 0.5) * 2
            ny = (y / height - 0.5) * 2
            abs_x = abs(nx)
            if abs_x < 0.35 and -0.6 < ny < 0.95:
                if ny > 0.5 or abs_x > 0.22 or y > height * 0.7:
                    idx = (y * width + x) * 4
                    rgba[idx:idx + 4] = bytes((255, 255, 255, 255))
            elif abs_x < 0.18 and -0.6 < ny < 0.7:
                idx = (y * width + x) * 4
                rgba[idx:idx + 4] = bytes((255, 255, 255, 255))

    return rgba


android_sizes = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
}

for folder, size in android_sizes.items():
    path = os.path.join(android_base, folder, 'ic_launcher.png')
    os.makedirs(os.path.dirname(path), exist_ok=True)
    write_png(path, size, size, generate_rgba(size, size))

ios_icons = {
    'Icon-App-20x20@1x.png': 20,
    'Icon-App-20x20@2x.png': 40,
    'Icon-App-20x20@3x.png': 60,
    'Icon-App-29x29@1x.png': 29,
    'Icon-App-29x29@2x.png': 58,
    'Icon-App-29x29@3x.png': 87,
    'Icon-App-40x40@1x.png': 40,
    'Icon-App-40x40@2x.png': 80,
    'Icon-App-40x40@3x.png': 120,
    'Icon-App-60x60@2x.png': 120,
    'Icon-App-60x60@3x.png': 180,
    'Icon-App-76x76@1x.png': 76,
    'Icon-App-76x76@2x.png': 152,
    'Icon-App-83.5x83.5@2x.png': 167,
    'Icon-App-1024x1024@1x.png': 1024,
}

for filename, size in ios_icons.items():
    path = os.path.join(ios_base, filename)
    write_png(path, size, size, generate_rgba(size, size))

write_png(icon_asset_path, 1024, 1024, generate_rgba(1024, 1024))
print('App icons generated to Android/iOS asset folders and source asset file.')
