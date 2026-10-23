import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Replica de `_ChangePermissionsPageState._labelForRole`
String labelForRole(String role) {
  switch (role) {
    case 'doctor':
      return 'Médico';
    case 'receptionist':
      return 'Rececionista';
    case 'admin':
      return 'Admin';
    default:
      return 'Paciente';
  }
}

/// Replica de `_ChangePermissionsPageState._avatarBgForRole`
Color avatarBgForRole(String role) {
  switch (role) {
    case 'doctor':
      return const Color(0xFF64B5F6);
    case 'receptionist':
      return const Color(0xCCBA7517);
    case 'admin':
      return const Color(0xCC6A9890);
    default:
      return const Color(0xCC3DBDAD);
  }
}


//  TESTES
void main() {

  //  _labelForRole
  group('change_permissions - _labelForRole', () {
    // TESTE 1 - todos os roles têm label correto em PT
    // Um label errado confundiria o admin ao selecionar o nível de acesso.
    test('devolve label correto para cada role', () {
      expect(labelForRole('patient'), 'Paciente');
      expect(labelForRole('doctor'), 'Médico');
      expect(labelForRole('receptionist'), 'Rececionista');
      expect(labelForRole('admin'), 'Admin');
    });

    // TESTE 2 - role desconhecido cai no default (Paciente = menor acesso)
    test('role desconhecido devolve "Paciente" como default seguro', () {
      expect(labelForRole('unknown'), 'Paciente');
    });
  });


  //  _avatarBgForRole
  group('change_permissions - _avatarBgForRole', () {
    // TESTE 3 - cores de avatar distintas por role
    // Garante diferenciação visual ao listar utilizadores com roles diferentes.
    test('devolve cores distintas para roles diferentes', () {
      final patient = avatarBgForRole('patient');
      final doctor = avatarBgForRole('doctor');
      final recep = avatarBgForRole('receptionist');
      final admin = avatarBgForRole('admin');

      expect(patient, isNot(equals(doctor)));
      expect(patient, isNot(equals(recep)));
      expect(patient, isNot(equals(admin)));
      expect(doctor, isNot(equals(recep)));
      expect(doctor, isNot(equals(admin)));
      expect(recep, isNot(equals(admin)));
    });

    // TESTE 4 - role desconhecido usa cor padrão de paciente
    test('role desconhecido usa cor padrão de paciente', () {
      expect(avatarBgForRole('unknown'), avatarBgForRole('patient'));
    });
  });
}
