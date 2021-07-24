import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:synchronized/extension.dart';

import 'middleware_types.dart';
import '../session.dart';

/// Middleware that handles secure communication
Future<dynamic> encryptionMiddleware(
  dynamic session,
  dynamic message,
  MiddlewareAction action,
  Future<dynamic> Function(dynamic) next,
) async {
  final _CryptoProvider provider = session.storage['crypto_provider'] ?? _CryptoProvider(session);

  // Redirect handshaking messages to the crypto provider
  if (_isHandshakeMsg(message)) {
    // Received handshaking messages are captured
    if (action == MiddlewareAction.receive) {
      provider(message);
      return null;
    }

    // Handshaking messages are not blocked nor passed to other middleware
    return message;
  }

  // Wait for secure channel to be established
  await provider.established;

  if (action == MiddlewareAction.receive) {
    // We catch all errors here as we can't trust the incoming data
    try {
      // Decrypt the message so other middleware can work with it
      message = await provider.decrypt(message);
    } catch (e) {
      session.raise(e);
      return null;
    }

    return await next(message);
  } else {
    // Let other middleware work with the message, finally encrypt it
    return await provider.encrypt(await next(message));
  }
}

/// Check if message belongs to handshaking protocol
bool _isHandshakeMsg(String msg) {
  return msg.startsWith(_CryptoConstants.prefix);
}

/// Class that handles secure communication
/// between client and server.
///
/// Every session has it's own instance of this class.
/// It normally lives in `session.storage['crypto_provider']`
class _CryptoProvider {
  /// Algorithm used for key exchange
  static final X25519 keyExchangeAlgo = Cryptography.instance.x25519();

  /// Algorithm used for encryption
  static final AesGcm encryptionAlgo = Cryptography.instance.aesGcm();

  /// This future finishes when the handshaking is done and a secure connection is established
  Future<void> get established => _completer.future;

  /// Completer that allows awaiting secure connection
  final Completer<void> _completer = Completer<void>();

  /// Future that completes once the own key pair is available
  late final Future<void> _ready;

  /// Own public key as string
  late final String _publicKeyStr;

  /// The session this provider is handling
  final Session _session;

  /// Our own key pair (private + public)
  late SimpleKeyPair _ownKeyPair;

  /// The generated shared key
  SecretKey? _sharedKey;

  _CryptoProvider(this._session) {
    // Install ourselves to the session
    _session.storage['crypto_provider'] = this;

    // Start handshaking on object creation
    _ready = _initHandshake();
  }

  //* General use

  /// Encrypt the given [message] with the preestablished shared key
  Future<String> encrypt(String message) async {
    // Generate a new nonce (has to be unique every message!)
    final List<int> nonce = _CryptoProvider.encryptionAlgo.newNonce();

    // Encrypt the message
    final SecretBox box = await _CryptoProvider.encryptionAlgo.encrypt(
      utf8.encode(message),
      secretKey: _sharedKey!,
      nonce: nonce,
    );

    return box.concatenation().join('-');
  }

  /// Decrypt the given [message] with the preestablished shared key
  Future<String> decrypt(String message) async {
    // Recreate SecretBox
    final SecretBox box = SecretBox.fromConcatenation(
      message.split('-').map((e) => int.parse(e)).toList(),
      nonceLength: 12,
      macLength: 16,
    );

    // Decrypt message
    final List<int> clearText = await _CryptoProvider.encryptionAlgo.decrypt(
      box,
      secretKey: _sharedKey!,
    );

    return utf8.decode(clearText);
  }

  //* Handshaking
  /// Handle handshaking responses
  void call(String message) async {
    // Wait for own key
    await _ready;

    //? We can not trust the other party -> catch all errors
    try {
      // Synchronize access to avoid multiple shared keys
      await synchronized<void>(() async {
        // Check if shared key not already established
        if (_completer.isCompleted) {
          throw HandshakeException(
            'Received crypto message after secure connection was established',
          );
        }

        // Remove the prefix ($) from the message
        message = message.substring(_CryptoConstants.prefix.length);

        // Determine msg type
        if (message.startsWith(_CryptoConstants.keyResponse) && _session is ClientSession) {
          await _handleKeyResponse(message, _CryptoConstants.keyResponse);
        } else if (message.startsWith(_CryptoConstants.keyRequest) && _session is ServerSession) {
          // Send own public key
          _session.send(_CryptoConstants.prefix + _CryptoConstants.keyResponse + _publicKeyStr);

          // Generate shared key with remote public key
          await _handleKeyResponse(message, _CryptoConstants.keyRequest);
        } else {
          throw HandshakeException("Invalid crypto message: '$message'");
        }
      });
    } catch (e) {
      _session.raise(e);
    }
  }

  /// Start to handshakes with the other party
  Future<void> _initHandshake() async {
    // Generate our own key pair
    _ownKeyPair = await _CryptoProvider.keyExchangeAlgo.newKeyPair();
    _publicKeyStr = (await _ownKeyPair.extractPublicKey()).bytes.join('-');

    // Request the other party's public key (only on client side)
    if (_session is ClientSession) {
      _session.send(_CryptoConstants.prefix + _CryptoConstants.keyRequest + _publicKeyStr);
    }
  }

  /// Handle the response to our key request
  Future<void> _handleKeyResponse(String message, String prefix) async {
    // Extract the public key
    final publicKeyStr = message.substring(prefix.length);

    // Check if the public key is valid (format)
    if (!_CryptoConstants.keyRegex.hasMatch(publicKeyStr)) {
      throw HandshakeException('Received publicKey is invalid');
    }

    // Construct actual public key
    final publicKey = SimplePublicKey(
      publicKeyStr.split('-').map((e) => int.parse(e)).toList(),
      type: KeyPairType.x25519,
    );

    // Establish shared key
    _sharedKey = await _CryptoProvider.keyExchangeAlgo.sharedSecretKey(
      keyPair: _ownKeyPair,
      remotePublicKey: publicKey,
    );

    // Complete the handshake
    _completer.complete();
  }
}

/// Common shared variables for crypto
class _CryptoConstants {
  static const String prefix = r'$';
  static const String keyRequest = 'KEY_REQUEST';
  static const String keyResponse = 'KEY_RESPONSE';
  static final keyRegex = RegExp(r'^(?:[\d]{0,3}-){31}[\d]{0,3}$');
}
