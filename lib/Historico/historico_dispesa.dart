import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

class DespesasPage extends StatefulWidget {
  final ParseUser user;

  DespesasPage({required this.user});

  @override
  _DespesasPageState createState() => _DespesasPageState();
}

class _DespesasPageState extends State<DespesasPage> {
  List<ParseObject> despesasList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDespesas();
  }

  void _loadDespesas() async {
    final QueryBuilder<ParseObject> query =
    QueryBuilder<ParseObject>(ParseObject('Expense'))
      ..whereEqualTo('user', widget.user);

    final ParseResponse apiResponse = await query.query();

    if (apiResponse.success && apiResponse.results != null) {
      setState(() {
        despesasList = apiResponse.results as List<ParseObject>;
      });
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro ao carregar despesas.')));
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _editDespesa(ParseObject despesa) async {
    final TextEditingController dateController =
    TextEditingController(text: despesa.get<String>('date'));
    final TextEditingController originController =
    TextEditingController(text: despesa.get<String>('origin'));
    final TextEditingController dueDateController =
    TextEditingController(text: despesa.get<String>('dueDate'));
    final TextEditingController valueController =
    TextEditingController(text: despesa.get<num>('value')?.toDouble().toString());
    final TextEditingController descriptionController =
    TextEditingController(text: despesa.get<String>('description'));

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Editar Despesa'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: dateController,
                    decoration: InputDecoration(labelText: 'Data'),
                  ),
                  TextField(
                    controller: originController,
                    decoration: InputDecoration(labelText: 'Origem da Despesa'),
                  ),
                  TextField(
                    controller: dueDateController,
                    decoration: InputDecoration(labelText: 'Vencimento da Despesa'),
                  ),
                  TextField(
                    controller: valueController,
                    decoration: InputDecoration(labelText: 'Valor da Despesa'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      CurrencyInputFormatter(),
                    ],
                  ),
                  TextField(
                    controller: descriptionController,
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
                onPressed: () async {
                  despesa
                    ..set('date', dateController.text)
                    ..set('origin', originController.text)
                    ..set('dueDate', dueDateController.text)
                    ..set('value', double.tryParse(valueController.text.replaceAll(RegExp(r'[^0-9]'), ''))! / 100)
                    ..set('description', descriptionController.text);

                  final response = await despesa.save();

                  if (response.success) {
                    setState(() {
                      _loadDespesas();
                    });
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Despesa editada com sucesso!')));
                    Navigator.of(context).pop();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erro ao editar despesa.')));
                  }
                },
              ),
            ],
          );
        });
  }

  void _deleteDespesa(ParseObject despesa) async {
    final response = await despesa.delete();

    if (response.success) {
      setState(() {
        despesasList.remove(despesa);
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Despesa excluída com sucesso!')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir despesa.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Despesas'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: despesasList.length,
        itemBuilder: (context, index) {
          final despesa = despesasList[index];
          return ListTile(
            title: Text(despesa.get<String>('origin') ?? 'Sem origem'),
            subtitle: Text(despesa.get<String>('description') ?? 'Sem descrição'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('R\$ ${despesa.get<num>('value')?.toDouble().toStringAsFixed(2) ?? '0.00'}'),
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => _editDespesa(despesa),
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => _deleteDespesa(despesa),
                ),
              ],
            ),
          );
        },
      ),
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
