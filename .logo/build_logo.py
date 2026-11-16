import glob, os, sys
import numpy as np
sys.path.insert(0, ".logo")
from PIL import Image, ImageDraw, ImageFont, ImageFilter
from seal_lib import draw_seal_placed, paper

TEXT = "心斋"
# 篆书字体（OFL）里没有「斋」，只有 心；所以用行草
FONT = ".logo/fonts/ZhiMangXing-Regular.ttf"
# 对角：心上左、斋下右，顺着阅读方向斜落
POSITIONS = [(-0.19, -0.19, 0), (0.19, 0.19, 0)]
MASTER = 1024


def placed_mask(canvas, text, font_path, positions, char_ratio, fatten=0):
    mask = Image.new("L", (canvas, canvas), 0)
    for ch, (dx, dy, rot) in zip(list(text), positions):
        m = _char_layer(canvas, ch, font_path, canvas * char_ratio, rot, fatten)
        shifted = Image.new("L", (canvas, canvas), 0)
        shifted.paste(m, (int(dx * canvas), int(dy * canvas)))
        mask = Image.fromarray(np.maximum(np.array(mask), np.array(shifted)))
    mask = mask.filter(ImageFilter.GaussianBlur(canvas * 0.0016))
    if fatten >= 3:
        mask = mask.filter(ImageFilter.MaxFilter(fatten + 1 if fatten % 2 == 0 else fatten))
    return mask


from seal_lib import _char_layer


def art(size, *, seal_ratio, char_ratio, border, corner, fatten=0, paper_bg=True):
    seal = draw_seal_placed(size, size * seal_ratio, TEXT, FONT, POSITIONS,
                            char_ratio=char_ratio, border=border, corner=corner,
                            fatten=fatten)
    if not paper_bg:
        return seal
    return Image.alpha_composite(paper(size), seal).convert("RGB")


big = art(MASTER, seal_ratio=0.74, char_ratio=0.40, border=True, corner=0.06)
small = art(MASTER, seal_ratio=0.88, char_ratio=0.43, border=False, corner=0.055, fatten=4)
mark = art(MASTER, seal_ratio=0.99, char_ratio=0.46, border=False, corner=0.055,
           fatten=3, paper_bg=False)

big.save(".logo/master_1024.png")
small.save(".logo/master_small_1024.png")
mark.save(".logo/app_mark_1024.png")

sources = {"big": big, "small": small}
for path in (glob.glob("android/app/src/main/res/mipmap-*/ic_launcher.png")
             + glob.glob("ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png")
             + glob.glob("macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_*.png")):
    with Image.open(path) as img:
        w, h = img.size
    sources["small" if max(w, h) <= 64 else "big"].resize((w, h), Image.LANCZOS).save(path, optimize=True)

os.makedirs("assets/logo", exist_ok=True)
mark.resize((256, 256), Image.LANCZOS).save("assets/logo/seal.png", optimize=True)

# 自适应图标：奶油底盘 + 印章（视口的 2/3）
for folder, size in [("mdpi", 108), ("hdpi", 162), ("xhdpi", 216),
                     ("xxhdpi", 324), ("xxxhdpi", 432)]:
    art(size, seal_ratio=0.44, char_ratio=0.28, border=True, corner=0.06).save(
        f"android/app/src/main/res/mipmap-{folder}/ic_launcher_foreground.png", optimize=True)

    layer = Image.new("RGBA", (size, size), (255, 255, 255, 0))
    layer.putalpha(placed_mask(size, TEXT, FONT, POSITIONS, 0.30, fatten=max(3, size // 60)))
    layer.save(f"android/app/src/main/res/mipmap-{folder}/ic_launcher_monochrome.png", optimize=True)

print("built", TEXT)
