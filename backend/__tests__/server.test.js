const request = require('supertest');
const app = require('../server'); // Adjust path as necessary if your server.js is elsewhere

describe('GET /health', () => {
    it('should respond with 200 OK and a health message', async () => {
        const response = await request(app).get('/health');
        expect(response.statusCode).toBe(200);
        expect(response.body).toEqual({ status: 'UP', message: 'Server is healthy' });
    });
});

describe('Error Handling Middleware', () => {
    describe('Generic Error', () => {
        it('should respond with 500 and standard error format for generic errors', async () => {
            const response = await request(app).get('/test-generic-error');
            expect(response.statusCode).toBe(500);
            expect(response.body).toEqual({
                success: false,
                error: {
                    code: 'INTERNAL_SERVER_ERROR',
                    message: 'Something went wrong!' // Error message from the thrown error
                }
            });
        });
    });

    describe('Custom Error', () => {
        it('should respond with custom status code and error details for custom errors', async () => {
            const response = await request(app).get('/test-custom-error');
            expect(response.statusCode).toBe(400);
            expect(response.body).toEqual({
                success: false,
                error: {
                    code: 'CUSTOM_ERROR_CODE',
                    message: 'Custom operation failed.'
                }
            });
        });
    });
});
