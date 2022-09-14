// Account quick search for the skyAccountSearch component (Skyward 2019)
public with sharing class SKY_AccountSearchController {
    @AuraEnabled(cacheable=true)
    public static List<Account> search(String searchTerm) {
        return Database.query('SELECT Id, Name FROM Account WHERE Name LIKE \'%' + searchTerm + '%\'');
    }
}
