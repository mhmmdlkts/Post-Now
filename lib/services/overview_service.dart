import 'package:firebase_database/firebase_database.dart';
import 'package:postnow/models/job.dart';

class OverviewService {
  final String uid;
  DatabaseReference _jobsRef, _userRef;
  List<Job> orders = List();

  OverviewService(this.uid) {
    _jobsRef = FirebaseDatabase.instance.reference().child('completed-jobs');
    _userRef = FirebaseDatabase.instance.reference().child('users').child(uid);
  }

  Future<void> initOrderList() async {
    List<Future> futures = List<Future>();
    await _userRef.child("orders").once().then((snapshot) => {
      snapshot.value.forEach((k1, v1) {
        v1.forEach((k2, v2) {
          futures.add(findJob(k1, k2, v2));
        });
      })
    });
    await Future.wait(futures);
  }

  Future<void> findJob(c1, c2, c3) async {
    await _jobsRef.child(c1).child(c2).child(c3).once().then((snapshot) => {
      orders.add(Job.fromSnapshot(snapshot)),
    });
  }
}