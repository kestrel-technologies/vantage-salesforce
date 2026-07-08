// Lists the queues the routing services resolve by developer name and flags any that are missing.
Set<String> expected = new Set<String>{
    'SDR_AMER_Enterprise', 'SDR_AMER_MidMarket', 'SDR_EMEA', 'SDR_APAC',
    'L1_Platform_AMER', 'L1_Platform_INTL', 'L1_Apps_AMER', 'L1_Apps_INTL', 'L1_Services', 'L2_Escalations'
};
Map<String, Group> found = new Map<String, Group>();
for (Group g : [SELECT Id, DeveloperName, Name FROM Group WHERE Type = 'Queue' AND DeveloperName IN :expected]) {
    found.put(g.DeveloperName, g);
}
for (String name : expected) {
    System.debug((found.containsKey(name) ? 'ok       ' : 'MISSING  ') + name);
}
