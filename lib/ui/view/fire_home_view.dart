import 'package:flutter/material.dart';
import 'package:postnow/core/service/firebase_service.dart';
import 'package:postnow/core/service/model/user.dart';

class FireHomeView extends StatefulWidget {
  @override
  _FireHomeViewState createState() => _FireHomeViewState();
}

class _FireHomeViewState extends State<FireHomeView> {
  FirebaseService service;

  @override
  void initState() {
    super.initState();
    service = FirebaseService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: userFutureBuilder,
    );
  }

  Widget get userFutureBuilder => FutureBuilder<List<User>>(
    future: service.getUsers(),
    builder: (context, snapshot) {
      if(snapshot == null)
        print("hm");
      switch (snapshot.connectionState) {
        case ConnectionState.done:
          if (snapshot.hasData) return _listUser(snapshot.data);
          else return _notFoundWidget();
          break;
        default:
          return _waitingWidget();
      }
    },);

  Widget _listUser(List<User> users) {
    return ListView.builder(itemCount: users.length, itemBuilder: (context, index) => _userCard(users[index]));
  }

  Widget _userCard(User user) {
    return Card(
      child: ListTile(
        title: Text(user.name),
        subtitle: Text(user.phone),
      ),
    );
  }

  Widget _notFoundWidget() => Center(child: Text("Not Found"),);
  Widget _waitingWidget() => Center(child: CircularProgressIndicator(),);
}
