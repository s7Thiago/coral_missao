import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Exceção customizada formatada para operações no Firestore.
class FirestoreException implements Exception {
  final String message;
  final dynamic originalError;

  FirestoreException(this.message, [this.originalError]);

  @override
  String toString() {
    if (originalError != null) {
      final origStr = originalError.toString().replaceAll(RegExp(r'^Exception:\s*'), '');
      return '$message: $origStr';
    }
    return message;
  }
}

/// Serviço genérico e reutilizável para operações de CRUD no Firebase Firestore.
/// Possui suporte reativo para notificar a interface quando operações assíncronas estão ativas.
class FirestoreService {
  final FirebaseFirestore _db;
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier<bool>(false);
  int _activeOperationsCount = 0;

  FirestoreService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  /// Expõe a instância direta do Firestore caso seja necessária para operações customizadas avançadas.
  FirebaseFirestore get instance => _db;

  /// Notifier reativo que indica se há alguma operação assíncrona do Firestore em andamento.
  ValueNotifier<bool> get isLoadingNotifier => _isLoadingNotifier;

  /// Retorna síncronamente se há alguma operação em andamento.
  bool get isLoading => _isLoadingNotifier.value;

  void _startOperation() {
    _activeOperationsCount++;
    if (_activeOperationsCount == 1) {
      _isLoadingNotifier.value = true;
    }
  }

  void _endOperation() {
    _activeOperationsCount--;
    if (_activeOperationsCount <= 0) {
      _activeOperationsCount = 0;
      _isLoadingNotifier.value = false;
    }
  }

  /// Wrapper utilitário que monitora e rastreia a execução de qualquer chamada assíncrona do Firestore.
  Future<T> _trackAsync<T>(Future<T> Function() action) async {
    _startOperation();
    try {
      return await action();
    } finally {
      _endOperation();
    }
  }

  // ===========================================================================
  // CREATION / UPDATE (Escrita)
  // ===========================================================================

  Future<String> addDocument({
    required String collectionPath,
    required Map<String, dynamic> data,
    String? docId,
    bool merge = true,
  }) async {
    return _trackAsync(() async {
      try {
        if (docId != null && docId.isNotEmpty) {
          await _db
              .collection(collectionPath)
              .doc(docId)
              .set(data, SetOptions(merge: merge));
          return docId;
        } else {
          final docRef = await _db.collection(collectionPath).add(data);
          return docRef.id;
        }
      } catch (e) {
        throw FirestoreException('Erro ao adicionar documento em [$collectionPath]', e);
      }
    });
  }

  Future<void> setDocument({
    required String collectionPath,
    required String docId,
    required Map<String, dynamic> data,
    bool merge = true,
  }) async {
    return _trackAsync(() async {
      try {
        await _db
            .collection(collectionPath)
            .doc(docId)
            .set(data, SetOptions(merge: merge));
      } catch (e) {
        throw FirestoreException('Erro ao atualizar documento [$docId] em [$collectionPath]', e);
      }
    });
  }

  Future<void> updateDocument({
    required String collectionPath,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    return _trackAsync(() async {
      try {
        await _db.collection(collectionPath).doc(docId).update(data);
      } catch (e) {
        throw FirestoreException('Erro ao atualizar campos do documento [$docId] em [$collectionPath]', e);
      }
    });
  }

  // ===========================================================================
  // DELETE (Remoção)
  // ===========================================================================

  Future<void> deleteDocument({
    required String collectionPath,
    required String docId,
  }) async {
    return _trackAsync(() async {
      try {
        await _db.collection(collectionPath).doc(docId).delete();
      } catch (e) {
        throw FirestoreException('Erro ao deletar documento [$docId] em [$collectionPath]', e);
      }
    });
  }

  // ===========================================================================
  // READ (Leitura pontual - Future)
  // ===========================================================================

  Future<Map<String, dynamic>?> getDocument({
    required String collectionPath,
    required String docId,
  }) async {
    return _trackAsync(() async {
      try {
        final docSnap = await _db.collection(collectionPath).doc(docId).get();
        if (!docSnap.exists || docSnap.data() == null) return null;
        final data = docSnap.data()!;
        data['id'] = docSnap.id;
        return data;
      } catch (e) {
        throw FirestoreException('Erro ao buscar documento [$docId] em [$collectionPath]', e);
      }
    });
  }

  Future<T?> getDocumentAs<T>({
    required String collectionPath,
    required String docId,
    required T Function(Map<String, dynamic> data, String id) builder,
  }) async {
    final data = await getDocument(collectionPath: collectionPath, docId: docId);
    if (data == null) return null;
    return builder(data, docId);
  }

  Future<List<Map<String, dynamic>>> getCollection({
    required String collectionPath,
    Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>> query)? queryBuilder,
  }) async {
    return _trackAsync(() async {
      try {
        Query<Map<String, dynamic>> query = _db.collection(collectionPath);
        if (queryBuilder != null) {
          query = queryBuilder(query);
        }
        final querySnap = await query.get();
        return querySnap.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
      } catch (e) {
        throw FirestoreException('Erro ao buscar coleção [$collectionPath]', e);
      }
    });
  }

  Future<List<T>> getCollectionAs<T>({
    required String collectionPath,
    required T Function(Map<String, dynamic> data, String id) builder,
    Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>> query)? queryBuilder,
  }) async {
    final listMap = await getCollection(
      collectionPath: collectionPath,
      queryBuilder: queryBuilder,
    );
    return listMap.map((map) => builder(map, map['id'] as String)).toList();
  }

  // ===========================================================================
  // STREAMS (Escuta em Tempo Real)
  // ===========================================================================

  Stream<Map<String, dynamic>?> streamDocumentRaw({
    required String collectionPath,
    required String docId,
  }) {
    return _db.collection(collectionPath).doc(docId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      final data = snapshot.data()!;
      data['id'] = snapshot.id;
      return data;
    });
  }

  Stream<T?> streamDocument<T>({
    required String collectionPath,
    required String docId,
    required T Function(Map<String, dynamic> data, String id) builder,
  }) {
    return streamDocumentRaw(collectionPath: collectionPath, docId: docId).map(
      (data) => data != null ? builder(data, docId) : null,
    );
  }

  Stream<List<Map<String, dynamic>>> streamCollectionRaw({
    required String collectionPath,
    Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>> query)? queryBuilder,
  }) {
    Query<Map<String, dynamic>> query = _db.collection(collectionPath);
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  Stream<List<T>> streamCollection<T>({
    required String collectionPath,
    required T Function(Map<String, dynamic> data, String id) builder,
    Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>> query)? queryBuilder,
  }) {
    return streamCollectionRaw(
      collectionPath: collectionPath,
      queryBuilder: queryBuilder,
    ).map((list) {
      return list.map((map) => builder(map, map['id'] as String)).toList();
    });
  }

  // ===========================================================================
  // UTILITÁRIOS & TRANSAÇÕES
  // ===========================================================================

  FieldValue get serverTimestamp => FieldValue.serverTimestamp();
  WriteBatch batch() => _db.batch();

  Future<T> runTransaction<T>(TransactionHandler<T> transactionHandler) {
    return _trackAsync(() async {
      return await _db.runTransaction(transactionHandler);
    });
  }
}
