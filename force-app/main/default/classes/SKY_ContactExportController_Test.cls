@IsTest
private class SKY_ContactExportController_Test {
    @IsTest static void exportsContactsForAccount() {
        Account a = new Account(Name = 'Export Test Co');
        Account other = new Account(Name = 'Other Co');
        insert new List<Account>{ a, other };
        insert new List<Contact>{
            new Contact(AccountId = a.Id, FirstName = 'Ana', LastName = 'Lima', Email = 'ana.lima@exporttest.example', Phone = '555-0100'),
            new Contact(AccountId = a.Id, FirstName = 'Ben', LastName = 'Ortiz', Email = 'ben.ortiz@exporttest.example'),
            new Contact(AccountId = other.Id, FirstName = 'Cy', LastName = 'Park', Email = 'cy.park@other.example')
        };

        Test.startTest();
        List<Contact> result = SKY_ContactExportController.exportForAccount(a.Id);
        Test.stopTest();

        System.assertEquals(2, result.size(), 'only the account\'s own contacts');
        Set<String> emails = new Set<String>();
        for (Contact c : result) emails.add(c.Email);
        System.assert(emails.contains('ana.lima@exporttest.example'));
        System.assert(!emails.contains('cy.park@other.example'));
    }
}
