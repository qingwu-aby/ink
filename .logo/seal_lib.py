import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter

PAPER = (247, 245, 239)
INK_RED = (166, 58, 47)


def _noise(size, strength, seed=7):
    rng = np.random.default_rng(seed)
    return rng.normal(1.0, strength, (size, size, 1)).clip(0.0, 1.0)


def _glyph_mask(canvas, text, font_path, box_w, box_h, vertical=True, fatten=0):
    """把 text 排进 box，返回 L 模式的 mask。"""
    mask = Image.new("L", (canvas, canvas), 0)
    d = ImageDraw.Draw(mask)
    chars = list(text)
    n = len(chars)

    if vertical:
        slot_h = (box_h - (n - 1) * box_h * 0.08) / n
        y = (canvas - box_h) / 2
        for ch in chars:
            fs = int(slot_h * 1.6)
            font = ImageFont.truetype(font_path, max(8, fs))
            bbox = d.textbbox((0, 0), ch, font=font)
            while (bbox[3] - bbox[1]) > slot_h and fs > 10:
                fs -= 3
                font = ImageFont.truetype(font_path, max(8, fs))
                bbox = d.textbbox((0, 0), ch, font=font)
            w = bbox[2] - bbox[0]
            h = bbox[3] - bbox[1]
            d.text(((canvas - w) / 2 - bbox[0], y + (slot_h - h) / 2 - bbox[1]),
                   ch, font=font, fill=255)
            y += slot_h + box_h * 0.08
    else:
        slot_w = (box_w - (n - 1) * box_w * 0.06) / n
        x = (canvas - box_w) / 2
        for ch in chars:
            fs = int(slot_w * 1.7)
            font = ImageFont.truetype(font_path, max(8, fs))
            bbox = d.textbbox((0, 0), ch, font=font)
            while (bbox[2] - bbox[0]) > slot_w and fs > 10:
                fs -= 3
                font = ImageFont.truetype(font_path, max(8, fs))
                bbox = d.textbbox((0, 0), ch, font=font)
            w = bbox[2] - bbox[0]
            h = bbox[3] - bbox[1]
            d.text((x + (slot_w - w) / 2 - bbox[0], (canvas - h) / 2 - bbox[1]),
                   ch, font=font, fill=255)
            x += slot_w + box_w * 0.06

    if fatten >= 3:
        mask = mask.filter(ImageFilter.MaxFilter(fatten + 1 if fatten % 2 == 0 else fatten))
    return mask


def draw_seal(canvas, seal_size, text, font_path, *, border=True, corner=0.075,
              fatten=0, vertical=True, glyph_ratio=0.62, seed=3):
    layer = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    off = (canvas - seal_size) / 2
    radius = seal_size * corner
    d.rounded_rectangle([off, off, off + seal_size, off + seal_size],
                        radius=radius, fill=INK_RED + (255,))

    if border:
        inset = seal_size * 0.052
        d.rounded_rectangle(
            [off + inset, off + inset, off + seal_size - inset, off + seal_size - inset],
            radius=max(2, radius - inset * 0.5), outline=PAPER + (255,),
            width=max(1, int(seal_size * 0.014)),
        )

    box = seal_size * glyph_ratio
    mask = _glyph_mask(canvas, text, font_path, box, box, vertical=vertical, fatten=fatten)
    mask = mask.filter(ImageFilter.GaussianBlur(seal_size * 0.0022))
    glyph = Image.new("RGBA", (canvas, canvas), PAPER + (0,))
    glyph.putalpha(mask)
    layer = Image.alpha_composite(layer, glyph)

    arr = np.array(layer).astype(np.float32)
    arr[:, :, :3] *= _noise(canvas, 0.05, seed)
    yy, xx = np.mgrid[0:canvas, 0:canvas]
    dist = np.minimum.reduce([
        np.abs(xx - off), np.abs(xx - (off + seal_size)),
        np.abs(yy - off), np.abs(yy - (off + seal_size)),
    ])
    inside = (xx >= off) & (xx <= off + seal_size) & (yy >= off) & (yy <= off + seal_size)
    edge = np.clip(dist / (seal_size * 0.02), 0, 1)
    arr[:, :, 3] *= np.where(inside, 0.55 + 0.45 * edge, 1.0)
    return Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGBA")


