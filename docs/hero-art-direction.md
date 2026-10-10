# Hero and equipment art — river-order craft

First pass delivered 2026-09-26; further refinement delivered 2026-09-27.
This completes a character/equipment pass; the wider art identity milestone still
requires world architecture, NPC models and signature restoration. The
[canonical RPG revision](rpg-systems-restoration-revision.md) defines the next
quality milestone as a full 10–15 minute opening sequence.

## Visual language

Ancient river-order craft: porcelain plates, patinated bronze/gold, indigo and teal
woven cloth, reed leaves, split crescents and restrained luminous riverglass. Keep
large silhouettes readable at the gameplay camera distance. Let layered tailoring
and fittings reward a closer look in the wardrobe.

- **Warden:** contoured human face, swept hair and reed diadem; layered shoulder
  plates, convex breastplate with water-chevron inlay, articulated hip tassets,
  shaped vambraces/shin guards, split embroidered tabard, boots and repair pouch.
- **Weaver:** an open, sculpted hood with a closed rear cowl, exposed face, reed
  crown, asymmetric porcelain shoulder leaves, tailored diagonal sash and eight
  curved, scalloped robe panels. The hood and base robe belong to the discipline;
  the back mantle remains replaceable equipment.
- **Five tools:** seed lantern, branching leaf cradle, riverglass crescent,
  three reed tips and ferryman's hooked lantern. Fitted grips and ferrules connect
  the crafted head to the shaft. Upgrade shapes differ beyond colour and size.
- **Four mantles:** folded cloth, scalloped hems, raised bindings, shoulder yokes,
  leaf/sun/reed crests and upgraded tassels. Small shader motion animates the hem.
- **Six brooches:** a round keepsake, heartbloom, crescent, bell, messenger wings
  and stonekeeper frame; restrained cut gems replace oversized glowing spheres.

## 2026-09-27 refinement

The second pass addresses remaining broad primitive shapes and flat surface depth:

- Sculpted, rimmed Warden shoulder shells and fitted gauntlet plates replace round
  pads. Pauldrons follow the upper arms during action poses. Plate thickness now
  follows local surface normals, preventing coplanar overlap on horizontal shells.
- More stature: the lower body is lengthened by 17% around a 0.68 m authored waist
  pivot, while head/upper torso sizes remain fixed. Bone rest joints and all three
  equipment slots use the same fitting function. Preserve both constants in
  `hero_finish.py` and `GearVisuals` when changing proportions.
- Weaver cheek wraps, layered porcelain/bronze shoulder fans, embroidered robe
  hems, improved eyelids, pupils and restrained eye highlights.
- Offline ray-traced crevice shading and tonal variation baked into one vertex
  colour channel. This survives GLB import and the hero shader uses `COLOR.rgb`.
  It adds depth beneath collars, plates and tailoring without runtime AO passes
  or texture dependencies. The hero model test now checks that colour data and a
  useful shading range survive import.
- Continuous sculpted lighting and improved metallic highlights; fine metal and
  porcelain forms use their authored trim rather than a black outline pass.
- Mantles have deeper folds and woven borders/hem patterns with pixel-footprint
  filtering. Earned staffs add cut octagonal gems, shaft inlay, ribbons and crafted
  head fittings. Brooch stones have retaining prongs. Gear still batches per item.
- The wardrobe is reframed for the taller silhouettes. Native front/back,
  three-quarter, walk and action renders and actual wardrobe/gameplay views were
  inspected. The final **3 hero and 6 equipment tests passed**; the full regression
  suite result below belongs to the first pass. Android APK was rebuilt.

Hero/gear shading separates matte cloth, porcelain, skin and metallic fittings.
Organic surfaces have smooth normals; ridged leaves and cut glass retain edges.
Fine facial features, moving cloth and sculpted porcelain/metal omit the outline
pass; gold contours and baked shading define the layered edges.
This is a stylized authored mesh pass, not textured realism.

## Facial definition refinement — 2026-09-27

