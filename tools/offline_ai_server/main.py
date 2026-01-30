from fastapi import FastAPI
from pydantic import BaseModel
from typing import Optional
from dateutil import parser as dateparser

app = FastAPI(title="SmartLedger Offline AI Prototype")

class AnalyzeRequest(BaseModel):
    text: str

class AnalyzeResponse(BaseModel):
    intent: str
    entities: dict

# Very small rule-based NLU prototype (replace with Rasa or similar)

def simple_nlu(text: str) -> dict:
    text_l = text.lower()
    # amount
    amount = None
    for token in text_l.replace(',', ' ').split():
        if token.endswith('원'):
            try:
                amount = int(token[:-1])
            except:
                pass
    # date (try parsing)
    date = None
    try:
        dt = dateparser.parse(text, fuzzy=True, default=None)
        if dt:
            date = dt.date().isoformat()
    except:
        date = None
    # category heuristics
    if '점심' in text_l or '식당' in text_l or '밥' in text_l:
        category = '식비'
    else:
        category = '기타'
    intent = 'add_expense' if amount else 'note'
    memo = text
    return {
        'intent': intent,
        'entities': {
            'amount': amount,
            'date': date,
            'category': category,
            'memo': memo,
        }
    }

@app.post('/analyze', response_model=AnalyzeResponse)
async def analyze(req: AnalyzeRequest):
    # TODO: integrate Vosk STT endpoint or accept text directly from Flutter (preferred: Flutter sends recognized text)
    result = simple_nlu(req.text)
    return AnalyzeResponse(intent=result['intent'], entities=result['entities'])

@app.get('/health')
async def health():
    return {'status': 'ok'}
