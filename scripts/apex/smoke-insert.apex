// =========================================================================
// SMOKE TEST: PropertyCare Data Model Validation
// This script inserts a Tenant__c and a linked Service_Request__c record
// to ensure all required fields, lookups, and unique constraints validate.
// =========================================================================

// 1. Instantiate and populate the Tenant record
// Name field is defined as standard Text (Length: 80) in the blueprint
Tenant__c testTenant = new Tenant__c(
    Name = 'Sandeep Kotaprolu',
    Email__c = 'sandeep.test@propertycare.com',
    Phone__c = '+919999999999',
    // Portal User Id must be Unique; using timestamp to prevent duplicate run failures
    Portal_User_Id__c = 'PORTAL_USR_' + DateTime.now().getTime(),
    Unit_Number__c = 'Apt-404',
    Active__c = true // Default is true, setting explicitly for smoke test clarity
);

System.debug('--- Inserting Tenant record ---');
insert testTenant;
System.debug('Tenant successfully inserted with ID: ' + testTenant.Id);


// 2. Instantiate and populate the Service Request record
// Relates directly to the Tenant record created above
Service_Request__c testRequest = new Service_Request__c(
    Tenant__c = testTenant.Id,
    // External Id must be Unique; using unique key format for safety
    External_Id__c = 'REQ_EXT_' + DateTime.now().getTime(),
    Category__c = 'Plumbing', // Must match active picklist values
    Priority__c = 'Medium',   // Must match active picklist values
    Description__c = 'Water leakage detected from the master bathroom ceiling tile.',
    Status__c = 'New',        // Picklist default is 'New'
    Source__c = 'Portal',     // Picklist value
    Requested_Slot__c = DateTime.now().addDays(1) // Preferred scheduling slot
    // Converted Work Order is left null as it's optional on creation
);

System.debug('--- Inserting Service Request record ---');
insert testRequest;
System.debug('Service Request successfully inserted with ID: ' + testRequest.Id);


// =========================================================================
// Verification & Assertions Section
// =========================================================================

// Query the records back from the database layer to inspect fields populate correctly
Tenant__c verifiedTenant = [
    SELECT Id, Name, Portal_User_Id__c 
    FROM Tenant__c 
    WHERE Id = :testTenant.Id 
    LIMIT 1
];

Service_Request__c verifiedRequest = [
    SELECT Id, Name, Tenant__c, External_Id__c, Status__c 
    FROM Service_Request__c 
    WHERE Id = :testRequest.Id 
    LIMIT 1
];

System.debug('--- Verifying Data Integrity Assertions ---');

// Assertions to verify DB state matches expectations
System.assert(verifiedTenant != null, 'Verification Failed: Tenant record not found in database.');
System.assert(verifiedRequest != null, 'Verification Failed: Service Request record not found in database.');

// Check relationship link integrity
System.assertEquals(verifiedTenant.Id, verifiedRequest.Tenant__c, 'Verification Failed: Service Request is not mapped to the correct Tenant.');

// Verify system-generated Auto-Numbers populate as expected
System.assert(String.isNotBlank(verifiedRequest.Name), 'Verification Failed: Service Request Auto-Number did not generate.');

System.debug('==================================================');
System.debug(' STATUS: SUCCESS — DATA MODEL VERIFIED');
System.debug(' Tenant Name: ' + verifiedTenant.Name);
System.debug(' Tenant Portal ID: ' + verifiedTenant.Portal_User_Id__c);
System.debug(' Service Request ID (Auto-Number): ' + verifiedRequest.Name);
System.debug(' Service Request External Key: ' + verifiedRequest.External_Id__c);
System.debug('==================================================');