"""Authored river-order heroes. Sculpted ring surfaces, layered plates and tailoring.
All dimensions are Blender Z-up metres. Faces point -Y. Faces/fittings are authored
locally; hero_anatomy adapts the separately credited CC0 human body foundation.
"""
import math
import bmesh
from mathutils import Matrix, Vector
from charlib import m
from kitlib import box, transform, prism_arc


def loft(rings, sides=16, phase=0, smooth=True):
    """Rings: (z, half_width, half_depth, y_offset). Closed elliptical sculpt."""
    bm = bmesh.new()
    layers = []
    for z, rx, ry, cy in rings:
        layers.append([bm.verts.new((rx*math.cos(phase+math.tau*i/sides),
                                     cy+ry*math.sin(phase+math.tau*i/sides),z)) for i in range(sides)])
    for a,b in zip(layers,layers[1:]):
        for i in range(sides): bm.faces.new((a[i],a[(i+1)%sides],b[(i+1)%sides],b[i]))
    bm.faces.new(tuple(reversed(layers[0])))
    bm.faces.new(tuple(layers[-1]))
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    for f in bm.faces: f.smooth = smooth and len(f.verts)==4
    return bm


def ellipsoid(at, size, sides=16, rings=8, smooth=True):
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm,u_segments=sides,v_segments=rings,radius=1)
    for v in bm.verts: v.co=(at[0]+v.co.x*size[0],at[1]+v.co.y*size[1],at[2]+v.co.z*size[2])
    for f in bm.faces: f.smooth=smooth
    return bm


def rod(a,b,r, sides=8, end=None):
    a,b=Vector(a),Vector(b)
    bm=bmesh.new()
    bmesh.ops.create_cone(bm,cap_ends=True,segments=sides,radius1=r,radius2=end if end is not None else r,depth=(b-a).length)
    rotation=Vector((0,0,1)).rotation_difference(b-a)
    transform(bm, Matrix.Translation((a+b)/2)@rotation.to_matrix().to_4x4())
    for f in bm.faces: f.smooth=len(f.verts)==4
    return bm


def surface(rows, depth=.006):
    """Curved plate/tailored panel, rows of explicit 3D points, with thickness."""
    bm=bmesh.new()
    grids=[]
    # Thickness follows the local surface normal, including horizontal armour.
    # A fixed Y offset collapses shoulder shells into overlapping coplanar sheets.
    for offset in [0,depth]:
        grid=[]
        for j,row in enumerate(rows):
            layer=[]
            for i,point in enumerate(row):
                along=Vector(row[min(i+1,len(row)-1)])-Vector(row[max(0,i-1)])
                across=Vector(rows[min(j+1,len(rows)-1)][i])-Vector(rows[max(0,j-1)][i])
                normal=along.cross(across).normalized()
                layer.append(bm.verts.new(Vector(point)-normal*offset))
            grid.append(layer)
        grids.append(grid)
    for grid in grids:
        for j in range(len(grid)-1):
            for i in range(len(grid[0])-1):
                f=bm.faces.new((grid[j][i],grid[j][i+1],grid[j+1][i+1],grid[j+1][i]))
                f.smooth=True
    for side in [0,-1]:
        for j in range(len(rows)-1): bm.faces.new((grids[0][j][side],grids[1][j][side],grids[1][j+1][side],grids[0][j+1][side]))
    for j in [0,-1]:
        for i in range(len(rows[0])-1): bm.faces.new((grids[0][j][i],grids[1][j][i],grids[1][j][i+1],grids[0][j][i+1]))
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    return bm


def leaf(a,b,width, depth=.012):
    a,b=Vector(a),Vector(b)
    d=b-a
    across=Vector((d.z,0,-d.x)).normalized()*width
    mid=a+d*.5+Vector((0,-depth,0))
    bm=bmesh.new()
    verts=[bm.verts.new(v) for v in [a,mid+across,b,mid-across,mid+Vector((0,-depth,0))]]
    for tri in [(0,1,4),(1,2,4),(2,3,4),(3,0,4)]: bm.faces.new([verts[i] for i in tri])
    return bm


def ring(at, radius, thickness, bone, body, material, plane="XY"):
    body.add(prism_arc(radius,thickness,.015,0,math.tau,20,center=at,plane=plane),material,bone)


