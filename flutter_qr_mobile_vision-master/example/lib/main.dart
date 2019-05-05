import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_mobile_vision/qr_camera.dart';

import 'package:flutter_blue/flutter_blue.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;

void main() {
  debugPaintSizeEnabled = false;
  runApp(new HomePage());
}

class HomePage extends StatefulWidget {
  @override
  HomeState createState() => new HomeState();
}

class HomeState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(debugShowCheckedModeBanner: false, home: new MyApp());
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String qr;
  String oldQr;
  bool camState = false;



  String productName;
  String ingredients;
  List<String> glutenList;
  List<String> lactoseList;
  List<String> nonVegetarianList;
  List<String> nonVeganList;

  String value1;
  String value2;
  String value3;
  String value4;

  bool vibrating = false;
  bool willVibrate = false;



  List<DropdownMenuItem<String>> _dropDownMenuItems;

  List choice = ["gluten", "lactose", "vegetarian", "vegan"];

  List choice_bool = [false, false, false, false];

  List indexes = [0, 1, 2, 3];

  bool gluten = false;
  bool lactose = false;
  bool nonVegetarian = false;
  bool nonVegan = false;


  FlutterBlue _flutterBlue = FlutterBlue.instance;

  /// Scanning
  StreamSubscription _scanSubscription;
  Map<DeviceIdentifier, ScanResult> scanResults = new Map();
  bool isScanning = false;

  /// State
  StreamSubscription _stateSubscription;
  BluetoothState state = BluetoothState.unknown;

  /// Device
  BluetoothDevice device;
  bool get isConnected => (device != null);
  StreamSubscription deviceConnection;
  StreamSubscription deviceStateSubscription;
  List<BluetoothService> services = new List();
  Map<Guid, StreamSubscription> valueChangedSubscriptions = {};
  BluetoothDeviceState deviceState = BluetoothDeviceState.disconnected;


  BluetoothCharacteristic characteristic;


  @override
  void dispose() {
    _stateSubscription?.cancel();
    _stateSubscription = null;
    _scanSubscription?.cancel();
    _scanSubscription = null;
    deviceConnection?.cancel();
    deviceConnection = null;
    super.dispose();
  }

  _startScan() {
    _scanSubscription = _flutterBlue
      .scan(
      timeout: const Duration(seconds: 5),
      /*withServices: [
          new Guid('0000180F-0000-1000-8000-00805F9B34FB')
        ]*/
    )
      .listen((scanResult) {
      print('localName: ${scanResult.advertisementData.localName}');
      print(
        'manufacturerData: ${scanResult.advertisementData.manufacturerData}');
      print('serviceData: ${scanResult.advertisementData.serviceData}');
      setState(() {
        scanResults[scanResult.device.id] = scanResult;
      });
    }, onDone: _stopScan);

    setState(() {
      isScanning = true;
    });
  }

  _stopScan() {
    _scanSubscription?.cancel();
    _scanSubscription = null;
    setState(() {
      isScanning = false;
    });
  }

  _connect(BluetoothDevice d) async {
    device = d;
    // Connect to device
    deviceConnection = _flutterBlue
      .connect(device, timeout: const Duration(seconds: 4))
      .listen(
      null,
      onDone: _disconnect,
    );

    // Update the connection state immediately
    device.state.then((s) {
      setState(() {
        deviceState = s;
      });
    });

    // Subscribe to connection changes
    deviceStateSubscription = device.onStateChanged().listen((s) {
      setState(() {
        deviceState = s;
      });
      if (s == BluetoothDeviceState.connected) {
        device.discoverServices().then((s) {
          setState(() {
            services = s;
            characteristic = services[2].characteristics[0];
          });
        });
      }
    });
  }

  _disconnect() {
    // Remove all value changed listeners
    valueChangedSubscriptions.forEach((uuid, sub) => sub.cancel());
    valueChangedSubscriptions.clear();
    deviceStateSubscription?.cancel();
    deviceStateSubscription = null;
    deviceConnection?.cancel();
    deviceConnection = null;
    setState(() {
      device = null;
    });
  }

  _readCharacteristic(BluetoothCharacteristic c) async {
    await device.readCharacteristic(c);
    setState(() {});
  }

  _writeCharacteristic(BluetoothCharacteristic c, List<int> values) async {
    if (isConnected) {
      await device.writeCharacteristic(c, values,
        type: CharacteristicWriteType.withResponse);
      setState(() {});
    }
  }

  _writeCharacteristic0(BluetoothCharacteristic c) async {
    await device.writeCharacteristic(c,  [0x00000000, 0x00000000, 0x00000000 ,0x00000000],
      type: CharacteristicWriteType.withResponse);
    setState(() {});
  }

  _writeCharacteristic1(BluetoothCharacteristic c) async {
    await device.writeCharacteristic(c,  [0xffffffffff, 0x00000000 ,0x00000000, 0x00000000],
      type: CharacteristicWriteType.withResponse);
    setState(() {});
  }

  _writeCharacteristic2(BluetoothCharacteristic c) async {
    await device.writeCharacteristic(c,  [0x00000000, 0xffffffffff, 0x00000000 ,0x00000000],
      type: CharacteristicWriteType.withResponse);
    setState(() {});
  }

  _writeCharacteristic3(BluetoothCharacteristic c) async {
    await device.writeCharacteristic(c,  [0x00000000, 0x00000000, 0xffffffffff ,0x00000000],
      type: CharacteristicWriteType.withResponse);
    setState(() {});
  }

  _writeCharacteristic4(BluetoothCharacteristic c) async {
    await device.writeCharacteristic(c,  [0x00000000, 0x00000000, 0x00000000 ,0xffffffffff],
      type: CharacteristicWriteType.withResponse);
    setState(() {});
  }

  _readDescriptor(BluetoothDescriptor d) async {
    await device.readDescriptor(d);
    setState(() {});
  }

  _writeDescriptor(BluetoothDescriptor d) async {
    await device.writeDescriptor(d, [0x12, 0x34]);
    setState(() {});
  }

  _setNotification(BluetoothCharacteristic c) async {
    if (c.isNotifying) {
      await device.setNotifyValue(c, false);
      // Cancel subscription
      valueChangedSubscriptions[c.uuid]?.cancel();
      valueChangedSubscriptions.remove(c.uuid);
    } else {
      await device.setNotifyValue(c, true);
      // ignore: cancel_subscriptions
      final sub = device.onValueChanged(c).listen((d) {
        setState(() {
          print('onValueChanged $d');
        });
      });
      // Add to map
      valueChangedSubscriptions[c.uuid] = sub;
    }
    setState(() {});
  }

  _refreshDeviceState(BluetoothDevice d) async {
    var state = await d.state;
    setState(() {
      deviceState = state;
      print('State refreshed: $deviceState');
    });
  }

  _buildScanningButton() {
    if (isConnected || state != BluetoothState.on) {
      return null;
    }
    if (isScanning) {
      return new FloatingActionButton(
        child: new Icon(Icons.stop),
        onPressed: _stopScan,
        backgroundColor: Colors.red,
      );
    } else {
      return new FloatingActionButton(
        child: new Icon(Icons.search), onPressed: _startScan);
    }
  }

  _buildScanResultTiles() {
    return scanResults.values
      .map((r) => ScanResultTile(
      result: r,
      onTap: () => _connect(r.device),
    ))
      .toList();
  }

  List<Widget> _buildServiceTiles() {
    return services
      .map(
        (s) => new ServiceTile(
        service: s,
        characteristicTiles: s.characteristics
          .map(
            (c) => new CharacteristicTile(
            characteristic: c,
            onReadPressed: () => _readCharacteristic(c),
            onWritePressed: () => _writeCharacteristic(c, [0xffffffff]),
            onNotificationPressed: () => _setNotification(c),
            descriptorTiles: c.descriptors
              .map(
                (d) => new DescriptorTile(
                descriptor: d,
                onReadPressed: () => _readDescriptor(d),
                onWritePressed: () =>
                  _writeDescriptor(d),
              ),
            )
              .toList(),
          ),
        )
          .toList(),
      ),
    )
      .toList();
  }

  _buildActionButtons() {
    if (isConnected) {
      return <Widget>[
        new IconButton(
          icon: const Icon(Icons.cancel),
          onPressed: () => _disconnect(),
        )
      ];
    }
  }

  _buildAlertTile() {
    return new Container(
      color: Colors.redAccent,
      child: new ListTile(
        title: new Text(
          'Bluetooth adapter is ${state.toString().substring(15)}',
          style: Theme.of(context).primaryTextTheme.subhead,
        ),
        trailing: new Icon(
          Icons.error,
          color: Theme.of(context).primaryTextTheme.subhead.color,
        ),
      ),
    );
  }

  _buildDeviceStateTile() {
    return new ListTile(
      leading: (deviceState == BluetoothDeviceState.connected)
        ? const Icon(Icons.bluetooth_connected)
        : const Icon(Icons.bluetooth_disabled),
      title: new Text('Device is ${deviceState.toString().split('.')[1]}.'),
      subtitle: new Text('${device.id}'),
      trailing: new IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: () => _refreshDeviceState(device),
        color: Theme.of(context).iconTheme.color.withOpacity(0.5),
      ));
  }

  _buildProgressBarTile() {
    return new LinearProgressIndicator();
  }


  @override
  void initState() {
    super.initState();
    // Immediately get the state of FlutterBlue
    _flutterBlue.state.then((s) {
      setState(() {
        state = s;
      });
    });
    // Subscribe to state changes
    _stateSubscription = _flutterBlue.onStateChanged().listen((s) {
      setState(() {
        state = s;
      });
    });

    _dropDownMenuItems = getDropDownMenuItems();
    value1 = _dropDownMenuItems[0].value;
    value2 = _dropDownMenuItems[1].value;
    value3 = _dropDownMenuItems[2].value;
    value4 = _dropDownMenuItems[3].value;

    readFile();
  }

  void deleteQr() {
    qr = null; oldQr = null; productName = null;
  }

  @override
  Widget build(BuildContext context) {

    //readFile();
    //if(_barcodes.isNotEmpty) getJSONData(_barcodes.last);



    if (qr!= null && oldQr != qr) {

      oldQr = qr;
      setState(() { vibrating = true; });

      final json = getJSONData(qr);
      json. then((_) {

        vibrate();
        setState(() { vibrating = false; });

      });

    }

    else {
      setState(() { vibrating = false; });
    }
    return new MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: new ThemeData(
        primarySwatch: Colors.blueGrey,
        buttonColor: Colors.blueGrey,
      ),
      home: new DefaultTabController(
        length: 3,
        child: new Scaffold(
          appBar: new AppBar(
            centerTitle: true,
            bottom: new TabBar(
              indicatorColor: Colors.black54,
              tabs: [
                new Tab(icon: new Icon(Icons.settings_overscan), text: 'Barcode', ),
                new Tab(icon: new Icon(Icons.bluetooth), text: 'Bluetooth', ),
                new Tab(icon: new Icon(Icons.pan_tool), text: 'Settings',),
                // new Tab(text: 'Face')
              ],
            ),
            title: new Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[ Text('MY FOOD GUIDE', style: new TextStyle(
                fontFamily: "Rubik",
                fontSize: 20.0),
              )],),
            /*
            leading: new IconButton(
            icon: new Icon(Icons.pan_tool),
            onPressed: () {},
            ),*/
          ),
          body: new TabBarView(children: [
            _cameraView(context),
            _bluetooth(context),
            _settings(context),
            //new GetIngredients(),
          ]),
        ),
      ),
    );
  }



  Widget _bluetooth(BuildContext context) {
    var tiles = new List<Widget>();
    tiles.add(new Container(
      height: MediaQuery.of(context).size.height * 0.02,
      child:  new Text(""),
    ),);
    if (state != BluetoothState.on) {
      tiles.add(_buildAlertTile());
    }
    if (isConnected) {
      tiles.add(new Container(
        height: MediaQuery.of(context).size.height * 0.02,
        child:  new Text(""),
      ),);
      tiles.add(_buildDeviceStateTile());
      //tiles.addAll(_buildServiceTiles());
      //tiles.add(_buildActionButtons());
      tiles.add(new Container(
        height: MediaQuery.of(context).size.height * 0.08,
        child:  new Text(""),
      ),);
      tiles.add(
        new Container(
          width: MediaQuery.of(context).size.width * 0.6 ,
          height: MediaQuery.of(context).size.height * 0.1 ,

          child: new RaisedButton(
            shape: new RoundedRectangleBorder(
              borderRadius: new BorderRadius.circular(30.0)),
            child: new Text(
              "disconnect",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white,  fontSize: 17.0),
            ),
            onPressed: () => _disconnect(),
          ),
        ),

      );
    } else {
      tiles.addAll(_buildScanResultTiles());
    }



    return new MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: new ThemeData(
        primarySwatch: Colors.blueGrey,
        buttonColor: Colors.blueGrey,
      ),
      home: new Scaffold(

        floatingActionButton: _buildScanningButton(),
        body: new Stack(
          children: <Widget>[
            (isScanning) ? _buildProgressBarTile() : new Container(),
            new Column(
              children: tiles,
            )
          ],
        ),
      ),
    );

    return new Column(
      children: <Widget>[
       _buildProgressBarTile(),
        new Stack(
          children: <Widget>[
            (isScanning) ? _buildProgressBarTile() : new Container(),
            new ListView(
              children: tiles,
            )
          ],
        ),
      ],
    );

    /*
    return new MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(
          actions: _buildActionButtons(),
        ),
        floatingActionButton: _buildScanningButton(),
        body: new Stack(
          children: <Widget>[
            (isScanning) ? _buildProgressBarTile() : new Container(),
            new ListView(
              children: tiles,
            )
          ],
        ),
      ),
    );
*/



  }


  Widget _cameraView(BuildContext context) {
    List<Widget> items = [];




    return new Column(
      children: [
        Spacer(flex: 2),
        Container(

          width: MediaQuery.of(context).size.width * 0.8 ,
          child: new Column (
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                height: MediaQuery.of(context).size.height * 0.01,
                child:  new Text(""),
              ),
              Container(
                height: MediaQuery.of(context).size.height * 0.1,
                child: productName == null ? new Text("") : new Text(productName, textAlign: TextAlign.center, style: new TextStyle(fontFamily: "Rubik", fontSize: 20.0))
              ),
              Container(
                height: MediaQuery.of(context).size.height * 0.01,
                child:  new Text(""),
              ),

            ],
          )
        ),

        Container(
          width: MediaQuery.of(context).size.width * 0.8 ,
          height: MediaQuery.of(context).size.height * 0.4,

          child:
          camState
            ? new Center(
            child: new SizedBox(
              child: vibrating?
              new Container(
                width: MediaQuery.of(context).size.width * 0.8 ,
                height: MediaQuery.of(context).size.height * 0.4,
                decoration: new BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(color: Colors.blueGrey, width: 3.0, style: BorderStyle.solid),
                ),
                child: new Column (
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    new Text("vibrating", style: new TextStyle(
                      fontFamily: "Rubik",
                      fontSize: 20.0), textAlign: TextAlign.center,),
                  ],
                ),


              ):
              new QrCamera(
                onError: (context, error) => Text(
                  error.toString(),
                  style: TextStyle(color: Colors.red),
                ),
                qrCodeCallback: (code) {
                  setState(() {
                    qr = code;
                  });
                },
                child: new Container(
                  decoration: new BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(color: Colors.blueGrey, width: 3.0, style: BorderStyle.solid),
                  ),
                ),
              ),
            ),
          )
            : new Center(child: new Text("Camera inactive", style: new TextStyle( fontSize: 17.0))),
        ),
        Spacer(flex: 1),
        Container(
          child: qr==null? new Text("") : new Text("QRCODE: $qr", style: new TextStyle( fontSize: 15.0)),
        ),
        Spacer(flex: 1),
        Container(
          child: new Row (
            children: <Widget>[
              Expanded(
                flex: 3, // 30%
                child: Container(),
              ),
              Container(
                child: new FloatingActionButton(
                  child: new Icon(Icons.camera_alt),
                  onPressed: () {
                    setState(() {
                      camState = !camState;
                    });
                  }),
              ),
              Spacer(flex: 1),
              Container(
                child: new FloatingActionButton(
                  child: new Icon(Icons.delete_outline),
                  onPressed: () {
                    setState(() {
                      deleteQr();
                    });
                  }),
              ),
              Expanded(
                flex: 3, // 30%
                child: Container(),
              ),


            ],
          )
        ),
        Spacer(flex: 1),


      ],
    );

