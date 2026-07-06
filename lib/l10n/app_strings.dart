import 'package:car_washing_app/l10n/app_locale.dart';
// ignore: unused_import
import 'package:flutter/material.dart';

class AppStrings {
  AppStrings(this.locale);

  final AppLocale locale;

  static AppStrings current = AppStrings(AppLocale.zhHans);

  String t(String key) {
    return _data[locale]?[key] ?? _data[AppLocale.en]![key] ?? key;
  }

  // ── App & login ──────────────────────────────────────────────────────────
  String get appTitle => t('appTitle');
  String get appTagline => t('appTagline');
  String get welcomeLogin => t('welcomeLogin');
  String get loginRoleHint => t('loginRoleHint');
  String get phoneOrTestAccount => t('phoneOrTestAccount');
  String get phoneLoginHint => t('phoneLoginHint');
  String get password => t('password');
  String get login => t('login');
  String get loggingIn => t('loggingIn');
  String get userRegister => t('userRegister');
  String get shopRegister => t('shopRegister');
  String get demoAccounts => t('demoAccounts');
  String get demoUser => t('demoUser');
  String get demoShop => t('demoShop');
  String get demoAdmin => t('demoAdmin');
  String get accountMismatch => t('accountMismatch');
  String get accountPending => t('accountPending');
  String get accountRejected => t('accountRejected');
  String get backendUnreachable => t('backendUnreachable');
  String get syncingData => t('syncingData');
  String get syncFailedHint => t('syncFailedHint');
  String get retrySync => t('retrySync');
  String get languageTitle => t('languageTitle');

  // ── Tabs ─────────────────────────────────────────────────────────────────
  String get tabCarWash => t('tabCarWash');
  String get tabPackages => t('tabPackages');
  String get tabOrders => t('tabOrders');
  String get tabProfile => t('tabProfile');
  String get tabStores => t('tabStores');
  String get tabReservations => t('tabReservations');
  String get tabMine => t('tabMine');
  String get tabApproval => t('tabApproval');
  String get tabOverview => t('tabOverview');
  String get tabStoresAdmin => t('tabStoresAdmin');
  String get tabReservationsAdmin => t('tabReservationsAdmin');
  String get tabOrdersAdmin => t('tabOrdersAdmin');
  String get tabPricing => t('tabPricing');

  // ── Car wash home ────────────────────────────────────────────────────────
  String get carWashTitle => t('carWashTitle');
  String get carWashSubtitle => t('carWashSubtitle');
  String get myLocation => t('myLocation');
  String get nearbyStores => t('nearbyStores');
  String get noStores => t('noStores');
  String get noStoresDesc => t('noStoresDesc');
  String get runningOrderTitle => t('runningOrderTitle');
  String get runningOrderSubtitle => t('runningOrderSubtitle');
  String get locationLoading => t('locationLoading');
  String get locationDisabled => t('locationDisabled');
  String get locationDenied => t('locationDenied');
  String get locationFailed => t('locationFailed');
  String get locationSuccess => t('locationSuccess');
  String get viewMap => t('viewMap');
  String get googleNav => t('googleNav');
  String get reserveStore => t('reserveStore');
  String get scanWash => t('scanWash');
  String get idleCount => t('idleCount');

  // ── Packages ─────────────────────────────────────────────────────────────
  String get buyPackages => t('buyPackages');
  String get buyPackagesSubtitle => t('buyPackagesSubtitle');
  String get myWashCredits => t('myWashCredits');
  String get selectPackage => t('selectPackage');
  String get buyNow => t('buyNow');
  String get recentUsage => t('recentUsage');
  String get noUsageHistory => t('noUsageHistory');
  String get noUsageHistoryDesc => t('noUsageHistoryDesc');
  String get packagePaymentHint => t('packagePaymentHint');
  String get purchaseFailed => t('purchaseFailed');
  String get creditsLine => t('creditsLine');

  // ── Cashier / scan ───────────────────────────────────────────────────────
  String get cashierTitle => t('cashierTitle');
  String get scanCarWashTitle => t('scanCarWashTitle');
  String get scanCarWashSubtitle => t('scanCarWashSubtitle');
  String get rescan => t('rescan');
  String get selectPackageLabel => t('selectPackageLabel');
  String get actualAmount => t('actualAmount');
  String get useFreeWashOn => t('useFreeWashOn');
  String get useFreeWashOff => t('useFreeWashOff');
  String get useFreeWashSubtitleOn => t('useFreeWashSubtitleOn');
  String get useFreeWashSubtitleOff => t('useFreeWashSubtitleOff');
  String get usePrepaidOn => t('usePrepaidOn');
  String get usePrepaidOff => t('usePrepaidOff');
  String get usePrepaidSubtitleOn => t('usePrepaidSubtitleOn');
  String get usePrepaidSubtitleOff => t('usePrepaidSubtitleOff');
  String get prepaidUsedNotice => t('prepaidUsedNotice');
  String get unknownQr => t('unknownQr');

  // ── User orders ──────────────────────────────────────────────────────────
  String get myOrdersTitle => t('myOrdersTitle');
  String get myOrdersSubtitle => t('myOrdersSubtitle');
  String get noOrdersTitle => t('noOrdersTitle');
  String get noOrdersDesc => t('noOrdersDesc');

  // ── Profile & settings ─────────────────────────────────────────────────
  String get personalCenter => t('personalCenter');
  String get personalCenterSubtitle => t('personalCenterSubtitle');
  String get logout => t('logout');
  String get settingsTitle => t('settingsTitle');
  String get nickname => t('nickname');
  String get phone => t('phone');
  String get newPasswordOptional => t('newPasswordOptional');
  String get autoUseFreeWash => t('autoUseFreeWash');
  String get settingsSaved => t('settingsSaved');
  String get save => t('save');
  String get saving => t('saving');

  // ── Shop merchant ────────────────────────────────────────────────────────
  String get shopMerchantTitle => t('shopMerchantTitle');
  String get shopMerchantSubtitle => t('shopMerchantSubtitle');
  String get addNewStore => t('addNewStore');
  String get reservationFormTitle => t('reservationFormTitle');
  String get reservationFormSubtitle => t('reservationFormSubtitle');
  String get shopOrdersTitle => t('shopOrdersTitle');
  String get shopOrdersSubtitle => t('shopOrdersSubtitle');
  String get noReservationsTitle => t('noReservationsTitle');
  String get noReservationsDesc => t('noReservationsDesc');
  String get noOrdersShopTitle => t('noOrdersShopTitle');
  String get noOrdersShopDesc => t('noOrdersShopDesc');
  String get collected => t('collected');
  String get pendingPay => t('pendingPay');
  String get completedOrders => t('completedOrders');

  // ── Admin ────────────────────────────────────────────────────────────────
  String get adminPlatformTitle => t('adminPlatformTitle');
  String get adminPlatformSubtitle => t('adminPlatformSubtitle');
  String get accountManagementTitle => t('accountManagementTitle');
  String get accountManagementSubtitle => t('accountManagementSubtitle');
  String get approve => t('approve');
  String get rejectAndReply => t('rejectAndReply');
  String get reviewReply => t('reviewReply');
  String get rejectAndSend => t('rejectAndSend');
  String get allStoresFilter => t('allStoresFilter');
  String get userAccounts => t('userAccounts');
  String get shopAccounts => t('shopAccounts');
  String get exitLogin => t('exitLogin');

  // ── Roles & approval ─────────────────────────────────────────────────────
  String get roleUser => t('roleUser');
  String get roleShop => t('roleShop');
  String get roleAdmin => t('roleAdmin');
  String get approvalPending => t('approvalPending');
  String get approvalApproved => t('approvalApproved');
  String get approvalRejected => t('approvalRejected');

  // ── Order status ─────────────────────────────────────────────────────────
  String get orderStatusCreated => t('orderStatusCreated');
  String get orderStatusPaid => t('orderStatusPaid');
  String get orderStatusStarting => t('orderStatusStarting');
  String get orderStatusRunning => t('orderStatusRunning');
  String get orderStatusCompleted => t('orderStatusCompleted');
  String get orderStatusFailed => t('orderStatusFailed');
  String get orderStatusRefunded => t('orderStatusRefunded');

  // ── Device status ────────────────────────────────────────────────────────
  String get deviceIdle => t('deviceIdle');
  String get deviceBusy => t('deviceBusy');
  String get deviceOffline => t('deviceOffline');
  String get deviceFaulted => t('deviceFaulted');

  // ── Service types ────────────────────────────────────────────────────────
  String get selfService => t('selfService');
  String get manualService => t('manualService');
  String get selfServiceEco => t('selfServiceEco');

  // ── Reservation status ───────────────────────────────────────────────────
  String get resPending => t('resPending');
  String get resArrived => t('resArrived');
  String get resCompleted => t('resCompleted');
  String get resCancelled => t('resCancelled');

  // ── User reservations ────────────────────────────────────────────────────
  String get myReservations => t('myReservations');
  String get myReservationsSubtitle => t('myReservationsSubtitle');
  String get noStoresToReserve => t('noStoresToReserve');
  String get noReservationsYet => t('noReservationsYet');
  String get noReservationsYetDesc => t('noReservationsYetDesc');
  String get newReservation => t('newReservation');
  String get selectStore => t('selectStore');
  String get reservationDate => t('reservationDate');
  String get reservationTime => t('reservationTime');
  String get contactPhone => t('contactPhone');
  String get reservationType => t('reservationType');
  String get reservationNote => t('reservationNote');
  String get submitReservation => t('submitReservation');

  // ── Reservation pages ────────────────────────────────────────────────────
  String get reserveVisitTitle => t('reserveVisitTitle');
  String get selectReservationType => t('selectReservationType');
  String get createReservationPage => t('createReservationPage');

  // ── Payment methods ──────────────────────────────────────────────────────
  String get paymentMethodAlipay => t('paymentMethodAlipay');
  String get paymentMethodWechat => t('paymentMethodWechat');
  String get paymentMethodApplePay => t('paymentMethodApplePay');
  String get paymentMethodCreditCard => t('paymentMethodCreditCard');
  String get paymentMethodAlipaySub => t('paymentMethodAlipaySub');
  String get paymentMethodWechatSub => t('paymentMethodWechatSub');
  String get paymentMethodApplePaySub => t('paymentMethodApplePaySub');
  String get paymentMethodCreditCardSub => t('paymentMethodCreditCardSub');
  String get paymentProviderAlipay => t('paymentProviderAlipay');
  String get paymentProviderWechat => t('paymentProviderWechat');
  String get paymentProviderApplePay => t('paymentProviderApplePay');
  String get paymentProviderBank => t('paymentProviderBank');
  String get paymentCancelled => t('paymentCancelled');

  // ── Payment & checkout ───────────────────────────────────────────────────
  String get confirmPayment => t('confirmPayment');
  String get cancelPayment => t('cancelPayment');
  String get confirmContinue => t('confirmContinue');
  String get packagePrices => t('packagePrices');
  String get addBay => t('addBay');
  String get addStorePage => t('addStorePage');
  String get submitNewStore => t('submitNewStore');
  String get storeSubmitted => t('storeSubmitted');
  String get simulatePayAndStart => t('simulatePayAndStart');
  String get finishWash => t('finishWash');
  String get orderFlowLabel => t('orderFlowLabel');
  String get paymentMethodLabel => t('paymentMethodLabel');
  String get transactionIdLabel => t('transactionIdLabel');
  String get paidAtLabel => t('paidAtLabel');
  String get minutesUnit => t('minutesUnit');
  String get washPackagePrices => t('washPackagePrices');
  String get addWashBay => t('addWashBay');
  String get setIdle => t('setIdle');
  String get setOffline => t('setOffline');
  String get setFault => t('setFault');
  String get bayNameLabel => t('bayNameLabel');
  String get addBayButton => t('addBayButton');
  String get storeNameLabel => t('storeNameLabel');
  String get storeAddressLabel => t('storeAddressLabel');
  String get latitude => t('latitude');
  String get longitude => t('longitude');
  String get licenseMaterials => t('licenseMaterials');
  String get serviceTypes => t('serviceTypes');
  String get modifyMaterials => t('modifyMaterials');
  String get materialsResubmitted => t('materialsResubmitted');
  String get shopReviewTitle => t('shopReviewTitle');
  String get adminReply => t('adminReply');
  String get merchantLicense => t('merchantLicense');
  String get userRegTitle => t('userRegTitle');
  String get shopRegTitle => t('shopRegTitle');
  String get merchantName => t('merchantName');
  String get merchantAddress => t('merchantAddress');
  String get merchantPhone => t('merchantPhone');
  String get smsCode => t('smsCode');
  String get emailLabel => t('emailLabel');
  String get emailVerificationCode => t('emailVerificationCode');
  String get friendReferralCode => t('friendReferralCode');
  String get registerLogin => t('registerLogin');
  String get shopRegSubmitted => t('shopRegSubmitted');
  String get noCountryMatch => t('noCountryMatch');
  String get homeLabel => t('homeLabel');
  String get standardWashDemo => t('standardWashDemo');
  String get withdrawToAlipay => t('withdrawToAlipay');
  String get sharePanelTitle => t('sharePanelTitle');
  String get copyShareCode => t('copyShareCode');
  String get copyShareText => t('copyShareText');
  String get freeWashCreditsLabel => t('freeWashCreditsLabel');
  String get orderInProgress => t('orderInProgress');
  String get clickForDetails => t('clickForDetails');
  String get mapLoading => t('mapLoading');
  String get adminPricingTitle => t('adminPricingTitle');
  String get editPackage => t('editPackage');
  String get packageUpdated => t('packageUpdated');
  String get saveFailed => t('saveFailed');
  String get userAccountMgmt => t('userAccountMgmt');
  String get shopAccountMgmt => t('shopAccountMgmt');
  String get viewLicenseMaterials => t('viewLicenseMaterials');
  String get storesAndBays => t('storesAndBays');
  String get allReservationsAdmin => t('allReservationsAdmin');
  String get allOrdersAdmin => t('allOrdersAdmin');
  String get personalSettingsPage => t('personalSettingsPage');
  String get merchantPhoneFixed => t('merchantPhoneFixed');
  String get licenseUpload => t('licenseUpload');
  String get addStoreBtn => t('addStoreBtn');
  String get addressLabel => t('addressLabel');
  String get serviceSummary => t('serviceSummary');
  String get modifyPackageTitle => t('modifyPackageTitle');
  String get cancelBtn => t('cancelBtn');
  String get saveBtn => t('saveBtn');
  String get emptyStateDefault => t('emptyStateDefault');

  String get materialsResubmittedAdminReply => t('materialsResubmittedAdminReply');

  String get errInvalidLatLng => t('errInvalidLatLng');

  String get errSelectOneService => t('errSelectOneService');

  String get errFillRequired => t('errFillRequired');

  String get errFillContactPhone => t('errFillContactPhone');

  String get errServiceTypeUnsupported => t('errServiceTypeUnsupported');

  String get errDeviceNotIdle => t('errDeviceNotIdle');

  String get errOrderNotPayable => t('errOrderNotPayable');

  String get errOrderNotFound => t('errOrderNotFound');

  String get errNoPrepaidWash => t('errNoPrepaidWash');

  String get errNoFreeWash => t('errNoFreeWash');

  String get errCannotUseBothCredits => t('errCannotUseBothCredits');

  String get errDeviceUnavailable => t('errDeviceUnavailable');

  String get errDeviceQrNotFound => t('errDeviceQrNotFound');

  String get errInsufficientBalance => t('errInsufficientBalance');

  String get errWithdrawPositive => t('errWithdrawPositive');

  String get errLoginAsShopMerchant => t('errLoginAsShopMerchant');

  String get errReferralSelf => t('errReferralSelf');

  String get errReferralInvalid => t('errReferralInvalid');

  String get errReferralUsed => t('errReferralUsed');

  String get errUserOnlyReferral => t('errUserOnlyReferral');

  String get errAccountExists => t('errAccountExists');

  String get errFillComplete => t('errFillComplete');

  String get errShopOnlyEditProfile => t('errShopOnlyEditProfile');

  String get errLoginAsShop => t('errLoginAsShop');

  String get errShopOnlyResubmit => t('errShopOnlyResubmit');

  String get errUploadLicense => t('errUploadLicense');

  String get errSmsCode1111 => t('errSmsCode1111');

  String get errFillPhone => t('errFillPhone');
  String get errFillEmail => t('errFillEmail');

  String get errSmsCode0000 => t('errSmsCode0000');

  String get errPackageNotFound => t('errPackageNotFound');

  String get errLoginAsUser => t('errLoginAsUser');

  String get completedOrdersLabel => t('completedOrdersLabel');

  String get shopOrdersEmptyDesc => t('shopOrdersEmptyDesc');

  String get addNewShopBtn => t('addNewShopBtn');

  String get selectReservationTypeLabel => t('selectReservationTypeLabel');

  String get simulatePayStart => t('simulatePayStart');

  String get redeemedFreeWash => t('redeemedFreeWash');

  String get defaultRejectMessage => t('defaultRejectMessage');

  String get rejectReplyPlaceholder => t('rejectReplyPlaceholder');

  String get approvedDefaultReply => t('approvedDefaultReply');

  String get shopRegSubmittedAdmin => t('shopRegSubmittedAdmin');

  String get manualBayLabel => t('manualBayLabel');

  String get selfServiceBayLabel => t('selfServiceBayLabel');

  String get bayTypeLabel => t('bayTypeLabel');

  String get bayNameExample => t('bayNameExample');

  String get setIdleOnline => t('setIdleOnline');

  String get addWashBaySlot => t('addWashBaySlot');

  String get storeRejectedReview => t('storeRejectedReview');

  String get storePendingReview => t('storePendingReview');

  String get metricFaultDevices => t('metricFaultDevices');

  String get metricMapPoints => t('metricMapPoints');

  String get packagePriceUpdated => t('packagePriceUpdated');

  String get durationFormatInvalid => t('durationFormatInvalid');

  String get durationMinLabel => t('durationMinLabel');

  String get manualServiceDetailHint => t('manualServiceDetailHint');

  String get reservationNotePlaceholder => t('reservationNotePlaceholder');

  String get locationFailedHkFallback => t('locationFailedHkFallback');

  String get locationSuccessSorted => t('locationSuccessSorted');

  String get locationDeniedHkFallback => t('locationDeniedHkFallback');

  String get locationDisabledHkFallback => t('locationDisabledHkFallback');

  String get locationLoadingDots => t('locationLoadingDots');

  String get defaultUserLabel => t('defaultUserLabel');

  String get defaultCarWashStore => t('defaultCarWashStore');

  String get freeWashLabel => t('freeWashLabel');

  String get selectPackageRequired => t('selectPackageRequired');

  String get selectDeviceQr => t('selectDeviceQr');

  String get confirmStartWash => t('confirmStartWash');

  String get processingLabel => t('processingLabel');

  String get actualPaymentLabel => t('actualPaymentLabel');

  String get useFreeWashSubtitlePay => t('useFreeWashSubtitlePay');

  String get currentDeviceLabel => t('currentDeviceLabel');

  String get scanPayTitle => t('scanPayTitle');

  String get registerShopOnMap => t('registerShopOnMap');

  String get submittingLabel => t('submittingLabel');

  String get merchantPhoneNumber => t('merchantPhoneNumber');

  String get addressGeocodedOk => t('addressGeocodedOk');

  String get smsCodeSent => t('smsCodeSent');
  String get emailCodeSent => t('emailCodeSent');

  String get fillPhoneFirst => t('fillPhoneFirst');
  String get fillEmailFirst => t('fillEmailFirst');
  String get invalidEmailFormat => t('invalidEmailFormat');

  String get referralCodeOptional => t('referralCodeOptional');

