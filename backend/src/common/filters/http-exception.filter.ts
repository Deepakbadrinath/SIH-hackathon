import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Request, Response } from 'express';

@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(HttpExceptionFilter.name);

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    let status = HttpStatus.INTERNAL_SERVER_ERROR;
    let message: string | string[] = 'Internal server error';
    let error = 'Internal Server Error';

    if (exception instanceof HttpException) {
      status = exception.getStatus();
      const res = exception.getResponse();

      if (typeof res === 'string') {
        message = res;
        error = exception.name;
      } else if (typeof res === 'object' && res !== null) {
        const obj = res as Record<string, any>;
        message = obj.message || exception.message;
        error = obj.error || exception.name;
      }
    } else {
      // Unhandled / system / DB error - Log internally with full stack trace
      const err = exception as Error;
      this.logger.error(
        `Unhandled Error on [${request.method}] ${request.url}: ${err?.message || 'Unknown'}`,
        err?.stack,
      );

      // Sanitize output for the client - NEVER expose stack traces, DB errors, or internal paths
      status = HttpStatus.INTERNAL_SERVER_ERROR;
      message = 'An unexpected internal error occurred. Please contact system support.';
      error = 'Internal Server Error';
    }

    // Heuristic protection: Scrub SQL syntax, schema details or path traces from client responses
    const sanitizeText = (text: string): string => {
      const sqlPattern = /\b(SELECT|INSERT\s+INTO|UPDATE\s+\w+\s+SET|DELETE\s+FROM|DROP\s+TABLE|ALTER\s+TABLE|UNION\s+SELECT|FROM\s+\w+|WHERE\s+\w+|JOIN\s+\w+)\b/i;
      if (sqlPattern.test(text)) {
        this.logger.warn(`Redacted SQL syntax leakage detected in exception message: ${text}`);
        return 'A data constraint or query validation error occurred.';
      }
      return text;
    };

    const cleanMessage = Array.isArray(message)
      ? message.map((m) => (typeof m === 'string' ? sanitizeText(m) : m))
      : typeof message === 'string'
      ? sanitizeText(message)
      : message;

    // Ensure error responses NEVER contain tokens, passwords, or stack traces
    response.status(status).json({
      statusCode: status,
      error,
      message: cleanMessage,
      path: request.url,
      timestamp: new Date().toISOString(),
    });
  }
}
