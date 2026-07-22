import type { NextApiResponse } from 'next';
import { query } from '../../lib/db';
import { withAuth, withErrorHandler, allowMethods, AuthenticatedRequest } from '../../lib/middleware';
import { sanitizeString } from '../../lib/validators';

async function handler(req: AuthenticatedRequest, res: NextApiResponse) {
  if (!allowMethods(req, res, ['PUT', 'PATCH'])) return;

  const { fullName, phoneNumber, countryCode, preferredLanguage, farmingType } = req.body || {};

  const cleanName = sanitizeString(fullName);
  const cleanPhone = sanitizeString(phoneNumber);
  const cleanCountry = sanitizeString(countryCode);
  const cleanLang = sanitizeString(preferredLanguage);
  const cleanFarming = sanitizeString(farmingType);

  const result = await query(
    `UPDATE users 
     SET full_name = COALESCE(NULLIF($1, ''), full_name),
         phone_number = COALESCE(NULLIF($2, ''), phone_number),
         country_code = COALESCE(NULLIF($3, ''), country_code),
         preferred_language = COALESCE(NULLIF($4, ''), preferred_language),
         farming_type = COALESCE(NULLIF($5, ''), farming_type)
     WHERE id = $6 AND deleted_at IS NULL
     RETURNING id, email, full_name, phone_number, country_code, preferred_language, farming_type, role`,
    [cleanName, cleanPhone, cleanCountry, cleanLang, cleanFarming, req.user.userId]
  );

  if (result.rowCount === 0) {
    return res.status(404).json({ error: 'user_not_found', message: 'User profile not found.' });
  }

  const user = result.rows[0];

  return res.status(200).json({
    message: 'Profile updated successfully.',
    user: {
      id: user.id,
      email: user.email,
      fullName: user.full_name,
      phoneNumber: user.phone_number,
      countryCode: user.country_code,
      preferredLanguage: user.preferred_language,
      farmingType: user.farming_type,
      role: user.role,
    },
  });
}

export default withErrorHandler(withAuth(handler));