  String get getVerificationCode => t('getVerificationCode');

  String get fullNameLabel => t('fullNameLabel');

  String get materialsResubmittedWait => t('materialsResubmittedWait');

  String get resubmitForReview => t('resubmitForReview');

  String get merchantLicensePermit => t('merchantLicensePermit');

  String get shopRegReviewTitle => t('shopRegReviewTitle');

  String get geocodeCoordsUpdated => t('geocodeCoordsUpdated');

  String get noDialCodeMatch => t('noDialCodeMatch');

  String get searchCountryHint => t('searchCountryHint');

  String get countryCodeLabel => t('countryCodeLabel');

  String get storeFilterLabel => t('storeFilterLabel');

  String get adminOrdersEmptyDesc => t('adminOrdersEmptyDesc');

  String get adminReservationsEmptyDesc => t('adminReservationsEmptyDesc');

  String get storesAndBaysSubtitle => t('storesAndBaysSubtitle');

  String get refreshFromBackend => t('refreshFromBackend');

  String get adminOverviewSubtitle => t('adminOverviewSubtitle');

  String get shopReservationsEmptyDesc => t('shopReservationsEmptyDesc');

  String get reservationFormShopSubtitle => t('reservationFormShopSubtitle');

  String get reservationFormShopTitle => t('reservationFormShopTitle');

  String get scanOnHomeHint => t('scanOnHomeHint');

  String get noOrdersYet => t('noOrdersYet');

  String get myOrdersSubtitleTrack => t('myOrdersSubtitleTrack');

  String get noStoresToReserveDesc => t('noStoresToReserveDesc');

  String get reservationRecords => t('reservationRecords');

  // ── User profile extras ──────────────────────────────────────────────────
  String get myVehicles => t('myVehicles');
  String get addVehicle => t('addVehicle');
  String get commonAddresses => t('commonAddresses');
  String get addAddress => t('addAddress');
  String get washCreditsCard => t('washCreditsCard');
  String get myPoints => t('myPoints');
  String get allOrders => t('allOrders');
  String get myVehiclesTitle => t('myVehiclesTitle');
  String get noVehicles => t('noVehicles');
  String get vehicleModel => t('vehicleModel');
  String get plateNumber => t('plateNumber');
  String get colorOptional => t('colorOptional');
  String get commonAddressesTitle => t('commonAddressesTitle');
  String get noAddresses => t('noAddresses');
  String get addressLabelHint => t('addressLabelHint');
  String get detailedAddress => t('detailedAddress');
  String get addBtn => t('addBtn');
  String get fillCompleteInfo => t('fillCompleteInfo');
  String get contactCustomerService => t('contactCustomerService');
  String get termsOfService => t('termsOfService');
  String get buyPackageLink => t('buyPackageLink');
  String get newPasswordLeaveBlank => t('newPasswordLeaveBlank');

  // ── Customer service & terms ─────────────────────────────────────────────
  String get customerServiceTitle => t('customerServiceTitle');
  String get hqPhoneTitle => t('hqPhoneTitle');
  String get hqPhoneHours => t('hqPhoneHours');
  String get onlineMessage => t('onlineMessage');
  String get messageHint => t('messageHint');
  String get messageSubmitted => t('messageSubmitted');
  String get submitMessage => t('submitMessage');
  String get termsTitle => t('termsTitle');
  String get termsHeading => t('termsHeading');
  String get termsBody => t('termsBody');

  // ── Order tabs ───────────────────────────────────────────────────────────
  String get tabAll => t('tabAll');
  String get tabUnpaid => t('tabUnpaid');
  String get tabInProgress => t('tabInProgress');
  String get tabCompleted => t('tabCompleted');
  String get noOrdersAll => t('noOrdersAll');
  String get noOrdersUnpaidTitle => t('noOrdersUnpaidTitle');
  String get noOrdersInProgressTitle => t('noOrdersInProgressTitle');
  String get noOrdersCompletedTitle => t('noOrdersCompletedTitle');
  String get noOrdersAllHint => t('noOrdersAllHint');
  String get noOrdersUnpaidHint => t('noOrdersUnpaidHint');
  String get noOrdersInProgressHint => t('noOrdersInProgressHint');
  String get noOrdersCompletedHint => t('noOrdersCompletedHint');
  String get selfServiceOrdersSubtitle => t('selfServiceOrdersSubtitle');
  String get defaultWashPackage => t('defaultWashPackage');
  String get washStoreFallback => t('washStoreFallback');
  String get creditsUsedOnce => t('creditsUsedOnce');

  // ── Share & referral ─────────────────────────────────────────────────────
  String get shareGiftTitle => t('shareGiftTitle');
  String get shareBeforeFirstWash => t('shareBeforeFirstWash');
  String get shareToFriends => t('shareToFriends');
  String get shareCodeBenefit => t('shareCodeBenefit');
  String get shareCodeCopied => t('shareCodeCopied');
  String get shareTextCopied => t('shareTextCopied');
  String get shareAndFreeWash => t('shareAndFreeWash');
  String get remainingCountLabel => t('remainingCountLabel');
  String get usedCountLabel => t('usedCountLabel');
  String get shareSuccessCountLabel => t('shareSuccessCountLabel');
  String get shareBenefitDetail => t('shareBenefitDetail');
  String get invitedFriends => t('invitedFriends');
  String get redeemShareCode => t('redeemShareCode');
  String get enterFriendShareCode => t('enterFriendShareCode');
  String get redeemSuccess => t('redeemSuccess');
  String get redeemShareCodeBtn => t('redeemShareCodeBtn');

  // ── Shop wallet & reviews ──────────────────────────────────────────────────
  String get myWallet => t('myWallet');
  String get withdrawableBalance => t('withdrawableBalance');
  String get withdraw => t('withdraw');
  String get incomeDetails => t('incomeDetails');
  String get noTransactions => t('noTransactions');
  String get withdrawAmount => t('withdrawAmount');
  String get enterValidAmount => t('enterValidAmount');
  String get withdrawSubmitted => t('withdrawSubmitted');
  String get confirmWithdraw => t('confirmWithdraw');
  String get myReviews => t('myReviews');
  String get noReviews => t('noReviews');
  String get scanQrAlignHint => t('scanQrAlignHint');

  // ── Admin approval ───────────────────────────────────────────────────────
  String get approvalCenter => t('approvalCenter');
  String get allClear => t('allClear');
  String get shopAccountReview => t('shopAccountReview');
  String get noPendingShopAccounts => t('noPendingShopAccounts');
  String get storeReview => t('storeReview');
  String get noPendingStores => t('noPendingStores');
  String get clearedBadge => t('clearedBadge');
  String get reviewBtn => t('reviewBtn');
  String get approveSegment => t('approveSegment');
  String get rejectSegment => t('rejectSegment');
  String get approvalCommentOptional => t('approvalCommentOptional');
  String get submitApproval => t('submitApproval');
  String get defaultMerchantName => t('defaultMerchantName');
  String get defaultStoreName => t('defaultStoreName');
  String get operatingLicense => t('operatingLicense');

  // ── Admin pricing extras ─────────────────────────────────────────────────
  String get editBundlePlan => t('editBundlePlan');
  String get packageNameLabel => t('packageNameLabel');
  String get washCountLabel => t('washCountLabel');
  String get priceYuanLabel => t('priceYuanLabel');
  String get bundlePricingUpdated => t('bundlePricingUpdated');
  String get platformPricing => t('platformPricing');
  String get platformPricingDesc => t('platformPricingDesc');
  String get shopPricingTitle => t('shopPricingTitle');
  String get shopPricingDesc => t('shopPricingDesc');
  String get storeWashPackagePricing => t('storeWashPackagePricing');
  String get storeWashPackagePricingHint => t('storeWashPackagePricingHint');
  String get washCreditBundlesSection => t('washCreditBundlesSection');
  String get washCreditBundlesSectionHint => t('washCreditBundlesSectionHint');
  String get tapToEditPrice => t('tapToEditPrice');
  String get priceFormatInvalid => t('priceFormatInvalid');
  String get countFormatInvalid => t('countFormatInvalid');

  // ── License files ────────────────────────────────────────────────────────
  String get imageLoadFailed => t('imageLoadFailed');
  String get imageCannotLoad => t('imageCannotLoad');
  String get fileNotUploadedYet => t('fileNotUploadedYet');
  String get tapToZoom => t('tapToZoom');
  String get pdfNoPreview => t('pdfNoPreview');
  String get noUploadedMaterials => t('noUploadedMaterials');
  String get noFileSelected => t('noFileSelected');
  String get cannotReadFilename => t('cannotReadFilename');
  String get cannotReadFileContent => t('cannotReadFileContent');
  String get fileTooLarge => t('fileTooLarge');
  String get unsupportedLicenseFormat => t('unsupportedLicenseFormat');
  String get uploadNoFilename => t('uploadNoFilename');
  String get licenseUploadHint => t('licenseUploadHint');
  String get uploading => t('uploading');
  String get selectAndUpload => t('selectAndUpload');
  String get tapImageFullPreview => t('tapImageFullPreview');

  // ── Shop profile ─────────────────────────────────────────────────────────
  String get todayCompleted => t('todayCompleted');
  String get todayRevenue => t('todayRevenue');
  String get walletBalance => t('walletBalance');
  String get viewBtn => t('viewBtn');
  String get commonTools => t('commonTools');
  String get walletShort => t('walletShort');
  String get reviewsShort => t('reviewsShort');
  String get customerServiceShort => t('customerServiceShort');
  String get settingsShort => t('settingsShort');
  String get accountInfo => t('accountInfo');
  String get shopInfoSection => t('shopInfoSection');
  String get loginAccount => t('loginAccount');
  String get shopAddressLabel => t('shopAddressLabel');
  String get notFilled => t('notFilled');
  String get mapCoordinates => t('mapCoordinates');
  String get manageStores => t('manageStores');
  String get businessLicense => t('businessLicense');
  String get uploadBusinessLicense => t('uploadBusinessLicense');
  String get goUpload => t('goUpload');
  String get editProfile => t('editProfile');
  String get profileSyncHint => t('profileSyncHint');
  String get accountSection => t('accountSection');
  String get addressAndCoordinates => t('addressAndCoordinates');
  String get profileSaved => t('profileSaved');
  String get uploadAtLeastOneLicense => t('uploadAtLeastOneLicense');
  String get latLngFormatInvalid => t('latLngFormatInvalid');
  String get fillAllRequired => t('fillAllRequired');

  // ── HK district picker ───────────────────────────────────────────────────
  String get hkRegionTitle => t('hkRegionTitle');
  String get hkMajorRegion => t('hkMajorRegion');
  String get hk18Districts => t('hk18Districts');
  String get hkSubArea => t('hkSubArea');
  String get hkDetailAddress => t('hkDetailAddress');

  // ── Payment UI ───────────────────────────────────────────────────────────
  String get paymentSessionExpiredReturn => t('paymentSessionExpiredReturn');
  String get fillCompleteCardInfo => t('fillCompleteCardInfo');
  String get paymentCancelledByUser => t('paymentCancelledByUser');
  String get expiredLabel => t('expiredLabel');
  String get selectPaymentMethod => t('selectPaymentMethod');
  String get iosOnly => t('iosOnly');
  String get pciComplianceNote => t('pciComplianceNote');
  String get creatingPayment => t('creatingPayment');
  String get awaitingAuthorization => t('awaitingAuthorization');
  String get verifyingPayment => t('verifyingPayment');
  String get sessionExpired => t('sessionExpired');
  String get selectMethodFirst => t('selectMethodFirst');
  String get amountDue => t('amountDue');
  String get usedFreeWashCredits => t('usedFreeWashCredits');
  String get sessionValid15Min => t('sessionValid15Min');
  String get cardholderName => t('cardholderName');
  String get enterCardholderName => t('enterCardholderName');
  String get cardNumber => t('cardNumber');
  String get invalidCardNumber => t('invalidCardNumber');
  String get expiryDate => t('expiryDate');
  String get expiryFormat => t('expiryFormat');
  String get cvvInvalid => t('cvvInvalid');
  String get processingPayment => t('processingPayment');
  String get creatingPaymentBanner => t('creatingPaymentBanner');
  String get authInProviderBanner => t('authInProviderBanner');
  String get verifyingBanner => t('verifyingBanner');
  String get processingGeneric => t('processingGeneric');
  String get paymentFailed => t('paymentFailed');
  String get paymentFlowNotice => t('paymentFlowNotice');
  String get paymentSuccessTitle => t('paymentSuccessTitle');
  String get paySuccess => t('paySuccess');
  String get receiptPaymentMethod => t('receiptPaymentMethod');
  String get receiptMerchant => t('receiptMerchant');
  String get receiptProduct => t('receiptProduct');
  String get receiptOrderId => t('receiptOrderId');
  String get receiptTransactionId => t('receiptTransactionId');
  String get receiptProviderRef => t('receiptProviderRef');
  String get receiptPaidAt => t('receiptPaidAt');
  String get receiptKeepTransactionId => t('receiptKeepTransactionId');
  String get completeAndStartWash => t('completeAndStartWash');
  String get enterPayPassword => t('enterPayPassword');
  String get wechatPayFailed => t('wechatPayFailed');
  String get alipayPayFailed => t('alipayPayFailed');
  String get authFailed => t('authFailed');
  String get confirmPaymentInfo => t('confirmPaymentInfo');
  String get confirmApplePayInfo => t('confirmApplePayInfo');
  String get applePaySecurityHint => t('applePaySecurityHint');
  String get cardEncryptedHint => t('cardEncryptedHint');
  String get payWithFaceId => t('payWithFaceId');
  String get confirmCreditCardPay => t('confirmCreditCardPay');
  String get payeeLabel => t('payeeLabel');
  String get paymentAmount => t('paymentAmount');
  String get payerAccountLabel => t('payerAccountLabel');
  String get retryWechatPay => t('retryWechatPay');
  String get retryAlipayPay => t('retryAlipayPay');
  String get simulatePaymentTest => t('simulatePaymentTest');
  String get paymentMethodAlipayRedirect => t('paymentMethodAlipayRedirect');
  String get paymentMethodWechatRedirect => t('paymentMethodWechatRedirect');
  String get paymentMethodApplePayBiometric => t('paymentMethodApplePayBiometric');
  String get paymentMethodCreditCardBrands => t('paymentMethodCreditCardBrands');

  // ── Order flow steps ─────────────────────────────────────────────────────
  String get orderFlow1 => t('orderFlow1');
  String get orderFlow2 => t('orderFlow2');
  String get orderFlow3 => t('orderFlow3');
  String get orderFlow4 => t('orderFlow4');
  String get orderFlow5 => t('orderFlow5');
  String get orderFlow6 => t('orderFlow6');
  String get orderFlow7 => t('orderFlow7');

  // ── Parameterized helpers ────────────────────────────────────────────────
  String distanceKm(double km) {
    final value = km.toStringAsFixed(1);
    return switch (locale) {
      AppLocale.en => 'About $value km away',
      AppLocale.zhHans => '距离约 $value km',
      AppLocale.zhHant => '距離約 $value km',
    };
  }

  String etaMinutes(int minutes) {
    return switch (locale) {
      AppLocale.en => 'ETA $minutes min',
      AppLocale.zhHans => '预计 $minutes 分钟到达',
      AppLocale.zhHant => '預計 $minutes 分鐘到達',
    };
  }

  String creditsSummary(int prepaid, int free) {
    return switch (locale) {
      AppLocale.en => 'Prepaid $prepaid · Free $free',
      AppLocale.zhHans => '次卡 $prepaid 次 · 免费 $free 次',
      AppLocale.zhHant => '次卡 $prepaid 次 · 免費 $free 次',
    };
  }

  String packageNameWithCount(String name, int count) {
    return switch (locale) {
      AppLocale.en => '$name × $count',
      AppLocale.zhHans => '$name（$count 次）',
      AppLocale.zhHant => '$name（$count 次）',
    };
  }

  String paymentSuccessMessage(int added, int remaining) {
    return switch (locale) {
      AppLocale.en =>
        'Successfully added $added washes. $remaining remaining.',
      AppLocale.zhHans => '已成功充值 $added 次，剩余 $remaining 次',
      AppLocale.zhHant => '已成功充值 $added 次，剩餘 $remaining 次',
    };
  }

  String orderStartedFree(String orderId) {
    return switch (locale) {
      AppLocale.en => 'Order $orderId started with a free wash',
      AppLocale.zhHans => '订单 $orderId 已使用免费洗车启动',
      AppLocale.zhHant => '訂單 $orderId 已使用免費洗車啟動',
    };
  }

  String reservationSubmitted(int eta) {
    return switch (locale) {
      AppLocale.en => 'Reservation submitted. ETA $eta min',
      AppLocale.zhHans => '预约已提交，预计 $eta 分钟到达',
      AppLocale.zhHant => '預約已提交，預計 $eta 分鐘到達',
    };
  }

  String priceYuan(num price) {
    return '¥${price.toStringAsFixed(0)}';
  }

  String minutesLabel(int minutes) {
    return switch (locale) {
      AppLocale.en => '$minutes min',
      AppLocale.zhHans => '$minutes 分钟',
      AppLocale.zhHant => '$minutes 分鐘',
    };
  }


  String countryRegionCount(int count) {
    return switch (locale) {
      AppLocale.en => '$count countries/regions',
      AppLocale.zhHans => '共 $count 个国家/地区',
      AppLocale.zhHant => '共 $count 個國家/地區',
    };
  }

  String smsResendIn(int seconds) {
    return switch (locale) {
      AppLocale.en => 'Resend in ${seconds}s',
      AppLocale.zhHans => '${seconds}s 后重发',
      AppLocale.zhHant => '${seconds}s 後重發',
    };
  }

  String idleBaysCount(int count) {
    return switch (locale) {
      AppLocale.en => '$count idle',
      AppLocale.zhHans => '$count 空闲',
      AppLocale.zhHant => '$count 空閒',
    };
  }

  String orderCountUnit(int count) {
    return switch (locale) {
      AppLocale.en => '$count orders',
      AppLocale.zhHans => '$count 笔',
      AppLocale.zhHant => '$count 筆',
    };
  }

  String shopMerchantSubtitleNamed(String name) {
    return switch (locale) {
      AppLocale.en => '$name — manage stores, bays, and statistics.',
      AppLocale.zhHans => '$name，管理店铺、工位状态和工位统计。',
      AppLocale.zhHant => '$name，管理店鋪、工位狀態和工位統計。',
    };
  }

  String reservationDistanceEta(double km, int eta) {
    return switch (locale) {
      AppLocale.en => 'About ${km.toStringAsFixed(1)} km · ETA $eta min',
      AppLocale.zhHans => '距离约 ${km.toStringAsFixed(1)} km，预计 $eta 分钟到达',
      AppLocale.zhHant => '距離約 ${km.toStringAsFixed(1)} km，預計 $eta 分鐘到達',
    };
  }

  String reservationDistanceEtaPeriod(double km, int eta) {
    return switch (locale) {
      AppLocale.en => 'Distance ${km.toStringAsFixed(1)} km · ETA $eta min.',
      AppLocale.zhHans => '距离 ${km.toStringAsFixed(1)} km，预计 $eta 分钟到达。',
      AppLocale.zhHant => '距離 ${km.toStringAsFixed(1)} km，預計 $eta 分鐘到達。',
    };
  }

  String reservationSubmittedEta(int eta) {
    return switch (locale) {
      AppLocale.en => 'Booking submitted. ETA $eta min',
      AppLocale.zhHans => '预约已提交，预计 $eta 分钟到达',
      AppLocale.zhHant => '預約已提交，預計 $eta 分鐘到達',
    };
  }

