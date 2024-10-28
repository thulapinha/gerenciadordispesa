import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';


class ReceitaPage extends StatefulWidget {
  final ParseUser user;

  ReceitaPage({required this.user});

  @override
  _ReceitaPageState createState() => _ReceitaPageState();
}

class _ReceitaPageState extends State<ReceitaPage> {
  List<ParseObject> receitaList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReceitas();
  }

  void _loadReceitas() async {
    final QueryBuilder<ParseObject> query =
    QueryBuilder<ParseObject>(ParseObject('Income'))
      ..whereEqualTo('user', widget.user);

    final ParseResponse apiResponse = await query.query();

    if (apiResponse.success && apiResponse.results != null) {
      setState(() {
        receitaList = apiResponse.results as List<ParseObject>;
      });
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro ao carregar receitas.')));
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _editReceita(ParseObject receita) async {
    final TextEditingController dateController =
    TextEditingController(text: receita.get<String>('date'));
    final TextEditingController originController =
    TextEditingController(text: receita.get<String>('origin'));
    final TextEditingController valueController =
    TextEditingController(text: receita.get<num>('value')?.toDouble().toString());
    final TextEditingController descriptionController =
    TextEditingController(text: receita.get<String>('description'));

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Editar Receita'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: dateController,
                    decoration: InputDecoration(labelText: 'Data'),
                  ),
                  TextField(
                    controller: originController,
                    decoration: InputDecoration(labelText: 'Origem da Receita'),
                  ),
                  TextField(
                    controller: valueController,
                    decoration: InputDecoration(labelText: 'Valor da Receita'),
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
                  receita
                    ..set('date', dateController.text)
                    ..set('origin', originController.text)
                    ..set('value', double.tryParse(valueController.text.replaceAll(RegExp(r'[^0-9]'), ''))! / 100)
                    ..set('description', descriptionController.text);

                  final response = await receita.save();

                  if (response.success) {
                    setState(() {
                      _loadReceitas();
                    });
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Receita editada com sucesso!')));
                    Navigator.of(context).pop();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erro ao editar receita.')));
                  }
                },
              ),
            ],
          );
        });
  }

  void _deleteReceita(ParseObject receita) async {
    final response = await receita.delete();

    if (response.success) {
      setState(() {
        receitaList.remove(receita);
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Receita excluída com sucesso!')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir receita.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Receitas'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: receitaList.length,
        itemBuilder: (context, index) {
          final receita = receitaList[index];
          return ListTile(
            title: Text(receita.get<String>('origin') ?? 'Sem origem'),
            subtitle: Text(receita.get<String>('description') ?? 'Sem descrição'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('R\$ ${receita.get<num>('value')?.toDouble().toStringAsFixed(2) ?? '0.00'}'),
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => _editReceita(receita),
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => _deleteReceita(receita),
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
