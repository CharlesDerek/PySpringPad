from fastapi import FastAPI
from pydantic import BaseModel
app = FastAPI()

@app.get('/')
def read_root():
    return {'message': 'Hello from FastAPI!'}

class Item(BaseModel):
    name: str
    qty: int

@app.post('/items')
def create_item(item: Item):
    return {'ok': True, 'item': item}