  String useFreeWashRemaining(int count) {
    return switch (locale) {
      AppLocale.en => 'Use free wash ($count remaining)',
      AppLocale.zhHans => '使用免费洗车（剩余 $count 次）',
      AppLocale.zhHant => '使用免費洗車（剩餘 $count 次）',
    };
  }

  String usePrepaidRemaining(int count) {
    return switch (locale) {
      AppLocale.en => 'Use prepaid credits ($count remaining)',
      AppLocale.zhHans => '使用洗车次卡（剩余 $count 次）',
      AppLocale.zhHant => '使用洗車次卡（剩餘 $count 次）',
    };
  }

  String originalPriceFreeUsed(double price) {
    final p = price.toStringAsFixed(0);
    return switch (locale) {
      AppLocale.en => 'Original ¥$p · free wash applied',
      AppLocale.zhHans => '原价 ¥$p，已使用免费洗车',
      AppLocale.zhHant => '原價 ¥$p，已使用免費洗車',
    };
  }

  String originalPricePrepaidUsed(double price) {
    final p = price.toStringAsFixed(0);
    return switch (locale) {
      AppLocale.en => 'Original ¥$p · prepaid credit applied',
      AppLocale.zhHans => '原价 ¥$p，已使用洗车次卡',
      AppLocale.zhHant => '原價 ¥$p，已使用洗車次卡',
    };
  }

  String goToPayment(double amount) {
    return switch (locale) {
      AppLocale.en => 'Pay ¥${amount.toStringAsFixed(0)}',
      AppLocale.zhHans => '前往付款 ¥${amount.toStringAsFixed(0)}',
      AppLocale.zhHant => '前往付款 ¥${amount.toStringAsFixed(0)}',
    };
  }

  String modifyPackageName(String name) {
    return switch (locale) {
      AppLocale.en => 'Edit "$name"',
      AppLocale.zhHans => '修改「$name」',
      AppLocale.zhHant => '修改「$name」',
    };
  }

  String saveFailedDetail(Object error) {
    return switch (locale) {
      AppLocale.en => 'Save failed: $error',
      AppLocale.zhHans => '保存失败：$error',
      AppLocale.zhHant => '儲存失敗：$error',
    };
  }

  String geocodeLocated(String address) {
    return switch (locale) {
      AppLocale.en => 'Located: $address',
      AppLocale.zhHans => '已定位：$address',
      AppLocale.zhHant => '已定位：$address',
    };
  }

  String geocodeFailedMsg(Object error) {
    return switch (locale) {
      AppLocale.en => 'Geocoding failed: $error',
      AppLocale.zhHans => '定位失败：$error',
      AppLocale.zhHant => '定位失敗：$error',
    };
  }

  String loginAccountLine(String username) {
    return switch (locale) {
      AppLocale.en => 'Login: $username',
      AppLocale.zhHans => '登录账号：$username',
      AppLocale.zhHant => '登入帳號：$username',
    };
  }

  String adminReplyLine(String reply) {
    return switch (locale) {
      AppLocale.en => 'Admin reply: $reply',
      AppLocale.zhHans => 'Admin 回复：$reply',
      AppLocale.zhHant => 'Admin 回覆：$reply',
    };
  }

  String userRegisterSuccess(String phone) {
    return switch (locale) {
      AppLocale.en => 'Registered. Log in with $phone',
      AppLocale.zhHans => '用户注册成功，请使用账号 $phone 登录',
      AppLocale.zhHant => '用戶註冊成功，請使用帳號 $phone 登入',
    };
  }

  String navigationPanelText(String storeName, double km, int eta) {
    return switch (locale) {
      AppLocale.en =>
        'Selected $storeName: ~${km.toStringAsFixed(1)} km, ETA $eta min. Tap Google Maps on the store card to navigate.',
      AppLocale.zhHans =>
        '已选择 $storeName：约 ${km.toStringAsFixed(1)} km，预计 $eta 分钟到达。点击店铺卡片的"Google导航"可跳转导航。',
      AppLocale.zhHant =>
        '已選擇 $storeName：約 ${km.toStringAsFixed(1)} km，預計 $eta 分鐘到達。點擊店鋪卡片的「Google導航」可跳轉導航。',
    };
  }

  String reservationUserLine(String name, String phone) {
    return switch (locale) {
      AppLocale.en => 'User: $name $phone',
      AppLocale.zhHans => '用户：$name $phone',
      AppLocale.zhHant => '用戶：$name $phone',
    };
  }

  String reservationTypeLine(String type) {
    return switch (locale) {
      AppLocale.en => 'Service: $type',
      AppLocale.zhHans => '预约类型：$type',
      AppLocale.zhHant => '預約類型：$type',
    };
  }

  String reservationArrivalLine(String time) {
    return switch (locale) {
      AppLocale.en => 'Arrival: $time',
      AppLocale.zhHans => '预约到店：$time',
      AppLocale.zhHant => '預約到店：$time',
    };
  }

  String reservationEtaDistanceLine(int eta, double km) {
    return switch (locale) {
      AppLocale.en => 'ETA $eta min · ${km.toStringAsFixed(1)} km',
      AppLocale.zhHans => '预计 $eta 分钟到达，距离 ${km.toStringAsFixed(1)} km',
      AppLocale.zhHant => '預計 $eta 分鐘到達，距離 ${km.toStringAsFixed(1)} km',
    };
  }

  String reservationNoteLine(String note) {
    return switch (locale) {
      AppLocale.en => 'Notes: $note',
      AppLocale.zhHans => '备注：$note',
      AppLocale.zhHant => '備註：$note',
    };
  }

  String reservationSubmitTimeLine(String time) {
    return switch (locale) {
      AppLocale.en => 'Submitted: $time',
      AppLocale.zhHans => '提交时间：$time',
      AppLocale.zhHant => '提交時間：$time',
    };
  }

  String orderFlowLine(String desc) {
    return switch (locale) {
      AppLocale.en => 'Flow: $desc',
      AppLocale.zhHans => '流程：$desc',
      AppLocale.zhHant => '流程：$desc',
    };
  }

  String freeWashOnOrder(String bayName) {
    return switch (locale) {
      AppLocale.en => '$bayName · free wash',
      AppLocale.zhHans => '$bayName · 免费洗车',
      AppLocale.zhHant => '$bayName · 免費洗車',
    };
  }

  String paidAmountLine(double amount) {
    return switch (locale) {
      AppLocale.en => 'Collected ¥${amount.toStringAsFixed(0)}',
      AppLocale.zhHans => '已收款 ¥${amount.toStringAsFixed(0)}',
      AppLocale.zhHant => '已收款 ¥${amount.toStringAsFixed(0)}',
    };
  }

  String paymentMethodLine(String method) {
    return switch (locale) {
      AppLocale.en => 'Payment: $method',
      AppLocale.zhHans => '支付方式：$method',
      AppLocale.zhHant => '支付方式：$method',
    };
  }

  String transactionIdLine(String id) {
    return switch (locale) {
      AppLocale.en => 'Transaction ID: $id',
      AppLocale.zhHans => '交易号：$id',
      AppLocale.zhHant => '交易號：$id',
    };
  }

  String paidAtLine(String time) {
    return switch (locale) {
      AppLocale.en => 'Paid at: $time',
      AppLocale.zhHans => '到账时间：$time',
      AppLocale.zhHant => '到帳時間：$time',
    };
  }

  String remainingTimeLine(String time) {
    return switch (locale) {
      AppLocale.en => 'Remaining $time',
      AppLocale.zhHans => '剩余 $time',
      AppLocale.zhHant => '剩餘 $time',
    };
  }

  String orderIdLine(String id) {
    return switch (locale) {
      AppLocale.en => 'Order: $id',
      AppLocale.zhHans => '订单号：$id',
      AppLocale.zhHant => '訂單號：$id',
    };
  }

  String platformOpinionLine(String reply) {
    return switch (locale) {
      AppLocale.en => 'Platform note: $reply',
      AppLocale.zhHans => '平台意见：$reply',
      AppLocale.zhHant => '平台意見：$reply',
    };
  }

  String serviceTypeLine(String summary) {
    return switch (locale) {
      AppLocale.en => 'Services: $summary',
      AppLocale.zhHans => '服务类型：$summary',
      AppLocale.zhHant => '服務類型：$summary',
    };
  }

  String revenueSummary(double revenue, int paidCount) {
    return switch (locale) {
      AppLocale.en =>
        'Revenue ¥${revenue.toStringAsFixed(0)} · $paidCount paid',
      AppLocale.zhHans =>
        '累计收款 ¥${revenue.toStringAsFixed(0)} · 已付 $paidCount 笔',
      AppLocale.zhHant =>
        '累計收款 ¥${revenue.toStringAsFixed(0)} · 已付 $paidCount 筆',
    };
  }

  String packageMinutesDesc(int minutes, String description) {
    return switch (locale) {
      AppLocale.en => '$minutes min · $description',
      AppLocale.zhHans => '$minutes 分钟 · $description',
      AppLocale.zhHant => '$minutes 分鐘 · $description',
    };
  }

  String deviceUsageLine(int useCount, String duration, int faultCount) {
    return switch (locale) {
      AppLocale.en =>
        'Uses $useCount · Duration $duration · Faults $faultCount',
      AppLocale.zhHans =>
        '使用次数 $useCount · 使用时长 $duration · 故障次数 $faultCount',
      AppLocale.zhHant =>
        '使用次數 $useCount · 使用時長 $duration · 故障次數 $faultCount',
    };
  }

  String merchantPhoneLocked(String phone) {
    return switch (locale) {
      AppLocale.en => 'Merchant phone: $phone (locked after approval)',
      AppLocale.zhHans => '商户电话账号：$phone（不可修改）',
      AppLocale.zhHant => '商戶電話帳號：$phone（不可修改）',
    };
  }

  String storeAddressLine(String address) {
    return switch (locale) {
      AppLocale.en => 'Address: $address',
      AppLocale.zhHans => '地址：$address',
      AppLocale.zhHant => '地址：$address',
    };
  }

  String accountRolePhoneLine(String role, String phone) {
    return switch (locale) {
      AppLocale.en => '$role · Phone: $phone',
      AppLocale.zhHans => '$role · 手机/账号：$phone',
      AppLocale.zhHant => '$role · 手機/帳號：$phone',
    };
  }

  String storeInfoLine(String name, String address) {
    return switch (locale) {
      AppLocale.en => 'Store: $name · $address',
      AppLocale.zhHans => '店铺：$name · $address',
      AppLocale.zhHant => '店鋪：$name · $address',
    };
  }

  String viewLicenseCount(int count) {
    return switch (locale) {
      AppLocale.en => 'View license files ($count)',
      AppLocale.zhHans => '查看许可证材料（$count）',
      AppLocale.zhHant => '查看許可證材料（$count）',
    };
  }

  String licensePageTitle(String name) {
    return switch (locale) {
      AppLocale.en => '$name · License materials',
      AppLocale.zhHans => '$name · 许可证材料',
      AppLocale.zhHant => '$name · 許可證材料',
    };
  }

  String formatDurationLocalized(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    return switch (locale) {
      AppLocale.en => '${minutes}m ${remaining}s',
      AppLocale.zhHans => '$minutes分$remaining秒',
      AppLocale.zhHant => '$minutes分$remaining秒',
    };
  }

  String geocodeSubAreaFallback(String message, String subArea) {
    return switch (locale) {
      AppLocale.en => '$message (using default location for $subArea)',
      AppLocale.zhHans => '$message（已使用「$subArea」默认位置）',
      AppLocale.zhHant => '$message（已使用「$subArea」預設位置）',
    };
  }

  String geocodeAreaFallback(Object error) {
    return switch (locale) {
      AppLocale.en => 'Geocoding failed; using regional default ($error)',
      AppLocale.zhHans => '定位失败，已使用区域默认位置（$error）',
      AppLocale.zhHant => '定位失敗，已使用區域預設位置（$error）',
    };
  }

  String addressPreviewLine(String locationLabel, String detail) {
    final suffix = detail.isEmpty ? '' : ' · $detail';
    return switch (locale) {
      AppLocale.en => 'Address preview: $locationLabel$suffix',
      AppLocale.zhHans => '地址预览：$locationLabel$suffix',
      AppLocale.zhHant => '地址預覽：$locationLabel$suffix',
    };
  }

  String coordinatesLine(double lat, double lng) {
    return switch (locale) {
      AppLocale.en => 'Coordinates: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
      AppLocale.zhHans => '坐标：${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
      AppLocale.zhHant => '座標：${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
    };
  }

  String orderFlowStep(int step, String text) {
    final flow = switch (step) {
      1 => orderFlow1,
      2 => orderFlow2,
      3 => orderFlow3,
      4 => orderFlow4,
      5 => orderFlow5,
      6 => orderFlow6,
      7 => orderFlow7,
      _ => null,
    };
    return flow ?? '$step. $text';
  }

  String vehicleCount(int count) => switch (locale) {
        AppLocale.en => '$count vehicle${count == 1 ? '' : 's'}',
        AppLocale.zhHans => '$count 辆',
        AppLocale.zhHant => '$count 輛',
      };

  String addressCount(int count) => switch (locale) {
        AppLocale.en => '$count address${count == 1 ? '' : 'es'}',
        AppLocale.zhHans => '$count 个',
        AppLocale.zhHant => '$count 個',
      };

  String washCreditsRemainingSubtitle(int count) => switch (locale) {
        AppLocale.en => '$count remaining · Buy package',
        AppLocale.zhHans => '剩余 $count 次 · 购买套餐',
        AppLocale.zhHant => '剩餘 $count 次 · 購買套餐',
      };

  String orderCountText(int count) => switch (locale) {
        AppLocale.en => '$count order${count == 1 ? '' : 's'}',
        AppLocale.zhHans => '$count 个订单',
        AppLocale.zhHant => '$count 個訂單',
      };

  String freeWashCountText(int count) => switch (locale) {
        AppLocale.en => 'Free washes: $count',
        AppLocale.zhHans => '免费洗车 $count 次',
        AppLocale.zhHant => '免費洗車 $count 次',
      };

  String currentFreeWashCountLine(int count) => switch (locale) {
        AppLocale.en => 'Free wash credits: $count',
        AppLocale.zhHans => '当前免费洗车次数：$count',
        AppLocale.zhHant => '當前免費洗車次數：$count',
      };

  String yourShareCodeLine(String code) => switch (locale) {
        AppLocale.en => 'Your share code: $code',
        AppLocale.zhHans => '您的分享码：$code',
        AppLocale.zhHant => '您的分享碼：$code',
      };

  String currentFreeWashAvailable(int count) => switch (locale) {
        AppLocale.en => 'Available free washes: $count',
        AppLocale.zhHans => '当前可用免费洗车：$count 次',
        AppLocale.zhHant => '當前可用免費洗車：$count 次',
      };

  String myShareCodeLine(String code) => switch (locale) {
        AppLocale.en => 'My share code: $code',
        AppLocale.zhHans => '我的分享码：$code',
        AppLocale.zhHant => '我的分享碼：$code',
      };

  String shareCodeShort(String code) => switch (locale) {
        AppLocale.en => 'Share code: $code',
        AppLocale.zhHans => '分享码：$code',
        AppLocale.zhHant => '分享碼：$code',
      };

  String referredByLine(String name) => switch (locale) {
        AppLocale.en => 'Registered via share code. Invited by: $name',
        AppLocale.zhHans => '通过分享码注册，邀请人：$name',
        AppLocale.zhHant => '通過分享碼註冊，邀請人：$name',
      };

  String shareMessage(String code) => switch (locale) {
        AppLocale.en =>
          'I washed my car with Wash On Demand! Join me — use my code $code at sign-up and we each get 1 free wash.',
        AppLocale.zhHans =>
          '我在「清洗到家」洗过车了，邀请你一起来！注册时填写我的分享码 $code，我们各得 1 次免费洗车。',
        AppLocale.zhHant =>
          '我在「清洗到家」洗過車了，邀請你一起來！註冊時填寫我的分享碼 $code，我們各得 1 次免費洗車。',
      };

  String purchaseFailedWithError(Object error) => switch (locale) {
        AppLocale.en => 'Purchase failed: $error',
        AppLocale.zhHans => '购买失败：$error',
        AppLocale.zhHant => '購買失敗：$error',
      };

  String saveFailedWithError(Object error) => switch (locale) {
        AppLocale.en => 'Save failed: $error',
        AppLocale.zhHans => '保存失败：$error',
        AppLocale.zhHant => '儲存失敗：$error',
      };

  String withdrawableHelper(double balance) => switch (locale) {
        AppLocale.en => 'Available ¥${balance.toStringAsFixed(2)}',
        AppLocale.zhHans => '可提现 ¥${balance.toStringAsFixed(2)}',
        AppLocale.zhHant => '可提現 ¥${balance.toStringAsFixed(2)}',
      };

  String shopReplyPrefix(String reply) => switch (locale) {
        AppLocale.en => 'Merchant reply: $reply',
        AppLocale.zhHans => '商家回复：$reply',
        AppLocale.zhHant => '商家回覆：$reply',
      };

  String starRating(int rating) => switch (locale) {
        AppLocale.en => '$rating stars',
        AppLocale.zhHans => '$rating 星',
        AppLocale.zhHant => '$rating 星',
      };

  String pendingItemsCount(int count) => switch (locale) {
        AppLocale.en => '$count item${count == 1 ? '' : 's'} pending — review first',
        AppLocale.zhHans => '有 $count 项待处理，请优先审核',
        AppLocale.zhHant => '有 $count 項待處理，請優先審核',
      };

  String pendingReviewBadge(int count) => switch (locale) {
        AppLocale.en => 'Pending $count',
        AppLocale.zhHans => '待审 $count',
        AppLocale.zhHant => '待審 $count',
      };

  String hkSelected(String label) => switch (locale) {
        AppLocale.en => 'Selected: $label',
        AppLocale.zhHans => '已选：$label',
        AppLocale.zhHant => '已選：$label',
      };

  String materialsFileCount(int count) => switch (locale) {
        AppLocale.en =>
          '$count file${count == 1 ? '' : 's'}. Images can be previewed in-app; tap to zoom.',
        AppLocale.zhHans => '共 $count 个文件，图片可直接在 App 内预览，点击可放大查看。',
        AppLocale.zhHant => '共 $count 個檔案，圖片可直接在 App 內預覽，點擊可放大查看。',
      };

  String uploadFailedWithCode(int code) => switch (locale) {
        AppLocale.en => 'Upload failed ($code)',
        AppLocale.zhHans => '上传失败（$code）',
        AppLocale.zhHant => '上傳失敗（$code）',
      };

  String cannotConnectUpload(String baseUrl, {String? debug}) => switch (locale) {
        AppLocale.en =>
          'Cannot connect to upload service. Ensure the backend is running ($baseUrl).${debug ?? ''}',
        AppLocale.zhHans =>
          '无法连接上传服务，请确认后端已启动（$baseUrl）。${debug ?? ''}',
        AppLocale.zhHant =>
          '無法連接上傳服務，請確認後端已啟動（$baseUrl）。${debug ?? ''}',
      };

  String storeCountBadge(int count) => switch (locale) {
        AppLocale.en => '$count store${count == 1 ? '' : 's'}',
        AppLocale.zhHans => '$count 家',
        AppLocale.zhHant => '$count 家',
      };

  String fileCountBadge(int count) => switch (locale) {
        AppLocale.en => '$count file${count == 1 ? '' : 's'}',
        AppLocale.zhHans => '$count 个文件',
        AppLocale.zhHant => '$count 個檔案',
      };

  String licenseTitleSuffix(String name) => switch (locale) {
        AppLocale.en => '$name · License',
        AppLocale.zhHans => '$name · 许可证',
        AppLocale.zhHant => '$name · 許可證',
      };

