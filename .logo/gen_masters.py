import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter

PAPER = (247, 245, 239)
INK_RED = (166, 58, 47)
FONT = ".logo/fonts/ZhiMangXing-Regular.ttf"
GLYPH = "墨"


def noise_layer(size, strength, seed=7):
    rng = np.random.default_rng(seed)
    return rng.normal(1.0, strength, (size, size, 1)).clip(0.0, 1.0)


def draw_seal(canvas_size, seal_size, glyph_ratio, border, seed=3, fatten=0, corner=0.075):
    layer = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    off = (canvas_size - seal_size) / 2
    radius = seal_size * corner
    d.rounded_rectangle([off, off, off + seal_size, off + seal_size],
                        radius=radius, fill=INK_RED + (255,))

    if border:
        inset = seal_size * 0.052
        d.rounded_rectangle(
            [off + inset, off + inset, off + seal_size - inset, off + seal_size - inset],
            radius=radius * 0.6, outline=PAPER + (255,),
            width=max(1, int(seal_size * 0.014)),
        )

    mask = Image.new("L", (canvas_size, canvas_size), 0)
    md = ImageDraw.Draw(mask)
    target = seal_size * glyph_ratio
    fs = int(target * 1.9)
    font = ImageFont.truetype(FONT, fs)
    bbox = md.textbbox((0, 0), GLYPH, font=font)
    while (bbox[3] - bbox[1]) > target and fs > 10:
        fs -= 4
        font = ImageFont.truetype(FONT, fs)
        bbox = md.textbbox((0, 0), GLYPH, font=font)
    x = (canvas_size - (bbox[2] - bbox[0])) / 2 - bbox[0]
    y = (canvas_size - (bbox[3] - bbox[1])) / 2 - bbox[1]
    md.text((x, y), GLYPH, font=font, fill=255)
    if fatten:
        mask = mask.filter(ImageFilter.MaxFilter(fatten))
    mask = mask.filter(ImageFilter.GaussianBlur(seal_size * 0.0022))

    glyph = Image.new("RGBA", (canvas_size, canvas_size), PAPER + (0,))
    glyph.putalpha(mask)
    layer = Image.alpha_composite(layer, glyph)

    arr = np.array(layer).astype(np.float32)
    arr[:, :, :3] *= noise_layer(canvas_size, 0.05, seed)
    yy, xx = np.mgrid[0:canvas_size, 0:canvas_size]
    dist = np.minimum.reduce([
        np.abs(xx - off), np.abs(xx - (off + seal_size)),
        np.abs(yy - off), np.abs(yy - (off + seal_size)),
    ])
    inside = (xx >= off) & (xx <= off + seal_size) & (yy >= off) & (yy <= off + seal_size)
    edge = np.clip(dist / (seal_size * 0.02), 0, 1)
    arr[:, :, 3] *= np.where(inside, 0.55 + 0.45 * edge, 1.0)
    return Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGBA")


def paper_background(size):
    arr = np.zeros((size, size, 3), dtype=np.float32)
    arr[:, :, :] = np.array(PAPER, dtype=np.float32)
    rng = np.random.default_rng(11)
    arr += rng.normal(0, 1.6, (size, size, 1))
    return Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGB").convert("RGBA")


def compose(size, *, seal_ratio=0.70, glyph_ratio=0.62, border=True, paper=True,
            fatten=0, corner=0.075):
    if paper:
        base = paper_background(size)
        seal = draw_seal(size, size * seal_ratio, glyph_ratio, border, fatten=fatten, corner=corner)
        return Image.alpha_composite(base, seal).convert("RGB")
    return draw_seal(size, size * seal_ratio, glyph_ratio, border, fatten=fatten, corner=corner)


MASTER = 1024
# 大尺寸：带内框、纸面留白，像个真的印章
compose(MASTER, seal_ratio=0.72, glyph_ratio=0.60, border=True, corner=0.06).save(".logo/master_1024.png")
# 小尺寸：去掉内框、印章占满、笔画加粗，48px 也认得出
compose(MASTER, seal_ratio=0.88, glyph_ratio=0.70, border=False, corner=0.055,
        fatten=5).save(".logo/master_small_1024.png")
# 透明印章：应用内 logo 用
compose(MASTER, seal_ratio=0.98, glyph_ratio=0.62, border=True, paper=False,
        corner=0.06).save(".logo/seal_transparent_1024.png")
# 应用内小图标：无框、加粗，32px 也认得出
compose(MASTER, seal_ratio=0.99, glyph_ratio=0.70, border=False, paper=False,
        corner=0.055, fatten=5).save(".logo/app_mark_1024.png")
print("ok")
