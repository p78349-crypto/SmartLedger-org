import os
p=r'C:\Users\plain\GemmaFineTuning\data'
for fn in os.listdir(p):
    if not (fn.endswith('.json') or fn.endswith('.jsonl')):
        continue
    path=os.path.join(p,fn)
    try:
        b=open(path,'rb').read()
        b.decode('utf-8')
        print('OK',fn)
    except Exception as e:
        print('BAD',fn,e)
