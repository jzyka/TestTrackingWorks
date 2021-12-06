import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/service_config.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';


class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final String baseUrl = 'https://krista-staging.trackingworks.io';
  int _currentIndex = 0;
  var selectedCard = 'WEIGHT';
  String _shiftDate = '-';
  String _shiftPeriod = '-';
  List<CardItems> items = [];

  List<Widget> _widgetOptions = <Widget>[];
  bool _isLoading = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initializeDateFormatting();
    DateFormat formatter = DateFormat('EEE, d MMM yyyy', 'id');
    _shiftDate = formatter.format(DateTime.now());

    items = items = [
      CardItems(
        title: '0',
        timer: '0 Jam 0 Menit',
        absent: 'Hadir',
        color: Colors.teal.shade50,
        colors: Colors.greenAccent.shade400,
      ),
      CardItems(
        title: '0',
        timer: '0 Jam 0 Menit',
        absent: 'Keluar awal',
        color: Colors.orange.shade50,
        colors: Colors.orangeAccent,
      ),
      CardItems(
        title: '0',
        timer: '0 Jam 0 Menit',
        absent: 'Terlambat',
        color: Colors.blueGrey.shade50,
        colors: Colors.blueGrey.shade300,
      ),
      CardItems(
        title: '0',
        timer: '0 Jam 0 Menit',
        absent: 'Cuti',
        color: Colors.blue.shade50,
        colors: Colors.blueAccent.shade100,
      ),
      CardItems(
        title: '0',
        timer: '0 Jam 0 Menit',
        absent: 'Tidak Hadir',
        color: Colors.red.shade100,
        colors: Colors.red,
      ),
      CardItems(
        title: '0',
        timer: '0 Jam 0 Menit',
        absent: 'Libur',
        color: Colors.purple.shade100,
        colors: Colors.purple,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Image.asset(
              'assets/logo.png'
            ),
            Flexible(fit: FlexFit.tight, child: SizedBox()),
            Text('ESCA HRIS',
              style: TextStyle(
                color:Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: FutureBuilder<bool>(
        future: _getSchedule(),
        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return Center(child: CircularProgressIndicator());
            default:
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                return _buildBody();
              }
          }
        },
      ),


      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        iconSize: 20,
        selectedFontSize: 13.0,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            title: Text('Home'),
            backgroundColor: Colors.white,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task_outlined),
            title: Text('Tugas'),
            backgroundColor: Colors.white,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            title: Text('Laporan'),
            backgroundColor: Colors.white,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            title: Text('Profile'),
            backgroundColor: Colors.white,
          ),
        ],
        onTap: (index){
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Future<bool> _getSchedule() async {
    try {
      var res = await ServiceConfig().getSchedule(context);
      if (res is String) {
        return false;
      } else {
        var response = jsonDecode(res.body);
        String start = response['data'][0]['shift']['time_start'];
        String end = response['data'][0]['shift']['time_end'];
        start = start.substring(0, start.length - 3);
        end = end.substring(0, end.length - 3);
        _shiftPeriod = '$start - $end';
        return true;
      }
    } catch (e) {
      final snackBar = ServiceConfig().buildSnackbar(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      return false;
    }
  }

  Widget buildCard({
    required CardItems items,
  }) =>
      Column(
        children: [
          Container(
            padding: EdgeInsets.only(left: 12, top: 10, bottom: 15, right: 30),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: items.color,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  items.title,
                  style: TextStyle(
                    color: items.colors,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  items.timer,
                  style: TextStyle(
                    color: items.colors,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 5),
                Row(
                  children: [
                    Icon(
                      Icons.date_range,
                      size: 12,
                      color: items.colors,
                    ),
                    SizedBox(width: 5),
                    Text(
                      items.absent,
                      style: TextStyle(
                        color: items.colors,
                        fontSize: 12
                      ),
                    )
                  ],
                ),
              ],
            ),
          )
        ],
      );

  Widget _buildUserInfo (String imgPath, String Userame, String email) {
    return Padding(
        padding: EdgeInsets.only(right: 10.0,),
        child: InkWell(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Container(
                    child: Row(
                        children: [
                          Hero(
                              tag: imgPath,
                              child: Image(
                                  image: AssetImage(imgPath),
                                  fit: BoxFit.cover,
                                  height: 50.0,
                                  width: 50.0
                              )
                          ),
                          SizedBox(width: 10.0),
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children:[
                                Text(
                                    Userame,
                                    style: TextStyle(
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.bold
                                    )
                                ),
                                Text(
                                    email,
                                    style: TextStyle(
                                        fontSize: 12.0,
                                        color: Colors.grey
                                    )
                                )
                              ]
                          )
                        ]
                    )
                ),
              ],
            )
        ));
  }

  Widget _buildBody() {
    return Column(
      children: [
        Container(
          height: MediaQuery.of(context).size.height - 465.0,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30.0), bottomRight: Radius.circular(30.0)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 0,
                blurRadius: 8.0,
                offset: Offset(0, 7), // changes position of shadow
              ),
            ],
          ),

          child: ListView(
            primary: false,
            padding: EdgeInsets.only(left: 25.0, right: 20.0),
            children: <Widget>[
              Padding(padding: EdgeInsets.only(top: 20.0),
                child: Container(
                  height: MediaQuery.of(context).size.height - 300.0,
                  child: ListView(children: [
                    Row(
                      children: [
                        Text(_shiftDate,
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Flexible(fit: FlexFit.tight, child: SizedBox()),
                        Text(_shiftPeriod,
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        SizedBox(height: 10),
                        _buildUserInfo('assets/ava.png', "Halo, Lorem", "lorem@gmail.com"),
                        SizedBox(height: 20),
                        Container(
                          height: 41,
                          width: 335,
                          child: ElevatedButton(onPressed: () async {
                            setState(() {
                              _isLoading = true;
                            });
                            await ServiceConfig().postAttendance(context);
                            setState(() {
                              _isLoading = false;
                            });
                          }, child: Text("Jam Masuk")),
                        ),
                      ],
                    ),
                  ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          child: Row(
            children: [
              Container(
                margin:EdgeInsets.only(left: 20, top: 10),
                child: Text("Simpulan Kehadiran (Nov 2021)",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              Flexible(fit: FlexFit.tight, child: SizedBox()),
              Container(
                margin: EdgeInsets.only(top: 10),
                child: TextButton(onPressed: () {},
                  child: const Text("Lihat Semua",
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Column(
            children: [
              Container(
                height: 117,
                child: ListView.separated(
                    itemCount: 6,
                    separatorBuilder: (context, _) => SizedBox(
                      width: 12,
                    ),
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) =>
                        buildCard(items: items[index])
                ),
              )],
          ),
        ),
        Container(
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin:EdgeInsets.only(left: 20,top: 5),
                    child: Text("Test Description Notice",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15
                      ),
                    ),
                  ),
                  Container(
                    margin:EdgeInsets.only(left: 20),
                    child: Text("26 November 2021",
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              Flexible(fit: FlexFit.tight, child: SizedBox()),
              IconButton(onPressed: () {},
                  icon: Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey,
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

class CardItems {
  final String title;
  final String timer;
  final String absent;
  final Color color;
  final Color colors;

  const CardItems({
    required this.title,
    required this.timer,
    required this.absent,
    required this.color,
    required this.colors,
  });

}
