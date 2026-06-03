// Launching the LDV generation routine to spawn 500,000 records
// We pass a scope size of 1 to run one execution block of 10k records per batch transaction thread loop
DataGeneratorBatch seederJob = new DataGeneratorBatch(500000);
Database.executeBatch(seederJob, 1);