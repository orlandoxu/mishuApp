import { expect, test } from 'bun:test';
import { sendVerificationCodeSms } from '../lib/aliyunSmsClient';

test(
  'SendSms direct HTTP API smoke test',
  async () => {
    const phone = process.env.SMS_TEST_PHONE ?? '12345678901';
    const result = await sendVerificationCodeSms({
      phoneNumber: phone,
      code: '123456',
    });

    expect(result).toBeDefined();
    expect(typeof result.success).toBe('boolean');
    expect(typeof result.message).toBe('string');
    if (!result.success) {
      expect(typeof result.code).toBe('string');
    }
  },
  20_000,
);