def sculpt_head(hooded=False):
    """Authored chin/jaw/cheek/socket planes; a rounded cranium behind the face.
    The Warden has a broad jaw; the Weaver tapers beneath pronounced cheekbones.
    """
    profile=[(1.050,.044,.066,.006),(1.068,.057,.080,.008),
             (1.092,.087,.086,.012),(1.120,.088,.085,.012),
             (1.148,.090,.082,.013),(1.180,.098,.089,.014),
             (1.205,.095,.080,.015),(1.231,.092,.092,.016),
             (1.255,.090,.086,.017),(1.286,.064,.064,.020),
             (1.305,.018,.023,.022)]
    bm=bmesh.new()
    rows=[]
    sides=20
    for row,(z,rx,ry,cy) in enumerate(profile):
        if hooded and row<=4: rx*=.88 if row<=2 else .94
        vertices=[]
        for i in range(sides):
            angle=math.tau*i/sides
            u=math.cos(angle)
            x=rx*u
            if math.sin(angle)<0:
                # Broad facial planes wrap into a firmer jaw corner instead of an ellipse.
                exponent=2.0 if z>=1.245 else (3.0 if z<1.13 else 2.6)
                front=math.sqrt(max(0,1-abs(u)**exponent))
                y=cy-ry*front
                socket=.006*math.exp(-((abs(x)-.037)/.019)**2-((z-1.205)/.017)**2)
                cheek=.004*math.exp(-((abs(x)-.061)/.024)**2-((z-1.18)/.019)**2)
                y+=socket-cheek
            else:
                y=cy+ry*math.sin(angle)
            vertices.append(bm.verts.new((x,y,z)))
        rows.append(vertices)
    for j in range(len(rows)-1):
        for i in range(sides):
            f=bm.faces.new((rows[j][i],rows[j][(i+1)%sides],rows[j+1][(i+1)%sides],rows[j+1][i]))
            f.smooth=True
    bm.faces.new(tuple(reversed(rows[0])))
    bm.faces.new(tuple(rows[-1]))
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    return bm


