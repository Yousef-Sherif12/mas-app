import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:masjid_app/features/ticker/domain/entities/ticker_message.dart';
import 'package:masjid_app/features/ticker/domain/repositories/ticker_repository.dart';
import 'package:masjid_app/features/ticker/presentation/cubit/ticker_state.dart';

class TickerCubit extends Cubit<TickerState> {
  final TickerRepository _repository;
  StreamSubscription<List<TickerMessage>>? _subscription;

  TickerCubit(this._repository) : super(const TickerState());

  void startListening() {
    _subscription?.cancel();
    _subscription = _repository.listenToTickerMessages().listen((messages) {
      if (!isClosed) {
        emit(TickerState(messages: messages));
      }
    });
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
