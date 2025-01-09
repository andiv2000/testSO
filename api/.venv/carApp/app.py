import json
from flask import Flask, redirect, url_for, render_template, request, session, request, jsonify
import requests

app = Flask(__name__)

@app.route('/')
def test():
    return "ok"

    
@app.route('/getCars')
def getCars():
    with open('lista.json') as f:
        data = json.load(f)
        return json.dumps(data)

@app.route('/getCar')
def getSpecificCar():
    carName=request.args.get('name')
    with open('lista.json') as f:
        data=json.load(f)
        for i in data:
            if i['name'].lower()==carName.lower():
                return json.dumps(i)
            
    return "Car not found", 404

@app.route('/addCar', methods=['POST'])
def addCar():
    if request.method == 'POST':
        carName = request.json.get('name')
        carYear = request.json.get('year')
        new_car = {"name": carName, "year": carYear}
        with open('lista.json', 'r+') as f:
            data = json.load(f)
            data.append(new_car)
            f.seek(0)  
            json.dump(data, f, indent=4) 
        return jsonify(new_car)
    
@app.route('/rmCar',methods=['POST'])
def rmJson():
    value=request.json.get('name')
    with open('lista.json', 'r') as f:
        data = json.load(f)  
    data = [item for item in data if item.get("name") != value]

    with open('lista.json', 'w') as f:
        json.dump(data, f, indent=4)
    return "Succes"

if __name__ == '__main__':
    app.run(debug=True, port=5012)
