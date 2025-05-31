/**
 * Custom Error Classes and Error Handling Utilities
 */

class AppError extends Error {
    constructor(message, statusCode = 500, errorCode = 'INTERNAL_SERVER_ERROR') {
        super(message);
        this.name = 'AppError';
        this.statusCode = statusCode;
        this.errorCode = errorCode;
        this.isOperational = true; // Distinguishes operational errors from programming errors
        
        Error.captureStackTrace(this, this.constructor);
    }
}

/**
 * Standardized error response handler for routes
 * @param {Error} error - The error object
 * @param {Response} res - Express response object
 * @param {Function} next - Express next function
 */
function handleRouteError(error, res, next) {
    if (error instanceof AppError) {
        // Handle our custom AppError
        return res.status(error.statusCode).json({
            success: false,
            error: {
                code: error.errorCode,
                message: error.message
            }
        });
    }
    
    // For non-AppError instances, pass to global error handler
    next(error);
}

/**
 * Global error handling middleware
 * @param {Error} err - The error object
 * @param {Request} req - Express request object
 * @param {Response} res - Express response object
 * @param {Function} next - Express next function
 */
function globalErrorHandler(err, req, res, next) {
    console.error('Unhandled error:', err.stack || err);

    // Default error response
    const statusCode = err.statusCode || 500;
    const errorCode = err.errorCode || 'INTERNAL_SERVER_ERROR';
    const message = process.env.NODE_ENV === 'production' 
        ? 'An internal server error occurred' 
        : err.message || 'An internal server error occurred';

    res.status(statusCode).json({
        success: false,
        error: {
            code: errorCode,
            message: message
        }
    });
}

module.exports = {
    AppError,
    handleRouteError,
    globalErrorHandler
}; 