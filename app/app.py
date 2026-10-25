from flask import Flask, jsonify

app = Flask(__name__)

@app.get("/health")
def health():
    return jsonify(status="ok")

@app.get("/")
def index():
    return jsonify(message= "CloudOps Launchpad API is running", version="0.1.0")   

if __name__ == "__main__":
    app.run(port=5000)