Faces now have authored chin, jaw, cheek, eye-socket and brow contours rather than
elliptical cross sections throughout. The Warden has a broader jaw; the Weaver
has a tapered lower face beneath defined cheekbones. A shaped nose bridge/tip,
small nostrils, arched brows and upper/lower lip volumes replace oval nose pieces
and the flat mouth line. Skin crevice shading is softened to retain a clear face.
The Weaver collar is lower so it reveals the jaw and chin. Hair, headgear, bone
names and animation clips retain their existing contracts.

Native front and three-quarter head close-ups are now part of
`dev/review_hero_art.gd`; images are `faces-front.png` and `faces-three-quarter.png`.
Also inspect the normal wardrobe view: facial details should not depend on zoom.

## Body and movement refinement — 2026-09-27

This first body pass has been superseded by the human foundation below.

The bodies now use continuous contoured torso, sleeve and trouser surfaces instead
of separate rigid limb sections. Shoulders, elbows, hips and knees blend between
adjacent bone weights; armour remains rigid on its appropriate bone. Shaped palms,
curved fingers and thumbs replace mitten forms. Boots have shaped ankles, toes and
flat soles. Tabards and robe panels follow the thighs slightly through their lower
weights, without adding cloth simulation.

Idle shifts weight and breathes subtly. Walking has contact/passing phases, bent
knees, torso counter-rotation and a smaller swing for the staff arm. The restoration
clip uses an asymmetric supported offering gesture. Runtime transitions blend over
0.10 seconds; the existing 12 bones and 0.333-second action duration are preserved.

Native phase renders and a recorded idle/walk/action sequence were inspected with
both equipped heroes, followed by actual world and wardrobe captures. The imported
model regression gate checks that blended skin weights survive GLB export. Reproduce
the motion review with the same native command below plus `-- --motion`; optionally
add `--write-movie builds/playtest/hero-art/body-motion.avi --fixed-fps 30` before `-s`.

## Human foundation replacement — 2026-09-27

The user approved a substantial move toward believable human anatomy. Both heroes
now use the MakeHuman core human mesh for their body and five-finger hands, adapted
to our rig, dressed and reduced for the game. This replaces the prototype lofted
limbs and volume-built torso. Shoulder, rib cage, abdomen, pelvis and limb forms
come from anatomical topology; the original faces, hair/hoods, armour, robe panels,
boots and equipment retain the river-order design.

The shared skeleton has **43 bones**. The original 12 names remain compatibility
anchors. Added neck/clavicles, arm/forearm twist bones, hands, two joints per finger
and feet carry real skin weights. Tools now bind to `hand.R`, allowing wrist motion
without losing the grip; the older forearm binding remains a compatibility fallback.
Cloth, armour, bone rests and mantle/brooch geometry share the same fitting rules:
legs 1.17, torso 1.22, head 0.82 and upper-body width 0.82, around the documented
canonical pivots. Do not change one side of that fitting contract alone.

Walking includes offline-baked ankle IK, knee bend, foot roll and torso/shoulder
counter-motion. It exports as ordinary keyframes; no runtime IK constraints or
controllers are required. Idle breathes and shifts weight; the offering gesture
opens the free hand while keeping the staff grip. The action duration remains
0.333 seconds. The imported-pose test verifies support/swing ankle heights and
the actual staff attachment's position, as well as skin weights on the added bones.

The body foundation is a shared anatomy asset, not a claim of exclusive geometry.
Its source revision and licences are kept locally. Distinctive tailoring, materials,
faces and equipment remain essential to our identity. This is believable anatomy
within the existing stylized fantasy presentation; photorealistic skin, facial
animation and simulated garments have not been delivered.

## Sources and editable assets

