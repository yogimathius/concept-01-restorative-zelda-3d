"""Original offline waterway motif and habitat loops; stdlib, no external audio.
Run python3 art/audio/build_soundscape.py. Subtle layers at 22050Hz mono.
"""
import math, random, struct, wave
from pathlib import Path
root=Path(__file__).resolve().parents[2]/'assets'/'audio';root.mkdir(parents=True,exist_ok=True)
rate=22050;duration=24;n=duration*rate;rng=random.Random(39)
def save(name,samples):
 with wave.open(str(root/(name+'.wav')),'wb') as f:
  f.setnchannels(1);f.setsampwidth(2);f.setframerate(rate)
  f.writeframes(b''.join(struct.pack('<h',int(max(-1,min(1,v))*32767)) for v in samples))
# A three-note reed-bell phrase sits over two slowly voiced open fifths.
notes=[(0,293.665),(2,349.228),(4.5,440),(9,293.665),(11.5,261.626),(15,349.228),(18,440)]
def motif(t):
 value=0
 for start,hz in notes:
  u=t-start
  if 0<u<4.8:
   value+=(math.sin(math.tau*hz*u)+.25*math.sin(math.tau*hz*2.01*u))*math.exp(-u*1.05)*min(1,u/0.035)*.18
 fade=math.sin(math.pi*t/duration)**2
 value+=sum(math.sin(math.tau*hz*t) for hz in [146.8325,220,293.665])*fade*.022
 return value
save('motif',(motif(i/rate) for i in range(n)))
filtered=0;water=[]
for i in range(n):
 filtered=filtered*.94+(rng.random()*2-1)*.06
 t=i/rate
 water.append(filtered*.85+math.sin(t*math.tau*73)*.008)
# Smooth seam with a short circular crossfade; no periodic loud hiss/pop.
for i in range(512):
 t=i/512;water[i]=water[-512+i]*(1-t)+water[i]*t
save('water',water)
def birds(t):
 value=0
 for start in [3,3.4,8,12,12.25,18,20.5]:
  u=t-start
  if 0<u<.19:
   value+=math.sin(math.tau*(1900*u+1400*u*u))*math.sin(math.pi*u/.19)**2*.14
 return value
save('birds',(birds(i/rate) for i in range(n)))
print('Built original 24-second motif, water and bird loops')