  String get geocodeUpdatedCoords => switch (locale) {
        AppLocale.en => 'Coordinates updated from address',
        AppLocale.zhHans => '已根据地址更新坐标',
        AppLocale.zhHant => '已根據地址更新座標',
      };


  String paymentConfirmDialogBody(
    String storeName,
    double amount,
    String method,
  ) =>
      switch (locale) {
        AppLocale.en =>
          'You will pay ¥${amount.toStringAsFixed(0)} to "$storeName" via $method.\n\nPlease confirm the amount and payee before continuing.',
        AppLocale.zhHans =>
          '您将向「$storeName」支付 ¥${amount.toStringAsFixed(0)}，使用$method。\n\n请确认金额与收款方无误后再继续。',
        AppLocale.zhHant =>
          '您將向「$storeName」支付 ¥${amount.toStringAsFixed(0)}，使用$method。\n\n請確認金額與收款方無誤後再繼續。',
      };

  String confirmPayAmount(double amount) => switch (locale) {
        AppLocale.en => 'Pay ¥${amount.toStringAsFixed(0)}',
        AppLocale.zhHans => '确认支付 ¥${amount.toStringAsFixed(0)}',
        AppLocale.zhHant => '確認支付 ¥${amount.toStringAsFixed(0)}',
      };

  String payerAccount(String masked) => switch (locale) {
        AppLocale.en => 'Payer $masked',
        AppLocale.zhHans => '付款账户 $masked',
        AppLocale.zhHant => '付款帳戶 $masked',
      };

  String orderIdShort(String orderId) => switch (locale) {
        AppLocale.en => 'Order $orderId',
        AppLocale.zhHans => '订单号 $orderId',
        AppLocale.zhHant => '訂單號 $orderId',
      };

  String applePayBiometricVerify(double amount) => switch (locale) {
        AppLocale.en =>
          'Use Face ID / Touch ID to confirm payment of ¥${amount.toStringAsFixed(0)}',
        AppLocale.zhHans =>
          '请使用 Face ID / Touch ID 验证\n确认支付 ¥${amount.toStringAsFixed(0)}',
        AppLocale.zhHant =>
          '請使用 Face ID / Touch ID 驗證\n確認支付 ¥${amount.toStringAsFixed(0)}',
      };

  String confirmCardPay(String last4, double amount) => switch (locale) {
        AppLocale.en =>
          'Confirm card ending $last4 for ¥${amount.toStringAsFixed(0)}',
        AppLocale.zhHans =>
          '确认使用尾号 $last4 卡片支付 ¥${amount.toStringAsFixed(0)}',
        AppLocale.zhHant =>
          '確認使用尾號 $last4 卡片支付 ¥${amount.toStringAsFixed(0)}',
      };

  String redirectingTo(String provider) => switch (locale) {
        AppLocale.en => 'Redirecting to $provider',
        AppLocale.zhHans => '正在跳转$provider',
        AppLocale.zhHant => '正在跳轉$provider',
      };

  String redirectCountdown(double amount, int seconds) =>
      '¥${amount.toStringAsFixed(0)} · $seconds ${seconds == 1 ? (locale == AppLocale.en ? 'sec' : '秒') : (locale == AppLocale.en ? 'sec' : '秒')}';

  String openingCashier(String provider) => switch (locale) {
        AppLocale.en =>
          'Opening $provider cashier\nEnter your payment password to complete',
        AppLocale.zhHans => '即将打开$provider收银台\n请输入支付密码完成付款',
        AppLocale.zhHant => '即將打開$provider收銀台\n請輸入支付密碼完成付款',
      };

  String cardLine(String name, String last4) => switch (locale) {
        AppLocale.en => 'Card · $name · $last4',
        AppLocale.zhHans => '卡片 · $name · 尾号 $last4',
        AppLocale.zhHant => '卡片 · $name · 尾號 $last4',
      };

  String securePayment(String provider) => switch (locale) {
        AppLocale.en => '$provider · Secure payment',
        AppLocale.zhHans => '$provider · 安全支付',
        AppLocale.zhHant => '$provider · 安全支付',
      };

  String washCountTimes(int count) => switch (locale) {
        AppLocale.en => '$count washes',
        AppLocale.zhHans => '$count 次',
        AppLocale.zhHant => '$count 次',
      };

  String todayCompletedValue(int count) => switch (locale) {
        AppLocale.en => '$count orders',
        AppLocale.zhHans => '$count 单',
        AppLocale.zhHant => '$count 單',
      };