The human anatomy source is the [MakeHuman core base mesh](https://github.com/makehumancommunity/makehuman/blob/a8bc2d54ff0ac92e78ff71431b1023eda42bf482/makehuman/data/3dobjs/base.obj),
released under [CC0 for graphical assets](https://github.com/makehumancommunity/makehuman/blob/a8bc2d54ff0ac92e78ff71431b1023eda42bf482/LICENSE.md).
Only asset data was imported. Local source files, licence text, pinned revision
and SHA-256 are in `art/source/makehuman/`; `.gdignore` keeps source data out of
runtime imports and exports. The rest of the hero/gear geometry is authored here.

- `art/characters/hero_finish.py`: proportion fitting and offline surface shading.
- `art/characters/hero_craft.py`: the authored hero surfaces and construction.
- `art/characters/hero_anatomy.py`: human mesh adaptation, anatomical skinning,
  expanded rig, boot fitting and baked ankle/foot animation.
- `art/characters/build_heroes.py`, `charlib.py`: rig, animation and GLB export.
- `assets/characters/warden.glb`, `weaver.glb`: runtime skinned models.
- `art/heroes/warden.blend`, `weaver.blend`: locally generated editable masters
  (ignored build outputs; regenerate rather than treating these as checked in).
- `scripts/gear/gear_visuals.gd`: all equipment geometry, binding and batching.
- `shaders/hero_surface.gdshader`, `hero_surface_material.tres`: finish and cloth.
- `scripts/toon_util.gd`: carries imported colour, emission, roughness and metal
  into the hero material. World geometry continues using its established shader.

Rebuild heroes (Blender does not need its GUI open):

```sh
/Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup \
  --python art/characters/build_heroes.py -- \
  --out assets/characters --preview art/heroes --no-preview
```

## Rig, equipment and mobile budgets

Preserve the existing 12 named bones within the 43-bone rig and idle/walk/attack
clips. New proportions move the rest joints but keep the runtime contract. Tool
fitting uses each rig's right hand rest position. Cloak and brooch attach to the chest. Equipping still
replaces exactly one mesh per slot; both disciplines retain the selected outfit.

Measured after Godot import:

| Asset | Triangles |
| --- | ---: |
| Warden body | 17,888 |
| Weaver body | 19,031 |
| Each tool | 694–1,670 |
| Each mantle | 1,808–2,104 |
| Each brooch | 224–528 |
| Inspected Warden outfit | 21,838 |
| Inspected Weaver outfit | 22,445 |

The former 2,500-triangle hero budget described the prototype. The deliberate new
body ceiling is now 24,000 for the approved anatomical replacement; each equipment
piece must remain below 3,000. Hero imports generate distance LODs. Equipment
batches into one mesh per item with 2–7 material surfaces (gate: no more than 8).
Index authored triangles before appending to primitive mesh surfaces: mixed
indexed/unindexed surfaces previously discarded decorative leaves during batching.
No CPU cloth simulation, extra skeletons or per-fitting runtime nodes are needed.
Physical Android device performance is not yet measured.

## Verification and review

The full regression suite passed **143 tests** after the human foundation
replacement, including imported blend weights, anatomical bone influences,
support/swing ankle placement, the animated wrist attachment and catalogue
geometry budgets. The focused hero suite passed **4 tests**. Android debug export
was rebuilt and signed. Native idle/walk/action recording, phase renders and
actual world/wardrobe captures were inspected. The native
game was reopened; the production save matched its pre-restart backup.
Inspect both disciplines from front/back and in walk/Mend poses; inspect all 15
pieces and the actual live wardrobe/world views. The native renderer logs for
these captures have no script/shader errors. Headless tests still produce the
existing dummy renderer null-material diagnostics and shutdown leak warning.

Reproduce the native review without touching a player save:

```sh
/Users/mathiusjohnson/Downloads/Godot.app/Contents/MacOS/Godot --path . \
  --resolution 1280x720 -s dev/review_hero_art.gd
```

Images are written under `builds/playtest/hero-art/` (ignored). The review prints
triangle/surface counts for every item and exits unsuccessfully if a piece exceeds
its review budget. Automated regression gates:

```sh
bash dev/test.sh hero_models
bash dev/test.sh restoration_gear
```

Inventory definitions, effects, touch controls and save format are unchanged by
this art pass. Existing owned/equipped IDs immediately display their new geometry.
