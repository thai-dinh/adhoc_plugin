import 'dart:typed_data';

import 'package:adhoc_plugin/src/appframework/config.dart';
import 'package:adhoc_plugin/src/presentation/key_mgnmt/certificate.dart';
import 'package:adhoc_plugin/src/presentation/key_mgnmt/certificate_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pointycastle/pointycastle.dart';

import 'certificate_test.mocks.dart';


@GenerateMocks([Certificate])
void main() {
  late CertificateRepository repository;
  late List<MockCertificate> list;
  late MockCertificate figurant;
  late MockCertificate mockCertificate;
  late Certificate certificate;

  group('Certificate tests', () {
    setUp(() {
      certificate = Certificate(
        'Owner', 'Issuer', DateTime(2021), RSAPublicKey(BigInt.one, BigInt.two)
      )..signature = Uint8List(1);
    });

    test('Certificate owner should be returned', () {
      expect(certificate.owner, 'Owner');
    });

    test('Certificate issuer should be returned', () {
      expect(certificate.issuer, 'Issuer');
    });

    test('Certificate validity time should be returned', () {
      expect(certificate.validity, DateTime(2021));
    });

    test('Certificate public key should be returned', () {
      expect(certificate.key, RSAPublicKey(BigInt.one, BigInt.two));
    });

    test('Certificate signature should be returned', () {
      expect(certificate.signature, Uint8List(1));
    });

    test('Certificate should not change when toJson() is used', () {
      expect(certificate.toJson(), {
        'owner': 'Owner',
        'issuer': 'Issuer',
        'validity': DateTime(2021).toIso8601String(),
        'key': {
          'modulus': BigInt.one.toString(),
          'exponent': BigInt.two.toString(),
        },
        'signature': Uint8List(1).toList(),
      });
    });

    test('Certificate should be the same when fromJson() is used', () {
      expect(Certificate.fromJson({
        'owner': 'Owner',
        'issuer': 'Issuer',
        'validity': DateTime(2021).toIso8601String(),
        'key': {
          'modulus': BigInt.one.toString(),
          'exponent': BigInt.two.toString(),
        },
        'signature': Uint8List(1).toList(),
      }).toString(), certificate.toString());
    });
  });

  group('Certificate repository tests', () {
    setUp(() {
      repository = CertificateRepository(Config());
      list = List.empty(growable: true);
      figurant = MockCertificate();
      when(figurant.owner).thenReturn('figurant');
      mockCertificate = MockCertificate();
      when(mockCertificate.owner).thenReturn('Owner');
      list..add(figurant)..add(mockCertificate);
    });

    test('Certificate should be added', () {
      repository.addCertificate(mockCertificate);

      expect(repository.containCertificate(mockCertificate.owner), true);
    });

    test('Certificate should be removed', () {
      repository.addCertificate(mockCertificate);
      repository.removeCertificate(mockCertificate.owner);

      expect(repository.containCertificate(mockCertificate.owner), false);
    });

    test('Certificate should be returned', () {
      repository.addCertificate(mockCertificate);
      var returned = repository.getCertificate(mockCertificate.owner)!;

      expect(returned, mockCertificate);
    });

    test('Certificate should be in the repository', () {
      repository.addCertificate(mockCertificate);

      expect(repository.containCertificate(mockCertificate.owner), true);
    });

    test('Certificate should not be in the repository', () {
      expect(repository.containCertificate(mockCertificate.owner), false);
    });

    test('List of certificate should be complete', () {
      repository.addCertificate(figurant);
      repository.addCertificate(mockCertificate);

      expect(repository.certificates.length, list.length);
    });
  });
}