def paper(size):
    arr = np.zeros((size, size, 3), dtype=np.float32)
    arr[:, :, :] = np.array(PAPER, dtype=np.float32)
    rng = np.random.default_rng(11)
    arr += rng.normal(0, 1.6, (size, size, 1))
    return Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGB").convert("RGBA")


def compose(size, text, font_path, *, seal_ratio=0.72, glyph_ratio=0.62, border=True,
            fatten=0, corner=0.06, paper_bg=True, vertical=True):
    seal = draw_seal(size, size * seal_ratio, text, font_path, border=border,
                     corner=corner, fatten=fatten, vertical=vertical,
                     glyph_ratio=glyph_ratio)
    if not paper_bg:
        return seal
    return Image.alpha_composite(paper(size), seal).convert("RGB")


def _char_layer(canvas, ch, font_path, target, rotation=0.0, fatten=0):
    """单个字的 mask，居中、可旋转。"""
    layer = Image.new("L", (canvas, canvas), 0)
    d = ImageDraw.Draw(layer)
    fs = int(target * 1.8)
    font = ImageFont.truetype(font_path, max(8, fs))
    bbox = d.textbbox((0, 0), ch, font=font)
    while max(bbox[2] - bbox[0], bbox[3] - bbox[1]) > target and fs > 10:
        fs -= 3
        font = ImageFont.truetype(font_path, max(8, fs))
        bbox = d.textbbox((0, 0), ch, font=font)
    w, h = bbox[2] - bbox[0], bbox[3] - bbox[1]
    d.text(((canvas - w) / 2 - bbox[0], (canvas - h) / 2 - bbox[1]), ch, font=font, fill=255)
    if rotation:
        layer = layer.rotate(rotation, resample=Image.BICUBIC, center=(canvas / 2, canvas / 2))
    if fatten >= 3:
        layer = layer.filter(ImageFilter.MaxFilter(fatten + 1 if fatten % 2 == 0 else fatten))
    return layer


def draw_seal_placed(canvas, seal_size, text, font_path, positions, char_ratio=0.44,
                     *, border=True, corner=0.06, fatten=0, seed=3):
    """positions: [(dx, dy, rotation)]，dx/dy 是相对印章中心、以印章边长为单位的偏移。"""
    layer = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    off = (canvas - seal_size) / 2
    radius = seal_size * corner
    red = (166, 58, 47)
    paper = (247, 245, 239)
    d.rounded_rectangle([off, off, off + seal_size, off + seal_size], radius=radius, fill=red + (255,))
    if border:
        inset = seal_size * 0.052
        d.rounded_rectangle(
            [off + inset, off + inset, off + seal_size - inset, off + seal_size - inset],
            radius=max(2, radius - inset * 0.5), outline=paper + (255,),
            width=max(1, int(seal_size * 0.014)))

    mask = Image.new("L", (canvas, canvas), 0)
    for ch, (dx, dy, rot) in zip(list(text), positions):
        m = _char_layer(canvas, ch, font_path, seal_size * char_ratio, rot, fatten)
        shifted = Image.new("L", (canvas, canvas), 0)
        shifted.paste(m, (int(dx * seal_size), int(dy * seal_size)))
        mask = Image.fromarray(np.maximum(np.array(mask), np.array(shifted)))

    mask = mask.filter(ImageFilter.GaussianBlur(seal_size * 0.0022))
    glyph = Image.new("RGBA", (canvas, canvas), paper + (0,))
    glyph.putalpha(mask)
    layer = Image.alpha_composite(layer, glyph)

    arr = np.array(layer).astype(np.float32)
    arr[:, :, :3] *= _noise(canvas, 0.05, seed)
    yy, xx = np.mgrid[0:canvas, 0:canvas]
    dist = np.minimum.reduce([
        np.abs(xx - off), np.abs(xx - (off + seal_size)),
        np.abs(yy - off), np.abs(yy - (off + seal_size)),
    ])
    inside = (xx >= off) & (xx <= off + seal_size) & (yy >= off) & (yy <= off + seal_size)
    edge = np.clip(dist / (seal_size * 0.02), 0, 1)
    arr[:, :, 3] *= np.where(inside, 0.55 + 0.45 * edge, 1.0)
    return Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGBA")
