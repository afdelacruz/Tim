describe('BalanceHistoryService', () => {
    it('should fail because service does not exist', () => {
        const BalanceHistoryService = require('../services/BalanceHistoryService');
        expect(true).toBe(false); // This should fail
    });
}); 