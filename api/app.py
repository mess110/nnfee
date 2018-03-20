from flask import Flask
app = Flask(__name__)

@app.route("/")
def root():
    return app.send_static_file('index.html')

@app.route("/nn")
def hello():
    return "Hello World!"
