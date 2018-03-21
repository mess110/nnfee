from classifier import FeeClassifier
from flask import Flask, jsonify

app = Flask(__name__)

@app.route("/")
def root():
    return app.send_static_file('index.html')

@app.route("/nn")
@app.route("/nn/<int:fee_per_byte>")
@app.route("/nn/<int:fee_per_byte>/<int:mempool_size>")
def predict(fee_per_byte=1, mempool_size=10):
    output = FeeClassifier().predict([[fee_per_byte, mempool_size]], ['?'])
    return jsonify({ 'result': output })