/*
    items.add(
      camState
        ? new Center(
        child: new SizedBox(
          width: MediaQuery.of(context).size.width * 0.8 ,
          height: MediaQuery.of(context).size.height * 0.5,
          child: new QrCamera(
            onError: (context, error) => Text(
              error.toString(),
              style: TextStyle(color: Colors.red),
            ),
            qrCodeCallback: (code) {
              setState(() {
                qr = code;
              });
            },
            child: new Container(
              decoration: new BoxDecoration(
                color: Colors.transparent,
                border: Border.all(color: Colors.blue, width: 3.0, style: BorderStyle.solid),
              ),
            ),
          ),
        ),
      )
        : new Center(child: new Text("Camera inactive")),
    );

    items.add(
    new Text("QRCODE: $qr"),
    );

    items.add(
      new FloatingActionButton(
        child: new Text(
          "press me",
          textAlign: TextAlign.center,
        ),
        onPressed: () {
          setState(() {
            camState = !camState;
          });
        }),
    );


    return new ListView(
      padding: const EdgeInsets.only(
        top: 12.0,
      ),
      children: items,
    );

    */
  }


  Widget _settings(BuildContext context) {
    return new Container(
      color: Colors.white,
      child: new Center(
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            new Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                new Text("Index finger: ", style: TextStyle(fontWeight: FontWeight.bold)),
                new Container(
                  padding: new EdgeInsets.all(6.0),
                ),
                new Container(

                  color: Colors.blueGrey[50],
                  width: MediaQuery.of(context).size.width * 0.6 ,
                  child: DropdownButtonHideUnderline(
                    child: ButtonTheme(
                      alignedDropdown: true,
                      child: new DropdownButton(

                        value: value1,
                        items: _dropDownMenuItems,
                        onChanged: changedDropDownItem1,
                      ),
                    )
                  )

                ),

                new Container(
                  padding: new EdgeInsets.all(10.0),
                ),
                new Text("Middle finger: ", style: TextStyle(fontWeight: FontWeight.bold)),
                new Container(
                  padding: new EdgeInsets.all(6.0),
                ),
                new Container(
                  color: Colors.blueGrey[50],
                  width: MediaQuery.of(context).size.width * 0.6 ,
                  child: DropdownButtonHideUnderline(
                    child: ButtonTheme(
                      alignedDropdown: true,
                      child: new DropdownButton(

                        value: value2,
                        items: _dropDownMenuItems,
                        onChanged: changedDropDownItem2,
                      ),
                    )
                  )

                ),
                new Container(
                  padding: new EdgeInsets.all(10.0),
                ),
                new Text("Ring finger: ", style: TextStyle(fontWeight: FontWeight.bold)),
                new Container(
                  padding: new EdgeInsets.all(6.0),
                ),
                new Container(

                  color: Colors.blueGrey[50],
                  width: MediaQuery.of(context).size.width * 0.6 ,
                  child: DropdownButtonHideUnderline(
                    child: ButtonTheme(
                      alignedDropdown: true,
                      child: new DropdownButton(

                        value: value3,
                        items: _dropDownMenuItems,
                        onChanged: changedDropDownItem3,
                      ),
                    )
                  )

                ),
                new Container(
                  padding: new EdgeInsets.all(10.0),
                ),
                new Text("Little finger: ", style: TextStyle(fontWeight: FontWeight.bold)),
                new Container(
                  padding: new EdgeInsets.all(6.0),
                ),
                new Container(

                  color: Colors.blueGrey[50],
                  width: MediaQuery.of(context).size.width * 0.6 ,
                  child: DropdownButtonHideUnderline(
                    child: ButtonTheme(
                      alignedDropdown: true,
                      child: new DropdownButton(

                        value: value4,
                        items: _dropDownMenuItems,
                        onChanged: changedDropDownItem4,
                      ),
                    )
                  )

                ),
              ],

            )


          ],
        )
      ),
    );
  }


  List<DropdownMenuItem<String>> getDropDownMenuItems() {
    List<DropdownMenuItem<String>> items = new List();
    for (String value in choice) {
      // here we are creating the drop down menu items, you can customize the item right here
      // but I'll just use a simple text for this
      items.add(new DropdownMenuItem(
        value: value,
        child: new Text(value)
      ));
    }
    return items;
  }

  void changedDropDownItem1(String selectedValue) {
    setState(() {
      value1 = selectedValue;
      indexes[0] = choice.indexOf(selectedValue);
    });
  }
  void changedDropDownItem2(String selectedValue) {
    setState(() {
      value2 = selectedValue;
      indexes[1] = choice.indexOf(selectedValue);
    });
  }
  void changedDropDownItem3(String selectedValue) {
    setState(() {
      value3 = selectedValue;
      indexes[2] = choice.indexOf(selectedValue);
    });
  }
  void changedDropDownItem4(String selectedValue) {
    setState(() {
      value4 = selectedValue;
      indexes[3] = choice.indexOf(selectedValue);
    });
  }




  Future<Null> scanAndVibrate(String barcode) {




    setState(() { vibrating = true; });
    final json = getJSONData(barcode);
    json. then((_) {
      vibrate();
    });
    setState(() { vibrating = false; });
    //vibrate();

    /*
    for(int i = 0; i < choice_bool.length; i++) {
      if (choice_bool[i]) willVibrate = true;
    }
    if(!willVibrate) {
      print("SHOULD STOP!!!");
      await dontVibrate();
      print("SHOULD HAVE STOP!!!");
      return;
    }

    build(context);
    await vibrate();
    vibrating = false;
*/
    /*
    if (willVibrate){
      vibrating = true;
      build(context);
      await vibrate();
      vibrating = false;
    }
    build(context);
    vibrating = false;
    willVibrate = false;
    */
    /*
    await getJSONData(barcode);
    for(int i = 0; i < choice_bool.length; i++) {
      if (choice_bool[i]) willVibrate = true;
    }
    if(willVibrate) {
      vibrating = true;
      await vibrate();
      vibrating = false;
    }
   */
  }

  Future<Null> getJSONData(String barcode) async {


    String url = "https://world.openfoodfacts.org/api/v0/product/"+ barcode + ".json";
    var response = await http.get(
      // Encode the url
      Uri.encodeFull(url),
      // Only accept JSON response
      headers: {"Accept": "application/json"});

    //var data = json.decode(response.body)["code"];

    if (json.decode(response.body)['product']  != null &&
      json.decode(response.body)['product']["ingredients_text_with_allergens_de"] != null) {
      productName = json.decode(response.body)['product']["product_name_de"].toString();
      ingredients = json.decode(response.body)['product']["ingredients_text_with_allergens_de"].toString();
      ingredients = ingredients.toLowerCase();
      print("lala" + ingredients);


      for(int i = 0; i < choice_bool.length; i++) {
        choice_bool[i] = false;
      }

      for( int i = 0; i < glutenList.length; i++) {
        if (ingredients.contains(glutenList[i])) {
          print (glutenList[i] + " yes gluten");
          choice_bool[0] = true;
        }
      }
      for( int i = 0; i < lactoseList.length; i++) {
        if (ingredients.contains(lactoseList[i])) {
          print (lactoseList[i] + " yes laktose");
          choice_bool[1] = true;
        }
      }
      for( int i = 0; i < nonVegetarianList.length; i++) {
        if (ingredients.contains(nonVegetarianList[i])) {
          print (nonVegetarianList[i] + " yes non vegetarian");
          choice_bool[2] = true;
          choice_bool[3] = true;
        }
      }
      if (!nonVegan) {
        for( int i = 0; i < nonVeganList.length; i++) {
          if (ingredients.contains(nonVeganList[i])) {
            print (nonVeganList[i] + " yes non vegan");
            choice_bool[3] = true;
          }
        }
      }


/*
      for(int i = 0; i < choice.length; i++) {
        if (value1 == choice[i] && choice_bool[i]) {
          _writeCharacteristic1(characteristic);
          sleep(const Duration(seconds:1));
          _writeCharacteristic0(characteristic);
          print ( " yes 1");
        }
      }

      for(int i = 0; i < choice.length; i++) {
        if (value2 == choice[i] && choice_bool[i]) {
          _writeCharacteristic2(characteristic);
          sleep(const Duration(seconds:1));
          _writeCharacteristic0(characteristic);
          print ( " yes 2");
        }
      }

      for(int i = 0; i < choice.length; i++) {
        if (value3 == choice[i] && choice_bool[i]) {
          _writeCharacteristic3(characteristic);
          sleep(const Duration(seconds:1));
          _writeCharacteristic0(characteristic);
          print ( " yes 3");
        }
      }

      for(int i = 0; i < choice.length; i++) {
        if (value4 == choice[i] && choice_bool[i]) {
          _writeCharacteristic4(characteristic);
          sleep(const Duration(seconds:1));
          _writeCharacteristic0(characteristic);
          print ( " yes 4");
        }
      }

      print(value1 + " " + value2 + " " + value3 + " " + value4);
*/
    }


    /*
    if (response.statusCode == 200) {
      // If server returns an OK response, parse the JSON
      return Ingredients.fromJson(json.decode(response.body)["product"]["ingredients_text_with_allergens_de"]);
    } else {
      // If that response was not OK, throw an error.
      throw Exception('Failed to load post');
    }
    */
  }

  void dontVibrate() async {
    vibrating = false;
    build(context);
  }
  void vibrate() {

    print(choice[indexes[0]] + " " + choice[indexes[1]] + " " + choice[indexes[2]] + " " + choice[indexes[3]]);



    vibrating = true;

    if(choice_bool[indexes[0]]) {
      _writeCharacteristic(characteristic, [0xffffffff, 0x00000000, 0x00000000 ,0x00000000]);
      sleep(const Duration(seconds:1));
      _writeCharacteristic(characteristic, [0x00000000, 0x00000000, 0x00000000 ,0x00000000]);
      sleep(const Duration(seconds:1));
    }
    if(choice_bool[indexes[1]]) {
      _writeCharacteristic(characteristic, [0x00000000, 0xffffffff, 0x00000000 ,0x00000000]);
      sleep(const Duration(seconds:1));
      _writeCharacteristic(characteristic, [0x00000000, 0x00000000, 0x00000000 ,0x00000000]);
      sleep(const Duration(seconds:1));
    }
    if(choice_bool[indexes[2]]) {
      _writeCharacteristic(characteristic, [0x00000000, 0x00000000, 0xffffffff ,0x00000000]);
      sleep(const Duration(seconds:1));
      _writeCharacteristic(characteristic, [0x00000000, 0x00000000, 0x00000000 ,0x00000000]);
      sleep(const Duration(seconds:1));
    }
    if(choice_bool[indexes[3]]) {
      _writeCharacteristic(characteristic, [0x00000000, 0x00000000, 0x00000000 ,0xffffffff]);
      sleep(const Duration(seconds:1));
      _writeCharacteristic(characteristic, [0x00000000, 0x00000000, 0x00000000 ,0x00000000]);
      sleep(const Duration(seconds:1));
    }




  }

  Future<String> getFileData(String string) async {

    return await rootBundle.loadString(string);
  }

  void readFile() async{
    try {
      String result = await getFileData('assets/Gluten.txt');
      glutenList = result.split(", ");
      for ( int i = 0; i < glutenList.length; i++) {
        glutenList[i] = glutenList[i].toLowerCase ();
      }
      //print(result);
    } catch(e) {
      print(e);
    }

    try {
      String result = await getFileData('assets/Laktose.txt');
      lactoseList = result.split(", ");
      for ( int i = 0; i < lactoseList.length; i++) {
        lactoseList[i] = lactoseList[i].toLowerCase ();
      }
      //print(result);
    } catch(e) {
      print(e);
    }

    try {
      String result = await getFileData('assets/NonVegetarian.txt');
      nonVegetarianList = result.split(", ");
      for ( int i = 0; i < nonVegetarianList.length; i++) {
        nonVegetarianList[i] = nonVegetarianList[i].toLowerCase ();
      }
      //print(result);
    } catch(e) {
      print(e);
    }

    try {
      String result = await getFileData('assets/NonVegan.txt');
      nonVeganList = result.split(", ");
      for ( int i = 0; i < nonVeganList.length; i++) {
        nonVeganList[i] = nonVeganList[i].toLowerCase ();
      }
      //print(result);
    } catch(e) {
      print(e);
    }

  }

}




























