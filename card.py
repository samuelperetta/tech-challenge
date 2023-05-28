from flask import Flask, jsonify, request
from pymongo import MongoClient
import random
from dotenv import load_dotenv
import os

load_dotenv('.env')

app = Flask(__name__)
client = MongoClient('mongodb://'+os.getenv('MONGODB_USERNAME')+':'+os.getenv('MONGODB_PASSWORD')+'@localhost:27017/')  # Conexão com o MongoDB
db = client['credit_card_db']  # Banco de dados
collection = db['credit_card_requests']  # Coleção

# Rota GET para listar todas as solicitações de cartão
@app.route('/cartao', methods=['GET'])
def get_credit_card_requests():
    requests = list(collection.find({}, {'_id': 0}))
    return jsonify(requests)

# Rota POST para inserir uma nova solicitação de cartão
@app.route('/cartao', methods=['POST'])
def create_credit_card_request():
    data = request.get_json()
    score = random.randint(1, 999)
    limite = get_credit_limit(score, data['renda'])

    request_data = {
        'nome': data['nome'],
        'score': score,
        'renda': data['renda'],
        'limite_credito': limite
    }
    collection.insert_one(request_data)
    return jsonify({'message': 'Solicitação de cartão criada com sucesso!'})

# Rota DELETE para remover uma solicitação de cartão
@app.route('/cartao/<nome>', methods=['DELETE'])
def delete_credit_card_request(nome):
    collection.delete_one({'nome': nome})
    return jsonify({'message': 'Solicitação de cartão removida com sucesso!'})

# Função para calcular o limite de crédito baseado no score e renda
def get_credit_limit(score, renda):
    if score >= 1 and score <= 299:
        return 'Reprovado'
    elif score >= 300 and score <= 599:
        return 'R$ 1.000,00'
    elif score >= 600 and score <= 799:
        limite = max(1000, 0.5 * renda)
        return 'R$ {:.2f}'.format(limite)
    elif score >= 800 and score <= 950:
        return 'R$ {:.2f}'.format(2 * renda)
    elif score >= 951 and score <= 999:
        return 'R$ 1.000.000'

if __name__ == '__main__':
    app.run()