@IsTest
private class SKY_AccountSearchController_Test {
    @TestSetup static void setup() {
        insert new List<Account>{
            new Account(Name = 'Harbor Logistics Test'),
            new Account(Name = 'Harbor Freight Test'),
            new Account(Name = 'Summit Retail Test')
        };
    }

    @IsTest static void findsMatchingAccounts() {
        List<Account> results = SKY_AccountSearchController.search('Harbor');
        System.assertEquals(2, results.size(), 'two accounts match Harbor');
        for (Account a : results) {
            System.assert(a.Name.contains('Harbor'), 'unexpected match ' + a.Name);
        }
    }

    @IsTest static void noMatchReturnsEmpty() {
        System.assertEquals(0, SKY_AccountSearchController.search('Nonexistent Co').size());
    }
}
