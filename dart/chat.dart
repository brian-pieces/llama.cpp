import 'dart:async';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:dynamic_library/dynamic_library.dart' show loadDynamicLibrary;
import 'package:path/path.dart';

import 'types.dart';

class ChatSession {
  late DynamicLibrary lib;

  // Native functions
  late ChatInitFunc _chatInit;
  late LoadModelFunc _loadModel;
  late ConverseFunc _chatConverse;
  late ResetFunc _chatReset;
  late FreeChatDartFunc _freeChat;

  // Chat session pointer
  late Pointer<Void> chatSessionPtr;

  bool modelLoaded = false;

  late String modelPath;
  late String modelName;

  // Timeout timer
  Timer? _timeoutTimer;


  // On construction, load the native library and initialize the ORT instance.
  // Pass the path to the model file and the ONNX data types for the input nodes.
  ChatSession(String modelPath, String modelName) {
    // Load helper libraries
    // loadDynamicLibrary(libraryName: 'tvm_runtime', searchPath: 'build');
    // loadDynamicLibrary(libraryName: 'mlc_llm', searchPath: 'build');

    // Load chat library
    lib = loadDynamicLibrary(
        libraryName: 'llamacpp_chat', searchPath: 'build');

    // Get native functions
    _chatInit =
        lib.lookup<NativeFunction<ChatInitFunc>>('chat_init').asFunction();
    _loadModel =
        lib.lookup<NativeFunction<LoadModelFunc>>('load_model').asFunction();
    _chatConverse =
        lib.lookup<NativeFunction<ConverseFunc>>('chat_converse').asFunction();
    _chatReset =
        lib.lookup<NativeFunction<ResetFunc>>('chat_reset').asFunction();
    _freeChat =
        lib.lookup<NativeFunction<FreeChatCFunc>>('chat_free').asFunction();

    this.modelPath = modelPath;
    this.modelName = modelName;

    // Initialize the backend
    WrappedChatInitC wrappedChatInitC = _chatInit(join(modelPath, modelName).toNativeUtf8());
    WrappedChatInit wrappedChatInit = WrappedChatInit(wrappedChatInitC);
    if (wrappedChatInit.success == false) {
      throw Exception(
          'Failed to create chat session: ${wrappedChatInit.error}');
    }
    chatSessionPtr = wrappedChatInit.data;
  }

  // Initialize
  void initialize_chat() {
    // Load model
    WrappedLoadModelC wrappedLoadModelC = _loadModel(chatSessionPtr);

    if (wrappedLoadModelC.success == false) {
      throw Exception(
          'Failed to load model: ${wrappedLoadModelC.error}');
    }

    modelLoaded = true;

    // Reset timeout timer
    _resetTimeoutTimer();
  }


  // Converse
  WrappedChatConverseReturnable converse({required String input}) {
    // Reset timeout timer
    _resetTimeoutTimer();

    // Check if chat session is initialized
    if (!modelLoaded) {
      print('Chat session not initialized');
      // Initialize chat session
      initialize_chat();
    }

    // Convert input to C string
    Pointer<Utf8> inputPtr = input.toNativeUtf8();

    WrappedChatConverseReturnableC wrappedChatConverseReturnableC =
        _chatConverse(chatSessionPtr, inputPtr);
    WrappedChatConverseReturnable wrappedChatConverseReturnable =
        WrappedChatConverseReturnable(wrappedChatConverseReturnableC);

    return wrappedChatConverseReturnable;
  }

  // Reset
  WrappedChatReset reset() {
    WrappedChatResetC wrappedChatResetC;

    wrappedChatResetC = _chatReset(chatSessionPtr);
    WrappedChatReset wrappedChatReset = WrappedChatReset(wrappedChatResetC);

    return wrappedChatReset;
  }

  void _resetTimeoutTimer() {
    // Cancel the existing timer if there is one
    _timeoutTimer?.cancel();

    // Set up a new timer that frees the chat session memory after set time
    _timeoutTimer = Timer(Duration(minutes: 2), free);

    print('timer reset');
  }

  // Free
  void free() {
    print('Freeing chat session...');
    _freeChat(chatSessionPtr);
    modelLoaded = false;
  }
}
