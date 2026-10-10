"""Signature river-order living arch: authored ceramic vessel, roots and willow canopy."""
import os, sys, math
import bpy, bmesh
HERE=os.path.dirname(os.path.abspath(__file__));sys.path.insert(0,HERE)
from charlib import setup_scene, m, export
from hero_craft import loft, rod, ellipsoid, leaf, transform
from mathutils import Matrix

def mesh(name,parts):
 objects=[]
 for bm,mat in parts:
  bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
  data=bpy.data.meshes.new(name);bm.to_mesh(data);bm.free();data.materials.append(mat)
  obj=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(obj);objects.append(obj)
 for obj in bpy.context.selected_objects:obj.select_set(False)
 for obj in objects:obj.select_set(True)
 bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join()
 result=bpy.context.object;result.name=name
 return result
setup_scene()
from kitlib import PALETTE
PALETTE.update({'porcelain':'#BBC3B0','root':'#796C57','leaf':'#598368','leaf_light':'#88AC77','wounded':'#665574','glass':'#64B7AC','silt':'#3C384A'})
models=[]
for restored in [False,True]:
 parts=[]
 def add(shape,color):parts.append((shape,m(color)))
 # Hollow ceramic bowl with carved fluted shell, stepped foot and bronze rim.
 shell=loft([(0,.78,.66,0),(.08,.79,.67,0),(.14,.66,.56,0),(.32,.68,.58,0),(.49,.82,.70,0),(.56,.84,.72,0)],32)
 add(shell,'porcelain' if restored else 'wounded')
 add(ellipsoid((0,0,.57),(.76,.65,.035),32,8),'glass' if restored else 'silt')
 for i in range(16):
  angle=math.tau*i/16
  add(rod((math.cos(angle)*.72,math.sin(angle)*.62,.22),(math.cos(angle)*.83,math.sin(angle)*.71,.53),.012,8),'metal_bronze')
 # Root trunks spiral up around the water channel.
 for side in [-1,1]:
  pts=[(side*.38,0,.47),(side*.30,.02,.9),(side*.34,.04,1.35),(side*.50,.04,1.70),(side*.77,.02,1.95)]
  for a,b,r in zip(pts,pts[1:],[.12,.1,.075,.05]):add(rod(a,b,r,12,end=r*.72),'root' if restored else 'wounded')
  for branch in range(4):
   tip=(side*(.72+branch*.14),-.12+branch*.11,1.92-branch*.1)
   add(rod(pts[-2],tip,.035,8,end=.009),'root' if restored else 'wounded')
   if restored:
    for k in range(5):
     start=(tip[0],tip[1],tip[2]-.18*k)
     end=(tip[0]+side*.10,tip[1]-.02,tip[2]-.18*k-.28)
     add(leaf(start,end,.07,.005),'leaf_light' if k%2 else 'leaf')
 # Central reed spine and split crest.
 add(rod((0,0,.55),(0,0,1.74),.09,16,end=.038),'root' if restored else 'wounded')
 for side in [-1,1]:
  add(rod((0,0,1.55),(side*.29,0,2.10),.025,8,end=.014),'metal_bronze')
  if restored:
   for i in range(7):
    z=.93+i*.14
    add(leaf((0,-.01,z),(side*(.24+math.sin(i)*.08),-.12,z+.14),.09,.012),'leaf')
 if not restored:
  for i in range(7):
   shape=ellipsoid((math.cos(i*2.4)*.62,math.sin(i*2.4)*.48,.59+i*.07),(.13,.10,.17),8,4)
   add(shape,'silt')
 models.append(mesh('grove_'+('restored' if restored else 'corrupted'),parts))
export(models,os.path.join(HERE,'../../assets/kit/homecoming_grove.glb'),animated=False)
print('GROVE',sum(len(o.data.polygons) for o in models),'faces')
