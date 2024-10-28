import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:flutter/services.dart';

import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

class AddExpenseDialog extends StatefulWidget {
  final ParseUser user;
  AddExpenseDialog({required this.user});

  @override
  _AddExpenseDialogState createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final _currencyFormatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _addExpense() async {
    final date = _dateController.text.trim();
    final origin = _originController.text.trim();
    final dueDate = _dueDateController.text.trim();
    final value = _currencyFormatter.parse(_valueController.text.trim()).toDouble();
    final description = _descriptionController.text.trim();

    if (date.isEmpty || origin.isEmpty || dueDate.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Por favor, preencha todos os campos')));
      return;
    }

    final expense = ParseObject('Expense')
      ..set('date', date)
      ..set('origin', origin)
      ..set('dueDate', dueDate)
      ..set('value', value)
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
    return AlertDialog(
      title: Text('Adicionar Despesas'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _dateController,
              decoration: InputDecoration(
                labelText: 'Data',
                suffixIcon: IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context, _dateController),
                ),
              ),
              readOnly: true,
            ),
            TextField(
              controller: _originController,
              decoration: InputDecoration(labelText: 'Origem da Despesa'),
            ),
            TextField(
              controller: _dueDateController,
              decoration: InputDecoration(
                labelText: 'Vencimento da Despesa',
                suffixIcon: IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context, _dueDateController),
                ),
              ),
              readOnly: true,
            ),
            TextField(
              controller: _valueController,
              decoration: InputDecoration(labelText: 'Valor da Despesa'),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                CurrencyInputFormatter(),
              ],
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Descrição'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text('Cancelar'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          child: Text('Salvar'),
          onPressed: _addExpense,
        ),
      ],
    );
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  final _currencyFormatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: 'R\$ 0,00');
    }

    double value = double.parse(newValue.text.replaceAll(RegExp(r'[^0-9]'), '')) / 100;
    final newText = _currencyFormatter.format(value);

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
