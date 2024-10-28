import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';




class AddExpensePage extends StatefulWidget {
  final ParseUser user;

  AddExpensePage({required this.user});

  @override
  _AddExpensePageState createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  void _addExpense() async {
    final amount = double.tryParse(_amountController.text.trim());
    final description = _descriptionController.text.trim();

    if (amount == null || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Por favor, preencha todos os campos')));
      return;
    }

    final expense = ParseObject('Expense')
      ..set('amount', amount)
      ..set('description', description)
      ..set('user', widget.user);

    final response = await expense.save();

    if (response.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Despesa adicionada com sucesso!')));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao adicionar despesa.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Adicionar Despesas'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _amountController,
              decoration: InputDecoration(labelText: 'Quantidade'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Descrição'),
            ),
            ElevatedButton(
              onPressed: _addExpense,
              child: Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
