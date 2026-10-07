import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../listings/domain/listing.dart';
import '../data/chat_repository.dart';
import '../domain/chat.dart';

class ChatState {
  const ChatState({this.conversations = const [], this.loading = false, this.error});

  final List<Conversation> conversations;

  /// Primera carga de la bandeja en curso (los refrescos en segundo plano no la activan).
  final bool loading;

  /// Mensaje de error de la bandeja; solo se muestra si no hay nada que enseñar.
  final String? error;

  ChatState copyWith({List<Conversation>? conversations, bool? loading, Object? error = _keep}) => ChatState(
        conversations: conversations ?? this.conversations,
        loading: loading ?? this.loading,
        error: identical(error, _keep) ? this.error : error as String?,
      );

  static const _keep = Object();
}

/// Chat contra la API con polling (sin WebSockets por ahora: no cuestan nada y
/// funcionan en Render gratis). La bandeja se refresca cada 15 s mientras hay
/// sesión; la pantalla de una conversación pide mensajes nuevos cada pocos segundos.
class ChatController extends Notifier<ChatState> {
  static const _inboxEvery = Duration(seconds: 15);

  int _tmp = 0;
  String? _openId;

  @override
  ChatState build() {
    final user = ref.watch(authProvider);
    if (user == null) return const ChatState();

    final timer = Timer.periodic(_inboxEvery, (_) => refresh());
    ref.onDispose(timer.cancel);
    Future.microtask(() => refresh(initial: true));
    return const ChatState(loading: true);
  }

  Conversation? byId(String id) {
    for (final c in state.conversations) {
      if (c.id == id) return c;
    }
    return null;
  }

  void _update(String id, Conversation Function(Conversation c) fn) {
    if (!ref.mounted) return;
    state = state.copyWith(conversations: [for (final c in state.conversations) c.id == id ? fn(c) : c]);
  }

  /// Marca qué conversación está abierta en pantalla: sus mensajes se leen al
  /// llegar, así que su contador de no leídos no debe volver a subir.
  void setOpen(String? id) => _openId = id;

  /// Baja la bandeja. Conserva los mensajes ya cargados de cada conversación.
  Future<void> refresh({bool initial = false}) async {
    if (ref.read(authProvider) == null) return;
    if (initial && ref.mounted) state = state.copyWith(loading: true, error: null);
    try {
      final fresh = await ref.read(chatRepositoryProvider).conversations();
      if (!ref.mounted) return;
      final old = {for (final c in state.conversations) c.id: c};
      state = ChatState(
        conversations: [
          for (final c in fresh)
            old[c.id] == null
                ? c
                : c.copyWith(
                    messages: old[c.id]!.messages,
                    messagesLoaded: old[c.id]!.messagesLoaded,
                    unread: c.id == _openId ? 0 : c.unread,
                  ),
        ],
      );
    } catch (e) {
      if (ref.mounted) state = state.copyWith(loading: false, error: '$e');
    }
  }

  /// Abre (o crea) la conversación ligada a una publicación. Lanza ApiException
  /// si el servidor la rechaza (p. ej. es tu propia publicación).
  Future<String> openFor(Listing l) async {
    final conv = await ref.read(chatRepositoryProvider).open(l.id);
    if (ref.mounted && byId(conv.id) == null) {
      state = state.copyWith(conversations: [conv, ...state.conversations]);
    }
    return conv.id;
  }

  /// Descarga mensajes: todos en la primera carga, solo los nuevos después (`after_id`).
  /// Devuelve false si falló (la pantalla decide si lo muestra; el polling lo ignora).
  Future<bool> loadMessages(String id) async {
    final conv = byId(id);
    if (conv == null) return false;
    try {
      final incoming = await ref.read(chatRepositoryProvider).messages(id, afterId: conv.lastServerId);
      if (!ref.mounted) return false;
      _update(id, (c) {
        final known = {for (final m in c.messages) m.id};
        final merged = [
          ...c.messages.where((m) => !m.isLocal),
          ...incoming.where((m) => !known.contains(m.id)),
        ]..sort((a, b) => (int.tryParse(a.id) ?? 0).compareTo(int.tryParse(b.id) ?? 0));
        // Los pendientes/fallidos siguen al final hasta que el servidor responda.
        final local = c.messages.where((m) => m.isLocal);
        return c.copyWith(messages: [...merged, ...local], messagesLoaded: true, unread: 0);
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Envío optimista: el mensaje aparece al instante como pendiente y se reemplaza
  /// por el del servidor; si falla queda marcado para reintentar.
  Future<void> sendText(String convId, String text) async {
    final conv = byId(convId);
    if (conv == null) return;
    final tmpId = 'tmp-${_tmp++}';
    final local = ChatMessage(id: tmpId, mine: true, at: DateTime.now(), text: text, pending: true);
    _update(convId, (c) => c.copyWith(
          messages: [...c.messages, local],
          lastText: text,
          lastMine: true,
          lastAt: local.at,
        ));
    await _deliver(convId, tmpId, text);
  }

  Future<void> retry(String convId, String tmpId) async {
    final msg = byId(convId)?.messages.where((m) => m.id == tmpId).firstOrNull;
    if (msg == null) return;
    _update(convId, (c) => c.copyWith(
          messages: [for (final m in c.messages) m.id == tmpId ? m.copyWith(pending: true, failed: false) : m],
        ));
    await _deliver(convId, tmpId, msg.text);
  }

  Future<void> _deliver(String convId, String tmpId, String text) async {
    try {
      final sent = await ref.read(chatRepositoryProvider).send(convId, text);
      _update(convId, (c) {
        // El polling pudo traer ya este mensaje antes de que llegara la respuesta del POST.
        final alreadyThere = c.messages.any((m) => m.id == sent.id);
        final rest = c.messages.where((m) => m.id != tmpId);
        return c.copyWith(messages: [...rest, if (!alreadyThere) sent]
          ..sort(_byServerOrder));
      });
    } catch (_) {
      _update(convId, (c) => c.copyWith(
            messages: [for (final m in c.messages) m.id == tmpId ? m.copyWith(pending: false, failed: true) : m],
          ));
    }
  }

  /// Confirmados por id; los locales (aún sin id de servidor) siempre al final.
  static int _byServerOrder(ChatMessage a, ChatMessage b) {
    if (a.isLocal != b.isLocal) return a.isLocal ? 1 : -1;
    if (a.isLocal) return 0;
    return (int.tryParse(a.id) ?? 0).compareTo(int.tryParse(b.id) ?? 0);
  }
}

final chatProvider = NotifierProvider<ChatController, ChatState>(ChatController.new);

final conversationProvider = Provider.family<Conversation?, String>((ref, id) {
  for (final c in ref.watch(chatProvider).conversations) {
    if (c.id == id) return c;
  }
  return null;
});

final unreadCountProvider = Provider<int>(
  (ref) => ref.watch(chatProvider).conversations.fold(0, (sum, c) => sum + c.unread),
);
