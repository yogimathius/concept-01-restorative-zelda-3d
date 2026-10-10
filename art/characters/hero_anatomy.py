"""Adult anatomical foundation and articulated hands/feet for both disciplines.

The MakeHuman CC0 body is adapted to the river-order rig and canonical metres.
The sculpted anatomical topology supplies the torso, limbs and five-finger hands.
Provenance is recorded in art/source/makehuman; armour and boot fittings are local.
"""
import math
import bpy
import bmesh
from mathutils import Matrix
from charlib import m


def smoothstep(a,b,v):
    t=max(0,min(1,(v-a)/(b-a)))
    return t*t*(3-2*t)


def skeleton(sx, core):
    layout=dict(core)
    layout['neck']=((0,0,1.0),(0,0,1.065),'chest')
    a,b,_=layout['head'];layout['head']=(a,b,'neck')
    for side,sign in [('L',1),('R',-1)]:
        suffix='.'+side
        layout['clavicle'+suffix]=((sign*.065,0,.96),(sign*sx,0,.97),'chest')
        a,b,_=layout['upper_arm'+suffix];layout['upper_arm'+suffix]=(a,b,'clavicle'+suffix)
        layout['arm_twist'+suffix]=((sign*sx,0,.86),(sign*sx,0,.76),'upper_arm'+suffix)
        layout['forearm_twist'+suffix]=((sign*sx,0,.64),(sign*sx,0,.54),'forearm'+suffix)
        layout['hand'+suffix]=((sign*sx,0,.535),(sign*sx,-.018,.484),'forearm'+suffix)
        for i,name in enumerate(['index','middle','ring','little']):
            x=sign*sx+(i-1.5)*.017
            length=[.052,.059,.055,.043][i]
            a=(x,-.025,.489);b=(x,-.038,.489-length*.55);c=(x,-.021,.489-length)
            layout[name+'1'+suffix]=(a,b,'hand'+suffix)
            layout[name+'2'+suffix]=(b,c,name+'1'+suffix)
        a=(sign*sx-sign*.028,-.010,.515);b=(sign*sx-sign*.043,-.041,.487);c=(sign*sx-sign*.028,-.039,.468)
        layout['thumb1'+suffix]=(a,b,'hand'+suffix)
        layout['thumb2'+suffix]=(b,c,'thumb1'+suffix)
        a,_,parent=layout['shin'+suffix];layout['shin'+suffix]=(a,(sign*.089,0,.11),parent)
        layout['foot'+suffix]=((sign*.089,0,.11),(sign*.089,-.116,.045),'shin'+suffix)
    return layout