def face(body, hooded=False):
    add=body.add
    bone="head"
    add(sculpt_head(hooded),m("skin"),bone)
    # A bridge, tip and alar planes replace the oval/button nose.
    nose=[]
    narrow=.90 if hooded else 1.0
    for z,width,edge,bridge in [(1.146,.013,-.082,-.098),(1.160,.019,-.086,-.108),
                                (1.186,.011,-.078,-.103),(1.216,.010,-.069,-.085)]:
        nose.append([(-width*narrow,edge,z),(0,bridge,z),(width*narrow,edge,z)])
    add(surface(nose,.007),m("skin"),bone)
    for side in [-1,1]:
        add(ellipsoid((side*.011*narrow,-.094,1.151),(.003,.002,.002),8,4),m("skin_shadow"),bone)
    # Cupid's bow and a shallow lower lip add volume without a dark drawn-on stripe.
    upper=[[(x,-.078,1.116+(0.002 if abs(x)==.012 else 0)) for x in [-.024,-.012,0,.012,.024]],
           [(x,-.085 if abs(x)<.020 else -.077,1.111) for x in [-.024,-.012,0,.012,.024]]]
    lower=[[(x,-.085 if abs(x)<.020 else -.077,1.110) for x in [-.024,-.012,0,.012,.024]],
           [(x,-.080,1.105+(0.003 if abs(x)>.02 else 0)) for x in [-.024,-.012,0,.012,.024]]]
    add(surface(upper,.002),m("skin_shadow"),bone)
    add(surface(lower,.002),m("skin"),bone)
    for side in [-1,1]:
        add(rod((0,-.086,1.110),(side*.022,-.078,1.111),.001,6),m("skin_shadow"),bone)
    for side in [-1,1]:
        add(ellipsoid((side*.096,.012,1.167),(.015,.016,.034),12,8),m("skin"),bone)
        add(ellipsoid((side*.037,-.069,1.207),(.019,.006,.009),12,6),m("skin_shadow"),bone)
        add(ellipsoid((side*.037,-.075,1.207),(.016,.003,.006),12,6),m("eye_white"),bone)
        add(ellipsoid((side*.037,-.079,1.207),(.0055,.002,.006),10,6),m("iris"),bone)
        add(ellipsoid((side*.037,-.081,1.207),(.0028,.0015,.0045),8,4),m("ink"),bone)
        add(ellipsoid((side*.034,-.083,1.211),(.002,.001,.002),8,4),m("eye_white"),bone)
        add(rod((side*.019,-.081,1.224),(side*.038,-.079,1.228),.0035,6),m("hair"),bone)
        add(rod((side*.038,-.079,1.228),(side*.062,-.071,1.224),.003,6),m("hair"),bone)
        add(rod((side*.018,-.072,1.212),(side*.055,-.063,1.211),.002),m("ink"),bone)
    # Swept hair cap and distinct temple strands rather than a cube helmet.
    if not hooded:
        hair=ellipsoid((0,.021,1.196),(.105,.094,.129),24,16)
        exposed=[f for f in hair.faces if f.calc_center_median().y<.007 and f.calc_center_median().z<1.258]
        bmesh.ops.delete(hair,geom=exposed,context='FACES')
        add(hair,m("hair"),bone)
        for side in [-1,1]:
            for i in range(3):
                add(rod((side*(.083+i*.008),-.015,1.26),(side*(.093+i*.003),-.01+i*.012,1.12-i*.01),.008),m("hair"),bone)
        # Bronze diadem follows the brow; upward reed fins establish a signature silhouette.
        add(prism_arc(.101,.006,.020,math.pi,math.tau,16,center=(0,.01,1.245),plane="XY"),m("metal_gold"),bone)
        add(leaf((0,-.082,1.24),(0,-.07,1.355),.020,.005),m("metal_gold"),bone)
        for side in [-1,1]:
            add(leaf((side*.084,-.01,1.245),(side*.108,.012,1.32),.019),m("porcelain"),bone)
    else:
        # Closed rear cowl, open at the face; the head never shows through behind.
        cowl=ellipsoid((0,.044,1.205),(.149,.126,.172),24,16)
        exposed=[f for f in cowl.faces if f.calc_center_median().y<.022]
        bmesh.ops.delete(cowl,geom=exposed,context='FACES')
        add(cowl,m("cloth_midnight"),bone)
        # Open hood: curved front/back bands leave a real recessed face visible.
        rows=[]
        for j in range(5):
            y=-.075+j*.051
            row=[]
            for i in range(17):
                t=math.pi*i/16
                row.append((.158*math.cos(t),y,1.11+.252*math.sin(t)-j*.010))
            rows.append(row)
        add(surface(rows,.012),m("cloth_midnight"),bone)
        for side in [-1,1]:
            wrap=[[(side*.075,-.041,1.105),(side*.13,-.028,1.10),(side*.159,.04,1.09)],
                  [(side*.084,-.033,1.177),(side*.14,-.027,1.178),(side*.154,.06,1.15)],
                  [(side*.107,-.02,1.25),(side*.149,-.012,1.257),(side*.153,.058,1.237)]]
            add(surface(wrap,.005),m("cloth_teal"),bone)
        for i in range(16):
            a,b=rows[0][i],rows[0][i+1]
            add(rod(a,b,.009),m("metal_gold"),bone)
        add(leaf((0,-.089,1.34),(0,-.10,1.47),.026),m("metal_gold"),bone)
        for side in [-1,1]:
            add(leaf((side*.081,-.039,1.17),(side*.129,-.038,1.28),.016),m("porcelain"),bone)
            add(rod((side*.135,-.06,1.16),(side*.112,-.055,1.07),.006),m("metal_gold"),bone)


def eased(a,b,value):
    t=max(0,min(1,(value-a)/(b-a)))
    return t*t*(3-2*t)


def torso_weights(point):
    hips=1-eased(.60,.75,point.z)
    chest=eased(.80,.94,point.z)
    return {"hips":hips,"spine":1-hips-chest,"chest":chest}


def arm_weights(side):
    suffix=".L" if side==1 else ".R"
    def weights(point):
        fore=1-eased(.675,.79,point.z)
        chest=eased(.92,1.015,point.z)*.30
        return {"upper_arm"+suffix:(1-fore)*(1-chest),"forearm"+suffix:fore*(1-chest),"chest":chest}
    return weights


