import bpy
import math
import os
import glob
from pathlib import Path
from mathutils import Vector


# ============================================================
# PATHS
# ============================================================

SCRIPT_PATH = Path(__file__).resolve()
REPO_ROOT = SCRIPT_PATH.parents[2]
OUTPUT_DIR = REPO_ROOT / "assets" / "gpa_lab" / "3d"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)


# ============================================================
# HELPERS
# ============================================================

def hex_rgb(value):
    value = value.lstrip("#")
    return tuple(
        int(value[i:i + 2], 16) / 255.0
        for i in (0, 2, 4)
    )


def rgba(value, alpha=1.0):
    return (*hex_rgb(value), alpha)


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)

    for block in list(bpy.data.meshes):
        if block.users == 0:
            bpy.data.meshes.remove(block)

    for block in list(bpy.data.curves):
        if block.users == 0:
            bpy.data.curves.remove(block)


def set_smooth(obj):
    if obj.type == "MESH":
        for polygon in obj.data.polygons:
            polygon.use_smooth = True


def add_bevel(obj, width=0.12, segments=5):
    modifier = obj.modifiers.new(
        name="Soft Machined Bevel",
        type="BEVEL",
    )
    modifier.width = width
    modifier.segments = segments
    modifier.limit_method = "ANGLE"

    if hasattr(modifier, "harden_normals"):
        modifier.harden_normals = True


def make_material(
    name,
    base,
    metallic=0.0,
    roughness=0.4,
    emission=None,
    emission_strength=0.0,
):
    material = bpy.data.materials.new(name=name)
    material.use_nodes = True

    bsdf = material.node_tree.nodes.get("Principled BSDF")

    bsdf.inputs["Base Color"].default_value = rgba(base)

    if "Metallic" in bsdf.inputs:
        bsdf.inputs["Metallic"].default_value = metallic

    if "Roughness" in bsdf.inputs:
        bsdf.inputs["Roughness"].default_value = roughness

    if emission is not None:
        if "Emission Color" in bsdf.inputs:
            bsdf.inputs["Emission Color"].default_value = rgba(emission)

        if "Emission Strength" in bsdf.inputs:
            bsdf.inputs["Emission Strength"].default_value = emission_strength

    return material


def assign_material(obj, material):
    if hasattr(obj.data, "materials"):
        obj.data.materials.append(material)


def create_cylinder(
    name,
    radius,
    depth,
    z,
    material,
    bevel=0.0,
):
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=128,
        radius=radius,
        depth=depth,
        location=(0, 0, z),
    )

    obj = bpy.context.active_object
    obj.name = name

    assign_material(obj, material)
    set_smooth(obj)

    if bevel > 0:
        add_bevel(
            obj,
            width=bevel,
            segments=6,
        )

    return obj


def create_torus(
    name,
    major_radius,
    minor_radius,
    z,
    material,
):
    bpy.ops.mesh.primitive_torus_add(
        major_segments=128,
        minor_segments=32,
        major_radius=major_radius,
        minor_radius=minor_radius,
        location=(0, 0, z),
    )

    obj = bpy.context.active_object
    obj.name = name

    assign_material(obj, material)
    set_smooth(obj)

    return obj


def create_uv_sphere(
    name,
    radius,
    location,
    material,
):
    bpy.ops.mesh.primitive_uv_sphere_add(
        segments=64,
        ring_count=32,
        radius=radius,
        location=location,
    )

    obj = bpy.context.active_object
    obj.name = name

    assign_material(obj, material)
    set_smooth(obj)

    return obj


def find_bold_font():
    patterns = [
        "/usr/share/fonts/**/Inter-Bold.ttf",
        "/usr/share/fonts/**/Inter_18pt-Bold.ttf",
        "/usr/share/fonts/**/DejaVuSans-Bold.ttf",
        "/usr/share/fonts/**/NotoSans-Bold.ttf",
    ]

    for pattern in patterns:
        files = glob.glob(
            pattern,
            recursive=True,
        )
        if files:
            try:
                return bpy.data.fonts.load(files[0])
            except Exception:
                pass

    return None


BOLD_FONT = find_bold_font()


def create_text(
    name,
    body,
    location,
    size,
    material,
    extrude=0.025,
    bevel_depth=0.008,
):
    bpy.ops.object.text_add(
        location=location,
    )

    obj = bpy.context.active_object
    obj.name = name

    text = obj.data
    text.body = body
    text.align_x = "CENTER"
    text.align_y = "CENTER"
    text.size = size
    text.extrude = extrude
    text.bevel_depth = bevel_depth
    text.bevel_resolution = 4

    if BOLD_FONT is not None:
        text.font = BOLD_FONT

    assign_material(obj, material)

    return obj


