"""Offline surface shading: ray-traced crevice occlusion carried as vertex colour.
No runtime AO textures, screen-space effect or extra render passes are required.
"""
import math
from mathutils import Vector
from mathutils.bvhtree import BVHTree


def bake_surface(obj):
    mesh=obj.data
    mesh.update()
    coords=[v.co.copy() for v in mesh.vertices]
    tree=BVHTree.FromPolygons(coords,[tuple(p.vertices) for p in mesh.polygons],all_triangles=False)
    colours=mesh.color_attributes.new(name="SurfaceCraft",type="FLOAT_COLOR",domain="CORNER")
    mesh.color_attributes.active_color=colours
    directions=[]
    for i in range(16):
        z=math.sqrt((i+.5)/16)
        r=math.sqrt(1-z*z)
        phi=i*2.39996323
        directions.append(Vector((r*math.cos(phi),r*math.sin(phi),z)))
    cache={}
    skin_loops={loop for polygon in mesh.polygons if mesh.materials[polygon.material_index].name=="skin" for loop in polygon.loop_indices}
    for loop in mesh.loops:
        p=coords[loop.vertex_index]
        n=mesh.corner_normals[loop.index].vector.normalized()
        key=tuple(round(v,5) for v in (*p,*n))
        if key not in cache:
            tangent=n.cross(Vector((0,0,1)))
            if tangent.length<.01: tangent=n.cross(Vector((0,1,0)))
            tangent.normalize()
            bitangent=n.cross(tangent)
            occlusion=0
            for sample in directions:
                d=tangent*sample.x+bitangent*sample.y+n*sample.z
                hit,_,_,distance=tree.ray_cast(p+n*.0015,d,.075)
                if hit is not None: occlusion+=(1-distance/.075)*sample.z
            ao=max(.58,1-occlusion*.072)
            if loop.index in skin_loops: ao=1-(1-ao)*.82
            # A subtle authored top-to-bottom tonal gradient reinforces volume.
            grad=.91+.09*min(1,max(0,p.z/1.35))
            shade=ao*grad
            cache[key]=(shade*.99,shade, min(1,shade*1.015),1)
        colours.data[loop.index].color=cache[key]
    print("SURFACE baked",obj.name,len(cache),"surface samples")


# Keep in sync with GearVisuals' authored-geometry fitting constants.
LOWER_BODY_SCALE=1.17
WAIST_HEIGHT=.68
TORSO_SCALE=1.22
HEAD_HEIGHT=1.05
HEAD_SCALE=.82
UPPER_WIDTH_SCALE=.82

def stature_height(z):
    if z<WAIST_HEIGHT: return z*LOWER_BODY_SCALE
    if z<HEAD_HEIGHT: return WAIST_HEIGHT*LOWER_BODY_SCALE+(z-WAIST_HEIGHT)*TORSO_SCALE
    return WAIST_HEIGHT*LOWER_BODY_SCALE+(HEAD_HEIGHT-WAIST_HEIGHT)*TORSO_SCALE+(z-HEAD_HEIGHT)*HEAD_SCALE


def stature_point(point):
    p=Vector(point)
    # Adult cranial proportions; taper the neck transition smoothly, never the shoulders.
    head=max(0,min(1,(p.z-1.035)/.04))
    upper=max(0,min(1,(p.z-.60)/.18))
    p.x*=1-upper*(1-UPPER_WIDTH_SCALE)
    p.y*=1-head*(1-HEAD_SCALE)
    p.z=stature_height(p.z)
    return p


def fit_stature(obj):
    for vertex in obj.data.vertices: vertex.co=stature_point(vertex.co)