// WIDGETS.DART

class ScanResultTile extends StatelessWidget {
  const ScanResultTile({Key key, this.result, this.onTap}) : super(key: key);

  final ScanResult result;
  final VoidCallback onTap;

  Widget _buildTitle(BuildContext context) {
    if (result.device.name.length > 0) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(result.device.name),
          Text(
            result.device.id.toString(),
            style: Theme.of(context).textTheme.caption,
          )
        ],
      );
    } else {
      return Text(result.device.id.toString());
    }
  }

  Widget _buildAdvRow(BuildContext context, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.caption),
          SizedBox(
            width: 12.0,
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context)
                .textTheme
                .caption
                .apply(color: Colors.black),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  String getNiceHexArray(List<int> bytes) {
    return '[${bytes.map((i) => i.toRadixString(16).padLeft(2, '0')).join(', ')}]'
      .toUpperCase();
  }

  String getNiceManufacturerData(Map<int, List<int>> data) {
    if (data.isEmpty) {
      return null;
    }
    List<String> res = [];
    data.forEach((id, bytes) {
      res.add(
        '${id.toRadixString(16).toUpperCase()}: ${getNiceHexArray(bytes)}');
    });
    return res.join(', ');
  }

  String getNiceServiceData(Map<String, List<int>> data) {
    if (data.isEmpty) {
      return null;
    }
    List<String> res = [];
    data.forEach((id, bytes) {
      res.add('${id.toUpperCase()}: ${getNiceHexArray(bytes)}');
    });
    return res.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: _buildTitle(context),
      leading: Text(result.rssi.toString()),
      trailing: RaisedButton(
        child: Text('CONNECT'),
        color: Colors.black,
        textColor: Colors.white,
        onPressed: (result.advertisementData.connectable) ? onTap : null,
      ),
      children: <Widget>[
        _buildAdvRow(
          context, 'Complete Local Name', result.advertisementData.localName),
        _buildAdvRow(context, 'Tx Power Level',
          '${result.advertisementData.txPowerLevel ?? 'N/A'}'),
        _buildAdvRow(
          context,
          'Manufacturer Data',
          getNiceManufacturerData(
            result.advertisementData.manufacturerData) ??
            'N/A'),
        _buildAdvRow(
          context,
          'Service UUIDs',
          (result.advertisementData.serviceUuids.isNotEmpty)
            ? result.advertisementData.serviceUuids.join(', ').toUpperCase()
            : 'N/A'),
        _buildAdvRow(context, 'Service Data',
          getNiceServiceData(result.advertisementData.serviceData) ?? 'N/A'),
      ],
    );
  }
}

