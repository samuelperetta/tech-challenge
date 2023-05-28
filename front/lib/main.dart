import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class CreditCardRequest {
  final String nome;
  final int score;
  final double renda;
  final String limiteCredito;

  CreditCardRequest({
    required this.nome,
    required this.score,
    required this.renda,
    required this.limiteCredito,
  });

  factory CreditCardRequest.fromJson(Map<String, dynamic> json) {
    return CreditCardRequest(
      nome: json['nome'],
      score: json['score'],
      renda: json['renda'],
      limiteCredito: json['limite_credito'],
    );
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<List<CreditCardRequest>> _futureCreditCardRequests;

  @override
  void initState() {
    super.initState();
    _futureCreditCardRequests = fetchCreditCardRequests();
  }

  Future<List<CreditCardRequest>> fetchCreditCardRequests() async {
    final response = await http.get(Uri.parse('http://localhost:5000/cartao'));
    if (response.statusCode == 200) {
      dynamic data = jsonDecode(response.body);
      if (data is List) {
        return data.map((item) => CreditCardRequest.fromJson(item)).toList();
      } else if (data is Map && data.containsKey('message')) {
        // Trata a mensagem de "Nenhuma solicitação de cartão encontrada"
        // Exibe a mensagem ou retorna uma lista vazia, dependendo do que for mais adequado para o seu caso
        return [];
      }
    }
    throw Exception('Failed to fetch credit card requests');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Solicitações de Cartão'),
      ),
      body: FutureBuilder<List<CreditCardRequest>>(
        future: fetchCreditCardRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            List<CreditCardRequest> requests = snapshot.data;
            return ListView.builder(
              itemCount: requests.length,
              itemBuilder: (context, index) {
                CreditCardRequest request = requests[index];
                return ListTile(
                  title: Text('Nome: ${request.name}'),
                  subtitle: Text('Score: ${request.score}'),
                  trailing: ElevatedButton(
                    child: Text('Preencher Formulário'),
                    onPressed: () {
                      // Navegar para a tela do formulário de solicitação de cartão
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CreditCardFormScreen(request: request),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          } else {
            return Center(
                child: Text('Nenhuma solicitação de cartão encontrada.'));
          }
        },
      ),
    );
  }
}

class CreditCardFormScreen extends StatefulWidget {
  final CreditCardRequest request;

  CreditCardFormScreen({required this.request});

  @override
  _CreditCardFormScreenState createState() => _CreditCardFormScreenState();
}

class _CreditCardFormScreenState extends State<CreditCardFormScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _incomeController = TextEditingController();
  double _creditLimit = 0;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.request.name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Formulário de Solicitação de Cartão'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Nome'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, informe o nome';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _incomeController,
                decoration: InputDecoration(labelText: 'Renda'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, informe a renda';
                  }
                  return null;
                },
              ),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _calculateCreditLimit();
                  }
                },
                child: Text('Calcular Limite de Crédito'),
              ),
              SizedBox(height: 16),
              Text(
                'Limite de Crédito: $_creditLimit',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _calculateCreditLimit() {
    double income = double.tryParse(_incomeController.text) ?? 0;

    if (widget.request.score >= 1 && widget.request.score <= 299) {
      _creditLimit = 0;
    } else if (widget.request.score >= 300 && widget.request.score <= 599) {
      _creditLimit = 1000;
    } else if (widget.request.score >= 600 && widget.request.score <= 799) {
      _creditLimit = max(0.5 * income, 1000);
    } else if (widget.request.score >= 800 && widget.request.score <= 950) {
      _creditLimit = 2 * income;
    } else if (widget.request.score >= 951 && widget.request.score <= 999) {
      _creditLimit = 1000000;
    }

    setState(() {});
  }
}
