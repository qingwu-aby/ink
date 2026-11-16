import glob, os, sys
import numpy as np
sys.path.insert(0, ".logo")
from PIL import Image, ImageFilter
from seal_lib import draw_seal_fill, draw_seal_round, paper, _char_layer

TEXT = "可道"
FONT = ".logo/fonts/JFZSKSealScript-V3.ttf"   # 中山王篆（OFL）
POSITIONS = [(-0.095, -0.085, 0), (0.09, 0.095, 0)]   # 两字收在中间
MASTER = 1024
# 细线为骨，略施一层让它站得住
FATTEN = 8


def glyph_mask(size, ratio, fatten=FATTEN):
    mask = Image.new("L", (size, size), 0)
    for ch, (dx, dy, rot) in zip(list(TEXT), POSITIONS):
        m = _char_layer(size, ch, FONT, size * ratio, rot, fatten)
        shifted = Image.new("L", (size, size), 0)
        shifted.paste(m, (int(dx * size), int(dy * size)))
        mask = Image.fromarray(np.maximum(np.array(mask), np.array(shifted)))
    return mask.filter(ImageFilter.GaussianBlur(size * 0.0016))


def icon_art(size):
    """铺满画布的红底 + 字，直接交给系统去裁形状。"""
    return draw_seal_fill(size, TEXT, FONT, POSITIONS, char_ratio=0.47,
                          corner=0.0, fatten=FATTEN, glyph_mask=glyph_mask(size, 0.47))


def round_mark(size):
    """应用内：圆形印，透明底，不加白圈。"""
    return draw_seal_round(size, size * 0.99, TEXT, FONT, POSITIONS,
                           char_ratio=0.49, ring=False, fatten=FATTEN, seed=5)


icon = icon_art(MASTER).convert("RGB")
icon.save(".logo/master_1024.png")

for path in (glob.glob("android/app/src/main/res/mipmap-*/ic_launcher.png")
             + glob.glob("ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png")
             + glob.glob("macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_*.png")):
    with Image.open(path) as img:
        w, h = img.size
    icon.resize((w, h), Image.LANCZOS).save(path, optimize=True)

mark = round_mark(MASTER)
mark.save(".logo/app_mark_1024.png")
os.makedirs("assets/logo", exist_ok=True)
mark.resize((256, 256), Image.LANCZOS).save("assets/logo/seal.png", optimize=True)

# 自适应图标：前景是一枚红圆（圆外透明），系统遮罩后看到的正好是圆形
for folder, size in [("mdpi", 108), ("hdpi", 162), ("xhdpi", 216),
                     ("xxhdpi", 324), ("xxxhdpi", 432)]:
    draw_seal_round(size, size * 0.995, TEXT, FONT, POSITIONS, char_ratio=0.47,
                    ring=False, fatten=FATTEN, seed=5).save(
        f"android/app/src/main/res/mipmap-{folder}/ic_launcher_foreground.png", optimize=True)

    layer = Image.new("RGBA", (size, size), (255, 255, 255, 0))
    layer.putalpha(glyph_mask(size, 0.26))
    layer.save(f"android/app/src/main/res/mipmap-{folder}/ic_launcher_monochrome.png", optimize=True)

print("built", TEXT, "fatten", FATTEN)
