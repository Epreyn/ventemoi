import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ventemoi/core/models/user.dart';

void main() {
  group('User Model Tests', () {
    test('should create User with all required fields', () {
      final user = User(
        id: 'test123',
        email: 'test@example.com',
        name: 'Test User',
        userTypeID: 'type1',
        imageUrl: 'https://example.com/image.jpg',
        isEnable: true,
        isVisible: true,
        personalAddress: '123 Test Street',
      );

      expect(user.id, 'test123');
      expect(user.email, 'test@example.com');
      expect(user.name, 'Test User');
      expect(user.userTypeID, 'type1');
      expect(user.imageUrl, 'https://example.com/image.jpg');
      expect(user.isEnable, true);
      expect(user.isVisible, true);
      expect(user.personalAddress, '123 Test Street');
    });

    test('should create User with default personalAddress when not provided', () {
      final user = User(
        id: 'test123',
        email: 'test@example.com',
        name: 'Test User',
        userTypeID: 'type1',
        imageUrl: 'https://example.com/image.jpg',
        isEnable: true,
        isVisible: false,
      );

      expect(user.personalAddress, '');
    });

    test('should implement Nameable interface correctly', () {
      final user = User(
        id: 'test123',
        email: 'test@example.com',
        name: 'Test User',
        userTypeID: 'type1',
        imageUrl: '',
        isEnable: true,
        isVisible: true,
      );

      expect(user.id, isNotNull);
      expect(user.name, isNotNull);
    });
  });
}