def leg_weights(side):
    suffix=".L" if side==1 else ".R"
    def weights(point):
        shin=1-eased(.265,.365,point.z)
        hips=eased(.48,.61,point.z)*.35
        return {"thigh"+suffix:(1-shin)*(1-hips),"shin"+suffix:shin*(1-hips),"hips":hips}
    return weights


def cloth_weights(point):
    # The lower garment follows a little leg motion; its waist remains on the hips.
    suffix=".L" if point.x>=0 else ".R"
    follow=(1-eased(.28,.63,point.z))*.18
    return {"hips":1-follow,"thigh"+suffix:follow}


def body_base(body, sx, weaver=False):
    from hero_anatomy import build_foundation
    build_foundation(body,sx,weaver)


def build_warden(body):
    add=body.add
    body_base(body,.29)
    face(body)
    # Sculpted breastplate: convex contour, waist taper and readable layered edges.
    rows=[[(x,-.128-curve,z) for x,curve in [(-w,0),(-w*.5,.027),(0,.045),(w*.5,.027),(w,0)]] for z,w in [(.80,.14),(.85,.17),(.94,.21),(1.0,.16)]]
    add(surface(rows,.025),m("porcelain"),"chest")
    for edge in [0,-1]:
        for j in range(len(rows)-1): add(rod(rows[j][edge],rows[j+1][edge],.003),m("metal_gold"),"chest")
    for j in range(len(rows[-1])-1): add(rod(rows[-1][j],rows[-1][j+1],.003),m("metal_gold"),"chest")
    for side in [-1,1]:
        for i in range(3):
            a=(side*(.02+i*.018),-.178,.84+i*.034)
            b=(side*(.139+i*.014),-.154,.9+i*.027)
            add(rod(a,b,.006),m("metal_gold"),"chest")
        # Shaped shoulder shells: a high central ridge, flared tip and layered lower lip.
        up="upper_arm.L" if side==1 else "upper_arm.R"
        for layer in range(2):
            rows=[]
            for j in range(5):
                t=j/4
                x=side*(.173+.20*t)
                width=.095+.035*math.sin(t*math.pi)
                z=1.025-.086*t-layer*.033
                rows.append([(x,width*(k/6*2-1),z-.030*(k/6*2-1)**2-.017*math.sin(t*math.pi)) for k in range(7)])
            add(surface(rows,.008),m("porcelain" if layer==0 else "metal_bronze"),up)
            if layer==0:
                for j in range(4):
                    for edge in [0,-1]: add(rod(rows[j][edge],rows[j+1][edge],.003,6),m("metal_gold"),up)
                for k in range(6): add(rod(rows[-1][k],rows[-1][k+1],.003,6),m("metal_gold"),up)
                add(leaf((side*.22,-.096,1.01),(side*.325,-.098,.968),.018,.005),m("metal_gold"),up)
        fore="forearm.L" if side==1 else "forearm.R"
        rows=[]
        for j in range(5):
            t=j/4
            z=.55+.155*t
            width=.042+.014*math.sin(t*math.pi)
            rows.append([(side*.29+width*(k/4*2-1),-.043-.032*math.sqrt(max(0,1-(k/4*2-1)**2)),z-.015*abs(k/4*2-1)) for k in range(5)])
        add(surface(rows,.008),m("porcelain"),fore)
        for edge in [0,-1]:
            for j in range(4): add(rod(rows[j][edge],rows[j+1][edge],.003,6),m("metal_gold"),fore)
        add(leaf((side*.29,-.087,.58),(side*.29,-.081,.70),.013,.005),m("metal_gold"),fore)
        for z in [.55,.71]: ring((side*.29,0,z),.056,.007,fore,body,m("metal_bronze"))
        shin="shin.L" if side==1 else "shin.R"
        add(ellipsoid((side*.089,-.060,.227),(.057,.031,.080),16,8),m("porcelain"),shin)
        add(leaf((side*.089,-.096,.164),(side*.089,-.090,.298),.024),m("metal_gold"),shin)
        # Three separate hip tassets articulate with the leg instead of a solid cube.
        thigh="thigh.L" if side==1 else "thigh.R"
        for i in range(3):
            x=side*(.08+i*.065)
            add(surface([[(x-.035,-.118,.634),(x,-.134,.644),(x+.035,-.118,.634)],[(x-.035,-.114,.48-i*.012),(x,-.134,.457-i*.012),(x+.035,-.114,.48-i*.012)]],.009),m("porcelain" if i!=1 else "metal_bronze"),thigh)
    # Long embroidered split tabard, independent of replaceable back equipment.
    for side in [-1,1]:
        rows=[]
        for j in range(5):
            z=.63-j*.09
            rows.append([(side*.008,-.134,z),(side*.082,-.155-j*.008-.008*math.sin(j*1.4),z),(side*.148,-.135,z-.024)])
        add(surface(rows,.006),m("cloth_indigo"),cloth_weights)
        add(rod(rows[0][2],rows[-1][2],.005),m("metal_gold"),cloth_weights)
        add(leaf((side*.074,-.197,.35),(side*.074,-.185,.53),.032,.004),m("metal_gold"),cloth_weights)
        for i in range(4):
            z=.32+i*.057
            add(leaf((side*.115,-.167,z),(side*.133,-.162,z+.033),.006,.002),m("cloth_linen"),cloth_weights)


