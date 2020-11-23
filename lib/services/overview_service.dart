import 'package:firebase_database/firebase_database.dart';
import 'package:postnow/models/address.dart';
import 'package:postnow/models/job.dart';

class OverviewService {
  final String uid;
  final DatabaseReference _jobsRef = FirebaseDatabase.instance.reference().child('completed-jobs');
  DatabaseReference _userRef;
  List<Job> orders = List();

  OverviewService(this.uid) {
    _userRef = FirebaseDatabase.instance.reference().child('users').child(uid);
  }

  List<Address> getLastAddresses(String searchText) {
    List<Address> addresses = List();

    checkAddress(Address tmp) {
      if (!tmp.alakadar(searchText))
        return;
      bool check = true;
      for (int x = 0; x < addresses.length; x++) {
        if (addresses[x] == tmp) {
          check = false;
          break;
        }
      }
      if (check)
        addresses.add(tmp);
    }

    for(int i = 0; i < orders.length; i++) {
      Address tmp = orders[i].getAddress(true);
      Address tmp2 = orders[i].getAddress(false);
      checkAddress(tmp);
      checkAddress(tmp2);
    }

    return addresses;
  }

  Future<void> initOrderList() async {
    List<Future> futures = List<Future>();
    await _userRef.child("orders").once().then((snapshot) => {
      if (snapshot.value != null) {
        snapshot.value.forEach((k1, v1) {
          v1.forEach((k2, v2) {
            v2.forEach((k3, v3) {
              futures.add(_findJob(k1, k2, v3));
            });
          });
        })
      }
    });
    await Future.wait(futures);
    orders.sort();
  }

  Future<void> _findJob(c1, c2, c3) async {
    await _jobsRef.child(c1).child(c2).child(c3).once().then((snapshot) => {
      orders.add(Job.fromSnapshot(snapshot)),
    });
  }
}