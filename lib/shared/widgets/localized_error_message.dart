import 'package:flutter/widgets.dart';

import '../../l10n/generated/app_localizations.dart';
import '../infrastructure/network/app_exception.dart';

/// Localizes the small set of known, client-owned error types; anything else
/// (e.g. `ClientException`/`ServerException` carrying a server-authored
/// message) is shown as-is, since that text comes from the backend and can't
/// be retranslated client-side.
String localizedErrorMessage(BuildContext context, Object error) {
  final l10n = AppLocalizations.of(context)!;
  if (error is NetworkException) return l10n.commonErrorNetwork;
  if (error is UnauthorizedException) return l10n.commonErrorUnauthorized;
  if (error is NoDriverIdException) return l10n.performanceErrorNoDriverId;
  return error.toString();
}
