import 'package:postnow/models/message.dart';
import 'package:postnow/services/chat_service.dart';

class OrderDetailDialogService {
  String _jobId;
  OrderDetailDialogService(this._jobId);
  
  void sendDetails(String message) {
    ChatService.sendMessageStatic(_jobId, Message(from_driver: false, message: message));
  }
}