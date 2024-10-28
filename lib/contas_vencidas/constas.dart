import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class ContasAVencerPage extends StatefulWidget {
  final ParseUser user;

  ContasAVencerPage({required this.user});

  @override
  _ContasAVencerPageState createState() => _ContasAVencerPageState();
}

class _ContasAVencerPageState extends State<ContasAVencerPage> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  List<ParseObject> contasList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadContas();
    _scheduleDailyNotification();
  }

  void _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_enois');

    final InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _loadContas() async {
    setState(() {
      _isLoading = true;
    });

    final DateTime hoje = DateTime.now();
    final DateTime cincoDiasDepois = hoje.add(Duration(days: 5));

    final QueryBuilder<ParseObject> query =
    QueryBuilder<ParseObject>(ParseObject('Expense'))
      ..whereEqualTo('user', widget.user)
      ..whereGreaterThanOrEqualsTo('dueDate', DateFormat('yyyy-MM-dd').format(hoje))
      ..whereLessThanOrEqualTo('dueDate', DateFormat('yyyy-MM-dd').format(cincoDiasDepois));

    final ParseResponse apiResponse = await query.query();

    if (apiResponse.success && apiResponse.results != null) {
      setState(() {
        contasList = apiResponse.results as List<ParseObject>;
      });

      // Ordenar a lista de contas pelo vencimento mais próximo
      contasList.sort((a, b) {
        final DateTime dateA = DateFormat('yyyy-MM-dd').parse(a.get<String>('dueDate')!);
        final DateTime dateB = DateFormat('yyyy-MM-dd').parse(b.get<String>('dueDate')!);
        return dateA.compareTo(dateB);
      });
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro ao carregar contas.')));
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _scheduleDailyNotification() async {
    tz.initializeTimeZones();
    final String timeZoneName = await tz.local.name;
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
    const AndroidNotificationDetails(
      'daily_reminder_channel_id',
      'Daily Reminders',
      importance: Importance.max,
      priority: Priority.high,
    );

    final NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Lembrete Diário',
      'Não se esqueça de verificar suas contas a vencer!',
      _nextInstanceOfNineFifteenPM(),
      platformChannelSpecifics,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOfNineFifteenPM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
    tz.TZDateTime(tz.local, now.year, now.month, now.day, 21, 25);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  void _confirmarPagamento(ParseObject conta) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar Pagamento'),
          content: Text('Você deseja marcar esta despesa como paga?'),
          actions: [
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            ElevatedButton(
              child: Text('Confirmar'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await conta.delete();
      setState(() {
        contasList.remove(conta);
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Despesa marcada como paga e removida da lista.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Contas a Vencer'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: contasList.length,
        itemBuilder: (context, index) {
          final conta = contasList[index];
          final origem = conta.get<String>('origin');
          final valor = conta.get<num>('value');
          final vencimento = conta.get<String>('dueDate');

          return ListTile(
            title: Text(origem!),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Valor: R\$${valor!.toStringAsFixed(2)}'),
                Text('Vencimento: ${vencimento!}'),
              ],
            ),
            onTap: () => _confirmarPagamento(conta),
          );
        },
      ),
    );
  }
}
