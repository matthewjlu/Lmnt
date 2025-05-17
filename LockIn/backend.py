from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route('/api/lockin', methods=['GET'])
def lockin():
    return jsonify("matthew mj lu"), 200


@app.route('/api/lockin/post', methods=['POST'])
def lockin_post():
    data = request.get_json()
    if not data:
        return jsonify({'error': 'error sending'}), 400
    return jsonify({'Data': data}), 200

if __name__ == '__main__':
    app.run(debug=True)

                                                 