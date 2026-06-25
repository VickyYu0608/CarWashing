import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:car_washing_app/main.dart';

void main() {
  test('user registers with phone verification and can log in', () {
    final store = AppStore.seeded();

    final user = store.registerUser(
      countryCode: '+86',
      phone: '13900000000',
      verificationCode: '0000',
      password: '123456',
      displayName: '新用户',
    );

    expect(user.username, '+8613900000000');
    expect(user.approvalStatus, ApprovalStatus.approved);
    expect(store.login('+8613900000000', '123456'), isTrue);
  });

  test('shop approval controls whether registered store is visible', () {
    final store = AppStore.seeded();

    final shop = store.registerShop(
      countryCode: '+86',
      phone: '13900000001',
      verificationCode: '1111',
      password: '123456',
      storeName: '新洗车店',
      address: '测试地址',
      latitude: 22.54,
      longitude: 113.93,
      licenseFiles: ['mock-business-license.pdf'],
      serviceTypes: {WashServiceType.selfService},
    );

    expect(store.approvedStores().any((item) => item.name == '新洗车店'), isFalse);
    store.updateAccountApproval(shop, ApprovalStatus.approved);
    expect(store.approvedStores().any((item) => item.name == '新洗车店'), isTrue);
  });

  testWidgets('auth page renders and admin can log in',
      (WidgetTester tester) async {
    await tester.pumpWidget(const CarWashingApp());

    expect(find.text('清洗到家'), findsOneWidget);
    expect(find.text('用户注册'), findsOneWidget);
    expect(find.text('商家注册'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'admin');
    await tester.enterText(find.byType(TextField).at(1), '123456');
    await tester.tap(find.text('登录'));
    await tester.pumpAndSettle();

    expect(find.text('Admin 平台端'), findsOneWidget);
  });

  testWidgets('registration pages render from auth page',
      (WidgetTester tester) async {
    await tester.pumpWidget(const CarWashingApp());

    await tester.tap(find.text('用户注册'));
    await tester.pumpAndSettle();
    expect(find.text('用户注册'), findsOneWidget);
    expect(find.text('验证码（测试填写 0000）'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('商家注册'));
    await tester.pumpAndSettle();
    expect(find.text('商家注册'), findsOneWidget);
    expect(find.text('验证码（测试填写 1111）'), findsOneWidget);
  });
}