def build_weaver(body):
    add=body.add
    body_base(body,.245,True)
    face(body,True)
    # Eight curved petal panels create a flowing robe silhouette with a scalloped hem.
    for sector in range(8):
        phase=math.tau*sector/8
        rows=[]
        for j in range(7):
            t=j/6
            z=.68-.53*t
            radius=.148+.14*t
            row=[]
            for k in range(5):
                angle=phase+(k/4-.5)*.81
                fold=.015*math.cos((k/4-.5)*math.tau)
                row.append(((radius+fold)*math.cos(angle),(radius*.76+fold)*math.sin(angle),z-.037*math.sin(k/4*math.pi)*t))
            rows.append(row)
        add(surface(rows,.005),m("cloth_teal" if sector%2==0 else "cloth_midnight"),cloth_weights)
        for j in range(6): add(rod(rows[j][0],rows[j+1][0],.004),m("metal_gold"),cloth_weights)
        if sector in [4,5,6]:
            add(leaf(rows[-2][2],rows[2][2],.027,.004),m("metal_gold"),cloth_weights)
            for k in range(4): add(rod(rows[-1][k],rows[-1][k+1],.003,6),m("cloth_linen"),cloth_weights)
    # High layered collar, porcelain breast crescent and asymmetric shoulder leaves.
    add(loft([(1.0,.109,.084,0),(1.04,.14,.10,.017),(1.064,.13,.10,.028)],20),m("cloth_midnight"),"chest")
    add(prism_arc(.091,.017,.018,math.pi,math.tau,20,center=(0,-.119,.975),plane="XZ"),m("porcelain"),"chest")
    for side in [-1,1]:
        for i in range(3):
            add(leaf((side*.15,-.055,.94-i*.027),(side*(.28+i*.022),-.018,1.078-i*.039),.027,.007),m("porcelain" if i!=1 else "metal_gold"),"chest")
        up="upper_arm.L" if side==1 else "upper_arm.R"
        fore=up.replace("upper_arm","forearm")
        for z in [.56,.69]: ring((side*.245,0,z),.061,.008,fore,body,m("metal_gold"))
        add(leaf((side*.245,-.064,.56),(side*.245,-.055,.71),.029),m("porcelain"),fore)
    # Draped sash with separated folds wraps the upper torso; not a baked gear cloak.
    sash=[]
    for j in range(8):
        t=j/7
        sash.append([(-.17+.315*t,-.13-.020*math.sin(t*math.pi)-.004*math.cos(k*math.pi),.858+.12*t+.072*k/4) for k in range(5)])
    add(surface(sash,.008),m("cloth_linen"),"chest")
    for side in [0,-1]:
        for j in range(7): add(rod(sash[j][side],sash[j+1][side],.003),m("metal_gold"),"chest")
    add(leaf((.14,-.11,.86),(.17,-.13,.57),.033),m("cloth_linen"),"chest")
