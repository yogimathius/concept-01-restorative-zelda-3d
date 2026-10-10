"""River-order civilians using the credited human foundation; no hero asset edits.
Blender -b --python art/characters/build_inhabitants.py -- --out assets/characters/npcs
"""
import argparse, math, os, sys
import bpy
HERE=os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0,HERE)
from charlib import Body, make_armature, pose_keys, setup_scene, export, m
from hero_anatomy import skeleton, build_foundation
from hero_craft import loft, face, surface, rod, ellipsoid, ring, transform
from hero_finish import fit_stature, stature_point, bake_surface
from mathutils import Matrix

CAST={
 'mara':('#496e72','#c3af8b','#6d625b','#ad795f'),
 'iona':('#45516f','#b5ad98','#a9a499','#b78568'),
 'oren':('#315b67','#87949a','#493c34','#a97653'),
 'neri':('#856170','#c5b796','#392f32','#ba8768'),
 'daro':('#576e57','#b8a88c','#625347','#936246'),
}

def layout():
 sx=.245
 core={'hips':((0,0,.58),(0,0,.70),None),'spine':((0,0,.70),(0,0,.84),'hips'),
       'chest':((0,0,.84),(0,0,1.02),'spine'),'head':((0,0,1.02),(0,0,1.28),'chest')}
 for sign,side in [(1,'L'),(-1,'R')]:
  core.update({'upper_arm.'+side:((sign*sx,0,.97),(sign*sx,0,.72),'chest'),
   'forearm.'+side:((sign*sx,0,.72),(sign*sx,0,.51),'upper_arm.'+side),
   'thigh.'+side:((sign*.09,0,.58),(sign*.09,0,.30),'hips'),
   'shin.'+side:((sign*.09,0,.30),(sign*.09,0,.04),'thigh.'+side)})
 return skeleton(sx,core)

def build(name,body):
 build_foundation(body,.245,True)
 # Civilian face, hair and tailored working clothes, with no armour or crown.
 first=len(body.parts);face(body,False)
 # The final four parts in the unhooded face are its diadem and three crests.
 for part in body.parts[-4:]:bpy.data.objects.remove(part,do_unlink=True)
 del body.parts[-4:]
 if name in ["mara","neri"]:
  for part in body.parts[first:]:
   for vertex in part.data.vertices:
    if vertex.co.z<1.185: vertex.co.x*=.90
  # A softer cheek-to-jaw transition makes their civilian identity distinct.

 if name in ['mara','iona','neri']:
  body.add(ellipsoid((0,.112,1.208),(.073,.050,.072),16,10),m('hair'),'head')
  body.add(rod((-.043,.149,1.22),(.048,.149,1.22),.004,8),m('metal_bronze'),'head')
 # A long split over-tunic, sculpted folds, and linen apron native to river work.
 body.add(loft([(.20,.19,.13,.02),(.31,.18,.127,.016),(.48,.165,.119,.01),
  (.65,.166,.122,.005),(.75,.162,.128,0),(.91,.17,.126,.001),
  (.98,.15,.117,.007),(1.01,.080,.073,.009)],28),m('cloth_teal'),'spine')
 rows=[]
 for z,rx,y in [(.23,.135,-.116),(.39,.125,-.12),(.55,.12,-.124),(.70,.105,-.126)]:
  rows.append([(x*rx,y+.025*x*x+.008*math.sin(x*10+z*3),z) for x in [-1,-.75,-.5,-.25,0,.25,.5,.75,1]])
 body.add(surface(rows,.008),m('cloth_linen'),'hips')
 for side in [-1,1]:
  body.add(rod((side*.115,-.104,.70),(side*.08,-.119,.91),.009,8),m('leather'),'chest')
  body.add(rod((side*.08,-.119,.91),(side*.068,-.115,.98),.009,8),m('leather'),'chest')
 body.add(loft([(.965,.12,.102,.014),(.988,.094,.083,.014),(1.02,.074,.064,.01)],24),m('cloth_linen'),'chest')
 body.add(loft([(.653,.177,.132,0),(.679,.176,.131,0)],24),m('leather'),'hips')
 ring((0,-.136,.672),.022,.005,'hips',body,m('metal_bronze'),'XZ')
 # Split crescent river-order insignia and small riverglass pin.
 body.add(ellipsoid((-.07,-.116,.94),(.018,.007,.024),12,8),m('metal_bronze'),'chest')
 body.add(ellipsoid((-.07,-.123,.94),(.009,.004,.014),12,8),m('porcelain'),'chest')
 if name=='oren':
  body.add(rod((-.29,.03,.015),(-.29,.03,1.08),.016,10),m('leather'),'hand.L')
  ring((-.29,.03,1.10),.040,.008,'hand.L',body,m('metal_bronze'),'XZ')
 if name=='daro':
  body.add(ellipsoid((.195,-.02,.61),(.048,.035,.055),16,8),m('porcelain'),'hips')
 if name=='iona':
  body.add(rod((-.11,-.127,.80),(.09,-.127,.75),.004,8),m('metal_bronze'),'chest')
 # Folded gauging ledger at the waist, bronze fittings rather than generic weapons.
 if name in ['mara','neri']:
  body.add(ellipsoid((.175,.007,.60),(.042,.018,.057),12,6),m('cloth_linen'),'hips')

def animate(rig):
 rest={'hips':(0,0,-1),'spine':(1,0,.7),'chest':(1,-2,0),'head':(-2,2,0),
       'upper_arm.L':(2,0,3),'upper_arm.R':(-3,0,-3),'forearm.L':(-8,0,0),'forearm.R':(-12,0,0)}
 pose_keys(rig,'idle-loop',{0:rest,45:{**rest,'chest':(2,-1,0),'head':(-3,1,0)},90:rest},90)
 poses={}
 for frame in range(0,25,3):
  wave=math.cos(math.tau*frame/24)
  poses[frame]={**rest,'thigh.L':(-22*wave,0,0),'thigh.R':(22*wave,0,0),
   'shin.L':(6+max(0,-wave)*18,0,0),'shin.R':(6+max(0,wave)*18,0,0),
   'upper_arm.L':(wave*9,0,3),'upper_arm.R':(-wave*9,0,-3)}
 pose_keys(rig,'walk-loop',poses,24)
 pose_keys(rig,'greeting',{0:rest,15:{**rest,'upper_arm.R':(-35,0,-25),'forearm.R':(-38,0,0),'head':(-5,0,0)},45:rest},45)
 rig.animation_data.action=None

def main():
 argv=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
 parser=argparse.ArgumentParser();parser.add_argument('--out',required=True);a=parser.parse_args(argv)
 os.makedirs(a.out,exist_ok=True)
 for name,colors in CAST.items():
  setup_scene()
  import kitlib
  kitlib.PALETTE.update(dict(zip(['cloth_teal','cloth_indigo','hair','skin'],[colors[0],colors[0],colors[2],colors[3]])))
  kitlib.PALETTE['cloth_linen']=colors[1]
  raw=layout();fitted={n:(stature_point(a),stature_point(b),p) for n,(a,b,p) in raw.items()}
  rig=make_armature(name,fitted);body=Body(name);body.layout=raw;build(name,body)
  obj=body.finish(rig);fit_stature(obj);bake_surface(obj);animate(rig)
  obj.data.calc_loop_triangles();triangles=len(obj.data.loop_triangles)
  assert triangles<=24000,(name,triangles)
  export([rig,obj],os.path.join(a.out,name+'.glb'),surface_colors=True)
  print('INHABITANT',name,triangles,'triangles')
if __name__=='__main__':main()
