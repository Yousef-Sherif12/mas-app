import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:masjid_app/features/ticker/data/models/ticker_message_model.dart';
import 'package:masjid_app/features/ticker/domain/entities/ticker_message.dart';
import 'package:masjid_app/features/ticker/domain/repositories/ticker_repository.dart';

class TickerRepositoryImpl implements TickerRepository {
  final FirebaseFirestore _db;

  TickerRepositoryImpl({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<TickerMessage>> listenToTickerMessages() {
    return _db
        .collection('ticker_messages')
        .orderBy('order')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => TickerMessageModel.fromMap({
                  'id': doc.id,
                  ...doc.data(),
                }),
              )
              .toList(),
        );
  }
}
