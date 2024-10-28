import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;

import 'package:intl/intl.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';


class ChartPage extends StatefulWidget {
  final ParseUser user;

  ChartPage({required this.user});

  @override
  _ChartPageState createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  List<charts.Series<dynamic, DateTime>> _seriesList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    // Carregar dados de despesas
    final QueryBuilder<ParseObject> despesasQuery =
    QueryBuilder<ParseObject>(ParseObject('Expense'))
      ..whereEqualTo('user', widget.user);

    final ParseResponse despesasResponse = await despesasQuery.query();

    List<TimeSeriesSales> despesasData = [];
    if (despesasResponse.success && despesasResponse.results != null) {
      despesasData = despesasResponse.results!.map((e) {
        final dateString = e.get<String>('date');
        final date = _parseDate(dateString); // Usa a função auxiliar para converter a data
        final value = e.get<num>('value').toDouble();
        return TimeSeriesSales(date, value);
      }).toList();
    }

    // Carregar dados de receitas
    final QueryBuilder<ParseObject> receitasQuery =
    QueryBuilder<ParseObject>(ParseObject('Income'))
      ..whereEqualTo('user', widget.user);

    final ParseResponse receitasResponse = await receitasQuery.query();

    List<TimeSeriesSales> receitasData = [];
    if (receitasResponse.success && receitasResponse.results != null) {
      receitasData = receitasResponse.results!.map((e) {
        final dateString = e.get<String>('date');
        final date = _parseDate(dateString); // Usa a função auxiliar para converter a data
        final value = e.get<num>('value').toDouble();
        return TimeSeriesSales(date, value);
      }).toList();
    }

    setState(() {
      _seriesList = [
        charts.Series<TimeSeriesSales, DateTime>(
          id: 'Despesas',
          colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault,
          domainFn: (TimeSeriesSales sales, _) => sales.time,
          measureFn: (TimeSeriesSales sales, _) => sales.sales,
          data: despesasData,
        ),
        charts.Series<TimeSeriesSales, DateTime>(
          id: 'Receitas',
          colorFn: (_, __) => charts.MaterialPalette.green.shadeDefault,
          domainFn: (TimeSeriesSales sales, _) => sales.time,
          measureFn: (TimeSeriesSales sales, _) => sales.sales,
          data: receitasData,
        ),
      ];
      _isLoading = false;
    });
  }

  DateTime _parseDate(String dateString) {
    try {
      return DateFormat('dd/MM/yyyy').parse(dateString);
    } catch (e) {
      // Tenta outro formato se o primeiro falhar
      return DateFormat('yyyy-MM-dd').parse(dateString);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gráficos'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: charts.TimeSeriesChart(
          _seriesList,
          animate: true,
          dateTimeFactory: const charts.LocalDateTimeFactory(),
        ),
      ),
    );
  }
}

class TimeSeriesSales {
  final DateTime time;
  final double sales;

  TimeSeriesSales(this.time, this.sales);
}
