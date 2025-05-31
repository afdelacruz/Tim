const jwt = require('jsonwebtoken');
const { AppError } = require('./errorHandler');
const UserRepositoryClass = require('../repositories/UserRepository');

const userRepository = new UserRepositoryClass();

const JWT_ACCESS_SECRET = process.env.JWT_ACCESS_SECRET || 'your-default-access-secret';

/**
 * Middleware to authenticate JWT access tokens
 * Adds user object to req.user if token is valid
 */
const authenticateToken = async (req, res, next) => {
    try {
        const authHeader = req.headers['authorization'];
        const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

        if (!token) {
            throw new AppError('Access token is required.', 401, 'MISSING_TOKEN');
        }

        // Verify the token
        const decoded = jwt.verify(token, JWT_ACCESS_SECRET);

        // Check token type
        if (decoded.type !== 'ACCESS') {
            throw new AppError('Invalid token type.', 401, 'INVALID_TOKEN_TYPE');
        }

        // Verify user still exists
        const user = await userRepository.findUserById(decoded.sub);
        if (!user) {
            throw new AppError('User associated with token not found.', 401, 'USER_NOT_FOUND');
        }

        // Exclude pin_hash from user object
        const { pin_hash, ...userWithoutPin } = user;
        req.user = userWithoutPin;

        next();
    } catch (error) {
        // Handle JWT-specific errors
        if (error instanceof jwt.TokenExpiredError) {
            return next(new AppError('Access token has expired.', 401, 'TOKEN_EXPIRED'));
        }
        if (error instanceof jwt.JsonWebTokenError) {
            return next(new AppError('Invalid access token.', 401, 'INVALID_TOKEN'));
        }
        
        next(error);
    }
};

module.exports = {
    authenticateToken
}; 