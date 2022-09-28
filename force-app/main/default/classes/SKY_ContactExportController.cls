// Contact export for the skyContactExport button on the Account page.
public without sharing class SKY_ContactExportController {
    @AuraEnabled
    public static List<Contact> exportForAccount(Id accountId) {
        List<Contact> contacts = [SELECT Id, Name, Email, Phone, MobilePhone, Title FROM Contact WHERE AccountId = :accountId];
        System.debug(JSON.serialize(contacts));
        return contacts;
    }
}
