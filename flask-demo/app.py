from flask import Flask, jsonify, request
app = Flask(__name__)

@app.get("/")
def index():
    return {"message": "Hello from Flask!"}

@app.get("/echo/<name>")
def echo(name):
    return jsonify(hello=name, q=request.args.get("q"))
