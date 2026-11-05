// Chat message value type, split out of chat_screen.dart to keep
// that file under the 250-line cap. No UI, no grounding logic.
class ChatMsg {
  ChatMsg(this.text, this.isUser, [this.saveId]);
  final String text;
  final bool isUser;
  final String? saveId;
}