class ServiceTile extends StatelessWidget {
  final BluetoothService service;
  final List<CharacteristicTile> characteristicTiles;

  const ServiceTile({Key key, this.service, this.characteristicTiles})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (characteristicTiles.length > 0) {
      return new ExpansionTile(
        title: new Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Service'),
            new Text(
              '0x${service.uuid.toString().toUpperCase().substring(4, 8)}',
              style: Theme.of(context)
                .textTheme
                .body1
                .copyWith(color: Theme.of(context).textTheme.caption.color))
          ],
        ),
        children: characteristicTiles,
      );
    } else {
      return new ListTile(
        title: const Text('Service'),
        subtitle: new Text(
          '0x${service.uuid.toString().toUpperCase().substring(4, 8)}'),
      );
    }
  }
}

class CharacteristicTile extends StatelessWidget {
  final BluetoothCharacteristic characteristic;
  final List<DescriptorTile> descriptorTiles;
  final VoidCallback onReadPressed;
  final VoidCallback onWritePressed;
  final VoidCallback onNotificationPressed;

  const CharacteristicTile(
    {Key key,
      this.characteristic,
      this.descriptorTiles,
      this.onReadPressed,
      this.onWritePressed,
      this.onNotificationPressed})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    var actions = new Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        new IconButton(
          icon: new Icon(
            Icons.file_download,
            color: Theme.of(context).iconTheme.color.withOpacity(0.5),
          ),
          onPressed: onReadPressed,
        ),
        new IconButton(
          icon: new Icon(Icons.file_upload,
            color: Theme.of(context).iconTheme.color.withOpacity(0.5)),
          onPressed: onWritePressed,
        ),
        new IconButton(
          icon: new Icon(
            characteristic.isNotifying ? Icons.sync_disabled : Icons.sync,
            color: Theme.of(context).iconTheme.color.withOpacity(0.5)),
          onPressed: onNotificationPressed,
        )
      ],
    );

    var title = new Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('Characteristic'),
        new Text(
          '0x${characteristic.uuid.toString().toUpperCase().substring(4, 8)}',
          style: Theme.of(context)
            .textTheme
            .body1
            .copyWith(color: Theme.of(context).textTheme.caption.color))
      ],
    );

    if (descriptorTiles.length > 0) {
      return new ExpansionTile(
        title: new ListTile(
          title: title,
          subtitle: new Text(characteristic.value.toString()),
          contentPadding: EdgeInsets.all(0.0),
        ),
        trailing: actions,
        children: descriptorTiles,
      );
    } else {
      return new ListTile(
        title: title,
        subtitle: new Text(characteristic.value.toString()),
        trailing: actions,
      );
    }
  }
}

class DescriptorTile extends StatelessWidget {
  final BluetoothDescriptor descriptor;
  final VoidCallback onReadPressed;
  final VoidCallback onWritePressed;

  const DescriptorTile(
    {Key key, this.descriptor, this.onReadPressed, this.onWritePressed})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    var title = new Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('Descriptor'),
        new Text(
          '0x${descriptor.uuid.toString().toUpperCase().substring(4, 8)}',
          style: Theme.of(context)
            .textTheme
            .body1
            .copyWith(color: Theme.of(context).textTheme.caption.color))
      ],
    );
    return new ListTile(
      title: title,
      subtitle: new Text(descriptor.value.toString()),
      trailing: new Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          new IconButton(
            icon: new Icon(
              Icons.file_download,
              color: Theme.of(context).iconTheme.color.withOpacity(0.5),
            ),
            onPressed: onReadPressed,
          ),
          new IconButton(
            icon: new Icon(
              Icons.file_upload,
              color: Theme.of(context).iconTheme.color.withOpacity(0.5),
            ),
            onPressed: onWritePressed,
          )
        ],
      ),
    );
  }
}
