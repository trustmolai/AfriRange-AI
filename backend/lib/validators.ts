// Input validation utilities for backend API

export function isValidEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

export function isValidPassword(password: string): { valid: boolean; message?: string } {
  if (password.length < 8) {
    return { valid: false, message: 'Password must be at least 8 characters long.' };
  }
  if (!/[A-Z]/.test(password)) {
    return { valid: false, message: 'Password must contain at least one uppercase letter.' };
  }
  if (!/[a-z]/.test(password)) {
    return { valid: false, message: 'Password must contain at least one lowercase letter.' };
  }
  if (!/[0-9]/.test(password)) {
    return { valid: false, message: 'Password must contain at least one number.' };
  }
  return { valid: true };
}

export function sanitizeString(input?: string): string {
  if (!input) return '';
  return input.trim().replace(/[<>]/g, '');
}

export function isValidUUID(uuid: string): boolean {
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
  return uuidRegex.test(uuid);
}

export function isValidIsoDate(dateStr: string): boolean {
  if (!dateStr) return false;
  const d = new Date(dateStr);
  return !isNaN(d.getTime());
}

export function validateRotationalPlanInput(body: any): { valid: boolean; message?: string } {
  if (!body.name || typeof body.name !== 'string' || body.name.trim().length === 0) {
    return { valid: false, message: 'Plan name is required.' };
  }
  if (!body.startDate || !isValidIsoDate(body.startDate)) {
    return { valid: false, message: 'Valid start date is required.' };
  }
  if (!body.endDate || !isValidIsoDate(body.endDate)) {
    return { valid: false, message: 'Valid end date is required.' };
  }
  if (new Date(body.endDate) <= new Date(body.startDate)) {
    return { valid: false, message: 'End date must be after start date.' };
  }
  if (!Array.isArray(body.paddockIds) || body.paddockIds.length === 0) {
    return { valid: false, message: 'At least one paddock must be selected.' };
  }
  return { valid: true };
}

