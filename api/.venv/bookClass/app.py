import json
from flask import Flask, jsonify, request, render_template_string
import requests
app = Flask(__name__)
valAdevar=False
@app.route('/')
def index():
    # Serve the login page (HTML form)
    return render_template_string(open('login.html').read())
@app.route('/logIn', methods=['POST'])
def logIn():
    username=request.form.get('username')
    password=request.form.get('password')
    with open('conturi.json') as f:
        data=json.load(f)
        global valAdevar
        for i in data:
            if i.get("nume")==username and i.get("parola")==password:
                valAdevar=True
                return render_template_string(open('select_option.html').read())
        return "nu merge"
@app.route('/displayClasses')
def displayClasses():
    if valAdevar:
        with open('claseParter.json') as f:
            data=json.load(f)
            return json.dumps(data)
@app.route('/checkIfFree')
def check():
    with open('claseParter.json') as f:
        data=json.load(f)
        freeItems=[]
        for i in data:
            if i.get("status")=="free":
                freeItems.append(i)
        if len(freeItems)>0:
            return json.dumps(freeItems,indent=4)
@app.route('/checkIfBusy')
def checkBusy():
    with open('claseParter.json') as f:
        data=json.load(f)
        busyRooms=[]
        for i in data:
            if i.get('status') == 'busy':
                busyRooms.append(i)
        if(len(busyRooms)>0):
            return json.dumps(busyRooms,indent=4)
        else:
            return "Nu exista sali ocupate!"
@app.route('/bookClass')
def bookClass():
    className=request.args.get('className')
    with open('claseParter.json','r+') as f:
        data=json.load(f)
        for i in data:
            if i.get("numar")==className:
                if i.get("status") != "busy":
                    i["status"]="busy"
                    f.seek(0)
                    #f.truncate()
                    json.dump(data,f,indent=4)
                    return "Booked!"
                else:
                    return "Class is already busy!"
        return "Clasa cu numele "+className+" nu exista"

@app.route('/showStaff')
def showStaff():
    with open('profesori.json','r')as f:
        data=json.load(f)
        return json.dumps(data)


@app.route('/ExperinetaMedieProfesori')
def exMeProf():
    li=[]
    experintaTotala=0
    contor=0
    with open('profesori.json') as f:
        data=json.load(f)
        for i in data:
            experintaTotala=experintaTotala+i.get('experienta')
            contor=contor+1
    experintaFinala=experintaTotala/contor
    li.append(experintaFinala)
    return li

@app.route('/addProf', methods=['POST'])
def addProf():
    if request.method == 'POST':
        profName=request.json.get('Name')
        profex=request.json.get('experienta')
        newProf={"Name":profName,"experineta":profex}
        with open('profesori.json','r+') as f:
            data=json.load(f)
            data.append(newProf)
            f.seek(0)
            f.truncate
            json.dump(data,f,indent=4)
        return jsonify(newProf)
if __name__=='__main__':
    app.run(debug=True,port=5018)#debug=True,port=5015)