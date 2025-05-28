from flask import Flask, request, jsonify
from flask_cors import CORS
import firebase_admin
from firebase_admin import credentials, db
from os import environ as env
from dotenv import load_dotenv

load_dotenv()

SERVICE_PATH = env.get("SERVICE_PATH")
DB_URL = env.get("DB_URL")

cred = credentials.Certificate(SERVICE_PATH)

firebase_admin.initialize_app(cred, {
    'databaseURL': DB_URL
})
app = Flask(__name__)
CORS(app)

@app.route('/', methods = ['GET'])
def home():
    return "this is a test"

@app.route('/search/user', methods = ['GET'])
def search_user():
    email = request.args.get('email')
    if not email:
        return jsonify({"error": "Email parameter needed"}), 400
    
    email = email.strip().lower()

    users_ref = db.reference("users")
    result = users_ref.order_by_child("email").equal_to(email).get()

    if result:
        return jsonify(result), 200
    else:
        return jsonify({"message": "User not found"}),401
    
if __name__ == '__main__':
    app.run(debug=True)

                                                 