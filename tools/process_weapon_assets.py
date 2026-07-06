"""Split, name, and losslessly crop the original Meowa weapon sprites.

No pixels are resized. The source-name mapping comes from each Meowa job response,
so output filenames never depend on prompt order.
"""
from __future__ import annotations

import json
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parent.parent
OUTPUT = ROOT / "godot" / "assets" / "weapons"
PADDING = 2

# Meowa returns correct names but not in the same order as sprite_XX files.
# source_index is therefore verified visually once and stored explicitly.
ASSETS = (
    ("realistic_firearm_overlays", 0, "M1911手枪", "pistol", "M1911 手枪", 68, "pistol", 0.43),
    ("realistic_firearm_overlays", 1, "UZI冲锋枪", "uzi", "UZI 冲锋手枪", 82, "pistol", 0.46),
    ("realistic_firearm_overlays", 2, "Kar98k栓动步枪", "kar98k", "Kar98k 步枪", 145, "rifle", 0.39),
    ("realistic_firearm_overlays", 3, "雷明顿870霰弹枪", "shotgun", "雷明顿 870", 148, "rifle", 0.36),
    ("realistic_firearm_overlays", 4, "AK47突击步枪", "ak47", "AK-47", 132, "rifle", 0.40),
    ("realistic_firearm_overlays", 5, "M4A1卡宾枪", "m4", "M4A1", 126, "rifle", 0.39),
    ("realistic_firearm_overlays", 6, "M249轻机枪", "m249", "M249 轻机枪", 142, "rifle", 0.42),
    ("realistic_melee_overlays", 0, "战术格斗刀", "knife", "战术匕首", 72, "melee", 0.35),
    ("realistic_melee_overlays", 1, "农用大砍刀", "machete", "开山刀", 96, "melee", 0.28),
)


def alpha_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        raise ValueError("sprite is fully transparent")
    left, top, right, bottom = bbox
    return (
        max(0, left - PADDING),
        max(0, top - PADDING),
        min(image.width, right + PADDING),
        min(image.height, bottom + PADDING),
    )


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    manifest: dict[str, dict[str, object]] = {}

    for pack_name, index, source_name, weapon_id, display_name, world_length, hold_pose, grip_x_ratio in ASSETS:
        pack_dir = ROOT / "art" / "meowa" / pack_name
        response = json.loads((pack_dir / "job_response.json").read_text(encoding="utf-8"))
        if source_name not in response["output"]["sprite_pack_names"]:
            raise RuntimeError(f'job response does not contain expected name "{source_name}"')
        source = pack_dir / f"sprite_{index:02d}.png"
        image = Image.open(source).convert("RGBA")
        raw_bbox = image.getchannel("A").getbbox()
        if raw_bbox is None:
            raise ValueError(f"{source} is fully transparent")
        visible_width = raw_bbox[2] - raw_bbox[0]
        cropped = image.crop(alpha_bbox(image))
        target = OUTPUT / f"{weapon_id}.png"
        cropped.save(target, optimize=True)
        manifest[weapon_id] = {
            "display_name": display_name,
            "source_name": source_name,
            "source_index": index,
            "source_file": source.relative_to(ROOT).as_posix(),
            "file": target.name,
            "pixel_size": [cropped.width, cropped.height],
            "visible_width": visible_width,
            "world_length": world_length,
            "hold_pose": hold_pose,
            "grip_x_ratio": grip_x_ratio,
        }
        print(f"{source_name} -> {target.name} {cropped.width}x{cropped.height}")

    expected = {asset[3] for asset in ASSETS}
    if set(manifest) != expected:
        raise RuntimeError(f"mapping incomplete: expected {expected}, got {set(manifest)}")
    (OUTPUT / "weapon_asset_manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()
