# Musique du bilan de saison, entièrement synthétisée (aucun échantillon externe).
import numpy as np, wave
SR=44100; BPM=120; beat=60/BPM; bars=32; N=int(SR*beat*4*bars)
t_all=np.arange(N)/SR
L=np.zeros(N); R=np.zeros(N)
rng=np.random.default_rng(7)
def place(sig, start, pan=0.0, gain=1.0):
    i=int(start*SR); j=min(N,i+len(sig)); s=sig[:j-i]*gain
    # bouclage parfait : ce qui dépasse revient au début
    L[i:j]+=s*(1-pan)/1.0*0.5*2/ (1+abs(pan)) ; R[i:j]+=s*(1+pan)*0.5*2/(1+abs(pan))
    if i+len(sig)>N:
        rest=sig[N-i:]*gain; k=len(rest)
        L[:k]+=rest*(1-pan)/(1+abs(pan)); R[:k]+=rest*(1+pan)/(1+abs(pan))
def env(n, a=0.005, d=0.2, s=0.6, r=0.1, dur=None):
    t=np.arange(n)/SR; e=np.ones(n)
    ai=int(a*SR); e[:ai]=np.linspace(0,1,ai) if ai>0 else 1
    di=int(d*SR); e[ai:ai+di]=np.linspace(1,s,len(e[ai:ai+di]))
    e[ai+di:]=s
    ri=int(r*SR); 
    if ri>0: e[-ri:]*=np.linspace(1,0,ri)
    return e
def midi(m): return 440*2**((m-69)/12)
def kick():
    n=int(.35*SR); t=np.arange(n)/SR
    f=50+120*np.exp(-t*35); ph=2*np.pi*np.cumsum(f)/SR
    return np.sin(ph)*np.exp(-t*9)*1.0
def clap():
    n=int(.25*SR); t=np.arange(n)/SR
    no=rng.standard_normal(n)
    # filtre passe-bande grossier
    no=np.convolve(no,np.ones(4)/4,'same')-np.convolve(no,np.ones(40)/40,'same')
    e=np.exp(-t*22)
    for dt in (0.01,0.02): e+= np.exp(-np.maximum(t-dt,0)*60)*(t>=dt)*0.5
    return no*e*0.5
def hat(open_=False):
    n=int((.18 if open_ else .05)*SR); t=np.arange(n)/SR
    no=rng.standard_normal(n); no=no-np.convolve(no,np.ones(6)/6,'same')
    return no*np.exp(-t*(18 if open_ else 70))*0.18
def saw(f,n,detune=0.0):
    t=np.arange(n)/SR; out=0
    for d in (-detune,0,detune):
        ph=(t*f*(1+d))%1; out=out+(2*ph-1)
    return out/3
def lowpass(x,a):
    y=np.zeros_like(x); acc=0
    for i in range(len(x)): acc+=a*(x[i]-acc); y[i]=acc
    return y
# Progression C - G - Am - F (2 temps... une mesure chacune)
prog=[(48,[60,64,67]),(43,[59,62,67]),(45,[57,60,64]),(41,[57,60,65])]
for bar in range(bars):
    t0=bar*4*beat
    root,ch=prog[bar%4]
    # batterie
    for b in range(4):
        if not (24<=bar<28): place(kick(), t0+b*beat, 0, 0.9)
        if b in (1,3): place(clap(), t0+b*beat, 0.05, 0.8)
        for h in range(2):
            place(hat(open_=(h==1 and b==3)), t0+b*beat+h*beat/2, 0.3 if h else -0.3, 1.0)
    # basse en croches (octave)
    for k in range(8):
        f=midi(root+(12 if k%2 else 0)); n=int(beat/2*SR*0.9)
        s=lowpass(saw(f,n),0.08)*env(n,0.003,0.1,0.7,0.03)
        place(s, t0+k*beat/2, 0, 0.55)
    # nappe d'accords, entrée après 4 mesures
    if bar>=2:
        n=int(4*beat*SR)
        pad=sum(saw(midi(m),n,0.004) for m in ch)/3
        pad=lowpass(pad,0.05)*env(n,0.3,0.5,0.8,0.4)
        place(pad, t0, 0, 0.4 if 24<=bar<28 else (0.32 if bar>=4 else 0.2))
    # mélodie simple sur les 8 dernières mesures
    if 12<=bar<24 or bar>=28:
        motif=[0,2,4,2, 4,7,4,2] if bar%2==0 else [4,5,7,5, 4,2,1,0]
        scale=[ch[0]+12, ch[1]+12, ch[2]+12]
        for k,step in enumerate(motif):
            m=[ch[0],ch[1],ch[2],ch[0]+12,ch[1]+12,ch[2]+12,ch[0]+24,ch[1]+24][step]+12
            n=int(beat/2*SR*0.85); tt=np.arange(n)/SR
            s=(np.sign(np.sin(2*np.pi*midi(m)*tt))*0.3+np.sin(2*np.pi*midi(m)*tt))*env(n,0.005,0.08,0.5,0.05)
            place(lowpass(s,0.25), t0+k*beat/2, -0.2 if k%2 else 0.2, 0.22)
mix=np.stack([L,R],1)
# compression douce + normalisation
mix=np.tanh(mix*1.2); mix/=np.max(np.abs(mix))*1.12
w=wave.open('wrapped.wav','wb'); w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR)
w.writeframes((mix*32767).astype('<i2').tobytes()); w.close()
print('ok', N/SR, 's')
