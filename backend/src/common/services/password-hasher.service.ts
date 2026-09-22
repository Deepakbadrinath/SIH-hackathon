import { Injectable } from '@nestjs/common';
import * as crypto from 'crypto';

@Injectable()
export class PasswordHasherService {
  private readonly keyLength = 64;
  private readonly saltLength = 16;
  private readonly scryptOptions = {
    N: 16384, // CPU/memory cost parameter (OWASP recommended for scrypt)
    r: 8,     // Block size
    p: 1,     // Parallelization parameter
  };

  /**
   * Hashes a plaintext password using salted scrypt.
   * Format: salt:hash (both hex encoded)
   */
  async hashPassword(password: string): Promise<string> {
    const salt = crypto.randomBytes(this.saltLength).toString('hex');
    const hash = await this.generateScryptHash(password, salt);
    return `${salt}:${hash}`;
  }

  /**
   * Verifies a plaintext password against a stored salted scrypt hash using constant-time comparison.
   */
  async verifyPassword(password: string, storedHash: string): Promise<boolean> {
    const parts = storedHash.split(':');
    if (parts.length !== 2) {
      return false;
    }

    const [salt, originalHash] = parts;
    const computedHash = await this.generateScryptHash(password, salt);

    const originalBuffer = Buffer.from(originalHash, 'hex');
    const computedBuffer = Buffer.from(computedHash, 'hex');

    if (originalBuffer.length !== computedBuffer.length) {
      return false;
    }

    // Constant-time comparison to prevent side-channel timing attacks
    return crypto.timingSafeEqual(originalBuffer, computedBuffer);
  }

  private generateScryptHash(password: string, salt: string): Promise<string> {
    return new Promise((resolve, reject) => {
      crypto.scrypt(
        password,
        salt,
        this.keyLength,
        this.scryptOptions,
        (err, derivedKey) => {
          if (err) {
            reject(err);
          } else {
            resolve(derivedKey.toString('hex'));
          }
        },
      );
    });
  }
}