def create_root(name):
    root = bpy.data.objects.new(
        name=name,
        object_data=None,
    )
    bpy.context.collection.objects.link(root)
    return root


def parent_objects(objects, root):
    for obj in objects:
        obj.parent = root


def point_object_at(obj, target):
    direction = Vector(target) - obj.location

    obj.rotation_euler = direction.to_track_quat(
        "-Z",
        "Y",
    ).to_euler()


# ============================================================
# MATERIALS
# ============================================================

MAT_GRAPHITE = make_material(
    "Graphite Deep Body",
    "#211D1E",
    metallic=0.72,
    roughness=0.25,
)

MAT_DARK_METAL = make_material(
    "Dark Machined Metal",
    "#4E4848",
    metallic=0.95,
    roughness=0.21,
)

MAT_FACE = make_material(
    "Ceramic Graphite Face",
    "#393334",
    metallic=0.18,
    roughness=0.20,
)

MAT_WHITE = make_material(
    "Warm White Lettering",
    "#FFF9F5",
    metallic=0.0,
    roughness=0.34,
)

MAT_CHAMPAGNE = make_material(
    "Champagne Metal",
    "#B7A39A",
    metallic=0.92,
    roughness=0.23,
)

MAT_CAVITY = make_material(
    "Dock Inner Cavity",
    "#171415",
    metallic=0.25,
    roughness=0.19,
)

MAT_CORAL = make_material(
    "AI Coral",
    "#EF5D60",
    metallic=0.22,
    roughness=0.23,
    emission="#EF5D60",
    emission_strength=0.45,
)

MAT_ORANGE = make_material(
    "TI Orange",
    "#FF9B55",
    metallic=0.22,
    roughness=0.23,
    emission="#FF9B55",
    emission_strength=0.45,
)

MAT_CYAN = make_material(
    "Dock B Cyan",
    "#63C6CD",
    metallic=0.18,
    roughness=0.22,
    emission="#63C6CD",
    emission_strength=0.40,
)

MAT_GREEN = make_material(
    "Dock B Plus Green",
    "#63C98D",
    metallic=0.18,
    roughness=0.22,
    emission="#63C98D",
    emission_strength=0.40,
)

MAT_AMBER = make_material(
    "Dock A Minus Amber",
    "#F3A24A",
    metallic=0.18,
    roughness=0.22,
    emission="#F3A24A",
    emission_strength=0.40,
)

MAT_RED = make_material(
    "Dock A Red",
    "#EF6863",
    metallic=0.18,
    roughness=0.22,
    emission="#EF6863",
    emission_strength=0.40,
)

MAT_LED_WHITE = make_material(
    "LED White Core",
    "#FFFFFF",
    metallic=0.0,
    roughness=0.15,
    emission="#FFFFFF",
    emission_strength=3.0,
)


# ============================================================
# TOKEN
# ============================================================

def build_token(
    root_name,
    code,
    credits,
    accent_material,
    scale=1.0,
):
    root = create_root(root_name)
    objects = []

    # Deep black lower body.
    objects.append(
        create_cylinder(
            f"{root_name} / Deep Body",
            radius=2.08 * scale,
            depth=0.70 * scale,
            z=0.35 * scale,
            material=MAT_GRAPHITE,
            bevel=0.15 * scale,
        )
    )

    # Slightly wider bottom foot.
    objects.append(
        create_cylinder(
            f"{root_name} / Lower Foot",
            radius=2.14 * scale,
            depth=0.20 * scale,
            z=0.12 * scale,
            material=MAT_GRAPHITE,
            bevel=0.09 * scale,
        )
    )

    # Machined top bezel.
    objects.append(
        create_cylinder(
            f"{root_name} / Metal Bezel",
            radius=2.04 * scale,
            depth=0.24 * scale,
            z=0.72 * scale,
            material=MAT_DARK_METAL,
            bevel=0.10 * scale,
        )
    )

    # Accent light ring.
    objects.append(
        create_torus(
            f"{root_name} / Accent Ring",
            major_radius=1.70 * scale,
            minor_radius=0.105 * scale,
            z=0.88 * scale,
            material=accent_material,
        )
    )

    # Ceramic face.
    objects.append(
        create_cylinder(
            f"{root_name} / Ceramic Face",
            radius=1.57 * scale,
            depth=0.18 * scale,
            z=0.82 * scale,
            material=MAT_FACE,
            bevel=0.07 * scale,
        )
    )

    # Main identity.
    objects.append(
        create_text(
            f"{root_name} / Code",
            body=code,
            location=(
                0,
                0.17 * scale,
                0.96 * scale,
            ),
            size=0.77 * scale,
            material=MAT_WHITE,
            extrude=0.025 * scale,
            bevel_depth=0.009 * scale,
        )
    )

    # Credits.
    objects.append(
        create_text(
            f"{root_name} / Credits",
            body=f"{credits} TC",
            location=(
                0,
                -0.60 * scale,
                0.955 * scale,
            ),
            size=0.30 * scale,
            material=accent_material,
            extrude=0.018 * scale,
            bevel_depth=0.006 * scale,
        )
    )

    parent_objects(
        objects,
        root,
    )

    return root, objects


