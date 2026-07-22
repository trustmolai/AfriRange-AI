import { Resend } from 'resend';

// Initialize Resend API client
const resendApiKey = process.env.RESEND_API_KEY || 're_mock_key';
export const resend = new Resend(resendApiKey);

const FROM_EMAIL = process.env.EMAIL_FROM || 'AfriRange AI <noreply@afrirange.ai>';
const APP_URL = process.env.APP_URL || 'https://afrirange.ai';

/**
 * Send welcome email to a newly registered user
 */
export async function sendWelcomeEmail(to: string, name: string) {
  if (process.env.NODE_ENV === 'test' || resendApiKey === 're_mock_key') {
    console.log(`[Mock Email] Welcome email sent to ${to}`);
    return { id: 'mock-id' };
  }

  return await resend.emails.send({
    from: FROM_EMAIL,
    to: [to],
    subject: 'Welcome to AfriRange AI',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; color: #1A1C18;">
        <h2 style="color: #2E7D32;">Welcome to AfriRange AI, ${name}!</h2>
        <p>Thank you for joining the Pan-African rangeland intelligence platform. We are excited to support your veld management and livestock decision-making.</p>
        <p>Start by setting up your farm boundary and scanning key plant species in your paddocks.</p>
        <div style="margin: 30px 0;">
          <a href="${APP_URL}" style="background-color: #2E7D32; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; font-weight: bold;">Get Started</a>
        </div>
        <p style="color: #666; font-size: 14px;">If you have any questions, feel free to reply to this email.</p>
      </div>
    `,
  });
}

/**
 * Generic sendEmail function for billing and transactional emails
 */
export async function sendEmail({ to, subject, html }: { to: string; subject: string; html: string }) {
  if (process.env.NODE_ENV === 'test' || resendApiKey === 're_mock_key') {
    console.log(`[Mock Email] Email sent to ${to}. Subject: ${subject}`);
    return { id: 'mock-id' };
  }

  return await resend.emails.send({
    from: FROM_EMAIL,
    to: [to],
    subject,
    html,
  });
}

/**
 * Send email verification token
 */
export async function sendVerificationEmail(to: string, token: string) {
  const verifyUrl = `${APP_URL}/api/auth/verify-email?token=${token}`;

  if (process.env.NODE_ENV === 'test' || resendApiKey === 're_mock_key') {
    console.log(`[Mock Email] Verification email sent to ${to}. Token: ${token}`);
    return { id: 'mock-id' };
  }

  return await resend.emails.send({
    from: FROM_EMAIL,
    to: [to],
    subject: 'Verify your AfriRange AI Account',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; color: #1A1C18;">
        <h2 style="color: #2E7D32;">Verify Your Email</h2>
        <p>Please confirm your email address by clicking the link below:</p>
        <div style="margin: 30px 0;">
          <a href="${verifyUrl}" style="background-color: #2E7D32; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; font-weight: bold;">Verify Email</a>
        </div>
        <p style="color: #666; font-size: 14px;">This link will expire in 24 hours.</p>
      </div>
    `,
  });
}

/**
 * Send password reset email
 */
export async function sendPasswordResetEmail(to: string, token: string) {
  const resetUrl = `${APP_URL}/reset-password?token=${token}`;

  if (process.env.NODE_ENV === 'test' || resendApiKey === 're_mock_key') {
    console.log(`[Mock Email] Password reset email sent to ${to}. Token: ${token}`);
    return { id: 'mock-id' };
  }

  return await resend.emails.send({
    from: FROM_EMAIL,
    to: [to],
    subject: 'Reset your AfriRange AI Password',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; color: #1A1C18;">
        <h2 style="color: #D32F2F;">Password Reset Request</h2>
        <p>We received a request to reset your AfriRange AI password. Click the link below to set a new password:</p>
        <div style="margin: 30px 0;">
          <a href="${resetUrl}" style="background-color: #2E7D32; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; font-weight: bold;">Reset Password</a>
        </div>
        <p style="color: #666; font-size: 14px;">If you did not request this, please ignore this email.</p>
      </div>
    `,
  });
}

/**
 * Send account deletion confirmation email
 */
export async function sendAccountDeletionEmail(to: string) {
  if (process.env.NODE_ENV === 'test' || resendApiKey === 're_mock_key') {
    console.log(`[Mock Email] Account deletion confirmation sent to ${to}`);
    return { id: 'mock-id' };
  }

  return await resend.emails.send({
    from: FROM_EMAIL,
    to: [to],
    subject: 'Account Deletion Request Received',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; color: #1A1C18;">
        <h2 style="color: #D32F2F;">Account Deletion Confirmation</h2>
        <p>Your request to delete your AfriRange AI account has been received and processed.</p>
        <p>Pursuant to Google Play Policy, all your personal data, paddock maps, and plant survey records will be permanently erased from our servers within 7 days.</p>
      </div>
    `,
  });
}
