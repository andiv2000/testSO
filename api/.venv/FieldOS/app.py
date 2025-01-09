from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route('/create_work_order', methods=['POST'])
def create_work_order():
    try:
        # Preluarea datelor trimise în request-ul POST
        data = request.get_json()

        # Verificare structură de bază a datelor
        required_keys = ["organisationId", "userName", "password", "workOrder"]
        for key in required_keys:
            if key not in data:
                return jsonify({"message": f"Missing required key: {key}"}), 400

        # Verificare detalii din workOrder
        for work_order in data.get("workOrder", []):
            wo_required_keys = [
                "creationDateTime", "creatorName", "locationName", "sublocationName",
                "workOrderType", "problemDescription", "creatorEmail", "getUrl"
            ]
            for key in wo_required_keys:
                if key not in work_order:
                    return jsonify({"message": f"Missing required key in workOrder: {key}"}), 400

        # Simulare răspuns API extern
        simulated_response = {
            "message": "Simulated work order creation success",
            "data": {
                "workOrderId": 12345,
                "status": "Created",
                "receivedData": data
            }
        }

        return jsonify(simulated_response), 200

    except Exception as e:
        return jsonify({"message": "An error occurred", "error": str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True, port=5100)