# ============================================================
# GRADE DOCK
# ============================================================

def build_dock(
    root_name,
    accent_material,
):
    root = create_root(root_name)
    objects = []

    # Solid foot.
    objects.append(
        create_cylinder(
            f"{root_name} / Base",
            radius=2.16,
            depth=0.36,
            z=0.18,
            material=MAT_CHAMPAGNE,
            bevel=0.14,
        )
    )

    # Outer machined metal lip.
    objects.append(
        create_torus(
            f"{root_name} / Metal Lip",
            major_radius=1.69,
            minor_radius=0.28,
            z=0.46,
            material=MAT_CHAMPAGNE,
        )
    )

    # Functional accent ring.
    objects.append(
        create_torus(
            f"{root_name} / Accent Ring",
            major_radius=1.51,
            minor_radius=0.115,
            z=0.53,
            material=accent_material,
        )
    )

    # Low cavity floor.
    objects.append(
        create_cylinder(
            f"{root_name} / Cavity",
            radius=1.38,
            depth=0.18,
            z=0.39,
            material=MAT_CAVITY,
            bevel=0.10,
        )
    )

    # Rear status LED.
    objects.append(
        create_uv_sphere(
            f"{root_name} / LED Glow",
            radius=0.14,
            location=(
                0,
                1.46,
                0.73,
            ),
            material=accent_material,
        )
    )

    objects.append(
        create_uv_sphere(
            f"{root_name} / LED Core",
            radius=0.055,
            location=(
                0,
                1.47,
                0.75,
            ),
            material=MAT_LED_WHITE,
        )
    )

    parent_objects(
        objects,
        root,
    )

    return root, objects


# ============================================================
# LIGHTING / CAMERA
# ============================================================

def add_area_light(
    name,
    location,
    energy,
    size,
    color,
    target=(0, 0, 0.4),
):
    data = bpy.data.lights.new(
        name=name,
        type="AREA",
    )

    data.energy = energy
    data.shape = "DISK"
    data.size = size
    data.color = hex_rgb(color)

    obj = bpy.data.objects.new(
        name=name,
        object_data=data,
    )

    bpy.context.collection.objects.link(obj)

    obj.location = location
    point_object_at(
        obj,
        target,
    )

    return obj


def setup_camera_and_lights():
    camera_data = bpy.data.cameras.new(
        name="GPA Asset Camera",
    )

    camera = bpy.data.objects.new(
        name="GPA Asset Camera",
        object_data=camera_data,
    )

    bpy.context.collection.objects.link(camera)

    camera.location = (
        5.6,
        -7.6,
        6.4,
    )

    camera_data.type = "ORTHO"
    camera_data.ortho_scale = 6.3

    point_object_at(
        camera,
        (0, 0, 0.45),
    )

    bpy.context.scene.camera = camera

    add_area_light(
        "Key / Warm",
        location=(4.5, -4.2, 7.8),
        energy=1050,
        size=4.3,
        color="#FFF1E8",
    )

    add_area_light(
        "Fill / Soft",
        location=(-4.6, -2.5, 5.0),
        energy=620,
        size=5.0,
        color="#DDE7FF",
    )

    add_area_light(
        "Rim / Champagne",
        location=(1.2, 5.4, 6.5),
        energy=900,
        size=3.4,
        color="#FFD0AD",
    )

    return camera


# ============================================================
# RENDER SETTINGS
# ============================================================