  static const Map<AppLocale, Map<String, String>> _data = {
    AppLocale.en: {
      'appTitle': 'Wash On Demand',
      'appTagline': 'Smart car wash · Easy booking · Simple management',
      'welcomeLogin': 'Welcome',
      'loginRoleHint':
          'After login, enter the user / merchant / admin portal based on your role',
      'phoneOrTestAccount': 'Phone number or test account',
      'phoneLoginHint':
          'Enter phone number only for login; test accounts user / shop / admin ignore country code.',
      'password': 'Password',
      'login': 'Log in',
      'loggingIn': 'Logging in…',
      'userRegister': 'User sign up',
      'shopRegister': 'Merchant sign up',
      'demoAccounts': 'Demo accounts',
      'demoUser': 'User: user / 123456',
      'demoShop': 'Shop: shop / 123456',
      'demoAdmin': 'Admin: admin / 123456',
      'accountMismatch': 'Account or password does not match',
      'accountPending': 'Account is pending platform review',
      'accountRejected':
          'Account review rejected. Please contact the platform admin.',
      'backendUnreachable':
          'Cannot reach the server. Check your network and ensure the backend is running.',
      'syncingData': 'Syncing latest data…',
      'syncFailedHint': 'Could not refresh data. Pull down to retry.',
      'retrySync': 'Retry',
      'languageTitle': 'Language',
      'tabCarWash': 'Wash',
      'tabPackages': 'Packages',
      'tabOrders': 'Orders',
      'tabProfile': 'Profile',
      'tabStores': 'Stores',
      'tabReservations': 'Bookings',
      'tabMine': 'Me',
      'tabApproval': 'Approval',
      'tabOverview': 'Overview',
      'tabStoresAdmin': 'Stores',
      'tabReservationsAdmin': 'Bookings',
      'tabOrdersAdmin': 'Orders',
      'tabPricing': 'Pricing',
      'carWashTitle': 'Car wash',
      'carWashSubtitle':
          'Map shows nearby stores. Scan to wash or book a visit.',
      'myLocation': 'My location',
      'nearbyStores': 'Nearby stores',
      'noStores': 'No stores available',
      'noStoresDesc': 'There are no approved car wash stores right now.',
      'runningOrderTitle': 'Wash in progress',
      'runningOrderSubtitle': 'Tap to view order details',
      'locationLoading': 'Getting location…',
      'locationDisabled': 'Location services are disabled',
      'locationDenied': 'Location permission denied',
      'locationFailed': 'Failed to get location',
      'locationSuccess': 'Location updated',
      'viewMap': 'View map',
      'googleNav': 'Google Maps',
      'reserveStore': 'Book visit',
      'scanWash': 'Scan to wash',
      'idleCount': 'Idle bays',
      'buyPackages': 'Buy wash packages',
      'buyPackagesSubtitle':
          'Purchase wash credits. Use prepaid credits at checkout when scanning.',
      'myWashCredits': 'My wash credits',
      'selectPackage': 'Select package',
      'buyNow': 'Buy now',
      'recentUsage': 'Recent usage',
      'noUsageHistory': 'No usage yet',
      'noUsageHistoryDesc':
          'Usage from prepaid credits will appear here after you buy a package.',
      'packagePaymentHint':
          'Tap Buy now to checkout. Credits are added automatically after payment.',
      'purchaseFailed': 'Purchase failed',
      'creditsLine': 'Prepaid · Free credits',
      'cashierTitle': 'Checkout',
      'scanCarWashTitle': 'Scan to wash',
      'scanCarWashSubtitle':
          'Scan the device QR code, choose a package, then pay at checkout.',
      'rescan': 'Scan again',
      'selectPackageLabel': 'Select package',
      'actualAmount': 'Amount due',
      'useFreeWashOn': 'Use free wash (credits available)',
      'useFreeWashOff': 'Use free wash (none available)',
      'useFreeWashSubtitleOn': 'When on, this order is ¥0',
      'useFreeWashSubtitleOff':
          'Earn free washes by sharing or redeeming codes',
      'usePrepaidOn': 'Use prepaid credits (credits available)',
      'usePrepaidOff': 'No prepaid credits',
      'usePrepaidSubtitleOn': 'When on, this order uses prepaid credits',
      'usePrepaidSubtitleOff': 'Buy packages in Profile to get prepaid credits',
      'prepaidUsedNotice': 'Original price applied; prepaid credit used',
      'unknownQr': 'Unrecognized QR code. Please scan a wash device code.',
      'myOrdersTitle': 'My orders',
      'myOrdersSubtitle': 'View your wash orders and status',
      'noOrdersTitle': 'No orders yet',
      'noOrdersDesc': 'Scan a device or buy a package to create your first order.',
      'personalCenter': 'Profile',
      'personalCenterSubtitle': 'Account, credits, and settings',
      'logout': 'Log out',
      'settingsTitle': 'Settings',
      'nickname': 'Nickname',
      'phone': 'Phone',
      'newPasswordOptional': 'New password (optional)',
      'autoUseFreeWash': 'Auto-use free wash',
      'settingsSaved': 'Settings saved',
      'save': 'Save',
      'saving': 'Saving…',
      'shopMerchantTitle': 'Merchant portal',
      'shopMerchantSubtitle': 'Manage stores, bays, bookings, and orders',
      'addNewStore': 'Add store',
      'reservationFormTitle': 'Store bookings',
      'reservationFormSubtitle': 'Review and manage customer visit bookings',
      'shopOrdersTitle': 'Store orders',
      'shopOrdersSubtitle': 'View wash orders for your stores',
      'noReservationsTitle': 'No bookings',
      'noReservationsDesc': 'Customer bookings will appear here.',
      'noOrdersShopTitle': 'No orders',
      'noOrdersShopDesc': 'Wash orders for your stores will appear here.',
      'collected': 'Collected',
      'pendingPay': 'Pending payment',
      'completedOrders': 'Completed',
      'adminPlatformTitle': 'Admin platform',
      'adminPlatformSubtitle': 'Approve accounts, stores, and platform pricing',
      'accountManagementTitle': 'Account management',
      'accountManagementSubtitle': 'Review user and merchant registrations',
      'approve': 'Approve',
      'rejectAndReply': 'Reject & reply',
      'reviewReply': 'Review reply',
      'rejectAndSend': 'Reject & send',
      'allStoresFilter': 'All stores',
      'userAccounts': 'User accounts',
      'shopAccounts': 'Merchant accounts',
      'exitLogin': 'Log out',
      'roleUser': 'User',
      'roleShop': 'Merchant',
      'roleAdmin': 'Admin',
      'approvalPending': 'Pending review',
      'approvalApproved': 'Approved',
      'approvalRejected': 'Rejected',
      'orderStatusCreated': 'Awaiting payment',
      'orderStatusPaid': 'Paid',
      'orderStatusStarting': 'Starting',
      'orderStatusRunning': 'Washing',
      'orderStatusCompleted': 'Completed',
      'orderStatusFailed': 'Error',
      'orderStatusRefunded': 'Refunded',
      'deviceIdle': 'Idle',
      'deviceBusy': 'Busy',
      'deviceOffline': 'Offline',
      'deviceFaulted': 'Fault',
      'selfService': 'Self-service',
      'manualService': 'Manual wash',
      'selfServiceEco': 'Eco self-service',
      'resPending': 'Awaiting visit',
      'resArrived': 'Arrived',
      'resCompleted': 'Completed',
      'resCancelled': 'Cancelled',
      'myReservations': 'My bookings',
      'myReservationsSubtitle':
          'Choose a store and submit a visit booking.',
      'noStoresToReserve': 'No stores to book',
      'noReservationsYet': 'No bookings yet',
      'noReservationsYetDesc':
          'Fill in the form above to submit your first booking.',
      'newReservation': 'New booking',
      'selectStore': 'Select store',
      'reservationDate': 'Date',
      'reservationTime': 'Time',
      'contactPhone': 'Contact phone',
      'reservationType': 'Service type',
      'reservationNote': 'Notes',
      'submitReservation': 'Submit booking',
      'reservationSubmitted': 'Booking submitted',
      'reserveVisitTitle': 'Book a visit',
      'selectReservationType': 'Select service type',
      'createReservationPage': 'New booking',
      'paymentMethodAlipay': 'Alipay',
      'paymentMethodWechat': 'WeChat Pay',
      'paymentMethodApplePay': 'Apple Pay',
      'paymentMethodCreditCard': 'Credit card',
      'paymentMethodAlipaySub': 'Pay with Alipay balance or linked card',
      'paymentMethodWechatSub': 'Pay with WeChat balance or linked card',
      'paymentMethodApplePaySub': 'Pay with Apple Pay on this device',
      'paymentMethodCreditCardSub': 'Visa, Mastercard, and other cards',
      'paymentProviderAlipay': 'Alipay',
      'paymentProviderWechat': 'WeChat Pay',
      'paymentProviderApplePay': 'Apple Pay',
      'paymentProviderBank': 'Bank card',
      'paymentCancelled': 'Payment cancelled',
      'confirmPayment': 'Confirm payment',
      'cancelPayment': 'Cancel payment',
      'confirmContinue': 'Confirm & continue',
      'packagePrices': 'Package pricing',
      'addBay': 'Add bay',
      'addStorePage': 'Add store',
      'submitNewStore': 'Submit store',
      'storeSubmitted': 'Store submitted for review',
      'simulatePayAndStart': 'Simulate pay & start',
      'finishWash': 'Finish wash',
      'orderFlowLabel': 'Flow',
      'paymentMethodLabel': 'Payment method',
      'transactionIdLabel': 'Transaction ID',
      'paidAtLabel': 'Paid at',
      'minutesUnit': 'min',
      'washPackagePrices': 'Wash package pricing',
      'addWashBay': 'Add wash bay',
      'setIdle': 'Set idle',
      'setOffline': 'Set offline',
      'setFault': 'Set fault',
      'bayNameLabel': 'Bay name',
      'addBayButton': 'Add bay',
      'storeNameLabel': 'Store name',
      'storeAddressLabel': 'Store address',
      'latitude': 'Latitude',
      'longitude': 'Longitude',
      'licenseMaterials': 'License materials',
      'serviceTypes': 'Service types',
      'modifyMaterials': 'Update materials',
      'materialsResubmitted': 'Materials resubmitted for review',
      'shopReviewTitle': 'Merchant review',
      'adminReply': 'Admin reply',
      'merchantLicense': 'Business license',
      'userRegTitle': 'User registration',
      'shopRegTitle': 'Merchant registration',
      'merchantName': 'Merchant name',
      'merchantAddress': 'Merchant address',
      'merchantPhone': 'Merchant phone',
      'smsCode': 'SMS code',
      'emailLabel': 'Email',
      'emailVerificationCode': 'Email verification code',
      'friendReferralCode': 'Referral code (optional)',
      'registerLogin': 'Register & log in',
      'shopRegSubmitted':
          'Registration submitted. Please wait for platform review.',
      'noCountryMatch': 'No matching country or region',
      'homeLabel': 'Home',
      'standardWashDemo': 'Standard wash demo',
      'withdrawToAlipay': 'Withdraw to Alipay',
      'sharePanelTitle': 'Share & earn free washes',
      'copyShareCode': 'Copy share code',
      'copyShareText': 'Copy share text',
      'freeWashCreditsLabel': 'Free wash credits',
      'orderInProgress': 'Order in progress',
      'clickForDetails': 'Tap for details',
      'mapLoading': 'Loading map…',
      'adminPricingTitle': 'Platform package pricing',
      'editPackage': 'Edit package',
      'packageUpdated': 'Package updated',
      'saveFailed': 'Save failed',
      'userAccountMgmt': 'User accounts',
      'shopAccountMgmt': 'Merchant accounts',
      'viewLicenseMaterials': 'View license materials',
      'storesAndBays': 'Stores & bays',
      'allReservationsAdmin': 'All bookings',
      'allOrdersAdmin': 'All orders',
      'personalSettingsPage': 'Personal settings',
      'merchantPhoneFixed': 'Merchant phone (fixed after approval)',
      'licenseUpload': 'Upload license',
      'addStoreBtn': 'Add store',
      'addressLabel': 'Address',
      'serviceSummary': 'Services',
      'modifyPackageTitle': 'Edit package',
      'cancelBtn': 'Cancel',
      'saveBtn': 'Save',
      'emptyStateDefault': 'Nothing here yet',
      'myVehicles': 'My vehicles',
      'addVehicle': 'Add vehicle',
      'commonAddresses': 'Saved addresses',
      'addAddress': 'Add address',
      'washCreditsCard': 'Wash credits',
      'myPoints': 'My points',
      'allOrders': 'All orders',
      'myVehiclesTitle': 'My vehicles',
      'noVehicles': 'No vehicles yet',
      'vehicleModel': 'Vehicle model',
      'plateNumber': 'License plate',
      'colorOptional': 'Color (optional)',
      'commonAddressesTitle': 'Saved addresses',
      'noAddresses': 'No addresses yet',
      'addressLabelHint': 'Label (e.g. Home, Work)',
      'detailedAddress': 'Full address',
      'addBtn': 'Add',
      'fillCompleteInfo': 'Please fill in all required fields',
      'contactCustomerService': 'Customer service',
      'termsOfService': 'Terms of service',
      'buyPackageLink': 'Buy package',
      'newPasswordLeaveBlank': 'New password (leave blank to keep)',
      'customerServiceTitle': 'Customer service',
      'hqPhoneTitle': 'HQ support phone',
      'hqPhoneHours': '400-888-6688 · 9:00–21:00',
      'onlineMessage': 'Online message',
      'messageHint': 'Describe your issue — we will reply soon',
      'messageSubmitted': 'Message sent. Support will contact you soon.',
      'submitMessage': 'Submit message',
      'termsTitle': 'Terms of service',
      'termsHeading': 'Wash On Demand Terms of Service',
      'termsBody':
          '1. Placing an order means you agree to platform rules and pricing.\n'
          '2. Arrive on time for bookings; late arrival may affect service.\n'
          '3. Follow device instructions for self-service; misuse damage is your responsibility.\n'
          '4. Refunds and disputes are handled within applicable law.',
      'tabAll': 'All',
      'tabUnpaid': 'Unpaid',
      'tabInProgress': 'In progress',
      'tabCompleted': 'Completed',
      'noOrdersAll': 'No orders yet',
      'noOrdersUnpaidTitle': 'No unpaid orders',
      'noOrdersInProgressTitle': 'No orders in progress',
      'noOrdersCompletedTitle': 'No completed orders',
      'noOrdersAllHint': 'Scan to wash on the home tab to see orders here',
      'noOrdersUnpaidHint': 'Unpaid orders appear here after creation',
      'noOrdersInProgressHint': 'Paid, in-progress washes appear here',
      'noOrdersCompletedHint': 'Finished or refunded orders appear here',
      'selfServiceOrdersSubtitle': 'Self-service wash orders',
      'defaultWashPackage': 'Wash package',
      'washStoreFallback': 'Car wash store',
      'creditsUsedOnce': '-1 credit',
      'shareGiftTitle': 'Share & earn',
      'shareBeforeFirstWash':
          'Complete your first wash to share your invite code. You and your friend each get 1 free wash.',
      'shareToFriends': 'Share with friends',
      'shareCodeBenefit':
          'When a friend registers or redeems your code, you each get 1 free wash.',
      'shareCodeCopied': 'Share code copied',
      'shareTextCopied': 'Share text copied — paste to send',
      'shareAndFreeWash': 'Share & free washes',
      'remainingCountLabel': 'Remaining',
      'usedCountLabel': 'Used',
      'shareSuccessCountLabel': 'Referrals',
      'shareBenefitDetail':
          'Share with friends — each gets 1 free wash. Friends can enter at sign-up or redeem below.',
      'invitedFriends': 'Invited friends:',
      'redeemShareCode': 'Redeem share code',
      'enterFriendShareCode': "Enter friend's share code",
      'redeemSuccess': 'Code redeemed — you each get 1 free wash',
      'redeemShareCodeBtn': 'Redeem code',
      'myWallet': 'My wallet',
      'withdrawableBalance': 'Withdrawable balance',
      'withdraw': 'Withdraw',
      'incomeDetails': 'Income history',
      'noTransactions': 'No transactions yet',
      'withdrawAmount': 'Withdrawal amount',
      'enterValidAmount': 'Enter a valid amount',
      'withdrawSubmitted': 'Withdrawal request submitted',
      'confirmWithdraw': 'Confirm withdrawal',
      'myReviews': 'My reviews',
      'noReviews': 'No reviews yet',
      'scanQrAlignHint': 'Align the device QR code in the frame',
      'approvalCenter': 'Review center',
      'allClear': 'Queue clear — all reviewed',
      'shopAccountReview': 'Merchant account review',
      'noPendingShopAccounts': 'No pending merchant accounts',
      'storeReview': 'Store review',
      'noPendingStores': 'No pending stores',
      'clearedBadge': 'Clear',
      'reviewBtn': 'Review',
      'approveSegment': 'Approve',
      'rejectSegment': 'Reject',
      'approvalCommentOptional': 'Comment (optional; recommended when rejecting)',
      'submitApproval': 'Submit review',
      'defaultMerchantName': 'Merchant',
      'defaultStoreName': 'Store',
      'operatingLicense': 'Business license',
      'editBundlePlan': 'Edit wash package',
      'packageNameLabel': 'Package name',
      'washCountLabel': 'Wash count',
      'priceYuanLabel': 'Price (CNY)',
      'bundlePricingUpdated': 'Package pricing updated',
      'platformPricing': 'Platform pricing',
      'platformPricingDesc':
          'Manage user wash credit packages. Per-store single-wash prices are set in the merchant portal.',
      'shopPricingTitle': 'Pricing',
      'shopPricingDesc':
          'Set wash counts and prices for credit packages users buy on the Packages tab.',
      'storeWashPackagePricing': 'In-store wash packages',
      'storeWashPackagePricingHint':
          'Quick / standard / premium prices are edited on each store card under the Stores tab.',
      'washCreditBundlesSection': 'Wash credit packages',
      'washCreditBundlesSectionHint':
          'Tap a row to edit name, wash count, and price.',
      'tapToEditPrice': 'Tap to edit',
      'priceFormatInvalid': 'Invalid price format',
      'countFormatInvalid': 'Invalid wash count',
      'imageLoadFailed': 'Image failed to load\nCheck upload and backend',
      'imageCannotLoad': 'Cannot load image',
      'fileNotUploadedYet': 'File may not be uploaded to server',
      'tapToZoom': 'Tap to zoom',
      'pdfNoPreview':
          'PDF preview is not supported in-app. Upload jpg/png to view on phone.',
      'noUploadedMaterials': 'No materials uploaded',
      'noFileSelected': 'No file selected',
      'cannotReadFilename': 'Cannot read file name',
      'cannotReadFileContent': 'Cannot read file — try again',
      'fileTooLarge': 'Each file must be under 10MB',
      'unsupportedLicenseFormat': 'License files: pdf, jpg, jpeg, png only',
      'uploadNoFilename': 'Upload succeeded but no filename returned',
      'licenseUploadHint':
          'Upload business license as pdf, jpg, jpeg, or png (max 10MB each)',
      'uploading': 'Uploading…',
      'selectAndUpload': 'Choose & upload file',
      'tapImageFullPreview': 'Tap image for full-screen preview',
      'todayCompleted': 'Completed today',
      'todayRevenue': "Today's revenue",
      'walletBalance': 'Wallet balance',
      'viewBtn': 'View',
      'commonTools': 'Tools',
      'walletShort': 'Wallet',
      'reviewsShort': 'Reviews',
      'customerServiceShort': 'Support',
      'settingsShort': 'Settings',
      'accountInfo': 'Account',
      'shopInfoSection': 'Store info',
      'loginAccount': 'Login ID',
      'shopAddressLabel': 'Store address',
      'notFilled': 'Not set',
      'mapCoordinates': 'Map coordinates',
      'manageStores': 'Manage stores',
      'businessLicense': 'Business license',
      'uploadBusinessLicense': 'Upload business license',
      'goUpload': 'Upload',
      'editProfile': 'Edit profile',
      'profileSyncHint': 'Changes sync to your store profile',
      'accountSection': 'Account',
      'addressAndCoordinates': 'Address & coordinates',
      'profileSaved': 'Profile saved',
      'uploadAtLeastOneLicense': 'Upload at least one business license',
      'latLngFormatInvalid': 'Invalid latitude/longitude',
      'fillAllRequired': 'Please fill all required fields',
      'hkRegionTitle': 'Hong Kong (3 regions · 18 districts · sub-areas)',
      'hkMajorRegion': 'Major region',
      'hk18Districts': '18 districts',
      'hkSubArea': 'Sub-area',
      'hkDetailAddress': 'Detail address (street/building, optional)',
      'paymentSessionExpiredReturn': 'Payment session expired — go back and retry',
      'fillCompleteCardInfo': 'Please complete card details',
      'paymentCancelledByUser': 'Payment cancelled',
      'expiredLabel': 'Expired',
      'selectPaymentMethod': 'Select payment method',
      'iosOnly': 'iOS devices only',
      'pciComplianceNote':
          'Production should use PCI-certified hosted fields (Stripe / Adyen). '
          'This app does not store full card numbers or CVV.',
      'creatingPayment': 'Creating payment…',
      'awaitingAuthorization': 'Awaiting authorization…',
      'verifyingPayment': 'Verifying payment…',
      'sessionExpired': 'Session expired',
      'selectMethodFirst': 'Select a payment method',
      'amountDue': 'Amount due',
      'usedFreeWashCredits': 'Free wash credit used',
      'sessionValid15Min': 'Payment session valid for 15 minutes',
      'cardholderName': 'Cardholder name',
      'enterCardholderName': 'Enter cardholder name',
      'cardNumber': 'Card number',
      'invalidCardNumber': 'Enter a valid card number',
      'expiryDate': 'Expiry MM/YY',
      'expiryFormat': 'Use MM/YY format',
      'cvvInvalid': '3–4 digits',
      'processingPayment': 'Processing…',
      'creatingPaymentBanner': 'Creating payment…',
      'authInProviderBanner': 'Complete verification in payment app…',
      'verifyingBanner': 'Verifying payment…',
      'processingGeneric': 'Processing…',
      'paymentFailed': 'Payment failed',
      'paymentFlowNotice':
          'Flow: choose method → confirm → authorize in provider → server verify → receipt. '
          'Alipay/WeChat passwords are entered only in official apps.',
      'paymentSuccessTitle': 'Payment successful',
      'paySuccess': 'Paid successfully',
      'receiptPaymentMethod': 'Payment method',
      'receiptMerchant': 'Merchant',
      'receiptProduct': 'Product',
      'receiptOrderId': 'Order ID',
      'receiptTransactionId': 'Transaction ID',
      'receiptProviderRef': 'Provider reference',
      'receiptPaidAt': 'Paid at',
      'receiptKeepTransactionId': 'Keep the transaction ID for inquiries. Payment verified by server.',
      'completeAndStartWash': 'Done — start wash',
      'enterPayPassword': 'Enter payment password',
      'wechatPayFailed': 'WeChat Pay failed',
      'alipayPayFailed': 'Alipay failed',
      'authFailed': 'Authorization failed',
      'confirmPaymentInfo': 'Confirm payment details to continue',
      'confirmApplePayInfo': 'Confirm Apple Pay details',
      'applePaySecurityHint': 'Biometric verification handled by Apple Pay.',
      'cardEncryptedHint': 'Card data is encrypted; full PAN/CVV not stored.',
      'payWithFaceId': 'Pay with Face ID',
      'confirmCreditCardPay': 'Confirm card payment',
      'payeeLabel': 'Payee',
      'paymentAmount': 'Amount',
      'payerAccountLabel': 'Payer account',
      'retryWechatPay': 'Retry WeChat Pay',
      'retryAlipayPay': 'Retry Alipay',
      'simulatePaymentTest': 'Simulate payment (test)',
      'paymentMethodAlipayRedirect': 'Opens Alipay cashier — enter password',
      'paymentMethodWechatRedirect': 'Opens WeChat cashier — enter password',
      'paymentMethodApplePayBiometric': 'Face ID / Touch ID to pay',
      'paymentMethodCreditCardBrands': 'Visa · Mastercard · UnionPay',
      'orderFlow1': '1. Order created — awaiting scan or online payment',
      'orderFlow2': '2. Paid — merchant received payment, waiting for device start',
      'orderFlow3': '3. Sending start command to device',
      'orderFlow4': '4. Washing — follow on-device instructions',
      'orderFlow5': '5. Wash complete — order closed',
      'orderFlow6': 'Error: device failed to start or order exception',
      'orderFlow7': 'Refunded — flow ended',      'reservationRecords': 'Booking history',
      'noStoresToReserveDesc': 'Try again later, or check nearby stores on the Wash tab.',
      'myOrdersSubtitleTrack': 'Track payment, start, washing, completion, and error status.',
      'noOrdersYet': 'No orders yet',
      'scanOnHomeHint': 'Select a store on the Wash tab and scan to pay.',
      'reservationFormShopTitle': 'Store bookings',
      'reservationFormShopSubtitle': 'Filter bookings submitted by users per store.',
      'shopReservationsEmptyDesc': 'Bookings will appear here after users submit them.',
      'adminOverviewSubtitle': 'Platform overview and key metrics.',
      'refreshFromBackend': 'Refresh from server',
      'storesAndBaysSubtitle': 'All merchant stores and bay statistics.',
      'adminReservationsEmptyDesc': 'Bookings will appear here after users submit them.',
      'adminOrdersEmptyDesc': 'Orders will appear here after users scan and pay.',
      'storeFilterLabel': 'Store filter',
      'countryCodeLabel': 'Country code',
      'searchCountryHint': 'Search country/region or dial code',
      'noDialCodeMatch': 'No matching dial code found',
      'geocodeCoordsUpdated': 'Coordinates updated from address',
      'shopRegReviewTitle': 'Merchant registration review',
      'merchantLicensePermit': 'Business permit',
      'resubmitForReview': 'Update materials and resubmit',
      'materialsResubmittedWait': 'Materials resubmitted. Please wait for admin review.',
      'fullNameLabel': 'Full name',
      'getVerificationCode': 'Get code',
      'referralCodeOptional': 'Referral code (optional)',
      'fillPhoneFirst': 'Enter phone number first',
      'fillEmailFirst': 'Enter email address first',
      'invalidEmailFormat': 'Enter a valid email address',
      'smsCodeSent': 'Verification code sent',
      'emailCodeSent': 'Verification code sent to your email',
      'addressGeocodedOk': 'Address geocoded',
      'merchantPhoneNumber': 'Merchant phone number',
      'submittingLabel': 'Submitting…',
      'registerShopOnMap': 'Register merchant & add to map',
      'scanPayTitle': 'Scan to pay',
      'currentDeviceLabel': 'Current device',
      'useFreeWashSubtitlePay': 'When on, pay ¥0; when off, pay package price',
      'actualPaymentLabel': 'Amount due',
      'processingLabel': 'Processing…',
      'confirmStartWash': 'Confirm & start wash',
      'selectDeviceQr': 'Please select a device QR code',
      'selectPackageRequired': 'Please select a package',
      'freeWashLabel': 'Free wash',
      'defaultCarWashStore': 'Car wash store',
      'defaultUserLabel': 'User',
      'locationLoadingDots': 'Getting location…',
      'locationDisabledHkFallback': 'Location off. Using Central & Western, HK as default.',
      'locationDeniedHkFallback': 'Location denied. Using Central & Western, HK as default.',
      'locationSuccessSorted': 'Location updated. Stores sorted by distance.',
      'locationFailedHkFallback': 'Location failed. Using Central & Western, HK as default.',
      'reservationNotePlaceholder': 'Notes, e.g. vehicle model or wash needs',
      'manualServiceDetailHint': 'Merchant manual reception & detail wash',
      'durationMinLabel': 'Duration (minutes)',
      'durationFormatInvalid': 'Invalid duration format',
      'packagePriceUpdated': 'Package price updated',
      'metricMapPoints': 'Map points',
      'metricFaultDevices': 'Fault devices',
      'storePendingReview': 'Pending review',
      'storeRejectedReview': 'Rejected',
      'addWashBaySlot': 'Add wash bay',
      'setIdleOnline': 'Set idle (online)',
      'bayNameExample': 'Bay name, e.g. Self-4 / Manual-1',
      'bayTypeLabel': 'Bay type',
      'selfServiceBayLabel': 'Self-service bay',
      'manualBayLabel': 'Manual wash bay',
      'shopRegSubmittedAdmin': 'Registration submitted. Please wait for admin review.',
      'approvedDefaultReply': 'Approved',
      'rejectReplyPlaceholder': 'Enter materials the merchant should update or provide',
      'defaultRejectMessage': 'Please update or supplement registration materials',
      'redeemedFreeWash': 'Free wash redeemed',
      'simulatePayStart': 'Simulate pay & start',
      'selectReservationTypeLabel': 'Select booking type',
      'addNewShopBtn': 'Add new store',
      'shopOrdersEmptyDesc': 'Orders appear here after users scan and pay.',
      'completedOrdersLabel': 'Completed orders',
      'errLoginAsUser': 'Please log in as a user first',
      'errPackageNotFound': 'Package not found',
      'errSmsCode0000': 'Invalid code. Use 0000 in test mode.',
      'errFillPhone': 'Enter phone number',
      'errFillEmail': 'Enter email address',
      'errSmsCode1111': 'Invalid code. Use 1111 in test mode.',
      'errUploadLicense': 'Upload at least one business license file',
      'errShopOnlyResubmit': 'Only merchant accounts can resubmit materials',
      'errLoginAsShop': 'Please log in as a merchant first',
      'errShopOnlyEditProfile': 'Only merchant accounts can edit profile',
      'errFillComplete': 'Please fill in all required fields',
      'errAccountExists': 'Account already exists. Choose another username.',
      'errUserOnlyReferral': 'Only user accounts can use referral codes',
      'errReferralUsed': 'You have already used a referral code',
      'errReferralInvalid': 'Invalid referral code. Please check and try again.',
      'errReferralSelf': 'You cannot use your own referral code',
      'errLoginAsShopMerchant': 'Please log in as a merchant first',
      'errWithdrawPositive': 'Withdrawal amount must be greater than 0',
      'errInsufficientBalance': 'Insufficient balance',
      'errDeviceQrNotFound': 'Device QR code not found',
      'errDeviceUnavailable': 'Device unavailable. Choose an idle device.',
      'errCannotUseBothCredits': 'Cannot use free wash and prepaid credits together',
      'errNoFreeWash': 'No free wash credits available',
      'errNoPrepaidWash': 'No prepaid wash credits available',
      'errOrderNotFound': 'Order not found',
      'errOrderNotPayable': 'Order cannot be paid in current status',
      'errDeviceNotIdle': 'Device not idle; escalated to backend exception handling',
      'errServiceTypeUnsupported': 'This store does not support the selected service type',
      'errFillContactPhone': 'Enter contact phone number',
      'errFillRequired': 'Please fill in all required fields',
      'errSelectOneService': 'Select at least one service type',
      'errInvalidLatLng': 'Invalid latitude/longitude format',
      'materialsResubmittedAdminReply': 'Materials resubmitted. Awaiting admin review.',

    },
    AppLocale.zhHans: {
      'appTitle': '清洗到家',
      'appTagline': '智慧洗车 · 一键预约 · 轻松管理',
      'welcomeLogin': '欢迎登录',
      'loginRoleHint': '登录后根据账号角色进入用户 / 商家 / 管理端',
      'phoneOrTestAccount': '手机号或测试账号',
      'phoneLoginHint': '手机号登录只输入号码；测试账号 user / shop / admin 不受区号影响。',
      'password': '密码',
      'login': '登录',
      'loggingIn': '登录中…',
      'userRegister': '用户注册',
      'shopRegister': '商家注册',
      'demoAccounts': '演示账号',
      'demoUser': 'User: user / 123456',
      'demoShop': 'Shop: shop / 123456',
      'demoAdmin': 'Admin: admin / 123456',
      'accountMismatch': '账号或密码不匹配',
      'accountPending': '账号正在等待平台审核',
      'accountRejected': '账号审核未通过，请联系平台管理员',
      'backendUnreachable': '无法连接服务器，请检查网络并确认后端已启动。',
      'syncingData': '正在同步最新数据…',
      'syncFailedHint': '数据刷新失败，下拉可重试。',
      'retrySync': '重试',
      'languageTitle': '语言',
      'tabCarWash': '洗车',
      'tabPackages': '套餐',
      'tabOrders': '订单',
      'tabProfile': '个人中心',
      'tabStores': '门店',
      'tabReservations': '预约',
      'tabMine': '我的',
      'tabApproval': '审核',
      'tabOverview': '概览',
      'tabStoresAdmin': '门店',
      'tabReservationsAdmin': '预约',
      'tabOrdersAdmin': '订单',
      'tabPricing': '定价',
      'carWashTitle': '洗车',
      'carWashSubtitle': '地图显示附近洗车店，支持自助扫码洗车与到店预约。',
      'myLocation': '我的位置',
      'nearbyStores': '附近门店',
      'noStores': '暂无门店',
      'noStoresDesc': '当前没有已审核通过的洗车店。',
      'runningOrderTitle': '洗车进行中',
      'runningOrderSubtitle': '点击查看订单详情',
      'locationLoading': '正在获取位置…',
      'locationDisabled': '定位服务未开启',
      'locationDenied': '未获得定位权限',
      'locationFailed': '获取位置失败',
      'locationSuccess': '位置已更新',
      'viewMap': '查看地图',
      'googleNav': 'Google导航',
      'reserveStore': '预约到店',
      'scanWash': '扫码洗车',
      'idleCount': '空闲工位',
      'buyPackages': '购买洗车次卡',
      'buyPackagesSubtitle': '购买洗车次数套餐，扫码洗车时可使用次卡免支付。',
      'myWashCredits': '我的洗车次数',
      'selectPackage': '选择套餐',
      'buyNow': '立即购买',
      'recentUsage': '最近使用',
      'noUsageHistory': '暂无使用记录',
      'noUsageHistoryDesc': '购买套餐后，扫码洗车使用次卡会显示在这里。',
      'packagePaymentHint':
          '点击「立即购买」进入收银台完成付款，付款成功后洗车次数自动到账。',
      'purchaseFailed': '购买失败',
      'creditsLine': '次卡 · 免费次数',
      'cashierTitle': '收银台',
      'scanCarWashTitle': '扫码洗车',
      'scanCarWashSubtitle': '扫描设备二维码，选择套餐后进入收银台完成付款。',
      'rescan': '重新扫码',
      'selectPackageLabel': '选择套餐',
      'actualAmount': '实付金额',
      'useFreeWashOn': '使用免费洗车（有可用次数）',
      'useFreeWashOff': '使用免费洗车（暂无可用次数）',
      'useFreeWashSubtitleOn': '开启后本单实付款 ¥0',
      'useFreeWashSubtitleOff': '完成分享或兑换后可获得免费洗车次数',
      'usePrepaidOn': '使用洗车次卡（有可用次数）',
      'usePrepaidOff': '暂无洗车次卡',
      'usePrepaidSubtitleOn': '开启后本单免支付，优先消耗次卡',
      'usePrepaidSubtitleOff': '可在个人中心购买次卡套餐',
      'prepaidUsedNotice': '已使用次卡，按套餐原价结算',
      'unknownQr': '未识别的二维码，请扫描洗车设备码',
      'myOrdersTitle': '我的订单',
      'myOrdersSubtitle': '查看洗车订单与进度',
      'noOrdersTitle': '暂无订单',
      'noOrdersDesc': '扫码洗车或购买套餐后可在此查看订单。',
      'personalCenter': '个人中心',
      'personalCenterSubtitle': '账号、次卡与设置',
      'logout': '退出登录',
      'settingsTitle': '设置',
      'nickname': '昵称',
      'phone': '手机号',
      'newPasswordOptional': '新密码（选填）',
      'autoUseFreeWash': '自动使用免费洗车',
      'settingsSaved': '设置已保存',
      'save': '保存',
      'saving': '保存中…',
      'shopMerchantTitle': '商家端',
      'shopMerchantSubtitle': '管理门店、工位、预约与订单',
      'addNewStore': '新增门店',
      'reservationFormTitle': '门店预约',
      'reservationFormSubtitle': '查看并管理用户到店预约',
      'shopOrdersTitle': '门店订单',
      'shopOrdersSubtitle': '查看本店洗车订单',
      'noReservationsTitle': '暂无预约',
      'noReservationsDesc': '用户提交的预约会显示在这里。',
      'noOrdersShopTitle': '暂无订单',
      'noOrdersShopDesc': '本店洗车订单会显示在这里。',
      'collected': '已收款',
      'pendingPay': '待支付',
      'completedOrders': '已完成',
      'adminPlatformTitle': '管理端',
      'adminPlatformSubtitle': '审核账号、门店与平台定价',
      'accountManagementTitle': '账号管理',
      'accountManagementSubtitle': '审核用户与商家注册',
      'approve': '批准',
      'rejectAndReply': '拒绝并回复',
      'reviewReply': '审核回复',
      'rejectAndSend': '拒绝并发送',
      'allStoresFilter': '全部门店',
      'userAccounts': '用户账号',
      'shopAccounts': '商家账号',
      'exitLogin': '退出登录',
      'roleUser': '用户',
      'roleShop': '商家',
      'roleAdmin': '管理员',
      'approvalPending': '待审核',
      'approvalApproved': '已通过',
      'approvalRejected': '已拒绝',
      'orderStatusCreated': '待支付',
      'orderStatusPaid': '已支付',
      'orderStatusStarting': '启动中',
      'orderStatusRunning': '洗车中',
      'orderStatusCompleted': '已完成',
      'orderStatusFailed': '异常',
      'orderStatusRefunded': '已退款',
      'deviceIdle': '空闲',
      'deviceBusy': '使用中',
      'deviceOffline': '离线',
      'deviceFaulted': '故障',
      'selfService': '自助洗车',
      'manualService': '人工洗车',
      'selfServiceEco': '环保自助',
      'resPending': '待到店',
      'resArrived': '已到店',
      'resCompleted': '已完成',
      'resCancelled': '已取消',
      'myReservations': '我的预约',
      'myReservationsSubtitle': '选择门店并填写信息，即可提交到店预约。',
      'noStoresToReserve': '暂无可预约门店',
      'noReservationsYet': '暂无预约',
      'noReservationsYetDesc': '填写上方表单即可提交第一条预约。',
      'newReservation': '新建预约',
      'selectStore': '选择门店',
      'reservationDate': '预约日期',
      'reservationTime': '预约时间',
      'contactPhone': '联系电话',
      'reservationType': '预约类型',
      'reservationNote': '备注',
      'submitReservation': '提交预约',
      'reservationSubmitted': '预约已提交',
      'reserveVisitTitle': '预约到店',
      'selectReservationType': '选择预约类型',
      'createReservationPage': '新建预约',
      'paymentMethodAlipay': '支付宝',
      'paymentMethodWechat': '微信支付',
      'paymentMethodApplePay': 'Apple Pay',
      'paymentMethodCreditCard': '信用卡',
      'paymentMethodAlipaySub': '使用支付宝余额或绑定银行卡支付',
      'paymentMethodWechatSub': '使用微信余额或绑定银行卡支付',
      'paymentMethodApplePaySub': '使用本设备 Apple Pay 支付',
      'paymentMethodCreditCardSub': '支持 Visa、Mastercard 等主流卡',
      'paymentProviderAlipay': '支付宝',
      'paymentProviderWechat': '微信支付',
      'paymentProviderApplePay': 'Apple Pay',
      'paymentProviderBank': '银行卡',
      'paymentCancelled': '已取消支付',
      'confirmPayment': '确认支付',
      'cancelPayment': '取消支付',
      'confirmContinue': '确认并继续',
      'packagePrices': '套餐价格',
      'addBay': '添加工位',
      'addStorePage': '新增门店',
      'submitNewStore': '提交门店',
      'storeSubmitted': '门店已提交，等待审核',
      'simulatePayAndStart': '模拟支付并启动',
      'finishWash': '结束洗车',
      'orderFlowLabel': '流程',
      'paymentMethodLabel': '支付方式',
      'transactionIdLabel': '交易号',
      'paidAtLabel': '支付时间',
      'minutesUnit': '分钟',
      'washPackagePrices': '洗车次卡定价',
      'addWashBay': '添加洗车工位',
      'setIdle': '设为空闲',
      'setOffline': '设为离线',
      'setFault': '设为故障',
      'bayNameLabel': '工位名称',
      'addBayButton': '添加工位',
      'storeNameLabel': '门店名称',
      'storeAddressLabel': '门店地址',
      'latitude': '纬度',
      'longitude': '经度',
      'licenseMaterials': '证照材料',
      'serviceTypes': '服务类型',
      'modifyMaterials': '修改材料',
      'materialsResubmitted': '材料已重新提交，等待审核',
      'shopReviewTitle': '商家审核',
      'adminReply': '管理员回复',
      'merchantLicense': '营业执照',
      'userRegTitle': '用户注册',
      'shopRegTitle': '商家注册',
      'merchantName': '商户名称',
      'merchantAddress': '商户地址',
      'merchantPhone': '商户电话',
      'smsCode': '短信验证码',
      'emailLabel': '邮箱',
      'emailVerificationCode': '邮箱验证码',
      'friendReferralCode': '好友推荐码（选填）',
      'registerLogin': '注册并登录',
      'shopRegSubmitted': '注册已提交，请等待平台审核',
      'noCountryMatch': '未找到匹配的国家或地区',
      'homeLabel': '首页',
      'standardWashDemo': '标准洗车演示',
      'withdrawToAlipay': '提现到支付宝',
      'sharePanelTitle': '分享赚免费洗车',
      'copyShareCode': '复制分享码',
      'copyShareText': '复制分享文案',
      'freeWashCreditsLabel': '免费洗车次数',
      'orderInProgress': '订单进行中',
      'clickForDetails': '点击查看详情',
      'mapLoading': '地图加载中…',
      'adminPricingTitle': '平台次卡定价',
      'editPackage': '编辑套餐',
      'packageUpdated': '套餐已更新',
      'saveFailed': '保存失败',
      'userAccountMgmt': '用户账号管理',
      'shopAccountMgmt': '商家账号管理',
      'viewLicenseMaterials': '查看证照材料',
      'storesAndBays': '门店与工位',
      'allReservationsAdmin': '全部预约',
      'allOrdersAdmin': '全部订单',
      'personalSettingsPage': '个人设置',
      'merchantPhoneFixed': '商户电话（审核通过后不可修改）',
      'licenseUpload': '上传证照',
      'addStoreBtn': '添加门店',
      'addressLabel': '地址',
      'serviceSummary': '服务项目',
      'modifyPackageTitle': '修改套餐',
      'cancelBtn': '取消',
      'saveBtn': '保存',
      'emptyStateDefault': '暂无内容',
      'myVehicles': '我的车辆',
      'addVehicle': '添加车辆',
      'commonAddresses': '常用地址',
      'addAddress': '添加地址',
      'washCreditsCard': '洗车次卡',
      'myPoints': '我的积分',
      'allOrders': '全部订单',
      'myVehiclesTitle': '我的车辆',
      'noVehicles': '暂无车辆',
      'vehicleModel': '车型',
      'plateNumber': '车牌号',
      'colorOptional': '颜色（选填）',
      'commonAddressesTitle': '常用地址',
      'noAddresses': '暂无地址',
      'addressLabelHint': '标签（如：家、公司）',
      'detailedAddress': '详细地址',
      'addBtn': '添加',
      'fillCompleteInfo': '请填写完整信息',
      'contactCustomerService': '联系客服',
      'termsOfService': '服务条款',
      'buyPackageLink': '购买套餐',
      'newPasswordLeaveBlank': '新密码（留空不修改）',
      'customerServiceTitle': '联系客服',
      'hqPhoneTitle': '总部客服电话',
      'hqPhoneHours': '400-888-6688 · 9:00–21:00',
      'onlineMessage': '在线留言',
      'messageHint': '请描述您的问题，客服将尽快回复',
      'messageSubmitted': '留言已提交，客服会尽快联系您',
      'submitMessage': '提交留言',
      'termsTitle': '服务条款',
      'termsHeading': '清洗到家服务条款',
      'termsBody':
          '1. 用户下单即表示同意平台服务规范与价格说明。\n'
          '2. 预约到店请按时到达，迟到可能影响服务安排。\n'
          '3. 自助洗车请按设备提示操作，违规使用造成的损坏由用户承担。\n'
          '4. 平台将在法律允许范围内处理退款与纠纷。',
      'tabAll': '全部',
      'tabUnpaid': '待支付',
      'tabInProgress': '进行中',
      'tabCompleted': '已完成',
      'noOrdersAll': '还没有订单',
      'noOrdersUnpaidTitle': '暂无待支付订单',
      'noOrdersInProgressTitle': '暂无进行中订单',
      'noOrdersCompletedTitle': '暂无已完成订单',
      'noOrdersAllHint': '在洗车页扫码支付后即可在此查看',
      'noOrdersUnpaidHint': '创建订单后未支付会显示在这里',
      'noOrdersInProgressHint': '支付后正在洗车的订单会显示在这里',
      'noOrdersCompletedHint': '洗完或已退款的订单会显示在这里',
      'selfServiceOrdersSubtitle': '自助洗车订单',
      'defaultWashPackage': '洗车套餐',
      'washStoreFallback': '洗车门店',
      'creditsUsedOnce': '-1 次',
      'shareGiftTitle': '分享有礼',
      'shareBeforeFirstWash':
          '完成首次洗车后，即可分享专属邀请码给好友。您和好友各获得 1 次免费洗车机会。',
      'shareToFriends': '分享给好友',
      'shareCodeBenefit': '好友注册或在我的页面填写分享码后，双方各得 1 次免费洗车。',
      'shareCodeCopied': '分享码已复制',
      'shareTextCopied': '分享文案已复制，可粘贴给好友',
      'shareAndFreeWash': '分享与免费洗车',
      'remainingCountLabel': '剩余次数',
      'usedCountLabel': '已使用',
      'shareSuccessCountLabel': '分享成功',
      'shareBenefitDetail': '分享给好友，双方各得 1 次免费洗车。好友可在注册时填写，或在下方兑换。',
      'invitedFriends': '已邀请好友：',
      'redeemShareCode': '兑换分享码',
      'enterFriendShareCode': '输入好友分享码',
      'redeemSuccess': '分享码兑换成功，双方各得 1 次免费洗车',
      'redeemShareCodeBtn': '兑换分享码',
      'myWallet': '我的钱包',
      'withdrawableBalance': '可提现余额',
      'withdraw': '提现',
      'incomeDetails': '收入明细',
      'noTransactions': '暂无交易记录',
      'withdrawAmount': '提现金额',
      'enterValidAmount': '请输入有效金额',
      'withdrawSubmitted': '提现申请已提交',
      'confirmWithdraw': '确认提现',
      'myReviews': '我的评价',
      'noReviews': '暂无评价',
      'scanQrAlignHint': '将设备二维码放入框内自动识别',
      'approvalCenter': '审核中心',
      'allClear': '暂无待审核项，全部已处理',
      'shopAccountReview': '商家账号审核',
      'noPendingShopAccounts': '暂无待审商家账号',
      'storeReview': '门店审核',
      'noPendingStores': '暂无待审门店',
      'clearedBadge': '已清空',
      'reviewBtn': '审核',
      'approveSegment': '通过',
      'rejectSegment': '驳回',
      'approvalCommentOptional': '审批意见（选填，驳回时建议填写）',
      'submitApproval': '提交审批',
      'defaultMerchantName': '商家',
      'defaultStoreName': '门店',
      'operatingLicense': '经营许可证',
      'editBundlePlan': '编辑次卡套餐',
      'packageNameLabel': '套餐名称',
      'washCountLabel': '洗车次数',
      'priceYuanLabel': '售价（元）',
      'bundlePricingUpdated': '次卡定价已更新',
      'platformPricing': '平台定价',
      'platformPricingDesc': '管理用户洗车次卡套餐。门店单次洗车价格在商家端各店铺内修改。',
      'shopPricingTitle': '定价管理',
      'shopPricingDesc': '设置用户在「套餐」页购买的洗车次卡次数与售价。',
      'storeWashPackagePricing': '门店单次洗车套餐',
      'storeWashPackagePricingHint': '快速冲洗、标准自助、精洗等价格在「门店」页各店铺卡片内修改。',
      'washCreditBundlesSection': '洗车次卡套餐',
      'washCreditBundlesSectionHint': '点击套餐可修改名称、次数与售价。',
      'tapToEditPrice': '点击修改',
      'priceFormatInvalid': '价格格式不正确',
      'countFormatInvalid': '次数格式不正确',
      'imageLoadFailed': '图片加载失败\n请确认文件已上传且后端正在运行',
      'imageCannotLoad': '图片无法加载',
      'fileNotUploadedYet': '文件可能尚未上传到服务器',
      'tapToZoom': '点击放大',
      'pdfNoPreview': 'PDF 文件暂不支持 App 内预览，请上传 jpg/png 图片格式以便在手机上直接查看。',
      'noUploadedMaterials': '暂无上传材料',
      'noFileSelected': '未选择文件',
      'cannotReadFilename': '无法读取文件名',
      'cannotReadFileContent': '无法读取文件内容，请重试',
      'fileTooLarge': '单个文件不能超过 10MB',
      'unsupportedLicenseFormat': '许可证文件仅支持 pdf、jpg、jpeg、png',
      'uploadNoFilename': '上传成功但服务器未返回文件名',
      'licenseUploadHint': '请上传 pdf、jpg、jpeg、png 格式的经营许可证，单个文件不超过 10MB',
      'uploading': '上传中…',
      'selectAndUpload': '选择并上传文件',
      'tapImageFullPreview': '点击图片可全屏预览',
      'todayCompleted': '今日完成',
      'todayRevenue': '今日收入',
      'walletBalance': '钱包余额',
      'viewBtn': '查看',
      'commonTools': '常用工具',
      'walletShort': '钱包',
      'reviewsShort': '评价',
      'customerServiceShort': '客服',
      'settingsShort': '设置',
      'accountInfo': '账户信息',
      'shopInfoSection': '店铺信息',
      'loginAccount': '登录账号',
      'shopAddressLabel': '店铺地址',
      'notFilled': '未填写',
      'mapCoordinates': '地图坐标',
      'manageStores': '管理店铺',
      'businessLicense': '经营许可证',
      'uploadBusinessLicense': '请上传经营许可证',
      'goUpload': '去上传',
      'editProfile': '编辑资料',
      'profileSyncHint': '修改后将同步更新店铺信息',
      'accountSection': '账户',
      'addressAndCoordinates': '地址与坐标',
      'profileSaved': '资料已保存',
      'uploadAtLeastOneLicense': '请上传至少一个经营许可证文件',
      'latLngFormatInvalid': '经纬度格式不正确',
      'fillAllRequired': '请填写所有必填信息',
      'hkRegionTitle': '香港地区（三大区 · 18区 · 细分区域）',
      'hkMajorRegion': '三大区',
      'hk18Districts': '18区',
      'hkSubArea': '细分区域',
      'hkDetailAddress': '详细地址（街道/大厦，选填）',
      'paymentSessionExpiredReturn': '支付会话已过期，请返回重新下单',
      'fillCompleteCardInfo': '请填写完整的信用卡资料',
      'paymentCancelledByUser': '您已取消支付',
      'expiredLabel': '已过期',
      'selectPaymentMethod': '选择付款方式',
      'iosOnly': '仅 iOS 设备可用',
      'pciComplianceNote':
          '正式环境应使用 Stripe / Adyen 等 PCI 认证托管字段，本 App 不会储存完整卡号或 CVV。',
      'creatingPayment': '创建支付单...',
      'awaitingAuthorization': '等待授权...',
      'verifyingPayment': '校验支付结果...',
      'sessionExpired': '会话已过期',
      'selectMethodFirst': '请选择付款方式',
      'amountDue': '应付金额',
      'usedFreeWashCredits': '已使用免费洗车次数',
      'sessionValid15Min': '支付会话 15 分钟内有效',
      'cardholderName': '持卡人姓名',
      'enterCardholderName': '请填写持卡人姓名',
      'cardNumber': '卡号',
      'invalidCardNumber': '请输入有效的卡号',
      'expiryDate': '到期日 MM/YY',
      'expiryFormat': '格式 MM/YY',
      'cvvInvalid': '3-4 位数字',
      'processingPayment': '处理中...',
      'creatingPaymentBanner': '正在创建支付单...',
      'authInProviderBanner': '请在支付渠道完成本人确认...',
      'verifyingBanner': '正在校验支付结果...',
      'processingGeneric': '处理中...',
      'paymentFailed': '付款失败',
      'paymentFlowNotice':
          '支付流程：选择方式 → 确认金额 → 跳转支付渠道授权 → 服务端扣款校验 → 支付凭证。'
          '支付宝/微信密码仅在官方 App 内输入，商户端不接触。',
      'paymentSuccessTitle': '支付成功',
      'paySuccess': '付款成功',
      'receiptPaymentMethod': '支付方式',
      'receiptMerchant': '收款商户',
      'receiptProduct': '商品',
      'receiptOrderId': '订单号',
      'receiptTransactionId': '交易号',
      'receiptProviderRef': '渠道参考号',
      'receiptPaidAt': '支付时间',
      'receiptKeepTransactionId': '请保留交易号以便查询。支付结果已通过服务端校验。',
      'completeAndStartWash': '完成并启动洗车',
      'enterPayPassword': '请输入支付密码',
      'wechatPayFailed': '微信支付失败',
      'alipayPayFailed': '支付宝支付失败',
      'authFailed': '授权失败',
      'confirmPaymentInfo': '请确认付款信息后再继续',
      'confirmApplePayInfo': '请确认 Apple Pay 付款信息',
      'applePaySecurityHint': '生物识别验证由 Apple Pay 安全模块处理。',
      'cardEncryptedHint': '卡片信息已加密处理，本 App 不会储存完整卡号或 CVV。',
      'payWithFaceId': '通过 Face ID 支付',
      'confirmCreditCardPay': '确认信用卡支付',
      'payeeLabel': '收款方',
      'paymentAmount': '支付金额',
      'payerAccountLabel': '付款账户',
      'retryWechatPay': '重试微信支付',
      'retryAlipayPay': '重试支付宝支付',
      'simulatePaymentTest': '模拟支付（测试）',
      'paymentMethodAlipayRedirect': '跳转支付宝收银台，显示金额并输入支付密码',
      'paymentMethodWechatRedirect': '跳转微信收银台，显示金额并输入支付密码',
      'paymentMethodApplePayBiometric': 'Face ID / Touch ID 确认支付',
      'paymentMethodCreditCardBrands': 'Visa · Mastercard · UnionPay',
      'orderFlow1': '1. 已创建订单，等待扫码或线上付款',
      'orderFlow2': '2. 用户已付款，商家已收款，等待设备启动',
      'orderFlow3': '3. 正在向设备发送启动指令',
      'orderFlow4': '4. 洗车中，请按设备提示完成清洗',
      'orderFlow5': '5. 洗车完成，订单已结束',
      'orderFlow6': '异常：设备启动失败或订单异常',
      'orderFlow7': '已退款，流程结束',      'reservationRecords': '预约记录',
      'noStoresToReserveDesc': '请稍后再试，或先在洗车页查看附近门店。',
      'myOrdersSubtitleTrack': '跟踪支付、启动、洗车中、完成和异常状态。',
      'noOrdersYet': '还没有订单',
      'scanOnHomeHint': '在洗车页选择门店并扫码支付。',
      'reservationFormShopTitle': '预约表单',
      'reservationFormShopSubtitle': '按店铺筛选用户提交的预约。',
      'shopReservationsEmptyDesc': '用户提交预约到店后会显示在这里。',
      'adminOverviewSubtitle': '平台总览和关键指标。',
      'refreshFromBackend': '从后端刷新',
      'storesAndBaysSubtitle': '包含商家端全部店铺和工位统计信息。',
      'adminReservationsEmptyDesc': '用户预约后会出现在这里。',
      'adminOrdersEmptyDesc': '用户扫码付款后订单会出现在这里。',
      'storeFilterLabel': '店铺筛选',
      'countryCodeLabel': '区号',
      'searchCountryHint': '搜索国家/地区或区号',
      'noDialCodeMatch': '未找到匹配的区号',
      'geocodeCoordsUpdated': '已根据地址更新坐标',
      'shopRegReviewTitle': '商家注册审核',
      'merchantLicensePermit': '商户经营许可证',
      'resubmitForReview': '修改材料并重新提交审核',
      'materialsResubmittedWait': '材料已重新提交，请等待 Admin 审核',
      'fullNameLabel': '姓名',
      'getVerificationCode': '获取验证码',
      'referralCodeOptional': '好友分享码（选填）',
      'fillPhoneFirst': '请先填写手机号',
      'fillEmailFirst': '请先填写邮箱',
      'invalidEmailFormat': '请输入有效的邮箱地址',
      'smsCodeSent': '验证码已发送',
      'emailCodeSent': '验证码已发送至您的邮箱',
      'addressGeocodedOk': '已根据地址定位',
      'merchantPhoneNumber': '商户电话号码',
      'submittingLabel': '提交中…',
      'registerShopOnMap': '注册商家并加入地图',
      'scanPayTitle': '扫码支付',
      'currentDeviceLabel': '当前设备',
      'useFreeWashSubtitlePay': '开启后本单实付款 ¥0，关闭则按套餐原价支付',
      'actualPaymentLabel': '实付款',
      'processingLabel': '处理中...',
      'confirmStartWash': '确认并启动洗车',
      'selectDeviceQr': '请选择设备二维码',
      'selectPackageRequired': '请选择套餐',
      'freeWashLabel': '免费洗车',
      'defaultCarWashStore': '洗车门店',
      'defaultUserLabel': '用户',
      'locationLoadingDots': '正在获取定位...',
      'locationDisabledHkFallback': '定位服务未开启，使用香港中西区默认位置。',
      'locationDeniedHkFallback': '未获得定位权限，使用香港中西区默认位置。',
      'locationSuccessSorted': '已获取当前位置，列表按距离由近到远排序。',
      'locationFailedHkFallback': '定位失败，使用香港中西区默认位置。',
      'reservationNotePlaceholder': '备注，例如车型、洗车需求',
      'manualServiceDetailHint': '商家人工接待与精洗',
      'durationMinLabel': '时长（分钟）',
      'durationFormatInvalid': '时长格式不正确',
      'packagePriceUpdated': '套餐价格已更新',
      'metricMapPoints': '地图点',
      'metricFaultDevices': '异常设备',
      'storePendingReview': '待审核',
      'storeRejectedReview': '已驳回',
      'addWashBaySlot': '添加洗车位',
      'setIdleOnline': '设为在线空闲',
      'bayNameExample': '工位名称，例如 自助4号 / 人工1号',
      'bayTypeLabel': '工位类型',
      'selfServiceBayLabel': '自助洗车位',
      'manualBayLabel': '人工洗车位',
      'shopRegSubmittedAdmin': '商家注册已提交，请等待 Admin 审核',
      'approvedDefaultReply': '审核通过',
      'rejectReplyPlaceholder': '请输入需要商家修改或补充的材料',
      'defaultRejectMessage': '请修改或补充注册材料',
      'redeemedFreeWash': '已核销免费洗车',
      'simulatePayStart': '模拟付款并启动',
      'selectReservationTypeLabel': '选择预约类型',
      'addNewShopBtn': '添加新的店铺',
      'shopOrdersEmptyDesc': '用户扫码付款后订单会显示在这里。',
      'completedOrdersLabel': '已完成订单',
      'errLoginAsUser': '请先以用户身份登录',
      'errPackageNotFound': '套餐不存在',
      'errSmsCode0000': '验证码错误，测试阶段请填写 0000',
      'errFillPhone': '请填写手机号',
      'errFillEmail': '请填写邮箱',
      'errSmsCode1111': '验证码错误，测试阶段请填写 1111',
      'errUploadLicense': '请上传至少一个经营许可证文件',
      'errShopOnlyResubmit': '只有商家账号可以重新提交材料',
      'errLoginAsShop': '请先以商家账号登录',
      'errShopOnlyEditProfile': '只有商家账号可以修改个人信息',
      'errFillComplete': '请填写完整信息',
      'errAccountExists': '账号已存在，请换一个账号名',
      'errUserOnlyReferral': '只有用户账号可以使用分享码',
      'errReferralUsed': '您已经使用过分享码',
      'errReferralInvalid': '分享码无效，请检查后重试',
      'errReferralSelf': '不能使用自己的分享码',
      'errLoginAsShopMerchant': '请先以商家身份登录',
      'errWithdrawPositive': '提现金额必须大于 0',
      'errInsufficientBalance': '余额不足',
      'errDeviceQrNotFound': '没有找到这个设备二维码',
      'errDeviceUnavailable': '设备当前不可用，请选择空闲设备',
      'errCannotUseBothCredits': '不能同时使用免费次卡和预付次卡',
      'errNoFreeWash': '没有可用的免费洗车次数',
      'errNoPrepaidWash': '没有可用的洗车次卡',
      'errOrderNotFound': '找不到订单',
      'errOrderNotPayable': '订单状态不可付款',
      'errDeviceNotIdle': '设备未处于空闲状态，已进入后台异常处理',
      'errServiceTypeUnsupported': '该店铺不支持这个服务类型',
      'errFillContactPhone': '请填写联系电话',
      'errFillRequired': '请填写所有必填信息',
      'errSelectOneService': '至少选择一种服务类型',
      'errInvalidLatLng': '经纬度格式不正确',
      'materialsResubmittedAdminReply': '已重新提交材料，等待 Admin 审核。',

    },
    AppLocale.zhHant: {
      'appTitle': '清洗到家',
      'appTagline': '智慧洗車 · 一鍵預約 · 輕鬆管理',
      'welcomeLogin': '歡迎登入',
      'loginRoleHint': '登入後根據帳號角色進入用戶 / 商家 / 管理端',
      'phoneOrTestAccount': '手機號或測試帳號',
      'phoneLoginHint': '手機號登入只輸入號碼；測試帳號 user / shop / admin 不受區號影響。',
      'password': '密碼',
      'login': '登入',
      'loggingIn': '登入中…',
      'userRegister': '用戶註冊',
      'shopRegister': '商家註冊',
      'demoAccounts': '演示帳號',
      'demoUser': 'User: user / 123456',
      'demoShop': 'Shop: shop / 123456',
      'demoAdmin': 'Admin: admin / 123456',
      'accountMismatch': '帳號或密碼不匹配',
      'accountPending': '帳號正在等待平台審核',
      'accountRejected': '帳號審核未通過，請聯繫平台管理員',
      'backendUnreachable': '無法連接伺服器，請檢查網路並確認後端已啟動。',
      'syncingData': '正在同步最新資料…',
      'syncFailedHint': '資料刷新失敗，下拉可重試。',
      'retrySync': '重試',
      'languageTitle': '語言',
      'tabCarWash': '洗車',
      'tabPackages': '套餐',
      'tabOrders': '訂單',
      'tabProfile': '個人中心',
      'tabStores': '門店',
      'tabReservations': '預約',
      'tabMine': '我的',
      'tabApproval': '審核',
      'tabOverview': '概覽',
      'tabStoresAdmin': '門店',
      'tabReservationsAdmin': '預約',
      'tabOrdersAdmin': '訂單',
      'tabPricing': '定價',
      'carWashTitle': '洗車',
      'carWashSubtitle': '地圖顯示附近洗車店，支援自助掃碼洗車與到店預約。',
      'myLocation': '我的位置',
      'nearbyStores': '附近門店',
      'noStores': '暫無門店',
      'noStoresDesc': '目前沒有已審核通過的洗車店。',
      'runningOrderTitle': '洗車進行中',
      'runningOrderSubtitle': '點擊查看訂單詳情',
      'locationLoading': '正在取得位置…',
      'locationDisabled': '定位服務未開啟',
      'locationDenied': '未獲得定位權限',
      'locationFailed': '取得位置失敗',
      'locationSuccess': '位置已更新',
      'viewMap': '查看地圖',
      'googleNav': 'Google導航',
      'reserveStore': '預約到店',
      'scanWash': '掃碼洗車',
      'idleCount': '空閒工位',
      'buyPackages': '購買洗車次卡',
      'buyPackagesSubtitle': '購買洗車次數套餐，掃碼洗車時可使用次卡免支付。',
      'myWashCredits': '我的洗車次數',
      'selectPackage': '選擇套餐',
      'buyNow': '立即購買',
      'recentUsage': '最近使用',
      'noUsageHistory': '暫無使用記錄',
      'noUsageHistoryDesc': '購買套餐後，掃碼洗車使用次卡會顯示在這裡。',
      'packagePaymentHint':
          '點擊「立即購買」進入收銀台完成付款，付款成功後洗車次數自動到帳。',
      'purchaseFailed': '購買失敗',
      'creditsLine': '次卡 · 免費次數',
      'cashierTitle': '收銀台',
      'scanCarWashTitle': '掃碼洗車',
      'scanCarWashSubtitle': '掃描裝置二維碼，選擇套餐後進入收銀台完成付款。',
      'rescan': '重新掃碼',
      'selectPackageLabel': '選擇套餐',
      'actualAmount': '實付金額',
      'useFreeWashOn': '使用免費洗車（有可用次數）',
      'useFreeWashOff': '使用免費洗車（暫無可用次數）',
      'useFreeWashSubtitleOn': '開啟後本單實付款 ¥0',
      'useFreeWashSubtitleOff': '完成分享或兌換後可獲得免費洗車次數',
      'usePrepaidOn': '使用洗車次卡（有可用次數）',
      'usePrepaidOff': '暫無洗車次卡',
      'usePrepaidSubtitleOn': '開啟後本單免支付，優先消耗次卡',
      'usePrepaidSubtitleOff': '可在個人中心購買次卡套餐',
      'prepaidUsedNotice': '已使用次卡，按套餐原價結算',
      'unknownQr': '未識別的二維碼，請掃描洗車裝置碼',
      'myOrdersTitle': '我的訂單',
      'myOrdersSubtitle': '查看洗車訂單與進度',
      'noOrdersTitle': '暫無訂單',
      'noOrdersDesc': '掃碼洗車或購買套餐後可在此查看訂單。',
      'personalCenter': '個人中心',
      'personalCenterSubtitle': '帳號、次卡與設定',
      'logout': '退出登入',
      'settingsTitle': '設定',
      'nickname': '暱稱',
      'phone': '手機號',
      'newPasswordOptional': '新密碼（選填）',
      'autoUseFreeWash': '自動使用免費洗車',
      'settingsSaved': '設定已儲存',
      'save': '儲存',
      'saving': '儲存中…',
      'shopMerchantTitle': '商家端',
      'shopMerchantSubtitle': '管理門店、工位、預約與訂單',
      'addNewStore': '新增門店',
      'reservationFormTitle': '門店預約',
      'reservationFormSubtitle': '查看並管理用戶到店預約',
      'shopOrdersTitle': '門店訂單',
      'shopOrdersSubtitle': '查看本店洗車訂單',
      'noReservationsTitle': '暫無預約',
      'noReservationsDesc': '用戶提交的預約會顯示在這裡。',
      'noOrdersShopTitle': '暫無訂單',
      'noOrdersShopDesc': '本店洗車訂單會顯示在這裡。',
      'collected': '已收款',
      'pendingPay': '待支付',
      'completedOrders': '已完成',
      'adminPlatformTitle': '管理端',
      'adminPlatformSubtitle': '審核帳號、門店與平台定價',
      'accountManagementTitle': '帳號管理',
      'accountManagementSubtitle': '審核用戶與商家註冊',
      'approve': '批准',
      'rejectAndReply': '拒絕並回覆',
      'reviewReply': '審核回覆',
      'rejectAndSend': '拒絕並發送',
      'allStoresFilter': '全部門店',
      'userAccounts': '用戶帳號',
      'shopAccounts': '商家帳號',
      'exitLogin': '退出登入',
      'roleUser': '用戶',
      'roleShop': '商家',
      'roleAdmin': '管理員',
      'approvalPending': '待審核',
      'approvalApproved': '已通過',
      'approvalRejected': '已拒絕',
      'orderStatusCreated': '待支付',
      'orderStatusPaid': '已支付',
      'orderStatusStarting': '啟動中',
      'orderStatusRunning': '洗車中',
      'orderStatusCompleted': '已完成',
      'orderStatusFailed': '異常',
      'orderStatusRefunded': '已退款',
      'deviceIdle': '空閒',
      'deviceBusy': '使用中',
      'deviceOffline': '離線',
      'deviceFaulted': '故障',
      'selfService': '自助洗車',
      'manualService': '人工洗車',
      'selfServiceEco': '環保自助',
      'resPending': '待到店',
      'resArrived': '已到店',
      'resCompleted': '已完成',
      'resCancelled': '已取消',
      'myReservations': '我的預約',
      'myReservationsSubtitle': '選擇門店並填寫資訊，即可提交到店預約。',
      'noStoresToReserve': '暫無可預約門店',
      'noReservationsYet': '暫無預約',
      'noReservationsYetDesc': '填寫上方表單即可提交第一條預約。',
      'newReservation': '新建預約',
      'selectStore': '選擇門店',
      'reservationDate': '預約日期',
      'reservationTime': '預約時間',
      'contactPhone': '聯絡電話',
      'reservationType': '預約類型',
      'reservationNote': '備註',
      'submitReservation': '提交預約',
      'reservationSubmitted': '預約已提交',
      'reserveVisitTitle': '預約到店',
      'selectReservationType': '選擇預約類型',
      'createReservationPage': '新建預約',
      'paymentMethodAlipay': '支付寶',
      'paymentMethodWechat': '微信支付',
      'paymentMethodApplePay': 'Apple Pay',
      'paymentMethodCreditCard': '信用卡',
      'paymentMethodAlipaySub': '使用支付寶餘額或綁定銀行卡支付',
      'paymentMethodWechatSub': '使用微信餘額或綁定銀行卡支付',
      'paymentMethodApplePaySub': '使用本裝置 Apple Pay 支付',
      'paymentMethodCreditCardSub': '支援 Visa、Mastercard 等主流卡',
      'paymentProviderAlipay': '支付寶',
      'paymentProviderWechat': '微信支付',
      'paymentProviderApplePay': 'Apple Pay',
      'paymentProviderBank': '銀行卡',
      'paymentCancelled': '已取消支付',
      'confirmPayment': '確認支付',
      'cancelPayment': '取消支付',
      'confirmContinue': '確認並繼續',
      'packagePrices': '套餐價格',
      'addBay': '添加工位',
      'addStorePage': '新增門店',
      'submitNewStore': '提交門店',
      'storeSubmitted': '門店已提交，等待審核',
      'simulatePayAndStart': '模擬支付並啟動',
      'finishWash': '結束洗車',
      'orderFlowLabel': '流程',
      'paymentMethodLabel': '支付方式',
      'transactionIdLabel': '交易號',
      'paidAtLabel': '支付時間',
      'minutesUnit': '分鐘',
      'washPackagePrices': '洗車次卡定價',
      'addWashBay': '添加洗車工位',
      'setIdle': '設為空閒',
      'setOffline': '設為離線',
      'setFault': '設為故障',
      'bayNameLabel': '工位名稱',
      'addBayButton': '添加工位',
      'storeNameLabel': '門店名稱',
      'storeAddressLabel': '門店地址',
      'latitude': '緯度',
      'longitude': '經度',
      'licenseMaterials': '證照材料',
      'serviceTypes': '服務類型',
      'modifyMaterials': '修改材料',
      'materialsResubmitted': '材料已重新提交，等待審核',
      'shopReviewTitle': '商家審核',
      'adminReply': '管理員回覆',
      'merchantLicense': '營業執照',
      'userRegTitle': '用戶註冊',
      'shopRegTitle': '商家註冊',
      'merchantName': '商戶名稱',
      'merchantAddress': '商戶地址',
      'merchantPhone': '商戶電話',
      'smsCode': '簡訊驗證碼',
      'emailLabel': '電郵',
      'emailVerificationCode': '電郵驗證碼',
      'friendReferralCode': '好友推薦碼（選填）',
      'registerLogin': '註冊並登入',
      'shopRegSubmitted': '註冊已提交，請等待平台審核',
      'noCountryMatch': '未找到匹配的國家或地區',
      'homeLabel': '首頁',
      'standardWashDemo': '標準洗車演示',
      'withdrawToAlipay': '提現到支付寶',
      'sharePanelTitle': '分享賺免費洗車',
      'copyShareCode': '複製分享碼',
      'copyShareText': '複製分享文案',
      'freeWashCreditsLabel': '免費洗車次數',
      'orderInProgress': '訂單進行中',
      'clickForDetails': '點擊查看詳情',
      'mapLoading': '地圖載入中…',
      'adminPricingTitle': '平台次卡定價',
      'editPackage': '編輯套餐',
      'packageUpdated': '套餐已更新',
      'saveFailed': '儲存失敗',
      'userAccountMgmt': '用戶帳號管理',
      'shopAccountMgmt': '商家帳號管理',
      'viewLicenseMaterials': '查看證照材料',
      'storesAndBays': '門店與工位',
      'allReservationsAdmin': '全部預約',
      'allOrdersAdmin': '全部訂單',
      'personalSettingsPage': '個人設定',
      'merchantPhoneFixed': '商戶電話（審核通過後不可修改）',
      'licenseUpload': '上傳證照',
      'addStoreBtn': '添加門店',
      'addressLabel': '地址',
      'serviceSummary': '服務項目',
      'modifyPackageTitle': '修改套餐',
      'cancelBtn': '取消',
      'saveBtn': '儲存',
      'emptyStateDefault': '暫無內容',
      'myVehicles': '我的車輛',
      'addVehicle': '添加車輛',
      'commonAddresses': '常用地址',
      'addAddress': '添加地址',
      'washCreditsCard': '洗車次卡',
      'myPoints': '我的積分',
      'allOrders': '全部訂單',
      'myVehiclesTitle': '我的車輛',
      'noVehicles': '暫無車輛',
      'vehicleModel': '車型',
      'plateNumber': '車牌號',
      'colorOptional': '顏色（選填）',
      'commonAddressesTitle': '常用地址',
      'noAddresses': '暫無地址',
      'addressLabelHint': '標籤（如：家、公司）',
      'detailedAddress': '詳細地址',
      'addBtn': '添加',
      'fillCompleteInfo': '請填寫完整資訊',
      'contactCustomerService': '聯繫客服',
      'termsOfService': '服務條款',
      'buyPackageLink': '購買套餐',
      'newPasswordLeaveBlank': '新密碼（留空不修改）',
      'customerServiceTitle': '聯繫客服',
      'hqPhoneTitle': '總部客服電話',
      'hqPhoneHours': '400-888-6688 · 9:00–21:00',
      'onlineMessage': '在線留言',
      'messageHint': '請描述您的問題，客服將盡快回覆',
      'messageSubmitted': '留言已提交，客服會盡快聯繫您',
      'submitMessage': '提交留言',
      'termsTitle': '服務條款',
      'termsHeading': '清洗到家服務條款',
      'termsBody':
          '1. 用戶下單即表示同意平台服務規範與價格說明。\n'
          '2. 預約到店請按時到達，遲到可能影響服務安排。\n'
          '3. 自助洗車請按裝置提示操作，違規使用造成的損壞由用戶承擔。\n'
          '4. 平台將在法律允許範圍內處理退款與糾紛。',
      'tabAll': '全部',
      'tabUnpaid': '待支付',
      'tabInProgress': '進行中',
      'tabCompleted': '已完成',
      'noOrdersAll': '還沒有訂單',
      'noOrdersUnpaidTitle': '暫無待支付訂單',
      'noOrdersInProgressTitle': '暫無進行中訂單',
      'noOrdersCompletedTitle': '暫無已完成訂單',
      'noOrdersAllHint': '在洗車頁掃碼支付後即可在此查看',
      'noOrdersUnpaidHint': '建立訂單後未支付會顯示在這裡',
      'noOrdersInProgressHint': '支付後正在洗車的訂單會顯示在這裡',
      'noOrdersCompletedHint': '洗完或已退款的訂單會顯示在這裡',
      'selfServiceOrdersSubtitle': '自助洗車訂單',
      'defaultWashPackage': '洗車套餐',
      'washStoreFallback': '洗車門店',
      'creditsUsedOnce': '-1 次',
      'shareGiftTitle': '分享有禮',
      'shareBeforeFirstWash':
          '完成首次洗車後，即可分享專屬邀請碼給好友。您和好友各獲得 1 次免費洗車機會。',
      'shareToFriends': '分享給好友',
      'shareCodeBenefit': '好友註冊或在我的頁面填寫分享碼後，雙方各得 1 次免費洗車。',
      'shareCodeCopied': '分享碼已複製',
      'shareTextCopied': '分享文案已複製，可貼上給好友',
      'shareAndFreeWash': '分享與免費洗車',
      'remainingCountLabel': '剩餘次數',
      'usedCountLabel': '已使用',
      'shareSuccessCountLabel': '分享成功',
      'shareBenefitDetail': '分享給好友，雙方各得 1 次免費洗車。好友可在註冊時填寫，或在下方兌換。',
      'invitedFriends': '已邀請好友：',
      'redeemShareCode': '兌換分享碼',
      'enterFriendShareCode': '輸入好友分享碼',
      'redeemSuccess': '分享碼兌換成功，雙方各得 1 次免費洗車',
      'redeemShareCodeBtn': '兌換分享碼',
      'myWallet': '我的錢包',
      'withdrawableBalance': '可提現餘額',
      'withdraw': '提現',
      'incomeDetails': '收入明細',
      'noTransactions': '暫無交易記錄',
      'withdrawAmount': '提現金額',
      'enterValidAmount': '請輸入有效金額',
      'withdrawSubmitted': '提現申請已提交',
      'confirmWithdraw': '確認提現',
      'myReviews': '我的評價',
      'noReviews': '暫無評價',
      'scanQrAlignHint': '將裝置二維碼放入框內自動識別',
      'approvalCenter': '審核中心',
      'allClear': '暫無待審核項，全部已處理',
      'shopAccountReview': '商家帳號審核',
      'noPendingShopAccounts': '暫無待審商家帳號',
      'storeReview': '門店審核',
      'noPendingStores': '暫無待審門店',
      'clearedBadge': '已清空',
      'reviewBtn': '審核',
      'approveSegment': '通過',
      'rejectSegment': '駁回',
      'approvalCommentOptional': '審批意見（選填，駁回時建議填寫）',
      'submitApproval': '提交審批',
      'defaultMerchantName': '商家',
      'defaultStoreName': '門店',
      'operatingLicense': '經營許可證',
      'editBundlePlan': '編輯次卡套餐',
      'packageNameLabel': '套餐名稱',
      'washCountLabel': '洗車次數',
      'priceYuanLabel': '售價（元）',
      'bundlePricingUpdated': '次卡定價已更新',
      'platformPricing': '平台定價',
      'platformPricingDesc': '管理用戶洗車次卡套餐。門店單次洗車價格在商家端各店鋪內修改。',
      'shopPricingTitle': '定價管理',
      'shopPricingDesc': '設定用戶在「套餐」頁購買的洗車次卡次數與售價。',
      'storeWashPackagePricing': '門店單次洗車套餐',
      'storeWashPackagePricingHint': '快速沖洗、標準自助、精洗等價格在「門店」頁各店鋪卡片內修改。',
      'washCreditBundlesSection': '洗車次卡套餐',
      'washCreditBundlesSectionHint': '點擊套餐可修改名稱、次數與售價。',
      'tapToEditPrice': '點擊修改',
      'priceFormatInvalid': '價格格式不正確',
      'countFormatInvalid': '次數格式不正確',
      'imageLoadFailed': '圖片載入失敗\n請確認檔案已上傳且後端正在運行',
      'imageCannotLoad': '圖片無法載入',
      'fileNotUploadedYet': '檔案可能尚未上傳到伺服器',
      'tapToZoom': '點擊放大',
      'pdfNoPreview': 'PDF 檔案暫不支援 App 內預覽，請上傳 jpg/png 圖片格式以便在手機上直接查看。',
      'noUploadedMaterials': '暫無上傳材料',
      'noFileSelected': '未選擇檔案',
      'cannotReadFilename': '無法讀取檔案名',
      'cannotReadFileContent': '無法讀取檔案內容，請重試',
      'fileTooLarge': '單個檔案不能超過 10MB',
      'unsupportedLicenseFormat': '許可證檔案僅支援 pdf、jpg、jpeg、png',
      'uploadNoFilename': '上傳成功但伺服器未返回檔案名',
      'licenseUploadHint': '請上傳 pdf、jpg、jpeg、png 格式的經營許可證，單個檔案不超過 10MB',
      'uploading': '上傳中…',
      'selectAndUpload': '選擇並上傳檔案',
      'tapImageFullPreview': '點擊圖片可全螢幕預覽',
      'todayCompleted': '今日完成',
      'todayRevenue': '今日收入',
      'walletBalance': '錢包餘額',
      'viewBtn': '查看',
      'commonTools': '常用工具',
      'walletShort': '錢包',
      'reviewsShort': '評價',
      'customerServiceShort': '客服',
      'settingsShort': '設定',
      'accountInfo': '帳戶資訊',
      'shopInfoSection': '店鋪資訊',
      'loginAccount': '登入帳號',
      'shopAddressLabel': '店鋪地址',
      'notFilled': '未填寫',
      'mapCoordinates': '地圖座標',
      'manageStores': '管理店鋪',
      'businessLicense': '經營許可證',
      'uploadBusinessLicense': '請上傳經營許可證',
      'goUpload': '去上傳',
      'editProfile': '編輯資料',
      'profileSyncHint': '修改後將同步更新店鋪資訊',
      'accountSection': '帳戶',
      'addressAndCoordinates': '地址與座標',
      'profileSaved': '資料已儲存',
      'uploadAtLeastOneLicense': '請上傳至少一個經營許可證檔案',
      'latLngFormatInvalid': '經緯度格式不正確',
      'fillAllRequired': '請填寫所有必填資訊',
      'hkRegionTitle': '香港地區（三大區 · 18區 · 細分區域）',
      'hkMajorRegion': '三大區',
      'hk18Districts': '18區',
      'hkSubArea': '細分區域',
      'hkDetailAddress': '詳細地址（街道/大廈，選填）',
      'paymentSessionExpiredReturn': '支付會話已過期，請返回重新下單',
      'fillCompleteCardInfo': '請填寫完整的信用卡資料',
      'paymentCancelledByUser': '您已取消支付',
      'expiredLabel': '已過期',
      'selectPaymentMethod': '選擇付款方式',
      'iosOnly': '僅 iOS 裝置可用',
      'pciComplianceNote':
          '正式環境應使用 Stripe / Adyen 等 PCI 認證託管欄位，本 App 不會儲存完整卡號或 CVV。',
      'creatingPayment': '建立支付單...',
      'awaitingAuthorization': '等待授權...',
      'verifyingPayment': '校驗支付結果...',
      'sessionExpired': '會話已過期',
      'selectMethodFirst': '請選擇付款方式',
      'amountDue': '應付金額',
      'usedFreeWashCredits': '已使用免費洗車次數',
      'sessionValid15Min': '支付會話 15 分鐘內有效',
      'cardholderName': '持卡人姓名',
      'enterCardholderName': '請填寫持卡人姓名',
      'cardNumber': '卡號',
      'invalidCardNumber': '請輸入有效的卡號',
      'expiryDate': '到期日 MM/YY',
      'expiryFormat': '格式 MM/YY',
      'cvvInvalid': '3-4 位數字',
      'processingPayment': '處理中...',
      'creatingPaymentBanner': '正在建立支付單...',
      'authInProviderBanner': '請在支付渠道完成本人確認...',
      'verifyingBanner': '正在校驗支付結果...',
      'processingGeneric': '處理中...',
      'paymentFailed': '付款失敗',
      'paymentFlowNotice':
          '支付流程：選擇方式 → 確認金額 → 跳轉支付渠道授權 → 服務端扣款校驗 → 支付憑證。'
          '支付寶/微信密碼僅在官方 App 內輸入，商戶端不接觸。',
      'paymentSuccessTitle': '支付成功',
      'paySuccess': '付款成功',
      'receiptPaymentMethod': '支付方式',
      'receiptMerchant': '收款商戶',
      'receiptProduct': '商品',
      'receiptOrderId': '訂單號',
      'receiptTransactionId': '交易號',
      'receiptProviderRef': '渠道參考號',
      'receiptPaidAt': '支付時間',
      'receiptKeepTransactionId': '請保留交易號以便查詢。支付結果已通過服務端校驗。',
      'completeAndStartWash': '完成並啟動洗車',
      'enterPayPassword': '請輸入支付密碼',
      'wechatPayFailed': '微信支付失敗',
      'alipayPayFailed': '支付寶支付失敗',
      'authFailed': '授權失敗',
      'confirmPaymentInfo': '請確認付款資訊後再繼續',
      'confirmApplePayInfo': '請確認 Apple Pay 付款資訊',
      'applePaySecurityHint': '生物識別驗證由 Apple Pay 安全模組處理。',
      'cardEncryptedHint': '卡片資訊已加密處理，本 App 不會儲存完整卡號或 CVV。',
      'payWithFaceId': '通過 Face ID 支付',
      'confirmCreditCardPay': '確認信用卡支付',
      'payeeLabel': '收款方',
      'paymentAmount': '支付金額',
      'payerAccountLabel': '付款帳戶',
      'retryWechatPay': '重試微信支付',
      'retryAlipayPay': '重試支付寶支付',
      'simulatePaymentTest': '模擬支付（測試）',
      'paymentMethodAlipayRedirect': '跳轉支付寶收銀台，顯示金額並輸入支付密碼',
      'paymentMethodWechatRedirect': '跳轉微信收銀台，顯示金額並輸入支付密碼',
      'paymentMethodApplePayBiometric': 'Face ID / Touch ID 確認支付',
      'paymentMethodCreditCardBrands': 'Visa · Mastercard · UnionPay',
      'orderFlow1': '1. 已建立訂單，等待掃碼或線上付款',
      'orderFlow2': '2. 用戶已付款，商家已收款，等待裝置啟動',
      'orderFlow3': '3. 正在向裝置發送啟動指令',
      'orderFlow4': '4. 洗車中，請按裝置提示完成清洗',
      'orderFlow5': '5. 洗車完成，訂單已結束',
      'orderFlow6': '異常：裝置啟動失敗或訂單異常',
      'orderFlow7': '已退款，流程結束',      'reservationRecords': '預約記錄',
      'noStoresToReserveDesc': '請稍後再試，或先在洗車頁查看附近門店。',
      'myOrdersSubtitleTrack': '追蹤支付、啟動、洗車中、完成和異常狀態。',
      'noOrdersYet': '還沒有訂單',
      'scanOnHomeHint': '在洗車頁選擇門店並掃碼支付。',
      'reservationFormShopTitle': '預約表單',
      'reservationFormShopSubtitle': '按店鋪篩選用戶提交的預約。',
      'shopReservationsEmptyDesc': '用戶提交預約到店後會顯示在這裡。',
      'adminOverviewSubtitle': '平台總覽和關鍵指標。',
      'refreshFromBackend': '從後端刷新',
      'storesAndBaysSubtitle': '包含商家端全部店鋪和工位統計資訊。',
      'adminReservationsEmptyDesc': '用戶預約後會出現在這裡。',
      'adminOrdersEmptyDesc': '用戶掃碼付款後訂單會出現在這裡。',
      'storeFilterLabel': '店鋪篩選',
      'countryCodeLabel': '區號',
      'searchCountryHint': '搜尋國家/地區或區號',
      'noDialCodeMatch': '未找到匹配的區號',
      'geocodeCoordsUpdated': '已根據地址更新座標',
      'shopRegReviewTitle': '商家註冊審核',
      'merchantLicensePermit': '商戶經營許可證',
      'resubmitForReview': '修改材料並重新提交審核',
      'materialsResubmittedWait': '材料已重新提交，請等待 Admin 審核',
      'fullNameLabel': '姓名',
      'getVerificationCode': '取得驗證碼',
      'referralCodeOptional': '好友分享碼（選填）',
      'fillPhoneFirst': '請先填寫手機號',
      'fillEmailFirst': '請先填寫電郵',
      'invalidEmailFormat': '請輸入有效的電郵地址',
      'smsCodeSent': '驗證碼已發送',
      'emailCodeSent': '驗證碼已發送至您的電郵',
      'addressGeocodedOk': '已根據地址定位',
      'merchantPhoneNumber': '商戶電話號碼',
      'submittingLabel': '提交中…',
      'registerShopOnMap': '註冊商家並加入地圖',
      'scanPayTitle': '掃碼支付',
      'currentDeviceLabel': '目前裝置',
      'useFreeWashSubtitlePay': '開啟後本單實付款 ¥0，關閉則按套餐原價支付',
      'actualPaymentLabel': '實付款',
      'processingLabel': '處理中...',
      'confirmStartWash': '確認並啟動洗車',
      'selectDeviceQr': '請選擇裝置二維碼',
      'selectPackageRequired': '請選擇套餐',
      'freeWashLabel': '免費洗車',
      'defaultCarWashStore': '洗車門店',
      'defaultUserLabel': '用戶',
      'locationLoadingDots': '正在取得定位...',
      'locationDisabledHkFallback': '定位服務未開啟，使用香港中西區預設位置。',
      'locationDeniedHkFallback': '未獲得定位權限，使用香港中西區預設位置。',
      'locationSuccessSorted': '已取得目前位置，列表按距離由近到遠排序。',
      'locationFailedHkFallback': '定位失敗，使用香港中西區預設位置。',
      'reservationNotePlaceholder': '備註，例如車型、洗車需求',
      'manualServiceDetailHint': '商家人工接待與精洗',
      'durationMinLabel': '時長（分鐘）',
      'durationFormatInvalid': '時長格式不正確',
      'packagePriceUpdated': '套餐價格已更新',
      'metricMapPoints': '地圖點',
      'metricFaultDevices': '異常裝置',
      'storePendingReview': '待審核',
      'storeRejectedReview': '已駁回',
      'addWashBaySlot': '添加洗車位',
      'setIdleOnline': '設為線上空閒',
      'bayNameExample': '工位名稱，例如 自助4號 / 人工1號',
      'bayTypeLabel': '工位類型',
      'selfServiceBayLabel': '自助洗車位',
      'manualBayLabel': '人工洗車位',
      'shopRegSubmittedAdmin': '商家註冊已提交，請等待 Admin 審核',
      'approvedDefaultReply': '審核通過',
      'rejectReplyPlaceholder': '請輸入需要商家修改或補充的材料',
      'defaultRejectMessage': '請修改或補充註冊材料',
      'redeemedFreeWash': '已核銷免費洗車',
      'simulatePayStart': '模擬付款並啟動',
      'selectReservationTypeLabel': '選擇預約類型',
      'addNewShopBtn': '添加新的店鋪',
      'shopOrdersEmptyDesc': '用戶掃碼付款後訂單會顯示在這裡。',
      'completedOrdersLabel': '已完成訂單',
      'errLoginAsUser': '請先以用戶身份登入',
      'errPackageNotFound': '套餐不存在',
      'errSmsCode0000': '驗證碼錯誤，測試階段請填寫 0000',
      'errFillPhone': '請填寫手機號',
      'errFillEmail': '請填寫電郵',
      'errSmsCode1111': '驗證碼錯誤，測試階段請填寫 1111',
      'errUploadLicense': '請上傳至少一個經營許可證文件',
      'errShopOnlyResubmit': '只有商家帳號可以重新提交材料',
      'errLoginAsShop': '請先以商家帳號登入',
      'errShopOnlyEditProfile': '只有商家帳號可以修改個人資訊',
      'errFillComplete': '請填寫完整資訊',
      'errAccountExists': '帳號已存在，請換一個帳號名',
      'errUserOnlyReferral': '只有用戶帳號可以使用分享碼',
      'errReferralUsed': '您已經使用過分享碼',
      'errReferralInvalid': '分享碼無效，請檢查後重試',
      'errReferralSelf': '不能使用自己的分享碼',
      'errLoginAsShopMerchant': '請先以商家身份登入',
      'errWithdrawPositive': '提現金額必須大於 0',
      'errInsufficientBalance': '餘額不足',
      'errDeviceQrNotFound': '沒有找到這個裝置二維碼',
      'errDeviceUnavailable': '裝置目前不可用，請選擇空閒裝置',
      'errCannotUseBothCredits': '不能同時使用免費次卡和預付次卡',
      'errNoFreeWash': '沒有可用的免費洗車次數',
      'errNoPrepaidWash': '沒有可用的洗車次卡',
      'errOrderNotFound': '找不到訂單',
      'errOrderNotPayable': '訂單狀態不可付款',
      'errDeviceNotIdle': '裝置未處於空閒狀態，已進入後台異常處理',
      'errServiceTypeUnsupported': '該店鋪不支援這個服務類型',
      'errFillContactPhone': '請填寫聯絡電話',
      'errFillRequired': '請填寫所有必填資訊',
      'errSelectOneService': '至少選擇一種服務類型',
      'errInvalidLatLng': '經緯度格式不正確',
      'materialsResubmittedAdminReply': '已重新提交材料，等待 Admin 審核。',

    },
  };
}
