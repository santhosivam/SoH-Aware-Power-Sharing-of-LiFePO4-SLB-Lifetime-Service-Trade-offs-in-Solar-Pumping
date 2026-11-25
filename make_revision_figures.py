import csv
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

base=Path(__file__).resolve().parent
out=base/'figures';out.mkdir(exist_ok=True)
def font(size,bold=False):
    choices=(['C:/Windows/Fonts/arialbd.ttf','DejaVuSans-Bold.ttf'] if bold
             else ['C:/Windows/Fonts/arial.ttf','DejaVuSans.ttf'])
    for candidate in choices:
        try:return ImageFont.truetype(candidate,size)
        except OSError:pass
    return ImageFont.load_default(size=size)
def rows(path):
    with path.open(newline='',encoding='utf-8-sig') as f:return list(csv.DictReader(f))
def f(r,k):return float(r[k])
def text(d,xy,s,size=24,color='#17202a',bold=False):d.text(xy,s,font=font(size,bold),fill=color)

full={r['controller']:r for r in rows(base/'full_daily_summary.csv')}
conv={(int(r['daysPerYear']),int(r['strategy'])):r for r in rows(base/'model_copy'/'convergence_results.csv')}
img=Image.new('RGB',(1800,880),'white');d=ImageDraw.Draw(img)
text(d,(60,35),'Annual sampling: threshold and first-year service',36,bold=True)
colors={1:'#147d93',3:'#db6d32'}
for pane,(title,key,lo,hi,fmt) in enumerate([
    ('First module reaches SoH 0.65 (years)','eolYears',7,13,'{:.1f}'),
    ('Year-one unserved pump energy (kWh)','year1UnservedKWh',0,330,'{:.0f}')]):
    x0=105+pane*900;y0=150;w=700;h=570
    text(d,(x0,y0-55),title,26,bold=True)
    d.line((x0,y0,x0,y0+h,x0+w,y0+h),fill='#555555',width=3)
    for j in range(5):
        val=lo+(hi-lo)*j/4;yy=y0+h-int(h*j/4)
        d.line((x0,yy,x0+w,yy),fill='#e3e8ec',width=2)
        text(d,(x0-65,yy-12),fmt.format(val),21)
    for strategy,name in [(1,'ES'),(3,'SA')]:
        pts=[]
        for i,n in enumerate((37,73,365)):
            r=conv[n,strategy] if n<365 else full['ES' if strategy==1 else 'SA full']
            xx=x0+110+i*235;yy=y0+h-int((f(r,key)-lo)/(hi-lo)*h)
            pts.append((xx,yy));d.ellipse((xx-7,yy-7,xx+7,yy+7),fill=colors[strategy])
            text(d,(xx-19,yy-43),fmt.format(f(r,key)),20,color=colors[strategy],bold=True)
        d.line(pts,fill=colors[strategy],width=5)
    for i,n in enumerate((37,73,365)):
        text(d,(x0+82+i*235,y0+h+15),str(n),24)
    text(d,(x0+245,y0+h+63),'Simulated days/year',22)
text(d,(1480,35),'ES',23,colors[1],True);text(d,(1580,35),'SA',23,colors[3],True)
img.save(out/'convergence.png',dpi=(300,300))

es={r['scenario']:r for r in rows(base/'paired_es'/'paired_es_results.csv')}
sa={r['scenario']:r for r in rows(base/'robustness_copy'/'robustness_results.csv')}
sa.update({r['scenario']:r for r in rows(base/'stress_copy'/'robustness_fixed_min.csv')})
names=list(es);values=[f(sa[n],'eolYears')-f(es[n],'eolYears') for n in names]
maxval=5.0
img=Image.new('RGB',(1800,1210),'white');d=ImageDraw.Draw(img)
text(d,(55,30),'Paired lifetime benefit of health-aware sharing',36,bold=True)
text(d,(55,83),'SA minus ES, identical weather, initial health, aging coefficients, and seed',24)
x0=410;y0=145;w=1190;rowh=62
for j in range(0,6):
    x=x0+w*j/5;d.line((x,y0,x,y0+rowh*len(names)),fill='#e0e5e8',width=2)
    text(d,(x-18,y0+rowh*len(names)+10),f'{maxval*j/5:.1f}',21)
for i,(name,value) in enumerate(zip(names,values)):
    y=y0+i*rowh;color='#df8b3a' if name.startswith('seed_') else '#197e92'
    text(d,(55,y+12),name.replace('_',' '),23)
    d.rectangle((x0,y+10,x0+w*value/maxval,y+43),fill=color)
    text(d,(x0+w*value/maxval+12,y+13),f'{value:+.2f} y',22,color=color,bold=True)
text(d,(x0+410,1145),'Lifetime gain (years)',23)
img.save(out/'paired_robustness.png',dpi=(300,300))
print(out)