def continuous_foundation(body,sx,weaver):
    from pathlib import Path
    from mathutils import Vector
    from mathutils.kdtree import KDTree
    source=Path(__file__).resolve().parents[1]/'source'/'makehuman'/'base.obj'
    positions=[];faces=[];groups={};active=''
    for line in source.read_text().splitlines():
        if line.startswith('v '): positions.append(Vector(tuple(map(float,line.split()[1:4]))))
        elif line.startswith('g '): active=line[2:];groups[active]=set()
        elif line.startswith('f '):
            ids=[int(v.split('/')[0])-1 for v in line.split()[1:]]
            groups[active].update(ids)
            if active=='body':faces.append(ids)
    def joint(name):
        ids=groups['joint-'+name]
        return sum((positions[i] for i in ids),Vector())/len(ids)
    ground=min(positions[i].y for i in groups['body'])
    anchors=[(ground,0),(-7.4478,.11),(-3.6948,.30),(.7268,.58),
             (1.1868,.70),(2.7966,.84),(4.3285,.94),(5.8902,1.035),(6.9749,1.15)]
    def height(y):
        for (a,za),(b,zb) in zip(anchors,anchors[1:]):
            if y<=b:return za+(zb-za)*(y-a)/(b-a)
        return 1.15+(y-6.9749)*.08
    def canonical(p):return Vector((p.x*.10,-p.z*.075,height(p.y)))
    source_bones={'hips':('pelvis','spine-4'),'spine':('spine-4','spine-2'),
                  'chest':('spine-2','neck'),'neck':('neck','head')}
    for side in ['L','R']:
        prefix=side.lower()+'-';suffix='.'+side
        source_bones.update({'clavicle'+suffix:('spine-1',prefix+'shoulder'),
            'upper_arm'+suffix:(prefix+'shoulder',prefix+'elbow'),
            'forearm'+suffix:(prefix+'elbow',prefix+'hand'),
            'hand'+suffix:(prefix+'hand',prefix+'finger-3-1'),
            'thigh'+suffix:(prefix+'upper-leg',prefix+'knee'),
            'shin'+suffix:(prefix+'knee',prefix+'ankle'),
            'foot'+suffix:(prefix+'ankle',prefix+'foot-1')})
        for digit,name in [(1,'thumb'),(2,'index'),(3,'middle'),(4,'ring'),(5,'little')]:
            source_bones[name+'1'+suffix]=(prefix+f'finger-{digit}-1',prefix+f'finger-{digit}-3')
            source_bones[name+'2'+suffix]=(prefix+f'finger-{digit}-3',prefix+f'finger-{digit}-4')
    segments=[]
    for name,(a,b) in source_bones.items():
        srca,srcb=canonical(joint(a)),canonical(joint(b))
        targeta,targetb,_=body.layout[name];targeta,targetb=Vector(targeta),Vector(targetb)
        vector=srcb-srca;targetvector=targetb-targeta
        rotation=vector.rotation_difference(targetvector)
        segments.append((name,srca,vector,targeta,rotation,targetvector.length/vector.length))
    transformed={};skin={}
    def distance(p,a,d):
        t=max(0,min(1,(p-a).dot(d)/d.length_squared))
        return (p-a-d*t).length
    for i in groups['body']:
        p=canonical(positions[i])
        ranked=sorted(((distance(p,a,d),name,a,d,target,rot,scale)
                       for name,a,d,target,rot,scale in segments),key=lambda item:item[0])[:4]
        weights=[1/max(.009,row[0])**5 for row in ranked];total=sum(weights)
        result=Vector();binding={}
        for row,w in zip(ranked,weights):
            _,name,a,d,target,rotation,scale=row
            w/=total
            along=d.normalized();delta=p-a
            mapped=rotation@(delta+along*delta.dot(along)*(scale-1))+target
            result+=mapped*w;binding[name]=w
        # Modest individual tailoring preserves the base mesh anatomy.
        if weaver:result.x*=.96
        for side in ['L','R']:
            for base,twist,center,spread in [('upper_arm','arm_twist',.83,.08),('forearm','forearm_twist',.62,.055)]:
                name=base+'.'+side
                if name in binding:
                    share=.32*math.exp(-((result.z-center)/spread)**2)
                    binding[twist+'.'+side]=binding[name]*share
                    binding[name]*=1-share
        binding=dict(sorted(binding.items(),key=lambda item:item[1],reverse=True)[:4])
        total=sum(binding.values());binding={name:w/total for name,w in binding.items()}
        transformed[i]=result;skin[i]=binding
    bm=bmesh.new();verts={}
    # Keep the existing authored faces/headgear, using the human mesh from neck down.
    for ids in faces:
        if max(positions[i].y for i in ids)>6.08:continue
        if min(positions[i].y for i in ids)<-7.15:continue
        for i in ids:
            if i not in verts:verts[i]=bm.verts.new(transformed[i])
        bm.faces.new([verts[i] for i in ids])
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    for f in bm.faces:f.smooth=True
    # Cloth sits outside the anatomical surface; gloves use the actual human hand topology.
    for v in bm.verts:
        p=v.co
        if p.z<1.02:v.co+=v.normal*.004
        if .65<p.z<.79 and abs(p.x)<.19:
            v.co.y+=.004*math.sin((p.z-abs(p.x)*.22)*125)*math.exp(-((p.z-.68)/.07)**2)
    original=[(v.co.copy(),skin[i]) for i,v in verts.items()]
    kd=KDTree(len(original))
    for i,(point,_) in enumerate(original):kd.insert(point,i)
    kd.balance()
    mesh=bpy.data.meshes.new('human-anatomy');bm.to_mesh(mesh);bm.free()
    obj=bpy.data.objects.new('human-anatomy',mesh);bpy.context.collection.objects.link(obj)
    for o in bpy.context.selected_objects:o.select_set(False)
    obj.select_set(True);bpy.context.view_layer.objects.active=obj
    reduce=obj.modifiers.new('mobile human surface','DECIMATE');reduce.ratio=.68
    bpy.ops.object.modifier_apply(modifier=reduce.name)
    bm=bmesh.new();bm.from_mesh(obj.data)
    oldmesh=obj.data;bpy.data.objects.remove(obj,do_unlink=True);bpy.data.meshes.remove(oldmesh)
    def weights(point):
        _,index,_=kd.find(point)
        return original[index][1]
    body.add(bm,m('cloth_teal' if weaver else 'cloth_indigo'),weights)
    fitted=body.parts[-1].data;fitted.update()
    fitted.materials.append(m('cloth_midnight'));fitted.materials.append(m('skin'));fitted.materials.append(m('leather'))
    for polygon in fitted.polygons:
        c=polygon.center
        if abs(c.x)>.22 and c.z<.549:polygon.material_index=3
        elif c.z<.61:polygon.material_index=1
        elif c.z>1.025 and abs(c.x)<.075:polygon.material_index=2
    fitted.update()
    print('ANATOMY adapted MakeHuman core asset',len(fitted.polygons),'faces')


