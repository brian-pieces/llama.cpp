import 'dart:ffi';

import 'package:test/test.dart' show Timeout, contains, expect, isTrue, test;
import 'package:path/path.dart' as p;
import 'dart:io';

import '../dart/chat.dart';
import '../dart/types.dart';

void main() async {
  test('chat test', () async {
    try {
      // Model config
      String modelPath = p.join(Directory.current.path, 'models');
      String modelName = 'llama-2-7b-chat.ggmlv3.q4_K_M.bin';

      // Create chat session
      ChatSession chatSession = ChatSession(modelPath, modelName);

      // Initialize chat session
      chatSession.initialize_chat();

      String input = "You are a helpful assistant for code related tasks. It is likely you will return code examples in your responses. If you include a code example, you must include it in the proper markdown code block syntax and it is critical that you specify the proper code language in the beginning of the markdown code block syntax. How do I add a new internal_server? with 3 new endpoints /hello1, /hello2, and /hello3";

      // Send message
      WrappedChatConverseReturnable wrappedChatConverseReturnable = chatSession
          .converse(input: input);
      expect(wrappedChatConverseReturnable.success, isTrue);

      print("output 1: ${wrappedChatConverseReturnable.data.output}");

      // chatSession.reset();

      // Check reset with another message
      String input2 = "What else can you tell me?";
      WrappedChatConverseReturnable wrappedChatConverseReturnable2 = chatSession
          .converse(input: input2);
      expect(wrappedChatConverseReturnable2.success, isTrue);

      print("output 2: ${wrappedChatConverseReturnable2.data.output}");



      // WrappedChatReset wrappedChatReset = chatSession.reset();
      // expect(wrappedChatReset.success, isTrue);
      //
      // // Free chat session
      // chatSession.free();
      // expect(chatSession.chatSessionPtr, nullptr);
      //
      // // Reinitialize chat session
      // chatSession.initialize_chat();
      // expect(chatSession.chatSessionPtr, isNot(nullptr));
      //
      // // Send another message
      // String input2 = "Write a function that takes a list of numbers and returns the sum of the squares of those numbers";
      // WrappedChatConverseReturnable wrappedChatConverseReturnable2 = chatSession
      //     .converse(input: input2);
      // expect(wrappedChatConverseReturnable2.success, isTrue);
      // print("output 2: ${wrappedChatConverseReturnable2.data.output}");
    } catch (e) {
      if (Platform.isLinux || Platform.isWindows) {
        expect(e.toString(), contains('VK_ERROR_INCOMPATIBLE_DRIVER'));
        return;
      } else {
        throw(Exception('Failed to create chat session: $e'));
      }
    }
  }, timeout: Timeout(Duration(minutes: 3)));
}
