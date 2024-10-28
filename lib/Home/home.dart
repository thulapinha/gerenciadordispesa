import 'package:flutter/material.dart';
import 'package:metroni/Botoes/botao_add_dispesa.dart';
import 'package:metroni/Botoes/botao_add_receita.dart';
import 'package:metroni/Historico/historico_dispesa.dart';
import 'package:metroni/Historico/historico_receita.dart';
import 'package:metroni/Login/login.dart';
import 'package:metroni/contas_vencidas/constas.dart';
import 'package:metroni/grafico/grafico.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';



class HomePage extends StatefulWidget {
  final ParseUser user;

  HomePage({required this.user});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double totalDespesas = 0.0;
  double totalReceitas = 0.0;
  bool _isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadTotals();
  }

  void _loadTotals() async {
    // Carregar total de despesas
    final QueryBuilder<ParseObject> despesasQuery =
    QueryBuilder<ParseObject>(ParseObject('Expense'))
      ..whereEqualTo('user', widget.user);

    final ParseResponse despesasResponse = await despesasQuery.query();

    if (despesasResponse.success && despesasResponse.results != null) {
      setState(() {
        totalDespesas = despesasResponse.results
            ?.map((e) => e.get<num>('value').toDouble())
            .reduce((a, b) => a + b);
      });
    }

    // Carregar total de receitas
    final QueryBuilder<ParseObject> receitasQuery =
    QueryBuilder<ParseObject>(ParseObject('Income'))
      ..whereEqualTo('user', widget.user);

    final ParseResponse receitasResponse = await receitasQuery.query();

    if (receitasResponse.success && receitasResponse.results != null) {
      setState(() {
        totalReceitas = receitasResponse.results
            ?.map((e) => e.get<num>('value').toDouble())
            .reduce((a, b) => a + b);
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChartPage(user: widget.user)),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ReceitaPage(user: widget.user)),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DespesasPage(user: widget.user)),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bem-vindo, ${widget.user.username}'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Inicio'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.history),
              title: Text('Histórico de Despesas'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DespesasPage(user: widget.user)),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.auto_graph_outlined),
              title: Text('Histórico de Receitas'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ReceitaPage(user: widget.user)),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.list_alt),
              title: Text('Contas a vencer'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ContasAVencerPage(user: widget.user,)),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Sair'),
              onTap: () async {
                await widget.user.logout();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator()
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      child: Text(
                        'R\$ ${totalDespesas.toStringAsFixed(2)}',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Total Despesas',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      child: Text(
                        'R\$ ${totalReceitas.toStringAsFixed(2)}',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Total Receitas',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 50),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) =>
                      AddExpenseDialog(user: widget.user),
                );
              },
              child: Text('Adicionar Despesas', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) =>
                      AddIncomeDialog(user: widget.user),
                );
              },
              child: Text('Adicionar Receita', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Gráfico',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Histórico de Receitas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Histórico de Despesas',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}