def boot_fittings(body,sx):
    from hero_craft import loft, rod, transform, ellipsoid
    add=body.add
    for sign,side in [(1,'L'),(-1,'R')]:
        suffix='.'+side
        # Ankle shaft bends with the shin; vamp/toe/sole articulate at the ankle.
        shaft=loft([(.115,.039,.049,.002),(.158,.041,.051,.009),(.215,.043,.054,.010),(.272,.048,.055,0)],16)
        transform(shaft,Matrix.Translation((sign*.089,0,0)));add(shaft,m('leather'),'shin'+suffix)
        foot=loft([(.014,.050,.092,-.040),(.036,.053,.094,-.041),(.061,.052,.091,-.039),
                   (.083,.046,.075,-.024),(.110,.039,.050,0),(.137,.038,.048,.004)],20)
        transform(foot,Matrix.Translation((sign*.089,0,0)));add(foot,m('leather'),'foot'+suffix)
        sole=loft([(.006,.053,.096,-.04),(.028,.054,.096,-.04)],20)
        transform(sole,Matrix.Translation((sign*.089,0,0)));add(sole,m('leather_dark'),'foot'+suffix)
        for z in [.167,.214]:
            add(rod((sign*.089-.036,-.046,z),(sign*.089+.036,-.046,z),.004,8),m('leather_dark'),'shin'+suffix)
        add(ellipsoid((sign*.089+.025,-.047,.192),(.009,.004,.012),10,6),m('metal_bronze'),'shin'+suffix)


def build_foundation(body,sx,weaver=False):
    from hero_craft import loft, ring, ellipsoid, rod
    continuous_foundation(body,sx,weaver)
    boot_fittings(body,sx)
    # A tailored neckline masks the anatomical trim boundary and frames the neck.
    body.add(loft([(1.001,.066,.054,.010),(1.025,.057,.049,.010),(1.037,.053,.047,.011)],24),
             m('cloth_midnight'), 'neck')
    body.add(loft([(1.019,.045,.042,.009),(1.045,.043,.039,.010),(1.064,.043,.039,.011)],24),
             m('skin'), 'neck')
    body.add(loft([(.635,.169,.119,.009),(.673,.162,.116,.005)],24),m('leather'),'hips')
    ring((0,-.122,.658),.023,.005,'hips',body,m('metal_gold'),'XZ')
    body.add(ellipsoid((.169,.045,.601),(.039,.035,.057),16,8),m('leather'),'hips')
    body.add(rod((.143,.007,.634),(.198,.007,.634),.004,8),m('metal_gold'),'hips')


def bake_footwork(rig,action,last_frame):
    """Bake ankle IK and foot roll into a normal clip; no runtime IK or extra nodes."""
    from mathutils import Vector
    from hero_finish import stature_point
    rig.animation_data.action=action
    helpers=[];constraints=[]
    for sign,side in [(1,'L'),(-1,'R')]:
        target=bpy.data.objects.new('ankle-target.'+side,None)
        pole=bpy.data.objects.new('knee-pole.'+side,None)
        bpy.context.collection.objects.link(target);bpy.context.collection.objects.link(pole)
        pole.location=stature_point((sign*.089,-.7,.32))
        c=rig.pose.bones['shin.'+side].constraints.new('IK')
        c.target=target;c.pole_target=pole;c.chain_count=2;c.pole_angle=-math.pi/2
        helpers.extend([target,pole]);constraints.append(c)
    baked=[]
    for frame in range(last_frame+1):
        bpy.context.scene.frame_set(frame)
        for i,(sign,side) in enumerate([(1,'L'),(-1,'R')]):
            t=(frame/last_frame+i*.5)%1
            if t<.5:
                y=-.17+.34*t/.5;lift=0
            else:
                u=(t-.5)/.5;y=.17*math.cos(math.pi*u);lift=.075*math.sin(math.pi*u)
            helpers[i*2].location=stature_point((sign*.089,y,.11+lift))
        bpy.context.view_layer.update()
        values={}
        for side in ['L','R']:
            for name in ['thigh.','shin.']:
                pb=rig.pose.bones[name+side]
                # Matrix_basis includes the constraint result only after conversion from the posed matrix.
                matrix=pb.bone.convert_local_to_pose(pb.matrix,pb.bone.matrix_local,
                    parent_matrix=pb.parent.matrix,parent_matrix_local=pb.parent.bone.matrix_local,invert=True)
                values[pb.name]=matrix.to_euler('XYZ')
            foot=rig.pose.bones['foot.'+side]
            # Keep the sole close to level during support; lift the toe through swing.
            t=(frame/last_frame+(0 if side=='L' else .5))%1
            roll=math.radians(8*math.sin(math.tau*t))
            world=foot.bone.matrix_local.copy()
            world.translation=rig.pose.bones['shin.'+side].tail
            from mathutils import Matrix
            world=Matrix.Rotation(roll,4,'X')@world
            world.translation=rig.pose.bones['shin.'+side].tail
            local=foot.bone.convert_local_to_pose(world,foot.bone.matrix_local,
                parent_matrix=foot.parent.matrix,parent_matrix_local=foot.parent.bone.matrix_local,invert=True)
            values[foot.name]=local.to_euler('XYZ')
        baked.append(values)
    for c in constraints:
        for pb in rig.pose.bones:
            if c in list(pb.constraints):pb.constraints.remove(c);break
    for obj in helpers:bpy.data.objects.remove(obj,do_unlink=True)
    for frame,values in enumerate(baked):
        bpy.context.scene.frame_set(frame)
        for name,rotation in values.items():
            pb=rig.pose.bones[name];pb.rotation_euler=rotation;pb.keyframe_insert('rotation_euler',frame=frame)
