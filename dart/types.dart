import 'dart:ffi';
import 'package:ffi/ffi.dart' show Utf8, Utf8Pointer;

class ChatConverseReturnable {
  late final String output;
  ChatConverseReturnable(ChatConverseReturnableC struct) {
    output = struct.output.toDartString();
  }
}

class ChatConverseReturnableC extends Struct {
  external Pointer<Utf8> output;
}

class WrappedChatConverseReturnableC extends Struct {
  @Bool()
  external bool success;
  external Pointer<Utf8> error;
  external ChatConverseReturnableC data;
}

class WrappedChatConverseReturnable {
  late final bool success;
  late final String error;
  late final ChatConverseReturnable data;

  WrappedChatConverseReturnable(WrappedChatConverseReturnableC struct) {
    success = struct.success;
    error = struct.error != nullptr ? struct.error.toDartString() : '';
    data = ChatConverseReturnable(struct.data);
  }
}

class WrappedChatInit {
  late final bool success;
  late final String error;
  late final Pointer<Void> data;

  WrappedChatInit(WrappedChatInitC struct) {
    success = struct.success;
    error = struct.error != nullptr ? struct.error.toDartString() : '';
    data = struct.data;
  }
}

class WrappedChatInitC extends Struct {
  @Bool()
  external bool success;
  external Pointer<Utf8> error;
  external Pointer<Void> data;
}

class WrappedLoadModel {
  late final bool success;
  late final String error;

  WrappedLoadModel(WrappedLoadModelC struct) {
    success = struct.success;
    error = struct.error != nullptr ? struct.error.toDartString() : '';
  }
}

class WrappedLoadModelC extends Struct {
  @Bool()
  external bool success;
  external Pointer<Utf8> error;
}

class WrappedChatReset {
  late final bool success;
  late final String error;

  WrappedChatReset(WrappedChatResetC struct) {
    success = struct.success;
    error = struct.error != nullptr ? struct.error.toDartString() : '';
  }
}

class WrappedChatResetC extends Struct {
  @Bool()
  external bool success;
  external Pointer<Utf8> error;
}

// Init
typedef ChatInitFunc = WrappedChatInitC Function(Pointer<Utf8> modelPath);

// Load model
typedef LoadModelFunc = WrappedLoadModelC Function(Pointer<Void> ptr);

// Converse
typedef ConverseFunc = WrappedChatConverseReturnableC Function(Pointer<Void> ptr,
    Pointer<Utf8> input);

// Reset
typedef ResetFunc = WrappedChatResetC Function(Pointer<Void> ptr);

// Free
typedef FreeChatCFunc = Void Function(Pointer<Void> ptr);
typedef FreeChatDartFunc = void Function(Pointer<Void> ptr);
