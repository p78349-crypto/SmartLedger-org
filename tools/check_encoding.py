import os
p=r'C:\Users\plain\GemmaFineTuning\data'
for fn in os.listdir(p):
    if fn.endswith('.jsonl') or fn.endswith('.json'):
        path=os.path.join(p,fn)
        try:
            with open(path,'r',encoding='utf-8') as f:
                f.read(1000)
            print('OK',fn)
        except Exception as e:
            print('ERR',fn,e)