def setup_render():
    scene = bpy.context.scene

    # Blender 5.2 identifier.
    scene.render.engine = "BLENDER_EEVEE"

    scene.render.resolution_x = 768
    scene.render.resolution_y = 768
    scene.render.resolution_percentage = 100

    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.image_settings.color_depth = "8"

    scene.render.film_transparent = True

    # Transparent edges look better in UI compositing.
    scene.render.image_settings.compression = 15

    # AgX is Blender's modern display transform.
    try:
        scene.view_settings.view_transform = "AgX"
    except Exception:
        pass

    try:
        scene.view_settings.look = "AgX - Medium High Contrast"
    except Exception:
        pass

    scene.world.use_nodes = True

    bg = scene.world.node_tree.nodes.get("Background")
    if bg:
        bg.inputs["Color"].default_value = (
            0.035,
            0.028,
            0.030,
            1.0,
        )
        bg.inputs["Strength"].default_value = 0.18


# ============================================================
# ASSET RENDERING
# ============================================================

ALL_ROOTS = []


def set_asset_render_visibility(root, visible):
    # Empty-parent hide_render does NOT reliably hide its children.
    # Explicitly toggle the whole hierarchy.
    hidden = not visible

    root.hide_render = hidden

    stack = list(root.children)

    while stack:
        obj = stack.pop()
        obj.hide_render = hidden
        stack.extend(list(obj.children))


def hide_all_assets():
    for root in ALL_ROOTS:
        set_asset_render_visibility(root, False)


def render_asset(
    root,
    filename,
    layout_x,
):
    hide_all_assets()

    root.location = (0, 0, 0)
    set_asset_render_visibility(root, True)

    scene = bpy.context.scene
    scene.render.filepath = str(
        OUTPUT_DIR / filename
    )

    print()
    print("=" * 60)
    print(f"Rendering {filename}")
    print("=" * 60)

    bpy.ops.render.render(
        write_still=True,
    )

    # Park asset in the .blend library after rendering.
    root.location = (
        layout_x,
        0,
        0,
    )

    set_asset_render_visibility(root, False)


# ============================================================
# MAIN
# ============================================================

clear_scene()
setup_render()
setup_camera_and_lights()


# AI Token
ai_root, _ = build_token(
    root_name="AI TOKEN",
    code="AI",
    credits=3,
    accent_material=MAT_CORAL,
    scale=1.00,
)
ALL_ROOTS.append(ai_root)

render_asset(
    ai_root,
    "ai_token.png",
    layout_x=0,
)


# TI Token: intentionally ~12% larger.
ti_root, _ = build_token(
    root_name="TI TOKEN",
    code="TI",
    credits=5,
    accent_material=MAT_ORANGE,
    scale=1.12,
)
ALL_ROOTS.append(ti_root)

render_asset(
    ti_root,
    "ti_token.png",
    layout_x=6.5,
)


# B Dock
b_root, _ = build_dock(
    "DOCK B",
    MAT_CYAN,
)
ALL_ROOTS.append(b_root)

render_asset(
    b_root,
    "dock_b.png",
    layout_x=13,
)


# B+ Dock
bp_root, _ = build_dock(
    "DOCK B PLUS",
    MAT_GREEN,
)
ALL_ROOTS.append(bp_root)

render_asset(
    bp_root,
    "dock_b_plus.png",
    layout_x=19.5,
)


# A- Dock
am_root, _ = build_dock(
    "DOCK A MINUS",
    MAT_AMBER,
)
ALL_ROOTS.append(am_root)

render_asset(
    am_root,
    "dock_a_minus.png",
    layout_x=26,
)


# A Dock
a_root, _ = build_dock(
    "DOCK A",
    MAT_RED,
)
ALL_ROOTS.append(a_root)

render_asset(
    a_root,
    "dock_a.png",
    layout_x=32.5,
)


# Show all assets inside saved .blend.
for root in ALL_ROOTS:
    set_asset_render_visibility(root, True)
    root.hide_viewport = False


blend_path = OUTPUT_DIR / "gpa_lab_assets.blend"

bpy.ops.wm.save_as_mainfile(
    filepath=str(blend_path),
)


print()
print("=" * 60)
print("DONE")
print("=" * 60)
print(f"Output folder: {OUTPUT_DIR}")
print()
print("Generated:")
print("  ai_token.png")
print("  ti_token.png")
print("  dock_b.png")
print("  dock_b_plus.png")
print("  dock_a_minus.png")
print("  dock_a.png")
print("  gpa_lab_assets.blend")
print()
