import 'dart:io';

import 'package:band_names/models/bands.dart';
import 'package:band_names/services/socket_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pie_chart/pie_chart.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = 'Home';
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Band> bands = [];

  @override
  void initState() {
    final SocketService socketService =
        Provider.of<SocketService>(context, listen: false);

    socketService.socket.on('active-bands', _handleActivebands);
    super.initState();
  }

  void _handleActivebands(payload) {
    this.bands = (payload as List).map((x) => Band.fromMap(x)).toList();
    setState(() {});
  }

  @override
  void dispose() {
    final SocketService socketService =
        Provider.of<SocketService>(context, listen: false);
    socketService.socket.off('active-band');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SocketService socketService =
        Provider.of<SocketService>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bandnames',
          style: TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: <Widget>[
          Container(
              margin: EdgeInsets.only(right: 16),
              child: (socketService.serverStatus == ServerStatus.Online)
                  ? Icon(
                      Icons.check_circle,
                      color: Colors.blue[300],
                    )
                  : Icon(
                      Icons.offline_bolt,
                      color: Colors.red[300],
                    ))
        ],
      ),
      body: Column(
        children: [
          _showGraph(),
          SizedBox(height: 15),
          Expanded(
              child: ListView.builder(
                  itemCount: bands.length,
                  itemBuilder: (BuildContext context, int i) =>
                      _bandTile(bands[i])))
        ],
      ),
      floatingActionButton:
          FloatingActionButton(child: Icon(Icons.add), onPressed: addNewBand),
    );
  }

  Widget _bandTile(Band band) {
    final SocketService socketService =
        Provider.of<SocketService>(context, listen: false);
    return Dismissible(
      key: Key(band.id!),
      direction: DismissDirection.startToEnd,
      onDismissed: (_) => socketService.emit('delete-band', {'id': band.id}),
      background: Container(
        padding: EdgeInsets.only(left: 10),
        color: Colors.red,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.delete_forever, color: Colors.white),
                SizedBox(
                  width: 3,
                ),
                Text(
                  'Eliminando',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                )
              ],
            )
          ],
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Text(band.name!.substring(0, 2)),
        ),
        title: Text(band.name!),
        trailing: Text(band.votes.toString()),
        onTap: () => socketService.emit('vote-band', {'id': band.id}),
      ),
    );
  }

  addNewBand() {
    final txtcontroller = new TextEditingController();
    final _title = const Text('New band name:');

    if (Platform.isAndroid) {
      return showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: _title,
                content: TextField(
                  controller: txtcontroller,
                ),
                actions: <Widget>[
                  MaterialButton(
                      child: Text('Add'),
                      elevation: 5,
                      onPressed: () => addBandtoList(txtcontroller.text))
                ],
              ));
    } else if (Platform.isIOS) {
      return showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
                title: _title,
                content: CupertinoTextField(
                  controller: txtcontroller,
                ),
                actions: <Widget>[
                  CupertinoDialogAction(
                      isDefaultAction: true,
                      child: Text('Add'),
                      onPressed: () => addBandtoList(txtcontroller.text)),
                  CupertinoDialogAction(
                      isDestructiveAction: true,
                      child: Text('Dismiss'),
                      onPressed: () => Navigator.pop(context))
                ],
              ));
    }
  }

  void addBandtoList(String name) {
    print('Agregando: ${name}');
    if (name.length > 1) {
      final SocketService socketService =
          Provider.of<SocketService>(context, listen: false);
      socketService.emit('add-band', {'name': name});
    }
    Navigator.pop(context);
  }

  Widget _showGraph() {
    final Map<String, double> dataMap = {};
    bands.forEach((x) {
      dataMap.putIfAbsent(x.name!, () => x.votes!.toDouble());
    });

    final colorList = <Color>[
      const Color(0xfffdcb6e),
      const Color(0xff0984e3),
      const Color(0xfffd79a8),
      const Color(0xffe17055),
      const Color(0xff6c5ce7),
    ];

    final gradientList = <List<Color>>[
      [
        const Color.fromRGBO(223, 250, 92, 1),
        const Color.fromRGBO(129, 250, 112, 1),
      ],
      [
        const Color.fromRGBO(129, 182, 205, 1),
        const Color.fromRGBO(91, 253, 199, 1),
      ],
      [
        const Color.fromRGBO(175, 63, 62, 1.0),
        const Color.fromRGBO(254, 154, 92, 1),
      ]
    ];

    return SizedBox(
      width: double.infinity,
      height: 150,
      child: dataMap.isNotEmpty
          ? PieChart(
              dataMap: dataMap,
              //colorList: colorList,
              //gradientList: gradientList,
              chartType: ChartType.ring,
            )
          : Container(),
    );
  }
}
