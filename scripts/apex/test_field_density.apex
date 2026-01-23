/**
 * Task 2.6: Test field density calculation
 * Tests the new SchemaHelper.calculateFieldDensity() method
 */

System.debug('===== TESTING FIELD DENSITY CALCULATION =====');

// Test 1: Calculate density for Opportunity object
System.debug('\n--- Test 1: Opportunity field density (100 records) ---');
Map<String, Integer> oppDensity = SchemaHelper.calculateFieldDensity('Opportunity', 100);

System.debug('Total fields analyzed: ' + oppDensity.size());
System.debug('\nField density results:');

// Show fields sorted by density (highest first)
List<String> fieldNames = new List<String>(oppDensity.keySet());
for (String fieldName : fieldNames) {
    Integer density = oppDensity.get(fieldName);
    String bar = '';
    for (Integer i = 0; i < density / 5; i++) {
        bar += '█';
    }
    System.debug(fieldName + ': ' + density + '% ' + bar);
}

// Test 2: Calculate density for Account object
System.debug('\n--- Test 2: Account field density (50 records) ---');
Map<String, Integer> accDensity = SchemaHelper.calculateFieldDensity('Account', 50);
System.debug('Total fields analyzed: ' + accDensity.size());

// Show only high-density fields (>50%)
System.debug('\nHigh-density fields (>50%):');
for (String fieldName : accDensity.keySet()) {
    Integer density = accDensity.get(fieldName);
    if (density > 50) {
        System.debug(fieldName + ': ' + density + '%');
    }
}

// Test 3: Test with small sample
System.debug('\n--- Test 3: Contact density (10 records) ---');
Map<String, Integer> contactDensity = SchemaHelper.calculateFieldDensity('Contact', 10);
System.debug('Total fields analyzed: ' + contactDensity.size());

System.debug('\n===== TESTS COMPLETE =====');
